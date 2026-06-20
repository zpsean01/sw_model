"""
Stage 5 — Inspect Semantics (深度边界跨越的风险语义层)

Defines the "what does it mean" of depth-limited symbolic execution:
  - InspectSpec: risk annotation attached to a function at the boundary
  - InspectTrigger: runtime record when a boundary is crossed
  - EntryPointSpec: entry-point definition (which function, how deep)
  - extract_entry_points_from_report(): Stage 4 → entry-point resolution

This is a pure semantics layer — no hook mechanism, no call-graph BFS.
For the interception mechanism, see hook.py.
"""

import json
import logging
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Dict, List, Optional, Set, Tuple

logger = logging.getLogger(__name__)


@dataclass
class InspectSpec:
    """Risk annotation for a function at the depth boundary.

    Attaches semantic meaning to a boundary crossing:
      - risk_level / risk_tags: what risk does this crossing pose?
      - return_range: permissible return-value bounds (if known)
      - modified_registers: which registers this function is expected to touch
      - description: human-readable risk characterization

    An InspectSpec is paired with a HookSpec from hook.py to form
    a complete boundary behavior definition.
    """

    function_name: str
    risk_level: str = "unknown"                 # "safe" | "warning" | "critical" | "unknown"
    risk_tags: List[str] = field(default_factory=list)  # e.g. ["register_write", "timing_critical"]
    return_range: Optional[Tuple[int, int]] = None     # (min, max) for concrete return
    modified_registers: List[str] = field(default_factory=list)
    description: str = ""

    def to_dict(self) -> Dict[str, Any]:
        return {
            "function_name": self.function_name,
            "risk_level": self.risk_level,
            "risk_tags": self.risk_tags,
            "return_range": list(self.return_range) if self.return_range else None,
            "modified_registers": self.modified_registers,
            "description": self.description,
        }

    @classmethod
    def from_dict(cls, d: Dict[str, Any]) -> "InspectSpec":
        rr = d.get("return_range")
        return cls(
            function_name=d["function_name"],
            risk_level=d.get("risk_level", "unknown"),
            risk_tags=d.get("risk_tags", []),
            return_range=tuple(rr) if rr else None,
            modified_registers=d.get("modified_registers", []),
            description=d.get("description", ""),
        )


@dataclass
class InspectTrigger:
    """Runtime record of a boundary crossing.

    Created when the symbolic execution engine encounters a call to a
    hooked function. Captures which entry point triggered it, which
    function was called, and the risk characterization.
    """

    entry_function: str
    called_function: str
    call_depth: int
    hook_type: str
    risk_level: str
    risk_tags: List[str] = field(default_factory=list)
    description: str = ""

    def to_dict(self) -> Dict[str, Any]:
        return {
            "entry_function": self.entry_function,
            "called_function": self.called_function,
            "call_depth": self.call_depth,
            "hook_type": self.hook_type,
            "risk_level": self.risk_level,
            "risk_tags": self.risk_tags,
            "description": self.description,
        }


@dataclass
class EntryPointSpec:
    """Definition of a symbolic execution entry point.

    Instead of starting from the binary's main entry, we start from a
    specific function and explore its call tree up to max_depth.

    Fields:
      function:     function name to use as entry point
      max_depth:    how many call levels to explore
      context:      why this entry point was chosen (e.g. Stage 4 finding reference)
      entry_args:   concrete arguments to pass to the entry function (if any)
    """

    function: str
    max_depth: int = 3
    context: str = ""
    entry_args: List[Any] = field(default_factory=list)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "function": self.function,
            "max_depth": self.max_depth,
            "context": self.context,
            "entry_args": self.entry_args,
        }

    @classmethod
    def from_dict(cls, d: Dict[str, Any]) -> "EntryPointSpec":
        return cls(
            function=d["function"],
            max_depth=d.get("max_depth", 3),
            context=d.get("context", ""),
            entry_args=d.get("entry_args", []),
        )


# ── Entry Point Extraction from Stage 4 ─────────────────────────────────────


def extract_entry_points_from_report(
    report_path: Path,
    default_max_depth: int = 3,
) -> List[EntryPointSpec]:
    """Extract entry points from Stage 4 security_report.json.

    Each finding with a location.function becomes a candidate entry point.
    Higher-severity findings get shallower depth (more conservative):
      critical → 1, high → 2, medium → 3, low → 4, info → 5
    """
    if not report_path.exists():
        logger.warning("Stage 4 report not found: %s", report_path)
        return []

    with open(report_path, "r", encoding="utf-8") as f:
        report = json.load(f)

    severity_depth = {
        "critical": 1,
        "high": 2,
        "medium": 3,
        "low": 4,
        "info": 5,
    }

    entry_points: List[EntryPointSpec] = []
    seen_functions: Set[str] = set()

    for finding in report.get("findings", []):
        loc = finding.get("location", {})
        func_name = loc.get("function", "")
        if not func_name or func_name in seen_functions:
            continue
        seen_functions.add(func_name)

        severity = finding.get("severity", "medium")
        depth = severity_depth.get(severity, default_max_depth)

        entry_points.append(EntryPointSpec(
            function=func_name,
            max_depth=depth,
            context=f"Stage 4: {finding.get('type', 'unknown')} — "
                    f"{finding.get('message', '')[:80]}",
        ))

    logger.info("Extracted %d entry points from Stage 4 report", len(entry_points))
    return entry_points