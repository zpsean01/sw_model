"""
Symbolic execution endpoints — serve results from data/sym_execution/.
"""

import json
import logging
from pathlib import Path
from typing import Any

from fastapi import APIRouter, HTTPException

ROOT = Path(__file__).resolve().parent.parent.parent
DATA_DIR = ROOT / "data" / "sym_execution"

logger = logging.getLogger(__name__)
router = APIRouter()


def _load(subdir: str, filename: str) -> Any:
    path = DATA_DIR / subdir / filename
    if not path.exists():
        raise HTTPException(status_code=404, detail=f"Resource not found: {path}")
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


@router.get("")
async def list_sym_execution_endpoints():
    """List all available symbolic execution endpoints."""
    return {
        "report": "/api/v1/sym_execution/report",
        "paths": "/api/v1/sym_execution/paths",
    }


@router.get("/report")
async def get_report():
    """Return the symbolic execution report."""
    return _load("", "symbolic_report.json")


@router.get("/paths")
async def list_paths():
    """List all exploited paths."""
    paths_dir = DATA_DIR / "exploit_paths"
    if not paths_dir.exists():
        raise HTTPException(status_code=404, detail="No exploit paths found")
    files = sorted(f.name for f in paths_dir.iterdir() if f.suffix == ".json")
    return {"paths": files, "count": len(files)}


@router.get("/paths/{path_id:path}")
async def get_path(path_id: str):
    """Return a specific exploited path."""
    paths_dir = DATA_DIR / "exploit_paths"
    # Ensure filename ends with .json
    if not path_id.endswith(".json"):
        path_id += ".json"
    path = (paths_dir / path_id).resolve()
    if not str(path).startswith(str(paths_dir.resolve())):
        raise HTTPException(status_code=403, detail="Access denied")
    if not path.exists():
        raise HTTPException(status_code=404, detail="Path not found")
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)