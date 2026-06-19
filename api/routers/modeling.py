"""
Modeling endpoints — serve results from data/modeling/ and gojs/modeling/.
"""

import json
import logging
from pathlib import Path
from typing import Any

from fastapi import APIRouter, HTTPException

ROOT = Path(__file__).resolve().parent.parent.parent
DATA_DIR = ROOT / "data" / "modeling"
GOJS_DIR = ROOT / "gojs" / "modeling"

logger = logging.getLogger(__name__)
router = APIRouter()

_ENDPOINTS = {
    "event_architecture": "event_architecture.json",
    "security_report": "security_report.json",
    "unified_model": "call_graph_unified.json",
}


def _load_json(path: Path) -> Any:
    if not path.exists():
        raise HTTPException(status_code=404, detail=f"Resource not found: {path}")
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


# ── Sub-routes for unified_model ──────────────────────────────────


@router.get("/unified_model/data")
async def get_unified_model_data():
    """Return the original call_graph_unified.json (NetworkX format)."""
    return _load_json(DATA_DIR / "call_graph_unified.json")


@router.get("/unified_model/gojs")
async def get_unified_model_gojs():
    """Return the GoJS-converted call_graph_unified.json."""
    return _load_json(GOJS_DIR / "call_graph_unified.json")


# ── Generic resource endpoint ─────────────────────────────────────


@router.get("")
async def list_modeling_endpoints():
    """List all available modeling endpoints."""
    return {name: f"/api/v1/modeling/{name}" for name in _ENDPOINTS}


@router.get("/{name}")
async def get_modeling_resource(name: str):
    """Return a modeling resource by name."""
    if name not in _ENDPOINTS:
        raise HTTPException(
            status_code=404,
            detail=f"Unknown resource '{name}'. Available: {list(_ENDPOINTS)}",
        )
    return _load_json(DATA_DIR / _ENDPOINTS[name])