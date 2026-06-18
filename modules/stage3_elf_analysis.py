"""
Stage 3 — ELF Binary Analysis

Extracts functions, global variables, type information from an ARM ELF binary,
and builds a call graph by disassembling BL/BLX instructions with capstone.
"""

import logging
from pathlib import Path
from typing import Any, Dict, List, Optional

from capstone import CS_ARCH_ARM, CS_MODE_ARM, CS_MODE_THUMB, Cs, CsInsn
from elftools.elf.elffile import ELFFile
from elftools.elf.sections import SymbolTableSection

from modules.base import BaseStage

logger = logging.getLogger(__name__)

# ARM call instructions
CALL_INSTRUCTIONS = {"bl", "blx"}


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
                self.save_json("binary_functions.json", results["binary_functions"])

            if extract_cfg.get("globals", True):
                results["binary_globals"] = self._extract_globals(elf)
                self.save_json("binary_globals.json", results["binary_globals"])

            if extract_cfg.get("types", True):
                results["binary_types"] = self._extract_types(elf)
                self.save_json("binary_types.json", results["binary_types"])

            if extract_cfg.get("call_graph", True):
                results["call_graph_binary"] = self._build_call_graph(elf, elf_path)
                self.save_json("call_graph_binary.json", results["call_graph_binary"])

        return {
            "stage3": {
                "output_dir": str(output_dir),
                "elf_file": str(elf_path),
                "summary": {k: len(v) for k, v in results.items() if v},
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
                        "name": die.attributes.get("DW_AT_name", {}).value
                                 if "DW_AT_name" in die.attributes else "<anonymous>",
                        "tag": die.tag,
                        "byte_size": die.attributes.get("DW_AT_byte_size", {}).value
                                     if "DW_AT_byte_size" in die.attributes else None,
                    }
                    # Extract members
                    members = []
                    for child in die.iter_children():
                        if child.tag in ("DW_TAG_member", "DW_TAG_enumerator"):
                            member = {
                                "name": child.attributes.get("DW_AT_name", {}).value
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
    # Call graph via disassembly
    # ------------------------------------------------------------------

    def _build_call_graph(
        self, elf: ELFFile, elf_path: Path
    ) -> List[Dict[str, Any]]:
        """Disassemble .text and extract BL/BLX edges."""
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
            return []

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
                # BL/BLX operands: typically the target address
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

        # Group edges by caller
        graph: Dict[str, List[Dict]] = {}
        for e in edges:
            caller = e["caller"]
            graph.setdefault(caller, [])
            graph[caller].append({"callee": e["callee"], "at": e["call_address"]})

        return [
            {"caller": k, "calls": v} for k, v in graph.items()
        ]