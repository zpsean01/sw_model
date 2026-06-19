"""
Stage 2 — AST Analysis

Pipeline:
  1. Parse each preprocessed (.i / .ii) file with libclang-ng
  2. In a single pass through the cursor tree:
     a. Serialize the full AST to JSON and save to ``file_ast_parse/``
     b. Use the libclang cursor API to extract structured information
        (functions, globals, types, ISRs, registers, state machines,
        interfaces, call graph)

Using libclang-ng's native cursor-based AST traversal ensures that macro-
expanded C source is analysed with full semantic resolution.
"""

import json
import logging
import re
from pathlib import Path
from typing import Any, Dict, List, Optional

import networkx as nx

from modules.base import BaseStage

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Kind-name groups
# ---------------------------------------------------------------------------

FUNCTION_KINDS = {"FUNCTION_DECL"}
TYPE_KINDS     = {"STRUCT_DECL", "UNION_DECL", "ENUM_DECL", "TYPEDEF_DECL"}
GLOBAL_KINDS   = {"VAR_DECL"}
CALL_KINDS     = {"CALL_EXPR"}
FIELD_KINDS    = {"FIELD_DECL"}

# ---------------------------------------------------------------------------
# Cursor → JSON serialisation  (for file_ast_parse/)
# ---------------------------------------------------------------------------

def _loc_dict(cursor) -> Dict[str, Any]:
    loc = cursor.location
    return {
        "file": str(loc.file) if loc.file else "",
        "line": loc.line,
        "column": loc.column,
    }


def _extent_dict(cursor) -> Dict[str, int]:
    ext = cursor.extent
    return {"start_line": ext.start.line, "end_line": ext.end.line}


def _cursor_to_dict(cursor, depth: int = 0) -> Dict[str, Any]:
    """Recursively serialise a libclang cursor to a JSON-safe dict."""
    MAX_DEPTH = 80
    if depth > MAX_DEPTH:
        return {"kind": cursor.kind.name,
                "spelling": cursor.spelling or "",
                "truncated": True}

    node: Dict[str, Any] = {
        "kind": cursor.kind.name,
        "spelling": cursor.spelling or "",
        "location": _loc_dict(cursor),
        "extent": _extent_dict(cursor),
    }
    try:
        ts = cursor.type.spelling
        if ts:
            node["type"] = ts
    except Exception:
        pass
    try:
        rts = cursor.result_type.spelling
        if rts:
            node["result_type"] = rts
    except Exception:
        pass
    try:
        sc = str(cursor.storage_class)
        if sc and sc != "SC_None":
            node["storage_class"] = sc
    except Exception:
        pass
    try:
        node["is_definition"] = cursor.is_definition()
    except Exception:
        pass
    try:
        node["access_specifier"] = str(cursor.access_specifier)
    except Exception:
        pass

    children = [_cursor_to_dict(c, depth + 1) for c in cursor.get_children()]
    if children:
        node["children"] = children
    return node


# (the cursor-based analysis functions _make_function, _make_global,
#  _make_type, _is_interrupt, _is_register_access, _is_sm_enum,
#  _is_exported, and _traverse_cursor were removed in commit
#  eb1a7c9 — superseded by _load_from_file_ast_parse)


def _get_callee(cursor) -> Optional[str]:
    """Extract callee name from a CALL_EXPR cursor."""
    try:
        ref = cursor.referenced
        if ref:
            return ref.spelling
    except Exception:
        pass
    children = list(cursor.get_children())
    if children:
        return children[0].spelling
    return None


def _find_enclosing_function(cursor) -> Optional[str]:
    parent = cursor.semantic_parent
    while parent:
        if parent.kind.name == "FUNCTION_DECL":
            return parent.spelling
        parent = parent.semantic_parent
    return None


# -- #line directive parser --


_LINE_MARKER_RE = re.compile(r'^#\s+(\d+)\s+"([^"]+)"')


def _parse_line_markers(i_path: Path) -> Dict[int, str]:
    """Parse ``#line`` directives from a preprocessed ``.i`` file.

    Returns a dict mapping each preprocessed line number to the original
    source file path indicated by the active ``#line`` directive.
    """
    mapping: Dict[int, str] = {}
    current_file = str(i_path)

    with open(i_path, "r", encoding="utf-8") as f:
        for line_no, line in enumerate(f, 1):
            m = _LINE_MARKER_RE.match(line)
            if m:
                fname = m.group(2)
                # Skip built-in / command-line virtual files
                if fname not in ("<built-in>", "<command-line>"):
                    current_file = fname
            mapping[line_no] = current_file

    return mapping


# -- per-file schema builder --


def _build_file_schema(
    cursor,
    source_file: Path,
    line_source_map: Dict[int, str],
    cfg: Dict[str, bool],
) -> Dict[str, Any]:
    """Build a structured schema dict for one preprocessed file.

    Returns::

        {
            "functions": [
                {
                    "name": str,
                    "return_type": str,
                    "parameters": [{"name": str, "type": str}],
                    "calls": [str, ...],
                    "file": str,
                },
            ],
            "global_variables": {
                name: {"type": str, "file": str, "line": int},
            },
            "type_definitions": {
                name: {"kind": str, "file": str, "line": int},
            },
        }
    """
    funcs: List[Dict[str, Any]] = []
    globals_dict: Dict[str, Dict[str, Any]] = {}
    types_dict: Dict[str, Dict[str, Any]] = {}
    # track call edges per-file to attach to function dicts
    per_file_edges: List[Dict[str, str]] = []

    def _walk(node, parent_kind=None):
        kn = node.kind.name
        sp = node.spelling or ""

        # Functions
        if kn in FUNCTION_KINDS:
            func: Dict[str, Any] = {
                "name": sp or "<anonymous>",
                "return_type": str(node.result_type.spelling) if node.type else "",
                "parameters": [
                    {"name": a.spelling or f"arg{i}", "type": str(a.type.spelling)}
                    for i, a in enumerate(node.get_arguments() or [])
                ],
                "calls": [],  # filled after traversal
                "file": line_source_map.get(node.location.line, str(source_file)),
            }
            funcs.append(func)

        # Globals (TU scope)
        if kn in GLOBAL_KINDS and parent_kind in ("TRANSLATION_UNIT", None):
            if sp:
                globals_dict[sp] = {
                    "type": str(node.type.spelling),
                    "file": line_source_map.get(node.location.line, str(source_file)),
                    "line": node.location.line,
                }

        # Types
        if kn in TYPE_KINDS and sp:
            types_dict[sp] = {
                "kind": kn,
                "file": line_source_map.get(node.location.line, str(source_file)),
                "line": node.location.line,
            }

        # Call edges (for per-function calls)
        if kn in CALL_KINDS:
            callee = _get_callee(node)
            caller = _find_enclosing_function(node)
            if callee and caller:
                per_file_edges.append({"caller": caller, "callee": callee})

        for child in node.get_children():
            _walk(child, parent_kind=kn)

    _walk(cursor)

    # Attach calls to each function
    from collections import defaultdict
    by_caller: Dict[str, list] = defaultdict(list)
    for e in per_file_edges:
        by_caller[e["caller"]].append(e["callee"])
    for func in funcs:
        func["calls"] = sorted(set(by_caller.get(func["name"], [])))

    return {
        "functions": funcs,
        "global_variables": globals_dict,
        "type_definitions": types_dict,
    }


# -- recursive traversal (global category extraction) --

def _traverse_cursor(
    cursor,
    source_file: Path,
    *,
    parent_kind: Optional[str] = None,
    results: Dict[str, List],
    call_edges: List[Dict[str, str]],
    cfg: Dict[str, bool],
) -> None:
    """Recursive cursor walk that populates *results* in place."""
    kind_name = cursor.kind.name
    spelling = cursor.spelling or ""

    # --- Functions ---
    if cfg.get("functions", True) and kind_name in FUNCTION_KINDS:
        results["functions"].append(_make_function(cursor))

    # --- Global variables (translation-unit scope only) ---
    if cfg.get("globals", True) and kind_name in GLOBAL_KINDS:
        if parent_kind in ("TRANSLATION_UNIT", None):
            results["globals"].append(_make_global(cursor))

    # --- Type definitions ---
    if cfg.get("types", True) and kind_name in TYPE_KINDS:
        if spelling:
            results["types"].append(_make_type(cursor))

    # --- ISRs ---
    if cfg.get("interrupts", True) and kind_name in FUNCTION_KINDS:
        if _is_interrupt(cursor):
            results["interrupts"].append(_make_function(cursor))

    # --- Register access ---
    if cfg.get("registers", True) and kind_name in (GLOBAL_KINDS | FIELD_KINDS):
        if _is_register_access(cursor):
            results["registers"].append({
                "name": spelling,
                "type": str(cursor.type.spelling),
                "line": cursor.location.line,
                "file": str(source_file),
            })

    # --- State machine candidates ---
    if cfg.get("state_machines", True) and kind_name == "ENUM_DECL":
        if _is_sm_enum(cursor):
            values = [
                c.spelling for c in cursor.get_children()
                if c.kind.name == "ENUM_CONSTANT_DECL"
            ]
            results["state_machines"].append({
                "name": spelling,
                "file": str(cursor.location.file) if cursor.location.file else "",
                "line": cursor.location.line,
                "states": values,
            })

    # --- Interface / export detection ---
    if cfg.get("interfaces", True) and kind_name in (FUNCTION_KINDS | GLOBAL_KINDS):
        if _is_exported(cursor):
            results["interfaces"].append({
                "name": spelling,
                "kind": kind_name,
                "type": str(cursor.type.spelling),
                "line": cursor.location.line,
            })

    # --- Call graph edges ---
    if cfg.get("call_graph", True) and kind_name in CALL_KINDS:
        callee = _get_callee(cursor)
        caller = _find_enclosing_function(cursor)
        if callee and caller:
            call_edges.append({"caller": caller, "callee": callee})

    # --- Recurse ---
    for child in cursor.get_children():
        _traverse_cursor(
            child,
            source_file,
            parent_kind=kind_name,
            results=results,
            call_edges=call_edges,
            cfg=cfg,
        )


# ---------------------------------------------------------------------------
# Stage class
# ---------------------------------------------------------------------------

class Stage2ASTAnalysis(BaseStage):
    """AST analysis using libclang-ng cursor API (single-pass)."""

    def run(self, context: Dict[str, Any]) -> Dict[str, Any]:
        params = self.config["params"]
        preprocessed_dir = Path(params["preprocessed_dir"])
        output_dir = self.setup_output_dir(params["output_dir"])
        extract_cfg = params.get("extract", {})

        if not preprocessed_dir.exists():
            raise FileNotFoundError(
                f"Preprocessed directory not found: {preprocessed_dir}. "
                "Run Stage 1 first."
            )

        preproc_files = (
            sorted(preprocessed_dir.glob("*.i")) +
            sorted(preprocessed_dir.glob("*.ii"))
        )
        if not preproc_files:
            logger.warning("No preprocessed files found in %s", preprocessed_dir)
            return {"stage2": {"output_dir": str(output_dir), "files_processed": 0}}

        # ---- Phase 1 & 2 unified: one libclang parse per file ----------
        import clang.cindex

        index = clang.cindex.Index.create()

        ast_dir = output_dir / "file_ast_parse"
        ast_dir.mkdir(parents=True, exist_ok=True)
        saved_asts: List[Path] = []

        for pfile in preproc_files:
            try:
                tu = index.parse(str(pfile))
            except Exception as e:
                logger.warning("Failed to parse %s: %s", pfile, e)
                continue

            # ---- Save structured schema to file_ast_parse/ ----
            line_source_map = _parse_line_markers(pfile)
            file_schema = _build_file_schema(tu.cursor, pfile, line_source_map, extract_cfg)
            out_name = f"{pfile.name}.json"
            out_path = ast_dir / out_name
            with open(out_path, "w", encoding="utf-8") as f:
                json.dump(file_schema, f, indent=2, ensure_ascii=False)
            saved_asts.append(out_path)
            n_funcs = len(file_schema["functions"])
            n_globals = len(file_schema["global_variables"])
            n_types = len(file_schema["type_definitions"])
            logger.info("Saved: %s (functions=%d, globals=%d, types=%d)",
                        out_name, n_funcs, n_globals, n_types)

            # ---- Phase 2: load file_ast_parse/*.json, deduplicate, extract ----
        results = self._load_from_file_ast_parse(ast_dir, extract_cfg)

        # ---- Save extracted categories ----
        for category, data in results.items():
            if data:
                if category == "call_graph":
                    self.save_call_graph_json(f"{category}.json", data, subdir=category)
                else:
                    self.save_json(f"{category}.json", data, subdir=category)
                logger.info("Extracted %d %s", len(data) if not isinstance(data, nx.MultiDiGraph) else data.number_of_nodes(), category)

        # ---- Manifest ----
        manifest = [
            {"source": str(p), "ast": str(a)}
            for p, a in zip(preproc_files, saved_asts)
        ]
        self.save_json("file_ast_manifest.json", manifest, subdir="file_ast_parse")

        return {
            "stage2": {
                "output_dir": str(output_dir),
                "ast_dir": str(ast_dir),
                "files_processed": len(preproc_files),
                "ast_files_generated": len(saved_asts),
                "summary": {
                    k: ({"nodes": v.number_of_nodes(), "edges": v.number_of_edges()}
                        if isinstance(v, nx.MultiDiGraph) else len(v))
                    for k, v in results.items() if v
                },
            }
        }

    # ------------------------------------------------------------------
    # Phase 2 — load file_ast_parse/ → deduplicate → derive categories
    # ------------------------------------------------------------------

    def _load_from_file_ast_parse(
        self, ast_dir: Path, extract_cfg: Dict[str, bool]
    ) -> Dict[str, List[Dict[str, Any]]]:
        """Load all ``file_ast_parse/*.i.json`` and build deduplicated categories.

        All 8 result categories (functions, globals, types, interrupts,
        registers, state_machines, interfaces, call_graph) are derived
        from the per-file schema.
        """
        # ---- accumulate raw data with dedup keys ----
        dedup_funcs: Dict[str, Dict[str, Any]] = {}
        dedup_globals: Dict[str, Dict[str, Any]] = {}
        dedup_types: Dict[str, Dict[str, Any]] = {}
        all_edges: List[Dict[str, str]] = []  # (caller, callee)

        for fpath in sorted(ast_dir.glob("*.i.json")):
            if fpath.name == "file_ast_manifest.json":
                continue
            with open(fpath, "r", encoding="utf-8") as f:
                data = json.load(f)

            # Functions — dedup by name
            for func in data.get("functions", []):
                name = func.get("name", "")
                if name and name not in dedup_funcs:
                    dedup_funcs[name] = {
                        "name": name,
                        "kind": "CursorKind.FUNCTION_DECL",
                        "return_type": func.get("return_type", ""),
                        "parameters": func.get("parameters", []),
                        "calls": func.get("calls", []),
                        "file": func.get("file", ""),
                    }

            # Globals — dedup by name
            for name, info in data.get("global_variables", {}).items():
                if name not in dedup_globals:
                    dedup_globals[name] = {
                        "name": name,
                        "kind": "CursorKind.VAR_DECL",
                        "type": info.get("type", ""),
                        "line": info.get("line"),
                        "file": info.get("file", ""),
                    }

            # Types — dedup by name
            for name, info in data.get("type_definitions", {}).items():
                if name not in dedup_types:
                    dedup_types[name] = {
                        "name": name,
                        "kind": f"CursorKind.{info.get('kind', '')}",
                        "line": info.get("line"),
                        "file": info.get("file", ""),
                    }

            # Collect call edges for call graph
            for func in data.get("functions", []):
                caller = func.get("name", "")
                for callee in func.get("calls", []):
                    if caller and callee:
                        all_edges.append({"caller": caller, "callee": callee})

        # ---- build results ----
        results: Dict[str, List[Dict[str, Any]]] = {
            "functions": [],
            "globals": [],
            "types": [],
            "interrupts": [],
            "registers": [],
            "state_machines": [],
            "interfaces": [],
            "call_graph": [],
        }

        if extract_cfg.get("functions", True):
            results["functions"] = list(dedup_funcs.values())

        if extract_cfg.get("globals", True):
            results["globals"] = list(dedup_globals.values())

        if extract_cfg.get("types", True):
            results["types"] = list(dedup_types.values())

        # --- Derive interrupts from functions ---
        if extract_cfg.get("interrupts", True):
            _isr_prefixes = ("HAL_", "BSP_", "api_")
            for f in dedup_funcs.values():
                name = f["name"]
                if (name.endswith("_IRQHandler") or name.endswith("_Handler")
                        or name in ("NMI_Handler", "HardFault_Handler",
                                    "MemManage_Handler", "BusFault_Handler",
                                    "UsageFault_Handler", "SecureFault_Handler",
                                    "SVC_Handler", "DebugMon_Handler",
                                    "PendSV_Handler", "SysTick_Handler")):
                    results["interrupts"].append(f)

        # --- Derive registers from globals ---
        if extract_cfg.get("registers", True):
            for g in dedup_globals.values():
                type_str = (g.get("type") or "").lower()
                name_lower = g["name"].lower()
                if ("volatile" in type_str
                        or any(kw in name_lower for kw in ("reg", "io", "periph"))):
                    results["registers"].append(g)

        # --- Derive state machines from types ---
        if extract_cfg.get("state_machines", True):
            for t in dedup_types.values():
                name_lower = t["name"].lower()
                if any(kw in name_lower for kw in ("state", "mode", "status")):
                    results["state_machines"].append(t)

        # --- Derive interfaces from functions / globals ---
        if extract_cfg.get("interfaces", True):
            _if_prefixes = ("HAL_", "BSP_", "api_", "export_")
            for f in dedup_funcs.values():
                if any(f["name"].startswith(p) for p in _if_prefixes):
                    results["interfaces"].append(f)
            for g in dedup_globals.values():
                if any(g["name"].startswith(p) for p in _if_prefixes):
                    results["interfaces"].append(g)

        # --- Build call graph (MultiDiGraph) ---
        call_graph = nx.MultiDiGraph()
        if extract_cfg.get("call_graph", True) and all_edges:
            # Add nodes with function attributes
            for name, func in dedup_funcs.items():
                call_graph.add_node(name, **{k: v for k, v in func.items() if k != "name"})
            # Add edges
            for i, e in enumerate(all_edges):
                # Ensure both nodes exist (some callees may not be in dedup_funcs)
                if not call_graph.has_node(e["caller"]):
                    call_graph.add_node(e["caller"])
                if not call_graph.has_node(e["callee"]):
                    call_graph.add_node(e["callee"])
                call_graph.add_edge(e["caller"], e["callee"], key=str(i))
            results["call_graph"] = call_graph

        return results

    # ------------------------------------------------------------------
    # Helpers
    # ------------------------------------------------------------------

    @staticmethod
    def _count_nodes(node: Dict[str, Any]) -> int:
        cnt = 1
        for child in node.get("children", []):
            cnt += Stage2ASTAnalysis._count_nodes(child)
        return cnt