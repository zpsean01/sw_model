"""
Stage 5 — Hook Mechanism (深度受限符号执行的边界拦截机制)

Defines the "how" of depth-limited symbolic execution:
  - HookSpec: which function to intercept and what SimProcedure to use
  - HookLibrary: loads call_graph, performs BFS boundary computation,
    manages hook registry and auto-generation

This is a pure mechanism layer — no risk/annotation semantics here.
For risk characterization, see inspect.py.
"""

import json
import logging
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Dict, List, Optional, Set

logger = logging.getLogger(__name__)


@dataclass
class HookSpec:
    """Specification for a boundary hook — pure mechanism.

    Tells the symbolic execution engine:
      - function_name: which function to intercept
      - hook_type: what SimProcedure to use when the function is called
        "symbolic_return"  → return a fully unconstrained symbolic value
        "concrete_stub"    → return a fixed concrete value
        "summary"          → execute a predefined summary SimProcedure
    """

    function_name: str
    hook_type: str = "symbolic_return"

    def to_dict(self) -> Dict[str, Any]:
        return {
            "function_name": self.function_name,
            "hook_type": self.hook_type,
        }

    @classmethod
    def from_dict(cls, d: Dict[str, Any]) -> "HookSpec":
        return cls(
            function_name=d["function_name"],
            hook_type=d.get("hook_type", "symbolic_return"),
        )


class HookLibrary:
    """Manages the mapping of functions to HookSpec.

    Pure mechanism layer. Responsible for:
    1. Loading the call graph (NetworkX MultiDiGraph JSON)
    2. Computing boundary functions via BFS from an entry point
    3. Registering and auto-generating HookSpecs for boundary functions
    4. Loading/saving hook definitions to/from JSON

    Boundary detection is call-graph topology only — no risk semantics.
    """

    def __init__(self, call_graph_path: Optional[Path] = None):
        self._hooks: Dict[str, HookSpec] = {}
        self._call_graph: Dict[str, List[str]] = {}
        if call_graph_path and call_graph_path.exists():
            self._load_call_graph(call_graph_path)

    # ── Call graph loading ──────────────────────────────────────────────

    def _load_call_graph(self, path: Path) -> None:
        """Load call graph from NetworkX MultiDiGraph JSON format."""
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)

        edges = data.get("edges", [])
        for e in edges:
            src = e.get("source", "")
            tgt = e.get("target", "")
            if src and tgt:
                self._call_graph.setdefault(src, []).append(tgt)

        logger.info("HookLibrary: loaded call graph with %d edges from %d callers",
                    len(edges), len(self._call_graph))

    # ── Hook registration ────────────────────────────────────────────────

    def register(self, hook: HookSpec) -> None:
        """Register a HookSpec for a function."""
        self._hooks[hook.function_name] = hook

    def register_from_config(self, config: Dict[str, Any]) -> None:
        """Register HookSpecs from pipeline config dict.

        Expects a dict keyed by function_name, each with at least hook_type.
        """
        for func_name, cfg in config.items():
            cfg["function_name"] = func_name
            self.register(HookSpec.from_dict(cfg))

    def get(self, function_name: str) -> Optional[HookSpec]:
        """Get the HookSpec for a function, if registered."""
        return self._hooks.get(function_name)

    # ── Boundary computation ─────────────────────────────────────────────

    def get_boundary_functions(
        self,
        entry_function: str,
        max_depth: int,
    ) -> Set[str]:
        """Compute the set of functions at exactly max_depth from the entry.

        Performs BFS from the entry function through the call graph,
        stopping at max_depth. Returns all functions at the boundary.
        """
        if entry_function not in self._call_graph:
            logger.warning("Entry function '%s' not found in call graph", entry_function)
            return set()

        visited: Set[str] = set()
        current_level: Set[str] = {entry_function}

        for depth in range(max_depth):
            next_level: Set[str] = set()
            for func in current_level:
                if func in visited:
                    continue
                visited.add(func)
                for callee in self._call_graph.get(func, []):
                    if callee not in visited:
                        next_level.add(callee)

            if depth == max_depth - 1:
                return next_level
            current_level = next_level

        return set()

    def auto_generate_hooks(
        self,
        entry_function: str,
        max_depth: int,
        default_hook_type: str = "symbolic_return",
    ) -> Dict[str, HookSpec]:
        """Auto-generate HookSpecs for boundary functions.

        For each function at the max_depth boundary from the entry point,
        create a default HookSpec (hook_type = default_hook_type).
        If a HookSpec is already registered (from config), use that instead.
        """
        boundary = self.get_boundary_functions(entry_function, max_depth)
        generated: Dict[str, HookSpec] = {}

        for func_name in sorted(boundary):
            if func_name in self._hooks:
                generated[func_name] = self._hooks[func_name]
            else:
                generated[func_name] = HookSpec(
                    function_name=func_name,
                    hook_type=default_hook_type,
                )

        return generated

    # ── Serialization ─────────────────────────────────────────────────────

    def to_dict(self) -> Dict[str, Any]:
        """Serialize all registered HookSpecs."""
        return {name: h.to_dict() for name, h in self._hooks.items()}

    def save(self, path: Path) -> None:
        """Save hook library to JSON file."""
        with open(path, "w", encoding="utf-8") as f:
            json.dump(self.to_dict(), f, indent=2, ensure_ascii=False)
        logger.info("HookLibrary saved: %s (%d hooks)", path, len(self._hooks))

    @property
    def call_graph(self) -> Dict[str, List[str]]:
        """Expose call graph for read-only use by inspect layer."""
        return dict(self._hooks)