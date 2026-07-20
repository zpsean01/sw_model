"""
Stage 4 — Event-Driven Architecture Analysis (protocol-agnostic)

Combines AST-level (Stage 2) and binary-level (Stage 3) results to build an
event-driven architecture model, perform static security checks, and run
protocol-agnostic rule-based conformance checks using rules/ + spec_model oracle.
"""

import json
import logging
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List

from modules.base import BaseStage
from modules.stage4.protocol_conformance import ProtocolConformanceAnalyzer

logger = logging.getLogger(__name__)


class Stage4EventArchAnalysis(BaseStage):
    """Event-driven architecture modelling and static analysis."""

    def run(self, context: Dict[str, Any]) -> Dict[str, Any]:
        params = self.config["params"]
        output_dir = self.setup_output_dir(params["output_dir"])
        ast_dir = Path(params["ast_output_dir"])
        elf_dir = Path(params["elf_output_dir"])
        checks_cfg = params.get("checks", {})

        # ----------------------------------------------------------
        # Load data from previous stages
        # ----------------------------------------------------------
        interrupts = self._load_if_exists(ast_dir / "interrupts" / "interrupts.json")
        functions = self._load_if_exists(ast_dir / "functions" / "functions.json")
        ast_call_graph = self._load_if_exists(ast_dir / "call_graph" / "call_graph.json")
        binary_globals = self._load_if_exists(elf_dir / "globals" / "binary_globals.json")

        # ----------------------------------------------------------
        # Build the event-driven architecture model
        # ----------------------------------------------------------
        model = self._build_architecture_model(
            interrupts=interrupts,
            ast_call_graph=ast_call_graph,
            functions=functions,
        )
        self.save_json("event_architecture.json", model)

        # ----------------------------------------------------------
        # Run static security checks (stubs for MVP)
        # ----------------------------------------------------------
        report: Dict[str, Any] = {
            "summary": {},
            "findings": [],
        }

        if checks_cfg.get("irq_priority", True):
            report["findings"].extend(self._check_irq_priority(model))

        if checks_cfg.get("critical_section", True):
            report["findings"].extend(self._check_critical_section(model, ast_call_graph))

        if checks_cfg.get("stack_analysis", True):
            report["findings"].extend(self._check_stack_usage(ast_call_graph, functions))

        if checks_cfg.get("uninit_globals", True):
            report["findings"].extend(self._check_uninit_globals(model, binary_globals, functions))

        if checks_cfg.get("reentrancy", True):
            report["findings"].extend(self._check_reentrancy(model, ast_call_graph))

        if checks_cfg.get("state_machine_integrity", True):
            sm_data = self._load_if_exists(ast_dir / "state_machines" / "state_machines.json")
            report["findings"].extend(self._check_state_machine_integrity(sm_data))

        # ----------------------------------------------------------
        # Protocol-agnostic conformance: rules/ + spec_model oracle
        # ----------------------------------------------------------
        if checks_cfg.get("protocol_conformance", True):
            rules_dir = Path(params.get("rules_dir", "rules"))
            spec_model_dir = Path(params.get("spec_model_dir", ""))
            static_dir = ast_dir  # Stage 2 output

            analyzer = ProtocolConformanceAnalyzer(params)

            # Load protocol-agnostic rules
            n_constraints = analyzer.load_rules(rules_dir / "stage4")

            # Load spec_model oracle (protocol-specific binding)
            oracle_ok = analyzer.load_oracle(spec_model_dir)

            # Load firmware analysis data (Stage 2 output)
            fw_ok = analyzer.load_firmware(static_dir)

            # Load binary (Stage 3) call graph to supplement Stage 2's
            # empty ``calls`` arrays (libclang limitation)
            if analyzer.oracle.get("protocol") and analyzer.oracle.get("version"):
                proto_dir = f"{analyzer.oracle['protocol']}_{analyzer.oracle['version']}"
                binary_cg = output_dir / proto_dir / "call_graph_unified.json"
                analyzer.load_binary_call_graph(binary_cg)

            if n_constraints > 0 and oracle_ok and fw_ok:
                pc_findings = analyzer.run_all_checks()
                for f in pc_findings:
                    report["findings"].append(f)
                logger.info("Protocol conformance: %d findings", len(pc_findings))

                protocol_report = {
                    "spec_model_dir": str(spec_model_dir),
                    "total_protocol_findings": len(pc_findings),
                    "findings": pc_findings,
                }
                # ── Save to protocol-versioned path ─────────────
                self._save_protocol_conformance_agnostic(
                    protocol_report, analyzer.oracle, output_dir
                )
            else:
                logger.warning(
                    "Protocol conformance skipped: rules=%d, oracle=%s, fw=%s",
                    n_constraints, oracle_ok, fw_ok)

        report["summary"] = self._summarize_findings(report["findings"])
        self.save_json("security_report.json", report)

        return {
            "stage4": {
                "output_dir": str(output_dir),
                "model": str(output_dir / "event_architecture.json"),
                "report": str(output_dir / "security_report.json"),
                "total_findings": report["summary"].get("total", 0),
            }
        }

    # ------------------------------------------------------------------
    # Helpers
    # ------------------------------------------------------------------

    def _load_if_exists(self, path: Path) -> List[Any]:
        if path.exists():
            with open(path, "r", encoding="utf-8") as f:
                return json.load(f)
        logger.warning("File not found (skipping): %s", path)
        return []

    # ------------------------------------------------------------------
    # Architecture model
    # ------------------------------------------------------------------

    def _build_architecture_model(
        self,
        interrupts: List[Dict],
        ast_call_graph: List[Dict],
        functions: List[Dict],
    ) -> Dict[str, Any]:
        """Build an event-driven architecture model."""
        isr_names = {i["name"] for i in interrupts}
        isr_reachable = self._compute_reachable_from_isrs(isr_names, ast_call_graph)
        shared_functions = set()
        for caller, callees in isr_reachable.items():
            for c in callees:
                shared_functions.add(c)
        return {
            "total_isrs": len(interrupts),
            "isr_list": sorted(isr_names),
            "isr_reachable_functions": list(shared_functions),
            "model_type": "event_driven",
        }

    def _compute_reachable_from_isrs(
        self, isr_names: set, call_graph: List
    ) -> Dict[str, List[str]]:
        if isinstance(call_graph, list) and len(call_graph) == 2:
            edges = call_graph[1]
        else:
            edges = call_graph if isinstance(call_graph, list) else []
        graph: Dict[str, List[str]] = {}
        for e in edges:
            src = e.get("source")
            tgt = e.get("target")
            if src and tgt:
                graph.setdefault(src, []).append(tgt)
        result: Dict[str, List[str]] = {}

        def reachable(name: str, visited: set) -> set:
            if name in visited:
                return set()
            visited.add(name)
            callees = graph.get(name, [])
            callees_set = set(callees)
            for c in callees:
                callees_set |= reachable(c, visited)
            return callees_set

        for isr in isr_names:
            result[isr] = list(reachable(isr, set()))
        return result

    # ------------------------------------------------------------------
    # Security checks (stubs)
    # ------------------------------------------------------------------

    def _check_irq_priority(self, model: Dict) -> List[Dict]:
        return []

    def _check_critical_section(self, model: Dict, call_graph: List[Dict]) -> List[Dict]:
        return []

    def _check_stack_usage(self, call_graph: List[Dict], functions: List[Dict]) -> List[Dict]:
        return []

    def _check_uninit_globals(self, model: Dict, binary_globals: List[Dict], functions: List[Dict]) -> List[Dict]:
        return []

    def _check_reentrancy(self, model: Dict, call_graph: List[Dict]) -> List[Dict]:
        return []

    def _check_state_machine_integrity(self, state_machines: List[Dict]) -> List[Dict]:
        findings = []
        for sm in state_machines:
            if len(sm.get("states", [])) < 2:
                findings.append({
                    "type": "state_machine_integrity",
                    "severity": "low",
                    "message": f"State machine '{sm['name']}' has fewer than 2 states",
                    "location": {"file": sm.get("file", ""), "line": sm.get("line", 0)},
                })
        return findings

    # ------------------------------------------------------------------
    # Protocol-versioned save
    # ------------------------------------------------------------------

    def _save_protocol_conformance_agnostic(
        self,
        protocol_report: Dict[str, Any],
        oracle: Dict[str, Any],
        output_dir: Path,
    ) -> None:
        """Save protocol conformance report under protocol-versioned path."""
        proto = oracle.get("protocol", "UNKNOWN")
        version = oracle.get("version", "unknown")
        proto_dir = f"{proto}_{version}"
        proto_path = output_dir / proto_dir / "protocol_conformance"
        proto_path.mkdir(parents=True, exist_ok=True)

        ts = datetime.now().strftime("%Y%m%d_%H%M%S_%f")[:-3]
        ts_path = proto_path / f"report_{ts}.json"
        latest_path = proto_path / "report.json"

        with open(ts_path, "w", encoding="utf-8") as f:
            json.dump(protocol_report, f, indent=2, ensure_ascii=False)
        with open(latest_path, "w", encoding="utf-8") as f:
            json.dump(protocol_report, f, indent=2, ensure_ascii=False)

        logger.info("Protocol-versioned conformance saved: %s (latest: %s)",
                    ts_path, latest_path)

    def _summarize_findings(self, findings: List[Dict]) -> Dict[str, Any]:
        if not findings:
            return {"total": 0, "severities": {}}
        severities = {}
        for f in findings:
            s = f.get("severity", "info")
            severities[s] = severities.get(s, 0) + 1
        return {"total": len(findings), "severities": severities}