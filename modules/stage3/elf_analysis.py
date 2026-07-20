"""
Stage 3 — ELF Binary Analysis

Extracts functions, global variables, type information from an ARM ELF binary,
and builds a call graph by disassembling BL/BLX instructions with capstone.
"""

import json
import logging
from pathlib import Path
from typing import Any, Dict, List, Optional

import networkx as nx
from capstone import CS_ARCH_ARM, CS_MODE_ARM, CS_MODE_THUMB, Cs, CsInsn
from elftools.elf.elffile import ELFFile
from elftools.elf.sections import SymbolTableSection

from modules.base import BaseStage

logger = logging.getLogger(__name__)

# ARM call instructions
CALL_INSTRUCTIONS = {"bl", "blx"}


def _decode(val):
    """Convert bytes to str recursively for JSON serialization."""
    if isinstance(val, bytes):
        return val.decode("utf-8", errors="replace")
    return val


class Stage3ELFBinaryAnalysis(BaseStage):
    """ELF binary analysis stage using pyelftools + capstone."""

    def run(self, context: Dict[str, Any]) -> Dict[str, Any]:
        params = self.config["params"]
        elf_path = Path(params["elf_file"])
        output_dir = self.setup_output_dir(params["output_dir"])
        extract_cfg = params.get("extract", {})

        if not elf_path.exists():
            raise FileNotFoundError(f"ELF file not found: {elf_path}")

        with open(elf_path, "rb") as f:
            elf = ELFFile(f)

            if not elf.has_dwarf_info():  # not a hard requirement, just a note
                logger.info("ELF has no DWARF info — some features may be limited.")

            results = {}

            if extract_cfg.get("functions", True):
                results["binary_functions"] = self._extract_functions(elf)
                self.save_json("binary_functions.json", results["binary_functions"], subdir="functions")

            if extract_cfg.get("globals", True):
                results["binary_globals"] = self._extract_globals(elf)
                self.save_json("binary_globals.json", results["binary_globals"], subdir="globals")

            if extract_cfg.get("types", True):
                results["binary_types"] = self._extract_types(elf)
                self.save_json("binary_types.json", results["binary_types"], subdir="types")

            if extract_cfg.get("call_graph", True):
                call_graph = self._build_call_graph(elf, elf_path)
                self.save_call_graph_json("call_graph_binary.json", call_graph, subdir="call_graph")
                results["call_graph_binary"] = call_graph

            # Unified graph: merge static call_graph + registers → output to modeling/
            if extract_cfg.get("unified_graph", True):
                unified_graph = self._build_unified_graph(output_dir)
                unified_dir = Path(params.get("unified_output_dir", str(output_dir.parent / "modeling")))
                unified_dir.mkdir(parents=True, exist_ok=True)
                cg_data = self._call_graph_to_json(unified_graph)
                filepath = unified_dir / "call_graph_unified.json"
                with open(filepath, "w", encoding="utf-8") as f:
                    json.dump(cg_data, f, indent=2, ensure_ascii=False)
                logger.info("Saved: %s", filepath)
                results["call_graph_unified"] = unified_graph

        return {
            "stage3": {
                "output_dir": str(output_dir),
                "elf_file": str(elf_path),
                "summary": {
                    k: ({"nodes": v.number_of_nodes(), "edges": v.number_of_edges()}
                        if isinstance(v, nx.MultiDiGraph) else len(v))
                    for k, v in results.items() if v
                },
            }
        }

    # ------------------------------------------------------------------
    # Symbol-based extraction
    # ------------------------------------------------------------------

    def _extract_functions(self, elf: ELFFile) -> List[Dict[str, Any]]:
        """Extract functions from the ELF symbol table."""
        functions = []
        for section in elf.iter_sections():
            if not isinstance(section, SymbolTableSection):
                continue
            for sym in section.iter_symbols():
                if sym["st_info"]["type"] == "STT_FUNC" and sym["st_value"] != 0:
                    functions.append({
                        "name": sym.name,
                        "address": sym["st_value"],
                        "size": sym["st_size"],
                        "section": section.name,
                        "binding": sym["st_info"]["bind"],
                    })
        return functions

    def _extract_globals(self, elf: ELFFile) -> List[Dict[str, Any]]:
        """Extract global (non-function) symbols from the ELF symbol table."""
        globals_ = []
        for section in elf.iter_sections():
            if not isinstance(section, SymbolTableSection):
                continue
            for sym in section.iter_symbols():
                stype = sym["st_info"]["type"]
                bind = sym["st_info"]["bind"]
                if stype == "STT_OBJECT" and sym["st_value"] != 0:
                    globals_.append({
                        "name": sym.name,
                        "address": sym["st_value"],
                        "size": sym["st_size"],
                        "section": section.name,
                        "binding": bind,
                    })
        return globals_

    def _extract_types(self, elf: ELFFile) -> List[Dict[str, Any]]:
        """Extract type information from DWARF debug info if available."""
        types = []
        if not elf.has_dwarf_info():
            logger.warning("No DWARF info available for type extraction.")
            return types

        dwarfinfo = elf.get_dwarf_info()
        for cu in dwarfinfo.iter_CUs():
            for die in cu.iter_DIEs():
                if die.tag in ("DW_TAG_structure_type", "DW_TAG_union_type",
                               "DW_TAG_enumeration_type"):
                    type_info: Dict[str, Any] = {
                        "name": _decode(die.attributes.get("DW_AT_name", {}).value)
                                 if "DW_AT_name" in die.attributes else "<anonymous>",
                        "tag": _decode(die.tag),
                        "byte_size": die.attributes.get("DW_AT_byte_size", {}).value
                                     if "DW_AT_byte_size" in die.attributes else None,
                    }
                    # Extract members
                    members = []
                    for child in die.iter_children():
                        if child.tag in ("DW_TAG_member", "DW_TAG_enumerator"):
                            member = {
                                "name": _decode(child.attributes.get("DW_AT_name", {}).value)
                                        if "DW_AT_name" in child.attributes else "<unnamed>",
                            }
                            if "DW_AT_type" in child.attributes:
                                member["type_offset"] = (
                                    child.attributes["DW_AT_type"].value
                                )
                            members.append(member)
                    if members:
                        type_info["members"] = members
                    types.append(type_info)

        return types

    # ------------------------------------------------------------------
    # Call graph via angr CFG (fallback: capstone disassembly)
    # ------------------------------------------------------------------

    def _build_call_graph(
        self, elf: ELFFile, elf_path: Path
    ) -> nx.MultiDiGraph:
        """Build call graph — try angr CFG first, fall back to capstone."""
        try:
            return self._build_call_graph_angr(elf_path)
        except ImportError:
            logger.info("angr not available, falling back to capstone disassembly")
            return self._build_call_graph_capstone(elf, elf_path)
        except Exception as e:
            logger.warning("angr CFG failed (%s), falling back to capstone", e)
            return self._build_call_graph_capstone(elf, elf_path)

    def _build_call_graph_angr(self, elf_path: Path) -> nx.MultiDiGraph:
        """Use angr CFGFast to recover the call graph as a MultiDiGraph."""
        import angr

        proj = angr.Project(str(elf_path), auto_load_libs=False)
        cfg = proj.analyses.CFGFast()

        graph = nx.MultiDiGraph()

        for func_addr, func in cfg.functions.items():
            if func.is_simprocedure or func.is_alignment:
                continue
            caller_name = func.name if func.name else f"0x{func_addr:x}"
            if not graph.has_node(caller_name):
                graph.add_node(caller_name, address=func_addr)

            try:
                for call_site_addr in func.get_call_sites():
                    target = func.get_call_target(call_site_addr)
                    if target is None:
                        continue
                    callee_func = cfg.functions.get(target)
                    callee_name = (
                        callee_func.name
                        if callee_func and callee_func.name
                        else f"0x{target:x}"
                    )
                    if not graph.has_node(callee_name):
                        graph.add_node(callee_name, address=target)
                    key = f"0x{call_site_addr:x}"
                    graph.add_edge(caller_name, callee_name, key=key, at=key)
            except Exception:
                continue

        n_edges = graph.number_of_edges()
        logger.info("angr CFG call graph: %d nodes, %d edges",
                    graph.number_of_nodes(), n_edges)
        return graph

    def _build_call_graph_capstone(
        self, elf: ELFFile, elf_path: Path
    ) -> nx.MultiDiGraph:
        """Fallback: disassemble .text and extract BL/BLX edges."""
        # Build address → symbol name mapping
        sym_map: Dict[int, str] = {}
        for section in elf.iter_sections():
            if not isinstance(section, SymbolTableSection):
                continue
            for sym in section.iter_symbols():
                if sym["st_info"]["type"] == "STT_FUNC" and sym["st_value"] != 0:
                    sym_map[sym["st_value"]] = sym.name

        edges: List[Dict[str, str]] = []

        # Locate executable sections
        text_section = elf.get_section_by_name(".text")
        if text_section is None:
            logger.warning("No .text section found — cannot build call graph.")
            return nx.MultiDiGraph()

        data = text_section.data()
        base_addr = text_section["sh_addr"]

        # Determine ISA mode — prefer Thumb for most ARM firmware
        mode = CS_MODE_THUMB
        raw_bytes = elf_path.read_bytes()
        if b"\x00\x00\x00\x14" in raw_bytes[:32]:  # a weak check
            mode = CS_MODE_ARM

        md = Cs(CS_ARCH_ARM, mode)

        current_func = "<unknown>"
        for insn in md.disasm(data, base_addr):
            # Track function boundaries via symbol table
            if insn.address in sym_map:
                current_func = sym_map[insn.address]

            if insn.mnemonic.lower() in CALL_INSTRUCTIONS:
                for op_str in insn.op_str.split(", "):
                    try:
                        target = int(op_str, 16)
                    except ValueError:
                        continue
                    callee = sym_map.get(target, f"0x{target:x}")
                    edges.append({
                        "caller": current_func,
                        "callee": callee,
                        "call_address": hex(insn.address),
                    })

        graph = nx.MultiDiGraph()
        for e in edges:
            caller, callee = e["caller"], e["callee"]
            if not graph.has_node(caller):
                graph.add_node(caller)
            if not graph.has_node(callee):
                graph.add_node(callee)
            key = e["call_address"]
            graph.add_edge(caller, callee, key=key, at=key)

        logger.info("capstone call graph: %d nodes, %d edges",
                    graph.number_of_nodes(), graph.number_of_edges())
        return graph

    # ------------------------------------------------------------------
    # Unified graph: static call_graph + registers
    # ------------------------------------------------------------------

    def _build_unified_graph(self, output_dir: Path) -> nx.MultiDiGraph:
        """Build a unified MultiDiGraph merging static call_graph and registers.

        - Function nodes get ``node_type="function"`` (preferring binary CFG nodes,
          supplemented by static call_graph nodes when available).
        - Register nodes get ``node_type="register"``.
        - Call edges from the binary call graph are used as base; static call
          edges are merged where available.
        """
        params = self.config.get("params", {})
        graph = nx.MultiDiGraph()

        # --- 1. Load binary call graph (angr CFG) as base ---
        binary_cg_path = output_dir / "call_graph" / "call_graph_binary.json"
        if binary_cg_path.exists():
            bcg = self.load_json(str(binary_cg_path))
            for node in bcg.get("nodes", []):
                nid = node["id"]
                attrs = dict(node.get("attributes", {}))
                attrs["node_type"] = "function"
                graph.add_node(nid, **attrs)
            for edge in bcg.get("edges", []):
                u, v = edge["source"], edge["target"]
                k = edge.get("key", f"{u}->{v}")
                if not graph.has_node(u):
                    graph.add_node(u, node_type="function")
                if not graph.has_node(v):
                    graph.add_node(v, node_type="function")
                attrs = dict(edge.get("attributes", {}))
                graph.add_edge(u, v, key=k, **attrs)
            logger.info("Unified: loaded binary CFG (%d nodes, %d edges)",
                        bcg.get("node_count", 0), bcg.get("edge_count", 0))

        # --- 2. Merge static call_graph if available ---
        static_dir = Path(params.get("static_dir",
            str(output_dir.parent.parent / "static" / output_dir.name)))
        cg_path = static_dir / "call_graph" / "call_graph.json"
        if cg_path.exists():
            cg_data = self.load_json(str(cg_path))
            for node in cg_data.get("nodes", []):
                nid = node["id"]
                if not graph.has_node(nid):
                    attrs = dict(node.get("attributes", {}))
                    attrs["node_type"] = "function"
                    graph.add_node(nid, **attrs)
            for edge in cg_data.get("edges", []):
                u, v = edge["source"], edge["target"]
                k = edge.get("key", f"static:{u}->{v}")
                if not graph.has_node(u):
                    graph.add_node(u, node_type="function")
                if not graph.has_node(v):
                    graph.add_node(v, node_type="function")
                graph.add_edge(u, v, key=k)
            logger.info("Unified: merged static call_graph (%d nodes, %d edges)",
                        len(cg_data.get("nodes", [])), len(cg_data.get("edges", [])))

        # --- 3. Add register nodes ---
        reg_path = static_dir / "registers" / "registers.json"
        if reg_path.exists():
            registers = self.load_json(str(reg_path))
            for reg in registers:
                name = reg.get("name", str(reg))
                if graph.has_node(name):
                    name = f"{name}_reg"
                graph.add_node(name, node_type="register",
                               type=reg.get("type", ""),
                               file=reg.get("file", ""),
                               line=reg.get("line", 0),
                               kind=reg.get("kind", ""))
            logger.info("Unified: added %d register nodes", len(registers))

        n_edges = graph.number_of_edges()
        logger.info("Unified graph: %d nodes, %d edges",
                    graph.number_of_nodes(), n_edges)
        return graph