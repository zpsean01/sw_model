"""
Stage 4 — Protocol Conformance Analysis (protocol-agnostic rule engine)

Reads:
  - rules/         (protocol-agnostic audit patterns, e.g. register_sequence_rules.json)
  - spec_model/    (protocol-specific oracle: vertex_set, behavior_edges, register subgraphs)
  - data/static/   (firmware analysis from Stage 2: functions, call_graph, globals)

Applies each rule's semantic patterns against the spec_model oracle to determine
which registers/fields to check, then compares against firmware behavior found
in Stage 2 outputs. Reports findings as protocol_conformance/report.json.
"""

import json
import logging
import re
from pathlib import Path
from typing import Any, Dict, List, Optional

logger = logging.getLogger(__name__)

Finding = Dict[str, Any]


class ProtocolConformanceAnalyzer:
    """Protocol-agnostic rule engine for firmware compliance checking."""

    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.rules: List[Dict] = []
        self.oracle: Dict[str, Any] = {}        # spec_model oracle data
        self.fw_functions: List[Dict] = []       # from Stage 2
        self.fw_call_graph: List = []            # from Stage 2
        self.fw_globals: List[Dict] = []         # from Stage 2
        self.fw_binary_call_graph: Dict[str, List[str]] = {}  # from Stage 3 binary CFG

    # ── Public API ───────────────────────────────────────────────────────────

    def load_rules(self, rules_dir: Path) -> int:
        """Load all rule files from rules/stage4/."""
        count = 0
        for fpath in sorted(rules_dir.glob("*.json")):
            with open(fpath, "r", encoding="utf-8") as f:
                rule = json.load(f)
            if rule.get("category") == "protocol_conformance":
                self.rules.append(rule)
                count += len(rule.get("constraints", []))
        logger.info("Loaded %d rule files (%d constraints) from %s",
                     len([r for r in self.rules]), count, rules_dir)
        return count

    def load_oracle(self, spec_model_dir: Path) -> bool:
        """Load spec_model oracle from stage2_2/stage2_3/stage3 latest dirs."""
        if not spec_model_dir.exists():
            logger.warning("spec_model dir not found: %s", spec_model_dir)
            return False

        latest = spec_model_dir / "stage3" / "latest"
        if not latest.exists():
            logger.warning("stage3/latest not found under %s", spec_model_dir)
            return False

        # behavior_space_graph (vertex set + constraints)
        bsg = latest / "behavior_space_graph.json"
        if bsg.exists():
            with open(bsg, "r", encoding="utf-8") as f:
                self.oracle["behavior_space_graph"] = json.load(f)

        # register subgraphs (per-register dependency graphs)
        reg_dir = latest / "registers"
        if reg_dir.exists():
            self.oracle["register_subgraphs"] = {}
            for reg_sub in reg_dir.iterdir():
                subgraph_file = reg_sub / "subgraph.json"
                if subgraph_file.exists():
                    with open(subgraph_file, "r", encoding="utf-8") as f:
                        self.oracle["register_subgraphs"][reg_sub.name] = json.load(f)

        # vertex_set (entity type annotations)
        v2_dir = spec_model_dir / "stage2_2" / "latest"
        vs = v2_dir / "vertex_set.json"
        if vs.exists():
            if vs.stat().st_size < 2 * 1024 * 1024:  # skip if >2MB
                with open(vs, "r", encoding="utf-8") as f:
                    self.oracle["vertex_set"] = json.load(f)

        # protocol metadata
        self.oracle["protocol"] = "UNKNOWN"
        self.oracle["version"] = "unknown"
        manifest = latest / "manifest.json"
        if manifest.exists():
            with open(manifest, "r", encoding="utf-8") as f:
                m = json.load(f)
            self.oracle["protocol"] = m.get("metadata", {}).get("protocol", "UNKNOWN")
        # Also try from behavior_space_graph metadata
        if "behavior_space_graph" in self.oracle:
            g = self.oracle["behavior_space_graph"].get("graph", {})
            self.oracle["protocol"] = g.get("protocol", self.oracle["protocol"])
            self.oracle["version"] = g.get("version", self.oracle["version"])

        logger.info("Loaded spec_model oracle: protocol=%s v=%s, %d register subgraphs",
                     self.oracle["protocol"], self.oracle["version"],
                     len(self.oracle.get("register_subgraphs", {})))
        return True

    def load_firmware(self, static_dir: Path) -> bool:
        """Load Stage 2 firmware analysis outputs."""
        functions_file = static_dir / "functions" / "functions.json"
        if functions_file.exists():
            with open(functions_file, "r", encoding="utf-8") as f:
                self.fw_functions = json.load(f)

        cg_file = static_dir / "call_graph" / "call_graph.json"
        if cg_file.exists():
            with open(cg_file, "r", encoding="utf-8") as f:
                self.fw_call_graph = json.load(f)

        globals_file = static_dir / "globals" / "globals.json"
        if globals_file.exists():
            with open(globals_file, "r", encoding="utf-8") as f:
                self.fw_globals = json.load(f)

        total = len(self.fw_functions)
        logger.info("Loaded firmware data: %d functions, %d globals from %s",
                     total, len(self.fw_globals), static_dir)
        return total > 0

    def load_binary_call_graph(self, path: Path) -> bool:
        """Load binary (Stage 3) call graph to supplement static call info.

        The binary CFG captures calls that libclang may have missed (e.g.
        indirect calls, or calls via function pointers that the front-end
        could not resolve).
        """
        if not path.exists():
            logger.warning("Binary call graph not found: %s", path)
            return False
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
        for edge in data.get("edges", []):
            src = edge.get("source", "")
            tgt = edge.get("target", "")
            if src and tgt:
                self.fw_binary_call_graph.setdefault(src, []).append(tgt)
        logger.info("Loaded binary call graph: %d edges, %d callers",
                     len(data.get("edges", [])), len(self.fw_binary_call_graph))
        return True

    def run_all_checks(self) -> List[Finding]:
        """Run all loaded rules against oracle + firmware data."""
        findings: List[Finding] = []
        for rule in self.rules:
            for constraint in rule.get("constraints", []):
                findings.extend(self._apply_constraint(constraint, rule))
        return findings

    # ── Constraint engine ────────────────────────────────────────────────────

    def _apply_constraint(self, constraint: Dict, rule: Dict) -> List[Finding]:
        """Apply a single constraint against firmware + oracle."""
        cid = constraint.get("constraint_id", "?")
        check_on = constraint.get("check_on", "")
        findings: List[Finding] = []

        if check_on == "write_to_register":
            findings = self._check_write_sequence(constraint, rule)
        elif check_on == "cross_register_dependency":
            findings = self._check_cross_dependency(constraint, rule)
        else:
            logger.debug("Constraint %s: unknown check_on=%s", cid, check_on)

        return findings

    # ── SEQ-01 / SEQ-02: Write sequence checks ──────────────────────────────

    def _check_write_sequence(self, constraint: Dict, rule: Dict) -> List[Finding]:
        """Check register write sequences against expected order."""
        findings: List[Finding] = []

        # Get field semantic patterns from rule
        semantic_patterns = rule.get("semantic_patterns", {})
        enable_patterns = semantic_patterns.get("enable_fields", {}).get("name_patterns", [])
        activation_patterns = semantic_patterns.get("activation_fields", {}).get("name_patterns", [])
        wp_patterns = semantic_patterns.get("write_pending_fields", {}).get("name_patterns", [])

        # Get register subgraphs from oracle
        reg_subgraphs = self.oracle.get("register_subgraphs", {})

        for reg_name, subgraph in reg_subgraphs.items():
            # Match register's fields against semantic patterns
            fields = subgraph.get("graph", {})
            # Extract node names from this subgraph that match semantic patterns
            reg_upper = reg_name.upper()

            # Determine which fields match which semantic role
            enable_fields = self._match_fields(subgraph, enable_patterns)
            activation_fields = self._match_fields(subgraph, activation_patterns)
            wp_fields = self._match_fields(subgraph, wp_patterns)

            if not enable_fields and not activation_fields and not wp_fields:
                continue  # no semantic match → skip

            cid = constraint.get("constraint_id", "")
            expected_seq = constraint.get("expected_sequence", [])

            # Analyze firmware call sequences relevant to this register
            fw_analysis = self._analyze_fw_register_access(reg_name)

            if cid == "SEQ-01" and enable_fields and activation_fields:
                # Check: clear enables → set activation
                f_clear = fw_analysis.get("clear_enables", [])
                f_set_act = fw_analysis.get("set_activation", [])
                if f_clear and f_set_act:
                    # Both patterns found → pass
                    findings.append({
                        "type": "register_config_audit",
                        "severity": "info",
                        "rule": cid,
                        "status": "verified",
                        "message": (
                            f"[{cid}] {reg_name}: clear-enable→set-activation "
                            f"sequence verified. enables={enable_fields}, "
                            f"activation={activation_fields}"
                        ),
                        "location": {"function": "; ".join(f_clear + f_set_act)},
                    })
                elif f_set_act and not f_clear:
                    # Activation set without prior enable clear → violation
                    findings.append({
                        "type": "register_config_audit",
                        "severity": "critical",
                        "rule": cid,
                        "status": "violated",
                        "message": (
                            f"[{cid}] {reg_name}: activation fields set "
                            f"({activation_fields}) without prior clear of "
                            f"enable fields ({enable_fields})"
                        ),
                        "location": {"function": "; ".join(f_set_act)},
                    })
                else:
                    # Neither found → can't verify (no relevant FW code)
                    findings.append({
                        "type": "register_config_audit",
                        "severity": "info",
                        "rule": cid,
                        "status": "residual",
                        "message": (
                            f"[{cid}] {reg_name}: cannot verify — no matching "
                            f"register access pattern found in firmware"
                        ),
                    })

            elif cid == "SEQ-02" and wp_fields:
                # Check write → poll write_pending
                writes = fw_analysis.get("writes_to_register", [])
                polls = fw_analysis.get("polls_wp", [])
                if writes and polls:
                    findings.append({
                        "type": "register_config_audit",
                        "severity": "info",
                        "rule": cid,
                        "status": "verified",
                        "message": (
                            f"[{cid}] {reg_name}: write→poll-WP sequence "
                            f"verified"
                        ),
                        "location": {"function": "; ".join(writes + polls)},
                    })
                elif writes and not polls:
                    findings.append({
                        "type": "register_config_audit",
                        "severity": "critical",
                        "rule": cid,
                        "status": "violated",
                        "message": (
                            f"[{cid}] {reg_name}: write performed without "
                            f"RWP/busy poll"
                        ),
                        "location": {"function": "; ".join(writes)},
                    })

        return findings

    # ── SEQ-03: Cross-register dependency checks ────────────────────────────

    def _check_cross_dependency(self, constraint: Dict, rule: Dict) -> List[Finding]:
        """Check cross-register dependencies using behavior_edges from oracle."""
        findings: List[Finding] = []

        bsg = self.oracle.get("behavior_space_graph", {})
        edges = bsg.get("edges", [])
        if not edges:
            return findings

        # Filter edges that are "pre_condition_dependency" type
        dep_edges = [e for e in edges
                     if isinstance(e.get("attributes"), dict)
                     and e["attributes"].get("relationship") in ("enables", "blocks")]

        # Build dependency lookup from oracle
        for e in dep_edges[:20]:  # limit scope for MVP
            attrs = e.get("attributes", {})
            guard = attrs.get("guard", {})
            condition = guard.get("condition", "") if guard else ""
            source = e.get("source", "")
            target = e.get("target", "")

            # Check if firmware has code paths that hit this dependency
            src_relevant = self._find_fw_function_for_node(source)
            tgt_relevant = self._find_fw_function_for_node(target)

            if src_relevant or tgt_relevant:
                findings.append({
                    "type": "cross_register_dependency",
                    "severity": "high",
                    "rule": "SEQ-03",
                    "status": "residual" if condition else "verified",
                    "message": (
                        f"Cross-register dependency: {source} → {target}"
                        + (f"  guard: {condition}" if condition else "")
                    ),
                    "spec_ref": e.get("key", ""),
                    "location": {"function": src_relevant or tgt_relevant or "unknown"},
                })

        return findings

    # ── Helpers ──────────────────────────────────────────────────────────────

    def _match_fields(self, subgraph: Dict, name_patterns: List[str]) -> List[str]:
        """Match node names against name patterns to find semantically relevant fields."""
        matched = []
        for node in subgraph.get("nodes", []):
            nid = node.get("id", "")
            for pat in name_patterns:
                if not pat:
                    continue
                # Convert glob-like pattern to regex
                regex_pat = "^" + re.escape(pat).replace(r"\*", ".*") + "$"
                if re.search(regex_pat, nid, re.IGNORECASE):
                    if nid not in matched:
                        matched.append(nid)
        return matched

    def _analyze_fw_register_access(self, reg_name: str) -> Dict[str, List[str]]:
        """Analyze firmware function calls to find register access patterns.

        Uses function names and call graph to detect patterns like:
        - Writes to the register (name match or offset match)
        - Clear-enable operations
        - Set-activation operations
        - Polling of write-pending/busy bits

        Falls back to the binary (Stage 3) call graph when the static
        (Stage 2) ``calls`` arrays are empty (known libclang limitation).
        """
        result: Dict[str, List[str]] = {
            "writes_to_register": [],
            "clear_enables": [],
            "set_activation": [],
            "polls_wp": [],
        }
        reg_upper = reg_name.upper()

        for func in self.fw_functions:
            fname = func.get("name", "")
            # Try static calls first, fall back to binary call graph
            calls = func.get("calls") or func.get("attributes", {}).get("calls", [])
            if not calls:
                calls = self.fw_binary_call_graph.get(fname, [])
            if not calls:
                continue
            calls_str = " ".join(calls).upper()

            # Detect if any call involves this register or its address
            if reg_upper in calls_str or reg_name.lower() in calls_str:
                result["writes_to_register"].append(fname)

            # Pattern match: "clear" + "enable" keywords nearby
            if re.search(r"clr.*enab|clear.*enab|enab.*clear", calls_str, re.I):
                result["clear_enables"].append(fname)

            # Pattern match: "set" + routing/activation keywords
            if re.search(r"set.*(?:are|route|affin)", calls_str, re.I):
                result["set_activation"].append(fname)

            # Pattern match: polling for busy/RWP
            if re.search(r"(?:wait.*rwp|poll.*rwp|rwp.*poll|wait.*busy|while.*busy)", calls_str, re.I):
                result["polls_wp"].append(fname)

        return result

    def _find_fw_function_for_node(self, node_id: str) -> str:
        """Try to find a firmware function related to a spec_model vertex."""
        # Extract entity name from node_id like "armcorelinkgic700:distributor:gicd_ctlr:DS.write"
        parts = node_id.replace(".", ":").split(":")
        for p in parts:
            p_lower = p.lower()
            for func in self.fw_functions:
                fname = func.get("name", "").lower()
                if p_lower in fname:
                    return func["name"]
        return ""
