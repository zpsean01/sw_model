"""
Stage 6 — Risk Audit & Aggregation (RiskRegistryBuilder)

Faithfully records risks identified by Stage 4 (static analysis) and verified
by Stage 5 (symbolic execution), classifying each as "verified" or "residual".
Downstream systems consume this risk registry to design their own dynamic tests.

No test cases are generated — this stage is a "mirror, not a designer".
"""

import json
import logging
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List

from modules.base import BaseStage

logger = logging.getLogger(__name__)

# ── Severity values ──────────────────────────────────────────────────────────
SEVERITIES = ("critical", "high", "medium", "low", "info")
RISK_TYPES = (
    "state_machine_completeness",
    "timing_constraint_audit",
    "register_config_audit",
    "error_handling_coverage",
    "cross_register_dependency",
)

# ── Protocol info cache ──────────────────────────────────────────────────────
def _resolve_protocol_from_spec_model(spec_model_dir: str) -> tuple:
    """Read protocol name and version from spec_model oracle manifest."""
    manifest = Path(spec_model_dir) / "stage3" / "latest" / "manifest.json"
    if manifest.exists():
        with open(manifest, "r", encoding="utf-8") as f:
            m = json.load(f)
        meta = m.get("metadata", {})
        return meta.get("protocol", "UNKNOWN"), meta.get("version", "unknown")
    return "UNKNOWN", "unknown"


class Stage6RiskAggregator(BaseStage):
    """Aggregate Stage 4 & 5 findings into a consolidated risk registry."""

    def run(self, context: Dict[str, Any]) -> Dict[str, Any]:
        params = self.config["params"]
        output_dir = self.setup_output_dir(params["output_dir"])

        # ── Guard: Stage 5 must have actually produced data ──────────────
        stage5_path = Path(params.get("stage5_report_path", ""))
        if not stage5_path.name or not stage5_path.exists():
            raise RuntimeError(
                "Stage 5 symbolic execution report not found — Stage 6 cannot "
                "produce a risk registry without Stage 5 data. Either run Stage 5 "
                "first, or disable Stage 6 in the config if symbolic execution is "
                "not required for this target."
            )

        # ── Resolve protocol info from spec_model oracle ──────────────────
        spec_model_dir = params.get("spec_model_dir", "D:/programming/spec_model/data/arm_corelink_gic_700_r4p0/extract")
        protocol_name = params.get("protocol_name", "")
        protocol_version = params.get("protocol_version", "")
        if not protocol_name or not protocol_version:
            protocol_name, protocol_version = _resolve_protocol_from_spec_model(spec_model_dir)

        # Determine the protocol subdirectory under risks/
        proto_dir = f"{protocol_name}_{protocol_version}"
        output_proto = output_dir / proto_dir / "protocol_conformance"
        output_proto.mkdir(parents=True, exist_ok=True)

        # ── 1. Load Stage 4 protocol conformance findings ────────────────
        stage4_path = Path(params.get("stage4_pc_path", ""))
        if not stage4_path.exists():
            logger.warning("Stage 4 protocol_conformance not found: %s", stage4_path)
            stage4_findings = []
        else:
            with open(stage4_path, "r", encoding="utf-8") as f:
                pc_data = json.load(f)
            stage4_findings = pc_data.get("findings", [])
            logger.info("Loaded %d findings from Stage 4", len(stage4_findings))

        # ── 2. Load Stage 5 symbolic report ──────────────────────────────
        with open(stage5_path, "r", encoding="utf-8") as f:
            s5_data = json.load(f)
        entry_results = s5_data.get("entry_results", [])
        logger.info("Loaded %d entry results from Stage 5", len(entry_results))

        # ── 3. Build trace file lookup ───────────────────────────────────
        traces_dir = Path(params.get("stage5_traces_dir", ""))
        trace_map: Dict[str, Path] = {}
        if traces_dir.exists():
            for f in traces_dir.iterdir():
                if f.suffix == ".json" and f.stem.startswith("trace_"):
                    func_name = f.stem.replace("trace_", "", 1)
                    trace_map[func_name] = f

        # ── 4. Build Stage 5 entry function → trigger mapping ────────────
        # Which functions were entry points, and which had inspect_triggers?
        s5_entry_functions: set = set()
        s5_verified_functions: Dict[str, List[Dict]] = {}  # func → triggers

        for er in entry_results:
            func = er.get("entry_function", "")
            s5_entry_functions.add(func)
            triggers = er.get("inspect_triggers", [])
            if triggers and er.get("status") == "completed":
                s5_verified_functions[func] = triggers

        # ── 5. Build the risk registry ───────────────────────────────────
        risks: List[Dict] = []
        verified_count = 0
        residual_count = 0
        severity_dist: Dict[str, int] = {s: 0 for s in SEVERITIES}

        # 5a. Process each Stage 4 finding
        for finding in stage4_findings:
            risk_type = finding.get("type", "unknown")
            severity = finding.get("severity", "info")
            location = finding.get("location", {})
            func_name = location.get("function") if location else None

            # Determine if this finding is "verified" or "residual"
            # A finding is verified if its function was a Stage 5 entry
            # AND that entry had inspect_triggers (meaning hooks fired)
            is_verified = False
            verification_info: Dict[str, Any] = {}

            if func_name and func_name in s5_verified_functions:
                triggers = s5_verified_functions[func_name]
                is_verified = True
                verification_info = {
                    "entry_function": func_name,
                    "trace_file": str(trace_map.get(func_name, "")),
                    "constraints": self._collect_constraints(triggers),
                    "register_snapshot": self._collect_register_snapshot(triggers),
                }
            elif func_name and func_name in s5_entry_functions:
                # Was an entry point but no triggers — still residual
                verification_info = {
                    "entry_function": func_name,
                    "trace_file": str(trace_map.get(func_name, "")),
                }
            elif func_name:
                # Not even an entry point — residual (static-only)
                verification_info = {
                    "entry_function": func_name,
                    "trace_file": "",
                }

            if is_verified:
                verified_count += 1
            else:
                residual_count += 1

            sev = severity if severity in SEVERITIES else "info"
            severity_dist[sev] += 1

            risk_id = f"R-{risk_type}-{func_name or 'unknown'}-{len(risks)}"

            risk_entry: Dict[str, Any] = {
                "risk_id": risk_id,
                "source": "stage4",
                "finding_ref": finding.get("type", ""),
                "risk_type": risk_type,
                "severity": sev,
                "status": "verified" if is_verified else "residual",
                "message": finding.get("message", ""),
                "spec_ref": finding.get("spec_ref", ""),
                "expected": finding.get("expected", ""),
                "actual": finding.get("actual", ""),
                "location": {
                    "file": location.get("file", "") if location else "",
                    "function": func_name or "",
                },
            }
            if is_verified and verification_info:
                risk_entry["verification"] = verification_info

            risks.append(risk_entry)

        # 5b. Add Stage 5 specific findings (InspectTriggers) as additional risks
        # if they reference functions NOT covered by Stage 4 findings
        s4_functions = set()
        for finding in stage4_findings:
            loc = finding.get("location", {})
            if loc and loc.get("function"):
                s4_functions.add(loc.get("function"))

        for func, triggers in s5_verified_functions.items():
            if func in s4_functions:
                continue  # already covered from Stage 4
            for t in triggers:
                sev = t.get("risk_level", "unknown")
                sev = sev if sev in SEVERITIES else "info"
                severity_dist[sev] += 1
                verified_count += 1

                risk_id = f"R-stage5-{t.get('called_function', func)}-{len(risks)}"
                risk_entry: Dict[str, Any] = {
                    "risk_id": risk_id,
                    "source": "stage5",
                    "finding_ref": t.get("description", ""),
                    "risk_type": "register_config_audit",
                    "severity": sev,
                    "status": "verified",
                    "message": t.get("description", ""),
                    "spec_ref": t.get("hook_type", ""),
                    "location": {
                        "file": "",
                        "function": t.get("called_function", func),
                    },
                    "verification": {
                        "entry_function": func,
                        "trace_file": str(trace_map.get(func, "")),
                        "constraints": [],
                        "register_snapshot": {},
                    },
                }
                risks.append(risk_entry)

        # ── 6. Build the output ──────────────────────────────────────────
        risk_registry: Dict[str, Any] = {
            "protocol": {
                "name": protocol_name,
                "version": protocol_version,
            },
            "generated_at": datetime.now(timezone.utc).isoformat(),
            "summary": {
                "total_risks": len(risks),
                "verified": verified_count,
                "residual": residual_count,
                "severity_distribution": severity_dist,
            },
            "risks": risks,
        }

        # ── 7. Save risk_registry.json (timestamped + latest) ──────────────
        ts = datetime.now().strftime("%Y%m%d_%H%M%S_%f")[:-3]
        registry_ts = output_proto / f"risk_registry_{ts}.json"
        registry_latest = output_proto / "risk_registry.json"
        with open(registry_ts, "w", encoding="utf-8") as f:
            json.dump(risk_registry, f, indent=2, ensure_ascii=False)
        with open(registry_latest, "w", encoding="utf-8") as f:
            json.dump(risk_registry, f, indent=2, ensure_ascii=False)
        logger.info("Saved risk registry: %s (latest: %s) — %d risks, %d verified, %d residual",
                    registry_ts, registry_latest, len(risks), verified_count, residual_count)

        # ── 8. Save residual_risks.json (timestamped + latest) ─────────────
        residual_risks = [r for r in risks if r.get("status") == "residual"]
        residual_report: Dict[str, Any] = {
            "protocol": {
                "name": protocol_name,
                "version": protocol_version,
            },
            "total_residual": len(residual_risks),
            "note": (
                "These risks were identified by Stage 4 static analysis but "
                "NOT reproduced by Stage 5 symbolic execution. They require "
                "downstream dynamic testing for further validation."
            ),
            "risks": [],
        }
        for r in residual_risks:
            residual_report["risks"].append({
                "risk_id": r["risk_id"],
                "finding_ref": r["finding_ref"],
                "risk_type": r["risk_type"],
                "severity": r["severity"],
                "message": r["message"],
                "spec_ref": r["spec_ref"],
                "location": r["location"],
                "residual_reason": self._infer_residual_reason(r, s5_entry_functions),
            })

        residual_ts = output_proto / f"residual_risks_{ts}.json"
        residual_latest = output_proto / "residual_risks.json"
        with open(residual_ts, "w", encoding="utf-8") as f:
            json.dump(residual_report, f, indent=2, ensure_ascii=False)
        with open(residual_latest, "w", encoding="utf-8") as f:
            json.dump(residual_report, f, indent=2, ensure_ascii=False)
        logger.info("Saved residual risks: %s (latest: %s) — %d items",
                    residual_ts, residual_latest, len(residual_risks))

        return {
            "stage6": {
                "output_dir": str(output_dir),
                "risk_registry": str(registry_latest),
                "residual_risks": str(residual_latest),
                "total_risks": len(risks),
                "verified": verified_count,
                "residual": residual_count,
            }
        }

    # ── Helpers ──────────────────────────────────────────────────────────────

    @staticmethod
    def _collect_constraints(triggers: List[Dict]) -> List[str]:
        """Extract constraint strings from inspect triggers (best-effort)."""
        constraints = []
        for t in triggers[:3]:
            desc = t.get("description", "")
            if desc:
                constraints.append(desc[:120])
        return constraints if constraints else ["No constraints recorded"]

    @staticmethod
    def _collect_register_snapshot(triggers: List[Dict]) -> Dict[str, str]:
        """Extract register snapshot from inspect triggers (best-effort)."""
        for t in triggers:
            if "registers_at_hook" in t.get("details", {}):
                return t["details"]["registers_at_hook"]
        return {}

    @staticmethod
    def _infer_residual_reason(
        risk: Dict, s5_entry_functions: set
    ) -> str:
        """Infer why a risk remained residual."""
        func = risk.get("location", {}).get("function", "")
        if not func:
            return "static_only"
        if func not in s5_entry_functions:
            return "no_entry_point"
        return "path_not_reproduced"