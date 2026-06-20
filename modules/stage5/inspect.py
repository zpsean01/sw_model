"""
Stage 5 — Inspect Semantics (深度边界跨越的风险语义层)

Defines the "what does it mean" of depth-limited symbolic execution:
  - InspectSpec: risk annotation attached to a function at the boundary
  - InspectTrigger: runtime record when a boundary is crossed
  - TraceRecorder / TraceEvent: structured execution trace for reproducibility
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

# ── Trace — structured execution log for reproducibility ─────────────────


@dataclass
class TraceEvent:
    """A single step in the symbolic execution trace.

    Each event captures enough context to reproduce the finding:
      - event_type: what happened
      - function / depth: where it happened
      - symbolic_vars: which symbolic variables were created/mutated
      - constraints: the path constraints at this point
      - details: register values, memory addresses, etc.
    """

    event_type: str   # "entry_start" | "hook_triggered" | "symbolic_var_created"
                      # | "memory_write" | "register_write" | "branch" | "finding"
    function: str
    depth: int
    symbolic_vars: List[Dict[str, str]] = field(default_factory=list)
    constraints: List[str] = field(default_factory=list)
    details: Dict[str, Any] = field(default_factory=dict)
    finding_id: Optional[str] = None   # links to a finding in the report

    def to_dict(self) -> Dict[str, Any]:
        return {
            "event_type": self.event_type,
            "function": self.function,
            "depth": self.depth,
            "symbolic_vars": self.symbolic_vars,
            "constraints": self.constraints,
            "details": self.details,
            "finding_id": self.finding_id,
        }


class TraceRecorder:
    """Collects structured trace events during one entry point's execution.

    Produces:
      - trace_raw.json: machine-readable event list
      - trace_reproduce.md: human-readable reproduction log

    Usage:
      recorder = TraceRecorder(entry_function="ddr5_train_vref_dq", max_depth=3)
      recorder.record_entry_start(addr=0x8001234)
      recorder.record_hook(called_func, symbolic_vars=[...])
      recorder.save(output_dir)
    """

    def __init__(self, entry_function: str, max_depth: int):
        self.entry_function = entry_function
        self.max_depth = max_depth
        self._events: List[TraceEvent] = []
        self._seq = 0
        self._findings: List[Dict[str, Any]] = []

    # ── Event recorders ──────────────────────────────────────────────────

    def _next(self) -> int:
        self._seq += 1
        return self._seq

    def record_entry_start(self, addr: int, args: List[Any] = None) -> TraceEvent:
        """Record that symbolic execution began at this entry point."""
        ev = TraceEvent(
            event_type="entry_start",
            function=self.entry_function,
            depth=0,
            details={
                "address": hex(addr) if addr else "unknown",
                "max_depth": self.max_depth,
                "entry_args": args or [],
            },
        )
        self._events.append(ev)
        return ev

    def record_hook_triggered(
        self,
        called_function: str,
        depth: int,
        hook_type: str,
        symbolic_var: Dict[str, str],
        constraints: List[str],
        registers: Dict[str, str],
    ) -> TraceEvent:
        """Record that a boundary hook was triggered."""
        ev = TraceEvent(
            event_type="hook_triggered",
            function=called_function,
            depth=depth,
            symbolic_vars=[symbolic_var],
            constraints=constraints,
            details={
                "hook_type": hook_type,
                "registers": registers,
            },
        )
        self._events.append(ev)
        return ev

    def record_symbolic_var_created(
        self,
        function: str,
        depth: int,
        var_name: str,
        var_bits: int,
        description: str,
    ) -> TraceEvent:
        """Record creation of a symbolic variable."""
        ev = TraceEvent(
            event_type="symbolic_var_created",
            function=function,
            depth=depth,
            symbolic_vars=[{
                "name": var_name,
                "bits": var_bits,
                "description": description,
            }],
            details={},
        )
        self._events.append(ev)
        return ev

    def record_memory_write(
        self,
        function: str,
        depth: int,
        address: str,        # hex address or expression
        value_desc: str,     # description of what was written
        is_symbolic: bool,
        var_name: str = "",
    ) -> TraceEvent:
        """Record a memory write event (register write, etc.)."""
        sv = []
        if var_name:
            sv.append({"name": var_name, "bits": 32, "description": value_desc})
        ev = TraceEvent(
            event_type="memory_write",
            function=function,
            depth=depth,
            symbolic_vars=sv,
            details={
                "address": address,
                "value": value_desc,
                "is_symbolic": is_symbolic,
            },
        )
        self._events.append(ev)
        return ev

    def record_finding(
        self,
        finding_id: str,
        function: str,
        depth: int,
        message: str,
        symbolic_vars: List[Dict[str, str]],
        constraints: List[str],
        details: Dict[str, Any],
    ) -> TraceEvent:
        """Record a finding/risk detection."""
        ev = TraceEvent(
            event_type="finding",
            function=function,
            depth=depth,
            symbolic_vars=symbolic_vars,
            constraints=constraints,
            details={
                "message": message,
                **details,
            },
            finding_id=finding_id,
        )
        self._events.append(ev)
        self._findings.append({
            "finding_id": finding_id,
            "function": function,
            "message": message,
            "depth": depth,
            "symbolic_vars": symbolic_vars,
            "constraints": constraints,
        })
        return ev

    def record_branch(
        self,
        function: str,
        depth: int,
        condition: str,
        taken: bool,
    ) -> TraceEvent:
        """Record a branch decision."""
        ev = TraceEvent(
            event_type="branch",
            function=function,
            depth=depth,
            details={
                "condition": condition,
                "taken": taken,
            },
        )
        self._events.append(ev)
        return ev

    def record_entry_end(
        self, status: str, active_paths: int, deadended_paths: int
    ) -> TraceEvent:
        """Record that symbolic execution for this entry completed."""
        ev = TraceEvent(
            event_type="entry_end",
            function=self.entry_function,
            depth=0,
            details={
                "status": status,
                "active_paths": active_paths,
                "deadended_paths": deadended_paths,
                "total_events": len(self._events),
            },
        )
        self._events.append(ev)
        return ev

    # ── Serialization ───────────────────────────────────────────────────

    def to_dict(self) -> Dict[str, Any]:
        return {
            "entry_function": self.entry_function,
            "max_depth": self.max_depth,
            "event_count": len(self._events),
            "finding_count": len(self._findings),
            "events": [e.to_dict() for e in self._events],
            "findings": self._findings,
        }

    def to_markdown(self) -> str:
        """Generate a human-readable reproduction log."""
        lines = [
            f"# Symbolic Execution Trace: `{self.entry_function}`",
            f"",
            f"- **Max depth**: {self.max_depth}",
            f"- **Events**: {len(self._events)}",
            f"- **Findings**: {len(self._findings)}",
            f"",
            f"## Event Log",
            f"",
            f"| # | Type | Function | Depth | Details |",
            f"|---|------|----------|-------|---------|",
        ]
        for i, ev in enumerate(self._events):
            detail_str = "; ".join(
                f"{k}={v}" for k, v in ev.details.items()
            )[:120]
            lines.append(
                f"| {i} | {ev.event_type} | `{ev.function}` | {ev.depth} | {detail_str} |"
            )

        if self._findings:
            lines.extend(["", "## Findings", ""])
            for f in self._findings:
                lines.append(f"### Finding: {f['finding_id']}")
                lines.append(f"- **Function**: `{f['function']}` (depth={f['depth']})")
                lines.append(f"- **Message**: {f['message']}")
                for sv in f["symbolic_vars"]:
                    lines.append(f"- **Symbolic var**: `{sv['name']}` ({sv.get('bits', '?')} bit) — {sv.get('description', '')}")
                for c in f["constraints"]:
                    lines.append(f"- **Constraint**: `{c}`")
                lines.append("")

        return "\n".join(lines)

    def save(self, output_dir: Path) -> None:
        """Save trace as JSON + markdown."""
        output_dir.mkdir(parents=True, exist_ok=True)
        safe = self.entry_function.replace("::", "_").replace("/", "_")

        # Raw JSON
        json_path = output_dir / f"trace_{safe}.json"
        with open(json_path, "w", encoding="utf-8") as f:
            json.dump(self.to_dict(), f, indent=2, ensure_ascii=False)
        logger.info("Trace saved: %s (%d events)", json_path, len(self._events))

        # Human-readable markdown
        md_path = output_dir / f"trace_{safe}.md"
        with open(md_path, "w", encoding="utf-8") as f:
            f.write(self.to_markdown())
        logger.info("Trace markdown: %s", md_path)


# ── Existing data models ────────────────────────────────────────────────────


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
    trace_detail: Optional[Dict[str, Any]] = None   # snapshot of symbolic vars / constraints at trigger time

    def to_dict(self) -> Dict[str, Any]:
        return {
            "entry_function": self.entry_function,
            "called_function": self.called_function,
            "call_depth": self.call_depth,
            "hook_type": self.hook_type,
            "risk_level": self.risk_level,
            "risk_tags": self.risk_tags,
            "description": self.description,
            "trace_detail": self.trace_detail,
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