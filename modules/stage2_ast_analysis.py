"""
Stage 2 — AST Analysis

Parses preprocessed source files using libclang (or tree-sitter) and extracts:
- Functions, global variables, type definitions, ISRs, register access,
  state machines, interfaces, and function call graphs.
"""

import logging
from pathlib import Path
from typing import Any, Dict, List, Optional

from modules.base import BaseStage

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Data holders — simple dict builders for each extraction category
# ---------------------------------------------------------------------------

def _make_function(cursor) -> Dict[str, Any]:
    return {
        "name": cursor.spelling or "<anonymous>",
        "kind": str(cursor.kind),
        "line": cursor.location.line,
        "end_line": cursor.extent.end.line,
        "type": str(cursor.type.spelling) if cursor.type else "",
        "result_type": str(cursor.result_type.spelling) if cursor.type else "",
        "arguments": [
            {
                "name": arg.spelling or f"arg{i}",
                "type": str(arg.type.spelling),
            }
            for i, arg in enumerate(cursor.get_arguments() or [])
        ],
    }


def _make_global(cursor) -> Dict[str, Any]:
    return {
        "name": cursor.spelling,
        "kind": str(cursor.kind),
        "type": str(cursor.type.spelling),
        "line": cursor.location.line,
        "storage_class": str(cursor.storage_class),
    }


def _make_type(cursor) -> Dict[str, Any]:
    info: Dict[str, Any] = {
        "name": cursor.spelling or "<anonymous>",
        "kind": str(cursor.kind),
        "line": cursor.location.line,
    }
    fields = []
    for child in cursor.get_children():
        if child.kind.name in ("FIELD_DECL", "ENUM_CONSTANT_DECL"):
            fields.append({
                "name": child.spelling,
                "type": str(child.type.spelling),
                "line": child.location.line,
            })
    if fields:
        info["fields"] = fields
    return info


# ---------------------------------------------------------------------------
# AST traversal helpers
# ---------------------------------------------------------------------------

def _get_call_expr_name(cursor) -> Optional[str]:
    """Extract the callee name from a CallExpr cursor if it is a direct name."""
    try:
        ref = cursor.referenced
        if ref:
            return ref.spelling
    except Exception:
        pass
    # Fallback: look at the first child (usually the function name ref)
    children = list(cursor.get_children())
    if children:
        return children[0].spelling
    return None


class Stage2ASTAnalysis(BaseStage):
    """AST analysis stage using libclang binding."""

    def run(self, context: Dict[str, Any]) -> Dict[str, Any]:
        params = self.config["params"]
        preprocessed_dir = Path(params["preprocessed_dir"])
        output_dir = self.setup_output_dir(params["output_dir"])
        extract_cfg = params.get("extract", {})
        engine_name = params.get("ast_engine", "libclang")

        if not preprocessed_dir.exists():
            raise FileNotFoundError(
                f"Preprocessed directory not found: {preprocessed_dir}. "
                "Run Stage 1 first."
            )

        # Locate preprocessed files
        preproc_files = sorted(preprocessed_dir.glob("*.i")) + sorted(preprocessed_dir.glob("*.ii"))

        if not preproc_files:
            logger.warning("No preprocessed files found in %s", preprocessed_dir)
            return {"stage2": {"output_dir": str(output_dir), "files_processed": 0}}

        if engine_name == "libclang":
            results = self._analyze_with_libclang(preproc_files, extract_cfg)
        else:
            raise ValueError(f"Unsupported AST engine: {engine_name}")

        # Save each extraction category
        for category, data in results.items():
            if data:
                self.save_json(f"{category}.json", data)
                logger.info("Extracted %d %s", len(data), category)

        return {
            "stage2": {
                "output_dir": str(output_dir),
                "files_processed": len(preproc_files),
                "summary": {k: len(v) for k, v in results.items() if v},
            }
        }

    def _analyze_with_libclang(
        self, preproc_files: List[Path], extract_cfg: Dict[str, bool]
    ) -> Dict[str, List[Dict[str, Any]]]:
        """Run libclang-based analysis over all preprocessed files."""
        import clang.cindex

        index = clang.cindex.Index.create()

        results: Dict[str, List[Dict[str, Any]]] = {
            "functions": [],
            "globals": [],
            "types": [],
            "interrupts": [],
            "registers": [],
            "state_machines": [],
            "interfaces": [],
            "call_graph_functions": [],
        }

        call_edges: List[Dict[str, str]] = []

        for pfile in preproc_files:
            try:
                tu = index.parse(str(pfile))
            except Exception as e:
                logger.warning("Failed to parse %s: %s", pfile, e)
                continue

            self._traverse_translation_unit(
                tu.cursor, pfile, results, call_edges, extract_cfg
            )

        if extract_cfg.get("call_graph", True) and call_edges:
            # Group edges by caller
            graph: Dict[str, List[str]] = {}
            for edge in call_edges:
                graph.setdefault(edge["caller"], []).append(edge["callee"])
            results["call_graph_functions"] = [
                {"caller": k, "callees": list(set(v))} for k, v in graph.items()
            ]

        return results

    def _traverse_translation_unit(
        self,
        cursor,
        source_file: Path,
        results: Dict[str, List],
        call_edges: List[Dict[str, str]],
        cfg: Dict[str, bool],
    ) -> None:
        """Recursively traverse the AST cursor and extract information."""

        for child in cursor.get_children():
            kind_name = child.kind.name

            # --- Functions ---
            if cfg.get("functions", True) and kind_name == "FUNCTION_DECL":
                results["functions"].append(_make_function(child))

            # --- Global variables ---
            if cfg.get("globals", True) and kind_name in (
                "VAR_DECL", "FUNCTION_DECL"
            ):
                # Report only file-scope or translation-unit-scope vars
                if kind_name == "VAR_DECL" and child.semantic_parent:
                    parent_kind = child.semantic_parent.kind.name
                    if parent_kind in ("TRANSLATION_UNIT",):
                        results["globals"].append(_make_global(child))

            # --- Type definitions ---
            if cfg.get("types", True) and kind_name in (
                "STRUCT_DECL", "UNION_DECL", "ENUM_DECL", "TYPEDEF_DECL"
            ):
                # Only report definitions (is_definition may not be available on all)
                if child.spelling:
                    results["types"].append(_make_type(child))

            # --- Interrupt Service Routines ---
            if cfg.get("interrupts", True) and kind_name == "FUNCTION_DECL":
                is_isr = self._is_interrupt_function(child)
                if is_isr:
                    results["interrupts"].append(_make_function(child))

            # --- Register access patterns ---
            if cfg.get("registers", True) and kind_name in (
                "VAR_DECL", "FIELD_DECL"
            ):
                if self._is_register_access(child):
                    results["registers"].append({
                        "name": child.spelling,
                        "type": str(child.type.spelling),
                        "line": child.location.line,
                        "file": str(source_file),
                    })

            # --- State machine candidates ---
            if cfg.get("state_machines", True) and kind_name == "ENUM_DECL":
                sm = self._detect_state_machine(child)
                if sm:
                    results["state_machines"].append(sm)

            # --- Interface / export detection ---
            if cfg.get("interfaces", True) and kind_name in ("FUNCTION_DECL", "VAR_DECL"):
                iface = self._detect_interface(child)
                if iface:
                    results["interfaces"].append(iface)

            # --- Call graph edges ---
            if cfg.get("call_graph", True) and kind_name == "CALL_EXPR":
                callee = _get_call_expr_name(child)
                caller = self._find_enclosing_function(child)
                if callee and caller:
                    call_edges.append({"caller": caller, "callee": callee})

            # Recurse into children
            self._traverse_translation_unit(
                child, source_file, results, call_edges, cfg
            )

    # ------------------------------------------------------------------
    # Heuristic detectors
    # ------------------------------------------------------------------

    def _is_interrupt_function(self, cursor) -> bool:
        """Detect ISR via __attribute__((interrupt(...))) or naming convention."""
        # Check for __attribute__((interrupt))
        try:
            for t in cursor.type.get_canonical().spelling or "":
                pass
        except Exception:
            pass

        # Check raw tokens / displayname for interrupt attribute
        raw = cursor.displayname or cursor.spelling or ""
        if "interrupt" in raw.lower():
            return True

        # Naming heuristics:  USARTx_IRQHandler, TIMx_IRQHandler, etc.
        name = cursor.spelling or ""
        if name.endswith("_IRQHandler"):
            return True
        if name.endswith("_Handler"):
            return True

        return False

    def _is_register_access(self, cursor) -> bool:
        """Heuristic: variable with volatile-qualified type at fixed address."""
        try:
            type_str = str(cursor.type.spelling).lower()
        except Exception:
            return False
        if "volatile" in type_str:
            return True
        name_lower = (cursor.spelling or "").lower()
        if any(kw in name_lower for kw in ("reg", "io", "periph")):
            return True
        return False

    def _detect_state_machine(self, cursor) -> Optional[Dict[str, Any]]:
        """Treat enum declarations as state-machine candidates if name contains 'state'."""
        name = cursor.spelling or ""
        if "state" in name.lower() or "mode" in name.lower() or "status" in name.lower():
            values = []
            for child in cursor.get_children():
                if child.kind.name == "ENUM_CONSTANT_DECL":
                    values.append(child.spelling)
            return {
                "name": name,
                "file": cursor.location.file,
                "line": cursor.location.line,
                "states": values,
            }
        return None

    def _detect_interface(self, cursor) -> Optional[Dict[str, Any]]:
        """Heuristic: exported symbol (external linkage) with a prefix pattern."""
        name = cursor.spelling or ""
        # Common firmware API / export prefixes
        prefixes = ("api_", "export_", "HAL_", "BSP_")
        if any(name.startswith(p) for p in prefixes):
            return {
                "name": name,
                "kind": str(cursor.kind),
                "type": str(cursor.type.spelling),
                "line": cursor.location.line,
            }
        return None

    def _find_enclosing_function(self, cursor) -> Optional[str]:
        """Walk up the AST to find the nearest enclosing function definition."""
        parent = cursor.semantic_parent
        while parent:
            if parent.kind.name == "FUNCTION_DECL":
                return parent.spelling
            parent = parent.semantic_parent
        return None