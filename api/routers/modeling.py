"""
Modeling endpoints — serve results from data/modeling/.
"""

import json
import logging
from pathlib import Path
from typing import Any

from fastapi import APIRouter, HTTPException

ROOT = Path(__file__).resolve().parent.parent.parent
DATA_DIR = ROOT / "data" / "modeling"

logger = logging.getLogger(__name__)
router = APIRouter()

_ENDPOINTS = {
    "event_architecture": "event_architecture.json",
    "security_report": "security_report.json",
}


def _load_json(filename: str) -> Any:
    path = DATA_DIR / filename
    if not path.exists():
        raise HTTPException(status_code=404, detail=f"Resource not found: {path}")
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


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
    return _load_json(_ENDPOINTS[name])