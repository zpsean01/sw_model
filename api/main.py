"""
ARM Firmware Analysis API — FastAPI Application

Exposes pipeline analysis results via REST endpoints under /api/v1/sw_model/.
Uses fastapi-offline for self-contained Swagger UI (no CDN dependency).
"""

import logging
from pathlib import Path
from typing import Any, Dict, List

from fastapi_offline import FastAPIOffline

from api.routers import static, binary, modeling, sym_execution

logger = logging.getLogger(__name__)

ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = ROOT / "data"

app = FastAPIOffline(
    title="ARM Firmware Analysis API",
    description="REST API exposing static analysis, binary analysis, modeling, and symbolic execution results.",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

PREFIX = "/api/v1/sw_model"

# ── Mount routers ──────────────────────────────────────────────
app.include_router(static.router, prefix=f"{PREFIX}/static", tags=["Static Analysis"])
app.include_router(binary.router, prefix=f"{PREFIX}/binary", tags=["Binary Analysis"])
app.include_router(modeling.router, prefix=f"{PREFIX}/modeling", tags=["Modeling"])
app.include_router(sym_execution.router, prefix=f"{PREFIX}/sym_execution", tags=["Symbolic Execution"])


# ── ztree endpoint (tree navigation data in simpleData format) ──


def _flatten(nodes, parent_id="0"):
    """Recursively flatten nested tree nodes to zTree simpleData format."""
    result = []
    for n in nodes:
        children = n.pop("children", [])
        item = {
            "id": n["id"],
            "pId": parent_id,
            "name": n["name"],
            "isParent": "true" if children else "false",
        }
        if n.get("open"):
            item["open"] = True
        result.append(item)
        if children:
            result.extend(_flatten(children, n["id"]))
    return result


@app.get(f"{PREFIX}/ztree", tags=["ztree"])
async def get_ztree():
    """Return zTree simpleData (flat) format for navigation tree."""
    nested = [
        {
            "id": "static",
            "name": "Static Analysis",
            "open": True,
            "children": [
                {"id": "static/functions", "name": "Functions"},
                {"id": "static/call_graph", "name": "Call Graph"},
                {"id": "static/globals", "name": "Globals"},
                {"id": "static/types", "name": "Types"},
                {"id": "static/interrupts", "name": "Interrupts"},
                {"id": "static/registers", "name": "Registers"},
                {"id": "static/state_machines", "name": "State Machines"},
            ],
        },
        {
            "id": "binary",
            "name": "Binary Analysis",
            "open": True,
            "children": [
                {"id": "binary/functions", "name": "Functions"},
                {"id": "binary/call_graph", "name": "Call Graph"},
                {"id": "binary/globals", "name": "Globals"},
                {"id": "binary/types", "name": "Types"},
            ],
        },
        {
            "id": "modeling",
            "name": "Modeling",
            "open": True,
            "children": [
                {"id": "modeling/event_architecture", "name": "Event Architecture"},
                {"id": "modeling/security_report", "name": "Security Report"},
                {"id": "modeling/unified_model", "name": "Unified Model"},
                {"id": "modeling/protocol_conformance", "name": "Protocol Conformance"},
            ],
        },
        {
            "id": "sym_execution",
            "name": "Symbolic Execution",
            "open": True,
            "children": [
                {"id": "sym_execution/report", "name": "Report"},
                {"id": "sym_execution/paths", "name": "Paths"},
            ],
        },
    ]
    return _flatten(nested)


@app.get("/api/v1", tags=["Root"])
async def api_root():
    """List all available API namespaces."""
    return {
        "sw_model": f"{PREFIX}",
    }


@app.get("/health", tags=["Health"])
async def health():
    return {"status": "ok"}