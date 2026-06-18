"""
Stage 4 — Event-Driven Architecture Analysis

Combines AST-level (Stage 2) and binary-level (Stage 3) results to build an
event-driven architecture model and perform static security checks.
"""

import json
import logging
from pathlib import Path
from typing import Any, Dict, List

from modules.base import BaseStage

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
        interrupts = self._load_if_exists(ast_dir / "interrupts.json")
        functions = self._load_if_exists(ast_dir / "functions.json")
        ast_call_graph = self._load_if_exists(ast_dir / "call_graph_functions.json")
        binary_functions = self._load_if_exists(elf_dir / "binary_functions.json")
        binary_globals = self._load_if_exists(elf_dir / "binary_globals.json")

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
            sm_data = self._load_if_exists(ast_dir / "state_machines.json")
            findings = self._check_state_machine_integrity(sm_data)
            report["findings"].extend(findings)

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
        self, isr_names: set, call_graph: List[Dict]
    ) -> Dict[str, List[str]]:
        """Compute the transitive closure of callees for each ISR."""
        graph = {e["caller"]: e.get("callees", []) for e in call_graph}
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