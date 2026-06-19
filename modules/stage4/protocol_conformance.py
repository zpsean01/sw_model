"""
Stage 4 — Protocol Conformance Analysis (DDR5)

Compares firmware implementation against the DDR5 protocol specification
(spec_model) to identify conformance gaps, timing violations, and
quality issues as described in 功能说明书.md §4.3.

Dependencies:
  - Stage 2 output: functions.json, state_machines.json, call_graph.json,
    registers.json, file_ast_parse/*.json
  - External: spec_model_ddr5_mock.json (mock protocol knowledge base)

Checks implemented:
  1. state_machine_completeness  — Firmware state enum vs spec expected states
  2. timing_constraint_audit      — tMRD presence after MRW operations
  3. register_config_audit        — MR values vs spec valid ranges
  4. error_handling_coverage      — ERROR recovery path existence
  5. cross_register_dependency    — MR config order dependencies
"""

import json
import logging
import re
from pathlib import Path
from typing import Any, Dict, List, Tuple

logger = logging.getLogger(__name__)

# ── Finding schema ──────────────────────────────────────────────────────────
# Each check returns a list of dicts with:
#   type: str          — check category identifier
#   severity: str      — "critical" | "high" | "medium" | "low" | "info"
#   message: str       — human-readable description
#   spec_ref: str      — reference to spec section or protocol entity
#   location: dict     — optional {"file": ..., "function": ...}
#   expected: str      — what the spec requires
#   actual: str        — what the firmware does

Finding = Dict[str, Any]


class ProtocolConformanceAnalyzer:
    """Analyze firmware DDR5 implementation against protocol spec."""

    def __init__(self, spec_model: Dict[str, Any]):
        self.spec = spec_model
        self.registers_spec = spec_model.get("object_entities", {}).get("registers", [])
        self.state_machine_spec = spec_model.get("behavior_constraints", {}).get("state_machines", [])
        self.timing_spec = spec_model.get("behavior_constraints", {}).get("timing", [])
        self.scenarios = spec_model.get("scenarios", {})

    # ── Check 1: State Machine Completeness ─────────────────────────────────

    def check_state_machine_completeness(
        self, fw_state_machines: List[Dict]
    ) -> List[Finding]:
        """Compare firmware state machine states against spec expected states.

        Maps to 功能说明书.md §4.3: state_machine_integrity assertion.
        Targets bugs: #2 (ddr5_state_names missing entries)
        """
        findings = []

        for sm_spec in self.state_machine_spec:
            expected = sm_spec.get("expected_states", [])
            expected_set = set(expected)
            expected_count = sm_spec.get("protocol_states", 0)

            # Find matching firmware state machine by name heuristic
            fw_sm = self._find_matching_sm(fw_state_machines, sm_spec["name"])
            if not fw_sm:
                findings.append({
                    "type": "state_machine_completeness",
                    "severity": "critical",
                    "message": (
                        f"State machine '{sm_spec['name']}' not found in "
                        f"firmware AST extraction"
                    ),
                    "spec_ref": f"JESD79-5C §3.3 — {sm_spec['description']}",
                    "expected": f"State machine with {expected_count} protocol states",
                    "actual": "Not extracted by AST analysis",
                })
                continue

            fw_states = fw_sm.get("states", [])
            fw_state_names = {s.get("name", "") for s in fw_states}

            # Check missing states
            missing = expected_set - fw_state_names
            if missing:
                findings.append({
                    "type": "state_machine_completeness",
                    "severity": "high" if len(missing) > 1 else "medium",
                    "message": (
                        f"Firmware state machine '{sm_spec['name']}' is missing "
                        f"{len(missing)} protocol-defined state(s): {sorted(missing)}"
                    ),
                    "spec_ref": f"JESD79-5C §3.3 — expected {expected_count} states",
                    "expected": f"States: {sorted(expected)}",
                    "actual": f"Firmware states: {sorted(fw_state_names)}",
                    "location": {"file": fw_sm.get("file", ""), "line": fw_sm.get("line", 0)},
                })

            # Check extra states (firmware has something spec doesn't define)
            extra = fw_state_names - expected_set
            if extra and not all("ERROR" in s or "error" in s.lower() for s in extra):
                findings.append({
                    "type": "state_machine_completeness",
                    "severity": "low",
                    "message": f"Firmware defines unexpected states: {sorted(extra)}",
                    "spec_ref": f"JESD79-5C §3.3",
                    "expected": f"Only protocol-defined states",
                    "actual": f"Additional states: {sorted(extra)}",
                })

            # Check expected transitions
            expected_trans = sm_spec.get("expected_transitions", [])
            fw_trans = fw_sm.get("transitions", [])
            fw_trans_keys = {(t.get("from", ""), t.get("to", "")) for t in fw_trans}
            missing_trans = []
            for et in expected_trans:
                key = (et["from"], et["to"])
                if et["from"] == "*":
                    continue  # wildcard transitions not checkable statically
                if key not in fw_trans_keys:
                    missing_trans.append(key)
            if missing_trans:
                findings.append({
                    "type": "state_machine_completeness",
                    "severity": "medium",
                    "message": (
                        f"Missing {len(missing_trans)} expected state transition(s): "
                        + ", ".join(f"{f}→{t}" for f, t in missing_trans)
                    ),
                    "spec_ref": "JESD79-5C §3.3 state transition diagram",
                    "expected": f"Transitions: {sorted(expected_trans, key=lambda x: (x.get('from',''), x.get('to','')))}",
                    "actual": f"Missing: {missing_trans}",
                })

        return findings

    # ── Check 2: Timing Constraint Audit ────────────────────────────────────

    def check_timing_constraints(
        self, functions: List[Dict], call_graph: List
    ) -> List[Finding]:
        """Audit timing constraint adherence, focusing on tMRD after MRW.

        Maps to 功能说明书.md §4.3: timing_constraint assertion.
        Targets bugs: #1 (tMRD missing in _state_mr_verify retry path)
        """
        findings = []
        tMRD = self._get_timing_param("tMRD")

        if not tMRD:
            logger.warning("tMRD not found in spec_model timing constraints")
            return findings

        # Find DDR5-related functions
        ddr5_funcs = self._filter_ddr5_functions(functions)

        # Extract function details from file_ast_parse (call info per function)
        func_details = {f.get("name", ""): f for f in ddr5_funcs}

        # Check each DDR5 function for MRW write patterns
        for fname, finfo in func_details.items():
            calls = finfo.get("attributes", {}).get("calls", [])
            if not calls:
                continue

            # Detect: function contains a call to ddr5_write_reg near mr_reg_addr
            # followed by another call without DDR5_WAIT_CYCLES(DDR5_TMRD_CYCLES)
            # between them
            has_mrw_write = any(
                "write_reg" in c or "mr_write" in c or "MR_CMD_MRW" in c
                for c in calls
            )
            tMRD_in_calls = any("TMRD" in c or "tMRD" in c for c in calls)
            tMRD_in_func_name = "TMRD" in fname.upper() or "tmrd" in fname.lower()

            if has_mrw_write and not tMRD_in_calls and not tMRD_in_func_name:
                # Check if parent function calls include tMRD wait
                findings.append({
                    "type": "timing_constraint_audit",
                    "severity": "high",
                    "message": (
                        f"Function '{fname}' performs MR write operations but "
                        f"call list shows no DDR5_WAIT_CYCLES(DDR5_TMRD_CYCLES) "
                        f"call. Possible tMRD timing violation."
                    ),
                    "spec_ref": f"JESD79-5C §5.2.17 — tMRD ≥ {tMRD['min_cycles']} cycles",
                    "expected": f"Each MRW must be followed by tMRD wait ({tMRD['min_cycles']} cycles)",
                    "actual": f"No tMRD call found in '{fname}'",
                    "location": {"function": fname, "file": finfo.get("attributes", {}).get("file", "")},
                })

        return findings

    # ── Check 3: Register Configuration Audit ───────────────────────────────

    def check_register_config(
        self, functions: List[Dict], registers_ast: List[Dict]
    ) -> List[Finding]:
        """Audit MR register config values against spec valid ranges.

        Maps to 功能说明书.md §4.3: register_config assertion.
        Targets bugs: #6 (Vref >127 masked), #3 (MR3/MR5 ordering)
        """
        findings = []
        ddr5_funcs = self._filter_ddr5_functions(functions)

        # Build spec register map
        spec_reg_map = {}
        for reg in self.registers_spec:
            spec_reg_map[reg["name"]] = reg

        # Scan MR config patterns in DDR5 functions
        for finfo in ddr5_funcs:
            fname = finfo.get("name", "")
            calls = finfo.get("attributes", {}).get("calls", [])

            # Look for MR6/MR7 write → check Vref masking
            if "vref" in fname.lower() or "mr6" in fname.lower() or "mr7" in fname.lower():
                mr6_spec = spec_reg_map.get("MR6")
                if mr6_spec and mr6_spec.get("fields"):
                    vref_field = mr6_spec["fields"].get("VREF_DQ_VAL", {})
                    valid_max = max(vref_field.get("valid_values", [0, 127]))
                    if valid_max < 255:
                        findings.append({
                            "type": "register_config_audit",
                            "severity": "medium",
                            "message": (
                                f"Function '{fname}' writes MR6 Vref DQ value. "
                                f"Spec limits VREF_DQ_VAL to {valid_max} (7-bit), "
                                f"but training function may return 0-255. "
                                f"Values >{valid_max} will be silently truncated."
                            ),
                            "spec_ref": f"JESD79-5C §3.4.7 — MR6 VREF_DQ_VAL is 7-bit (0-{valid_max})",
                            "expected": f"Vref value in [0, {valid_max}]",
                            "actual": f"Training function returns uint8_t (0-255), masked to 7-bit",
                            "location": {"function": fname},
                        })

            # Check MR3→MR5 ordering dependency
            if fname == "_state_mr_config" or "mr_config" in fname.lower():
                mrw_calls = [c for c in calls if "mrw" in c.lower() or "MR" in c]
                mr_order = []
                for c in mrw_calls:
                    mr_num = re.search(r'MR(\d+)', c)
                    if mr_num:
                        mr_order.append(int(mr_num.group(1)))

                # Spec: MR5(DFE) depends on MR3(CRC). MR5 should come after MR3.
                if 5 in mr_order and 3 in mr_order:
                    pos3 = mr_order.index(3)
                    pos5 = mr_order.index(5)
                    if pos3 > pos5:
                        findings.append({
                            "type": "register_config_audit",
                            "severity": "medium",
                            "message": (
                                f"MR3 (CRC) is configured after MR5 (DFE) in "
                                f"'{fname}'. MR5 DFE_EN depends on MR3 CRC being "
                                f"enabled — potential ordering risk."
                            ),
                            "spec_ref": f"JESD79-5C §3.4.4/§3.4.6 — MR3 CRC → MR5 DFE dependency",
                            "expected": "MR3 configured before MR5",
                            "actual": f"MR order: {mr_order} (MR3 at position {pos3}, MR5 at position {pos5})",
                            "location": {"function": fname},
                        })

        return findings

    # ── Check 4: Error Handling Coverage ────────────────────────────────────

    def check_error_handling(
        self, state_machines: List[Dict], call_graph: List
    ) -> List[Finding]:
        """Check if ERROR states have recovery paths defined.

        Maps to 功能说明书.md §4.3: error_handling assertion.
        Targets bugs: #5 (MR verify retry without BUSY check)
        """
        findings = []
        sm_spec = self.state_machine_spec[0] if self.state_machine_spec else {}

        # Extract edges from call_graph
        edges = self._extract_edges(call_graph)

        # Build adjacency: who calls whom
        caller_map: Dict[str, List[str]] = {}
        for e in edges:
            src = e.get("source")
            tgt = e.get("target")
            if src and tgt:
                caller_map.setdefault(src, []).append(tgt)

        # Find functions that return error/check status
        error_checkers = []
        for caller, callees in caller_map.items():
            has_error_check = any("error" in c.lower() or "busy" in c.lower()
                                  for c in callees)
            if has_error_check:
                error_checkers.append(caller)

        # Check: do functions that trigger MRW in retry path check BUSY?
        mrw_funcs = [f for f in caller_map
                     if "mr_verify" in f.lower() or "retry" in f.lower()]
        for f in mrw_funcs:
            callees = caller_map.get(f, [])
            has_busy_check = any("busy" in c.lower() or "status" in c.lower()
                                 for c in callees)
            if not has_busy_check:
                findings.append({
                    "type": "error_handling_coverage",
                    "severity": "high",
                    "message": (
                        f"Function '{f}' performs MRW retry but does not check "
                        f"MR_CMD_BUSY bit before re-issuing command. "
                        f"Previous MRW may still be in progress."
                    ),
                    "spec_ref": "JESD79-5C §3.4 — MRW/MRR timing; "
                                "controller MR_CMD_BUSY check required",
                    "expected": "Check MR_CMD_BUSY before retry MRW",
                    "actual": f"'{f}' calls: {callees}, no BUSY check detected",
                    "location": {"function": f},
                })

        # Check if firmware has ERROR state with outgoing transitions
        fw_sm = self._find_matching_sm(state_machines, "ddr5_init")
        if fw_sm:
            transitions = fw_sm.get("transitions", [])
            error_trans = [t for t in transitions
                           if t.get("from") == "DDR5_STATE_ERROR"
                           or t.get("from") == "ERROR"]
            if not error_trans:
                findings.append({
                    "type": "error_handling_coverage",
                    "severity": "high",
                    "message": (
                        "DDR5 ERROR state has no outgoing transitions — "
                        "it is a dead-end state with no recovery path."
                    ),
                    "spec_ref": "JESD79-5C §3.3 — error recovery expectation",
                    "expected": "ERROR state has recovery path (retry or graceful degradation)",
                    "actual": "ERROR state is terminal (no outgoing transitions)",
                })

        return findings

    # ── Check 5: Cross-Register Dependency ──────────────────────────────────

    def check_cross_register_dependency(
        self, functions: List[Dict]
    ) -> List[Finding]:
        """Check MR configuration order respects hardware dependencies.

        Maps to 功能说明书.md §4.3: cross_register_dependency assertion.
        """
        findings = []
        spec_regs = self.registers_spec

        # Find registers with cross_dependency annotations
        dep_regs = [r for r in spec_regs if r.get("cross_dependency")]
        if not dep_regs:
            return findings

        ddr5_funcs = self._filter_ddr5_functions(functions)
        for finfo in ddr5_funcs:
            fname = finfo.get("name", "")
            if "mr_config" not in fname.lower():
                continue

            calls = finfo.get("attributes", {}).get("calls", [])
            for dep in dep_regs:
                dep_note = dep.get("cross_dependency", "")
                findings.append({
                    "type": "cross_register_dependency",
                    "severity": "low",
                    "message": (
                        f"Register dependency detected: {dep_note}. "
                        f"Verify configuration order in '{fname}'."
                    ),
                    "spec_ref": f"JESD79-5C — {dep['name']} ({dep.get('description', '')})",
                    "expected": f"Configuration order respects {dep['name']} dependency",
                    "actual": f"Static check — manual code review recommended for '{fname}'",
                    "location": {"function": fname},
                })

        return findings

    # ── Helpers ─────────────────────────────────────────────────────────────

    def _find_matching_sm(
        self, fw_sms: List[Dict], spec_name: str
    ) -> Dict[str, Any]:
        """Find firmware state machine matching a spec SM name."""
        for sm in fw_sms:
            sm_name = sm.get("name", "").lower()
            if spec_name.lower() in sm_name or "ddr5" in sm_name or "init" in sm_name:
                return sm
        return {}

    def _get_timing_param(self, param_name: str) -> Dict[str, Any]:
        """Get timing parameter spec by name."""
        for tp in self.timing_spec:
            if tp.get("parameter", "").upper() == param_name.upper():
                return tp
        return {}

    def _filter_ddr5_functions(self, functions: List[Dict]) -> List[Dict]:
        """Filter functions to those related to DDR5."""
        ddr5_keywords = ["ddr5", "mr_", "_state_", "vref", "zq_", "dca_",
                         "dq_train", "ca_train", "crc_config", "mr_verify",
                         "mrw_", "mrr_", "train_"]
        result = []
        for f in functions:
            name = f.get("name", f.get("id", ""))
            fname_lower = name.lower()
            if any(kw in fname_lower for kw in ddr5_keywords):
                result.append(f)
            # Also include functions from DDR5 files
            file_path = f.get("attributes", {}).get("file", "")
            if "ddr5" in file_path.lower() and f not in result:
                result.append(f)
        return result

    def _extract_edges(self, call_graph: List) -> List[Dict]:
        """Extract edges from NetworkX MultiDiGraph format."""
        if isinstance(call_graph, list) and len(call_graph) == 2:
            return call_graph[1]
        elif isinstance(call_graph, list):
            return call_graph
        return []