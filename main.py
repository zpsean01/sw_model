#!/usr/bin/env python3
"""
ARM Firmware Analysis Pipeline — Main Entry Point

Loads data_pipeline_config.json, resolves dependencies, and executes stages
sequentially. Each stage receives a shared context dict and enriches it with
its outputs.
"""

import argparse
import importlib
import json
import logging
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional

from modules.base import BaseStage

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger("pipeline")


def load_config(config_path: str) -> List[Dict[str, Any]]:
    """Load and return the pipeline stage configurations."""
    with open(config_path, "r", encoding="utf-8") as f:
        data = json.load(f)
    return data["pipeline"]["stages"]


def resolve_stage_class(
    module_path: str, class_name: str
) -> type:
    """Dynamically import and return the stage class."""
    mod = importlib.import_module(module_path)
    cls = getattr(mod, class_name)
    if not issubclass(cls, BaseStage):
        raise TypeError(f"{class_name} does not inherit from BaseStage")
    return cls


def resolve_dependency_order(
    stages: List[Dict[str, Any]]
) -> List[Dict[str, Any]]:
    """Topological sort of stages based on depends_on."""
    stage_map = {s["id"]: s for s in stages}
    visited: set = set()
    order: List[Dict[str, Any]] = []

    def dfs(sid: str):
        if sid in visited:
            return
        visited.add(sid)
        stage = stage_map[sid]
        for dep in stage.get("depends_on", []):
            if dep not in visited:
                dfs(dep)
        order.append(stage)

    for s in stages:
        if s["id"] not in visited:
            dfs(s["id"])

    return order


def run_pipeline(
    stages: List[Dict[str, Any]],
    skip_ids: List[str],
    only_ids: List[str],
    from_id: Optional[str] = None,
) -> int:
    """Execute the pipeline stages in order."""
    ordered = resolve_dependency_order(stages)

    if only_ids:
        ordered = [s for s in ordered if s["id"] in only_ids]
        all_ids = set(only_ids)
        for s in ordered:
            for dep in s.get("depends_on", []):
                if dep not in all_ids:
                    logger.warning(
                        "Stage '%s' depends on '%s' which is not in the "
                        "selected set — may lack required input.",
                        s["id"], dep,
                    )
    elif from_id:
        # --from: skip all stages before the specified one
        found = False
        filtered = []
        for s in ordered:
            if s["id"] == from_id:
                found = True
            if found:
                filtered.append(s)
        if not found:
            logger.error("Stage '%s' not found for --from", from_id)
            return 1
        ordered = filtered
        logger.info("--from '%s': running stages %s",
                    from_id, [s["id"] for s in ordered])

    context: Dict[str, Any] = {}
    exit_code = 0

    for stage_cfg in ordered:
        sid = stage_cfg["id"]

        if not stage_cfg.get("enabled", True):
            logger.info("[SKIP] Stage '%s' is disabled in config", sid)
            continue

        if skip_ids and sid in skip_ids:
            logger.info("[SKIP] Stage '%s' skipped via --skip", sid)
            continue

        logger.info("=" * 60)
        logger.info("[RUN]  Stage '%s' — %s", sid, stage_cfg.get("name", ""))
        logger.info("=" * 60)

        cls = resolve_stage_class(stage_cfg["module"], stage_cfg["class"])
        instance: BaseStage = cls(stage_cfg)
        instance.stage_id = sid

        try:
            result = instance.run(context)
            context.update(result)
            logger.info(
                "[DONE] Stage '%s' completed successfully", sid
            )
        except Exception as e:
            logger.exception(
                "[FAIL] Stage '%s' failed: %s", sid, e
            )
            context[f"{sid}_error"] = str(e)
            exit_code = 1
            # Optionally, halt on failure
            raise SystemExit(exit_code)

    return exit_code


def main():
    parser = argparse.ArgumentParser(
        description="ARM Firmware Analysis Pipeline"
    )
    parser.add_argument(
        "-c", "--config",
        default="data_pipeline_config.json",
        help="Path to pipeline configuration file (default: %(default)s)",
    )
    parser.add_argument(
        "--skip",
        nargs="+",
        default=[],
        help="Stage IDs to skip (e.g., --skip stage1 stage2)",
    )
    parser.add_argument(
        "--only",
        nargs="+",
        default=[],
        help="Run only specified stage IDs (e.g., --only stage3 stage4)",
    )
    parser.add_argument(
        "--list-stages",
        action="store_true",
        help="List configured stages and exit",
    )
    parser.add_argument(
        "--from",
        dest="from_id",
        default=None,
        help="Start pipeline from the specified stage ID (skips all earlier stages)",
    )

    args = parser.parse_args()

    config_path = Path(args.config)
    if not config_path.exists():
        logger.error("Configuration file not found: %s", config_path)
        sys.exit(1)

    stages = load_config(str(config_path))

    if args.list_stages:
        print(f"{'ID':<12} {'Name':<35} {'Enabled':<10} {'Depends On'}")
        print("-" * 75)
        for s in stages:
            deps = ", ".join(s.get("depends_on", [])) or "—"
            print(
                f"{s['id']:<12} {s['name']:<35} "
                f"{str(s.get('enabled', True)):<10} {deps}"
            )
        sys.exit(0)

    exit_code = run_pipeline(stages, args.skip, args.only, args.from_id)
    sys.exit(exit_code)


if __name__ == "__main__":
    main()