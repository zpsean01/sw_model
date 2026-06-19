"""
Binary analysis endpoints — serve results from data/binary/.
"""

import json
import logging
from pathlib import Path
from typing import Any

from fastapi import APIRouter, HTTPException

ROOT = Path(__file__).resolve().parent.parent.parent
DATA_DIR = ROOT / "data" / "binary"

logger = logging.getLogger(__name__)
router = APIRouter()

_ENDPOINTS = {
    "functions": "binary_functions.json",
    "globals": "binary_globals.json",
    "types": "binary_types.json",
    "call_graph": "call_graph_binary.json",
}


def _load_json(subdir: str, filename: str) -> Any:
    path = DATA_DIR / subdir / filename
    if not path.exists():
        raise HTTPException(status_code=404, detail=f"Resource not found: {path}")
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


@router.get("")
async def list_binary_endpoints():
    """List all available binary analysis endpoints."""
    return {name: f"/api/v1/binary/{name}" for name in _ENDPOINTS}


@router.get("/{name}")
async def get_binary_resource(name: str):
    """Return a binary analysis resource by name."""
    if name not in _ENDPOINTS:
        raise HTTPException(
            status_code=404,
            detail=f"Unknown resource '{name}'. Available: {list(_ENDPOINTS)}",
        )
    return _load_json(name, _ENDPOINTS[name])