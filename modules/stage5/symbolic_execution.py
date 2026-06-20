"""
Stage 5 — Dynamic Symbolic Execution (angr) with Depth-Limited Exploration

Refined design:
  Instead of full symbolic execution from main(), we:
  1. Start from custom entry points (functions identified by Stage 4 findings)
  2. Explore the call tree up to a configurable depth (max_depth)
  3. At the depth boundary, replace deeper calls with HookSpec (mechanism)
     paired with InspectSpec (risk annotation)

Separation of concerns:
  - Hook:    interception mechanism (hook_type, SimProcedure generation)
  - Inspect: risk semantics (risk_level, risk_tags, return_range)
  - EntryPointSpec: which function to start from, how deep
"""

import json
import logging
from pathlib import Path
from typing import Any, Dict, List, Optional

from modules.base import BaseStage
from modules.stage5.hook import HookLibrary, HookSpec
from modules.stage5.inspect import (
    EntryPointSpec,
    InspectSpec,
    InspectTrigger,
    extract_entry_points_from_report,
)

logger = logging.getLogger(__name__)


class Stage5SymbolicExecution(BaseStage):
    """Symbolic execution stage with depth-limited, inspect-driven exploration."""

    def run(self, context: Dict[str, Any]) -> Dict[str, Any]:
        params = self.config["params"]
        elf_path = Path(params["elf_file"])
        output_dir = self.setup_output_dir(params["output_dir"])
        strategy = params.get("global_strategy", {})

        if not elf_path.exists():
            raise FileNotFoundError(f"ELF file not found: {elf_path}")

        # ── 1. Load entry points ────────────────────────────────────────
        entry_points = self._resolve_entry_points(params, context)

        # ── 2. Load hook library (mechanism) ────────────────────────────
        call_graph_path = Path(strategy.get("call_graph_path",
            "data/modeling/call_graph_unified.json"))
        hook_lib = HookLibrary(call_graph_path)

        hook_cfg = params.get("hooks", {})
        if hook_cfg:
            hook_lib.register_from_config(hook_cfg)

        # ── 3. Load inspect specs (semantics) ───────────────────────────
        inspect_specs: Dict[str, InspectSpec] = {}
        inspect_cfg = params.get("inspect_specs", {})
        if inspect_cfg:
            for func_name, cfg in inspect_cfg.items():
                cfg["function_name"] = func_name
                inspect_specs[func_name] = InspectSpec.from_dict(cfg)

        # ── 4. Run symbolic execution per entry point ───────────────────
        timeout = strategy.get("timeout", 300)
        veritesting = strategy.get("veritesting", True)
        default_hook_type = strategy.get("default_hook_type", "symbolic_return")

        report = self._run_on_entry_points(
            elf_path=elf_path,
            entry_points=entry_points,
            hook_lib=hook_lib,
            inspect_specs=inspect_specs,
            default_hook_type=default_hook_type,
            timeout=timeout,
            veritesting=veritesting,
        )

        # ── 5. Save outputs ────────────────────────────────────────────
        self.save_json("symbolic_report.json", report)
        hook_lib.save(output_dir / "hooks.json")
        self._save_inspect_specs(output_dir, inspect_specs)
        self._save_entry_config(output_dir, entry_points)

        entries_dir = output_dir / "entry_results"
        entries_dir.mkdir(parents=True, exist_ok=True)
        for entry_result in report.get("entry_results", []):
            fname = entry_result.get("entry_function", "unknown")
            safe_name = fname.replace("::", "_").replace("/", "_")
            self.save_json(f"{safe_name}.json", entry_result, subdir="entry_results")

        return {
            "stage5": {
                "output_dir": str(output_dir),
                "report": str(output_dir / "symbolic_report.json"),
                "entry_points_analyzed": len(entry_points),
                "total_inspect_triggers": report.get("summary", {}).get("total_inspect_triggers", 0),
                "paths_found": report.get("summary", {}).get("paths_found", 0),
            }
        }

    # ── Entry point resolution ──────────────────────────────────────────────

    def _resolve_entry_points(
        self,
        params: Dict[str, Any],
        context: Dict[str, Any],
    ) -> List[EntryPointSpec]:
        """Resolve entry points from config, falling back to Stage 4 report."""
        cfg_entries = params.get("entry_points", [])
        if cfg_entries:
            logger.info("Using %d entry points from config", len(cfg_entries))
            return [EntryPointSpec.from_dict(e) for e in cfg_entries]

        stage4_report = context.get("stage4", {}).get("report")
        if stage4_report:
            default_depth = params.get("global_strategy", {}).get("default_max_depth", 3)
            entries = extract_entry_points_from_report(
                Path(stage4_report), default_max_depth=default_depth
            )
            if entries:
                logger.info("Extracted %d entry points from Stage 4 report", len(entries))
                return entries

        logger.warning("No entry points configured and none in Stage 4 report")
        return []

    # ── Core symbolic execution ─────────────────────────────────────────────

    def _run_on_entry_points(
        self,
        elf_path: Path,
        entry_points: List[EntryPointSpec],
        hook_lib: HookLibrary,
        inspect_specs: Dict[str, InspectSpec],
        default_hook_type: str,
        timeout: int,
        veritesting: bool,
    ) -> Dict[str, Any]:
        """Run symbolic execution for each entry point."""
        report: Dict[str, Any] = {
            "binary": str(elf_path),
            "entry_count": len(entry_points),
            "entry_results": [],
            "errors": [],
        }

        try:
            import angr
        except ImportError:
            logger.error("angr is not installed. Skipping symbolic execution.")
            report["errors"].append("angr not available")
            report["summary"] = self._empty_summary()
            return report

        try:
            proj = angr.Project(str(elf_path), auto_load_libs=False)
        except Exception as e:
            logger.error("Failed to load project: %s", e)
            report["errors"].append(f"Failed to load ELF: {e}")
            report["summary"] = self._empty_summary()
            return report

        for entry in entry_points:
            try:
                result = self._run_single_entry(
                    proj=proj,
                    entry=entry,
                    hook_lib=hook_lib,
                    inspect_specs=inspect_specs,
                    default_hook_type=default_hook_type,
                    timeout=timeout,
                    veritesting=veritesting,
                )
                report["entry_results"].append(result)
            except Exception as e:
                logger.error("Entry '%s' failed: %s", entry.function, e)
                report["entry_results"].append({
                    "entry_function": entry.function,
                    "status": "error",
                    "error": str(e),
                })

        report["summary"] = self._summarize_results(report["entry_results"])
        return report

    def _run_single_entry(
        self,
        proj,
        entry: EntryPointSpec,
        hook_lib: HookLibrary,
        inspect_specs: Dict[str, InspectSpec],
        default_hook_type: str,
        timeout: int,
        veritesting: bool,
    ) -> Dict[str, Any]:
        """Run symbolic execution from a single entry point."""
        import angr

        result: Dict[str, Any] = {
            "entry_function": entry.function,
            "max_depth": entry.max_depth,
            "context": entry.context,
            "status": "pending",
            "inspect_triggers": [],
            "errors": [],
        }

        # ── Resolve entry function address ──────────────────────────────
        entry_addr = self._resolve_function_address(proj, entry.function)
        if entry_addr is None:
            result["status"] = "skipped"
            result["errors"].append(f"Function '{entry.function}' not found in ELF symbols")
            return result

        result["entry_address"] = hex(entry_addr)

        # ── Generate boundary hooks (mechanism) ─────────────────────────
        boundary_hooks = hook_lib.auto_generate_hooks(
            entry.function, entry.max_depth,
            default_hook_type=default_hook_type,
        )
        logger.info("Entry '%s': %d boundary hooks at depth %d",
                    entry.function, len(boundary_hooks), entry.max_depth)

        # ── Apply hooks to project ──────────────────────────────────────
        triggers: List[InspectTrigger] = []
        applied_count = 0
        for func_name, hook_spec in boundary_hooks.items():
            func_addr = self._resolve_function_address(proj, func_name)
            if func_addr is None:
                continue

            inspect_spec = inspect_specs.get(func_name)

            simproc_cls = self._make_inspect_simproc(
                entry.function, hook_spec, inspect_spec, triggers, entry.max_depth
            )
            proj.hook(func_addr, simproc_cls)
            applied_count += 1

        logger.info("Entry '%s': applied %d hooks", entry.function, applied_count)
        result["boundary_hooks_applied"] = applied_count
        result["boundary_functions"] = sorted(boundary_hooks.keys())

        if applied_count == 0:
            result["status"] = "no_hooks"
            result["errors"].append("No boundary functions found to hook")
            return result

        # ── Create initial state at entry function ──────────────────────
        try:
            state = proj.factory.call_state(entry_addr)
        except Exception as e:
            result["status"] = "error"
            result["errors"].append(f"Failed to create call_state: {e}")
            return result

        # ── Explore ────────────────────────────────────────────────────
        simgr = proj.factory.simgr(state)

        if veritesting:
            try:
                simgr.use_technique(angr.exploration_techniques.Veritesting())
            except Exception as e:
                logger.warning("Veritesting not available: %s", e)

        logger.info("Exploring '%s' (depth=%d)...", entry.function, entry.max_depth)
        try:
            simgr.run()
        except Exception as e:
            logger.warning("Exploration interrupted: %s", e)
            result["errors"].append(f"Exploration interrupted: {e}")

        result["status"] = "completed"
        result["active_paths"] = len(simgr.active)
        result["deadended_paths"] = len(simgr.deadended)
        result["inspect_triggers"] = [t.to_dict() for t in triggers]

        return result

    # ── SimProcedure factory ────────────────────────────────────────────────

    def _make_inspect_simproc(
        self,
        entry_function: str,
        hook_spec: HookSpec,
        inspect_spec: Optional[InspectSpec],
        triggers: List[InspectTrigger],
        max_depth: int,
    ):
        """Create an angr SimProcedure that implements the boundary hook.

        Separates mechanism from semantics:
          - HookSpec: determines hook_type (what the SimProcedure does)
          - InspectSpec: (optional) provides risk annotation for the trigger record
        """
        import angr

        hook_type = hook_spec.hook_type
        called_func = hook_spec.function_name

        # Resolve risk fields from InspectSpec (or use defaults)
        risk_level = (inspect_spec.risk_level if inspect_spec
                      else "unknown")
        risk_tags = list(inspect_spec.risk_tags) if inspect_spec else []
        description = (inspect_spec.description if inspect_spec
                       else f"Boundary hook for '{called_func}'")
        return_range = (inspect_spec.return_range if inspect_spec
                        else None)

        class InspectSimProc(angr.SimProcedure):
            """Auto-generated SimProcedure for boundary hook."""

            def run(self, *args, **kwargs):
                triggers.append(InspectTrigger(
                    entry_function=entry_function,
                    called_function=called_func,
                    call_depth=max_depth,
                    hook_type=hook_type,
                    risk_level=risk_level,
                    risk_tags=list(risk_tags),
                    description=description,
                ))

                if hook_type == "concrete_stub" and return_range:
                    mid = (return_range[0] + return_range[1]) // 2
                    return self.state.solver.BVV(mid, 32)

                elif hook_type == "symbolic_return":
                    return self.state.solver.BVS(
                        f"inspect_{called_func}_ret", 32
                    )

                else:
                    return self.state.solver.BVV(0, 32)

        safe_name = called_func.replace("::", "_").replace("<", "").replace(">", "")
        InspectSimProc.__name__ = f"Inspect_{safe_name}"
        InspectSimProc.__qualname__ = f"Inspect_{safe_name}"

        return InspectSimProc

    # ── Summary ────────────────────────────────────────────────────────────

    def _summarize_results(self, results: List[Dict]) -> Dict[str, Any]:
        total_triggers = sum(len(r.get("inspect_triggers", [])) for r in results)
        completed = sum(1 for r in results if r.get("status") == "completed")
        errors = sum(1 for r in results if r.get("status") == "error")

        risk_counts: Dict[str, int] = {}
        for r in results:
            for t in r.get("inspect_triggers", []):
                rl = t.get("risk_level", "unknown")
                risk_counts[rl] = risk_counts.get(rl, 0) + 1

        return {
            "total_entry_points": len(results),
            "completed": completed,
            "errors": errors,
            "total_inspect_triggers": total_triggers,
            "risk_distribution": risk_counts,
            "paths_found": sum(r.get("active_paths", 0) for r in results),
        }

    def _empty_summary(self) -> Dict[str, Any]:
        return {
            "total_entry_points": 0,
            "completed": 0,
            "errors": 0,
            "total_inspect_triggers": 0,
            "risk_distribution": {},
            "paths_found": 0,
        }

    def _save_entry_config(
        self, output_dir: Path, entry_points: List[EntryPointSpec]
    ) -> None:
        self.save_json(
            "entry_points.json",
            [e.to_dict() for e in entry_points],
        )

    def _save_inspect_specs(
        self, output_dir: Path, specs: Dict[str, InspectSpec]
    ) -> None:
        self.save_json(
            "inspect_specs.json",
            {k: v.to_dict() for k, v in specs.items()},
        )