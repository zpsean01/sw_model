"""
Stage 4 — Event-Driven Architecture Analysis

Combines AST-level (Stage 2) and binary-level (Stage 3) results to build an
event-driven architecture model and perform static security checks.
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
        binary_functions = self._load_if_exists(elf_dir / "functions" / "binary_functions.json")
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
        # Run static security checks
        # ----------------------------------------------------------
        report: Dict[str, Any] = {
            "summary": {},
            "findings": [],
        }

        if checks_cfg.get("irq_priority", True):
            findings = self._check_irq_priority(model)
            report["findings"].extend(findings)

        if checks_cfg.get("critical_section", True):
            findings = self._check_critical_section(model, ast_call_graph)
            report["findings"].extend(findings)

        if checks_cfg.get("stack_analysis", True):
            findings = self._check_stack_usage(ast_call_graph, functions)
            report["findings"].extend(findings)

        if checks_cfg.get("uninit_globals", True):
            findings = self._check_uninit_globals(
                model, binary_globals, functions
            )
            report["findings"].extend(findings)

        if checks_cfg.get("reentrancy", True):
            findings = self._check_reentrancy(model, ast_call_graph)
            report["findings"].extend(findings)

        if checks_cfg.get("state_machine_integrity", True):
            sm_data = self._load_if_exists(ast_dir / "state_machines" / "state_machines.json")
            findings = self._check_state_machine_integrity(sm_data)
            report["findings"].extend(findings)

        # ----------------------------------------------------------
        # Protocol conformance analysis (DDR5 vs spec_model)
        # ----------------------------------------------------------
        if checks_cfg.get("protocol_conformance", True):
            spec_model_path = Path(params.get("spec_model_path", ""))
            if not spec_model_path.exists():
                logger.warning("spec_model not found: %s (skipping protocol conformance)", spec_model_path)
            else:
                with open(spec_model_path, "r", encoding="utf-8") as f:
                    spec_model = json.load(f)
                analyzer = ProtocolConformanceAnalyzer(spec_model)

                pc_findings = []
                registers_data = self._load_if_exists(ast_dir / "registers" / "registers.json")

                # Check 1: State machine completeness
                pc_findings.extend(analyzer.check_state_machine_completeness(sm_data))

                # Check 2: Timing constraint audit
                pc_findings.extend(analyzer.check_timing_constraints(functions, ast_call_graph))

                # Check 3: Register configuration audit
                pc_findings.extend(analyzer.check_register_config(functions, registers_data))

                # Check 4: Error handling coverage
                pc_findings.extend(analyzer.check_error_handling(sm_data, ast_call_graph))

                # Check 5: Cross-register dependency
                pc_findings.extend(analyzer.check_cross_register_dependency(functions))

                for f in pc_findings:
                    report["findings"].append(f)

                protocol_report = {
                    "spec_model": str(spec_model_path),
                    "total_protocol_findings": len(pc_findings),
                    "findings": pc_findings,
                }
                # ── Save to protocol-versioned path ─────────────────────
                self._save_protocol_conformance(
                    protocol_report, spec_model, output_dir
                )

                logger.info("Protocol conformance: %d findings", len(pc_findings))

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

        # Identify which functions are reachable from ISRs
        isr_reachable = self._compute_reachable_from_isrs(isr_names, ast_call_graph)

        # Identify shared globals (accessed by both ISR and main context)
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
        """Compute the transitive closure of callees for each ISR.

        call_graph is a NetworkX MultiDiGraph serialization:
            [[nodes], [edges]] where each edge has {source, target, ...}
        """
        # Extract edges from [nodes, edges] format
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
    # Security checks
    # ------------------------------------------------------------------

    def _check_irq_priority(self, model: Dict) -> List[Dict]:
        findings = []
        logger.info("IRQ priority check — stub")
        return findings

    def _check_critical_section(
        self, model: Dict, call_graph: List[Dict]
    ) -> List[Dict]:
        findings = []
        logger.info("Critical section check — stub")
        return findings

    def _check_stack_usage(
        self, call_graph: List[Dict], functions: List[Dict]
    ) -> List[Dict]:
        findings = []
        logger.info("Stack usage analysis — stub")
        return findings

    def _check_uninit_globals(
        self, model: Dict, binary_globals: List[Dict], functions: List[Dict]
    ) -> List[Dict]:
        findings = []
        logger.info("Uninitialized global variable check — stub")
        return findings

    def _check_reentrancy(
        self, model: Dict, call_graph: List[Dict]
    ) -> List[Dict]:
        findings = []
        # Simple heuristic: look for global variables accessed both in ISR
        # reachable paths and normal context
        logger.info("Reentrancy check — stub")
        return findings

    def _check_state_machine_integrity(
        self, state_machines: List[Dict]
    ) -> List[Dict]:
        findings = []
        for sm in state_machines:
            if len(sm.get("states", [])) < 2:
                findings.append({
                    "type": "state_machine_integrity",
                    "severity": "low",
                    "message": f"State machine '{sm['name']}' has fewer than 2 states",
                    "location": {"file": sm.get("file", ""), "line": sm.get("line", 0)},
                })
        logger.info("State machine integrity check: %d findings", len(findings))
        return findings

    # ------------------------------------------------------------------
    # Protocol-versioned save
    # ------------------------------------------------------------------

    def _save_protocol_conformance(
        self,
        protocol_report: Dict[str, Any],
        spec_model: Dict[str, Any],
        output_dir: Path,
    ) -> None:
        """Save a copy of the protocol conformance report under the
        protocol-versioned subdirectory, e.g.
        data/modeling/DDR5_JESD79-5C/protocol_conformance/report_20260620_220000.json

        A latest copy (report.json) is also saved and overwritten on each run
        so downstream stages always find a stable reference.
        """
        meta = spec_model.get("metadata", {})
        proto_dir = f"{meta.get('protocol', 'UNKNOWN')}_{meta.get('version', 'unknown')}"
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
        return {
            "total": len(findings),
            "severities": severities,
        }