"""
Stage 5 — Dynamic Symbolic Execution (angr)

Uses the angr framework to perform symbolic execution on the ARM firmware binary,
verifying paths identified by earlier stages and exploring potential vulnerabilities.
"""

import json
import logging
from pathlib import Path
from typing import Any, Dict, List, Optional

from modules.base import BaseStage

logger = logging.getLogger(__name__)


class Stage5SymbolicExecution(BaseStage):
    """Symbolic execution stage using angr."""

    def run(self, context: Dict[str, Any]) -> Dict[str, Any]:
        params = self.config["params"]
        elf_path = Path(params["elf_file"])
        output_dir = self.setup_output_dir(params["output_dir"])
        explore_cfg = params.get("exploration", {})

        if not elf_path.exists():
            raise FileNotFoundError(f"ELF file not found: {elf_path}")

        timeout = explore_cfg.get("timeout", 300)
        max_depth = explore_cfg.get("max_depth", 100)
        veritesting = explore_cfg.get("veritesting", True)
        lend_init = explore_cfg.get("lazy_initialization", True)

        target_addrs = params.get("target_addresses", [])

        # Load context from Stage 4 if available (suspicious targets)
        if not target_addrs:
            stage4_report = context.get("stage4", {}).get("report")
            if stage4_report:
                target_addrs = self._extract_targets_from_report(stage4_report)

        report = self._run_symbolic_execution(
            elf_path=elf_path,
            target_addresses=target_addrs,
            timeout=timeout,
            max_depth=max_depth,
            veritesting=veritesting,
        )

        self.save_json("symbolic_report.json", report)

        # Save detailed per-path data
        paths_dir = output_dir / "exploit_paths"
        paths_dir.mkdir(parents=True, exist_ok=True)
        for i, path in enumerate(report.get("paths", [])):
            path_file = paths_dir / f"path_{i:04d}.json"
            with open(path_file, "w", encoding="utf-8") as f:
                json.dump(path, f, indent=2)

        return {
            "stage5": {
                "output_dir": str(output_dir),
                "report": str(output_dir / "symbolic_report.json"),
                "targets_analyzed": len(target_addrs),
                "paths_found": len(report.get("paths", [])),
            }
        }

    # ------------------------------------------------------------------
    # Symbolic execution
    # ------------------------------------------------------------------

    def _run_symbolic_execution(
        self,
        elf_path: Path,
        target_addresses: List[int],
        timeout: int,
        max_depth: int,
        veritesting: bool,
    ) -> Dict[str, Any]:
        """Run angr symbolic execution on the given ELF binary."""
        report: Dict[str, Any] = {
            "binary": str(elf_path),
            "target_addresses": target_addresses,
            "paths": [],
            "errors": [],
        }

        try:
            import angr
        except ImportError:
            logger.error("angr is not installed. Skipping symbolic execution.")
            report["errors"].append("angr not available")
            return report

        try:
            proj = angr.Project(
                str(elf_path),
                auto_load_libs=False,
                use_sim_procs=True,
            )
        except Exception as e:
            logger.error("Failed to load project: %s", e)
            report["errors"].append(f"Failed to load ELF: {e}")
            return report

        # Determine entry point
        entry = proj.entry
        if not target_addresses:
            logger.info("No target addresses — performing exploratory analysis from entry")
            target_addresses = self._find_suspicious_addresses(proj)

        state = proj.factory.entry_state()
        simgr = proj.factory.simgr(state)

        if veritesting:
            technique = angr.exploration_techniques.Veritesting()
            simgr.use_technique(technique)

        if max_depth:
            technique = angr.exploration_techniques.DFS()  # depth-first for depth limiting
            simgr.use_technique(technique)

        # Explore toward targets
        logger.info(
            "Starting symbolic execution toward %d target(s)...",
            len(target_addresses),
        )

        try:
            simgr.explore(find=tuple(target_addresses), num_find=10)
        except Exception as e:
            logger.error("Exploration error: %s", e)
            report["errors"].append(f"Exploration error: {e}")

        # Collect reached paths
        for addr, found_states in simgr.found.items():
            path_info: Dict[str, Any] = {
                "target_address": hex(addr),
                "target_name": self._lookup_symbol(proj, addr),
                "solution_inputs": [],
            }
            for s in found_states[:3]:  # limit per target
                try:
                    solution = s.solver.eval(s.regs.pc)
                    input_data = s.posix.dumps(0)  # stdin
                    path_info["solution_inputs"].append({
                        "pc_at_target": hex(solution),
                        "stdin_size": len(input_data) if input_data else 0,
                    })
                except Exception as e:
                    path_info["solution_inputs"].append({"error": str(e)})
            report["paths"].append(path_info)

        total_visited = len(simgr.one_active) if simgr.one_active else 0
        logger.info(
            "Exploration done: %d paths found, %d active",
            len(report["paths"]),
            total_visited,
        )

        return report

    def _lookup_symbol(self, proj, address: int) -> str:
        """Resolve an address to a symbol name."""
        try:
            sym = proj.loader.find_symbol(address)
            return sym.name if sym else f"0x{address:x}"
        except Exception:
            return f"0x{address:x}"

    def _find_suspicious_addresses(self, proj) -> List[int]:
        """
        Heuristic: find addresses of known dangerous functions (memcpy, sprintf, etc.)
        that lead from .text.
        """
        dangerous = {"memcpy", "memmove", "sprintf", "vsprintf", "strcpy", "strcat"}
        addrs = []
        for sym_name, sym_obj in proj.loader.main_object.symbols_by_name.items():
            if sym_name in dangerous and sym_obj.rebased_addr:
                addrs.append(sym_obj.rebased_addr)
        return addrs

    def _extract_targets_from_report(self, report_path: str) -> List[int]:
        """Parse the Stage 4 security report for addresses needing verification."""
        try:
            with open(report_path, "r") as f:
                data = json.load(f)
        except (FileNotFoundError, json.JSONDecodeError):
            return []

        targets = []
        for finding in data.get("findings", []):
            loc = finding.get("location", {})
            if "address" in loc:
                targets.append(loc["address"])
        return targets