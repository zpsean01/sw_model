"""
Static analysis endpoints — serve results from data/static/.
"""

import json
import logging
from pathlib import Path
from typing import Any

from fastapi import APIRouter, HTTPException

ROOT = Path(__file__).resolve().parent.parent.parent
DATA_DIR = ROOT / "data" / "static"

logger = logging.getLogger(__name__)
router = APIRouter()

# ── Known subdirectory → JSON filename mapping ─────────────────
_ENDPOINTS = {
    "functions": "functions.json",
    "globals": "globals.json",
    "types": "types.json",
    "interrupts": "interrupts.json",
    "registers": "registers.json",
    "state_machines": "state_machines.json",
    "call_graph": "call_graph.json",
}


def _load_json(subdir: str, filename: str) -> Any:
    path = DATA_DIR / subdir / filename
    if not path.exists():
        raise HTTPException(status_code=404, detail=f"Resource not found: {path}")
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


@router.get("")
async def list_static_endpoints():
    """List all available static analysis endpoints."""
    endpoints = {name: f"/api/v1/static/{name}" for name in _ENDPOINTS}
    endpoints["file_ast_parse"] = "/api/v1/static/file_ast_parse"
    return endpoints


# ── file_ast_parse (per-file AST schemas) — must precede /{name} ─


@router.get("/file_ast_parse", summary="List all parsed file ASTs")
async def list_file_ast():
    """List available per-file AST schema files."""
    ast_dir = DATA_DIR / "file_ast_parse"
    if not ast_dir.exists():
        raise HTTPException(status_code=404, detail="file_ast_parse directory not found")
    files = sorted(f.name for f in ast_dir.iterdir() if f.suffix == ".json")
    return {"files": files, "count": len(files)}


@router.get("/file_ast_parse/{filename:path}")
async def get_file_ast(filename: str):
    """Return a specific per-file AST schema."""
    ast_dir = DATA_DIR / "file_ast_parse"
    path = (ast_dir / filename).resolve()
    if not str(path).startswith(str(ast_dir.resolve())):
        raise HTTPException(status_code=403, detail="Access denied")
    if not path.exists() or path.suffix != ".json":
        raise HTTPException(status_code=404, detail="File not found")
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


@router.get("/{name}")
async def get_static_resource(name: str):
    """Return a static analysis resource by name."""
    if name not in _ENDPOINTS:
        raise HTTPException(
            status_code=404,
            detail=f"Unknown resource '{name}'. Available: {list(_ENDPOINTS)}",
        )
    return _load_json(name, _ENDPOINTS[name])