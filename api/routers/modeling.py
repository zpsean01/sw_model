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


# ── Protocol conformance ────────────────────────────────────────────


@router.get("/protocol_conformance/data")
async def get_protocol_conformance_data():
    """Return protocol conformance analysis results."""
    return _load_json(DATA_DIR / "protocol_conformance.json")


@router.get("/protocol_conformance/gojs")
async def get_protocol_conformance_gojs():
    """Return colored GoJS data with protocol conformance finding highlights.

    Merges call_graph_unified GoJS data with finding information.
    Nodes with findings have diagnostics field populated.
    Also adds missing function nodes that have findings but aren't in the call graph.
    """
    gojs = _load_json(GOJS_DIR / "call_graph_unified.json")
    findings = _load_json(DATA_DIR / "protocol_conformance.json")

    # Collect all function names that have findings
    finding_funcs: set = set()
    for f in findings.get("findings", []):
        loc = f.get("location", {})
        fn = loc.get("function", "")
        if fn:
            finding_funcs.add(fn)

    # Build existing node key set
    existing_keys: set = set()
    for nd in gojs.get("nodeDataArray", []):
        existing_keys.add(nd.get("key", ""))

    # Load all functions from static analysis to add missing DDR5 nodes
    func_path = ROOT / "data" / "static" / "functions" / "functions.json"
    all_functions = []
    if func_path.exists():
        with open(func_path, "r", encoding="utf-8") as f:
            all_functions = json.load(f)

    # Add missing function nodes with findings as leaf nodes under functions-group
    finding_map: dict = {}
    for f in findings.get("findings", []):
        loc = f.get("location", {})
        fn = loc.get("function", "")
        if fn:
            if fn not in finding_map:
                finding_map[fn] = []
            finding_map[fn].append(f)

    # Severity → color mapping for frontend highlighting
    SEVERITY_COLORS = {
        "critical": "#7f1d1d",
        "high":     "#dc2626",
        "medium":   "#f59e0b",
        "low":      "#3b82f6",
        "info":     "#6b7280",
    }
    SEVERITY_ORDER = {"critical": 5, "high": 4, "medium": 3, "low": 2, "info": 1}

    def _pick_color(findings_list):
        """Pick the color of the highest severity finding."""
        max_order = 0
        best = "info"
        for ff in findings_list:
            s = ff.get("severity", "info")
            o = SEVERITY_ORDER.get(s, 1)
            if o > max_order:
                max_order = o
                best = s
        return SEVERITY_COLORS.get(best, "#6b7280")

    # Add nodes for functions with findings that aren't in the GoJS data yet
    node_data = gojs.get("nodeDataArray", [])
    for fn in sorted(finding_funcs):
        if fn not in existing_keys:
            node_data.append({
                "key": fn,
                "category": "Group",
                "isGroup": False,
                "group": "functions-group",
                "findings": finding_map.get(fn, []),
                "finding_highlight": True,
                "color": _pick_color(finding_map.get(fn, [])),
            })

    # Also annotate existing nodes with findings
    for nd in node_data:
        key = nd.get("key", "")
        base_key = key.split("::")[-1] if "::" in key else key
        if base_key in finding_funcs:
            existing_findings = nd.get("findings", [])
            if not existing_findings:
                nd["findings"] = finding_map.get(base_key, [])
            # Add color field
            nd["color"] = _pick_color(nd["findings"])

    return gojs


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