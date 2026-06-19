"""
Convert call_graph_unified.json to GoJS hierarchical format.

All nodes become GoJS group nodes (isGroup=true) organized in a tree:
  root → [{Functions, Registers} → {func/reg nodes}]
Edges are preserved as GoJS linkDataArray entries.

Usage:
    python modules/utils/convert_data_to_gojs_with_hierarchy.py
"""

import json
import logging
from pathlib import Path

logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
logger = logging.getLogger(__name__)

ROOT = Path(__file__).resolve().parent.parent.parent
SRC = ROOT / "data" / "modeling" / "call_graph_unified.json"
DST = ROOT / "gojs" / "modeling" / "call_graph_unified.json"


def _short_file(path: str) -> str:
    """Extract a short file identifier from a long path."""
    parts = path.replace("\\\\", "/").replace("\\", "/").split("/")
    return "/".join(parts[-3:]) if len(parts) >= 3 else path


def convert() -> None:
    if not SRC.exists():
        logger.error("Source not found: %s", SRC)
        return

    with open(SRC, "r", encoding="utf-8") as f:
        data = json.load(f)

    src_nodes = data.get("nodes", [])
    src_edges = data.get("edges", [])

    # ── Classify nodes ────────────────────────────────────────────
    func_nodes = [n for n in src_nodes if n.get("attributes", {}).get("node_type") == "function"]
    reg_nodes = [n for n in src_nodes if n.get("attributes", {}).get("node_type") == "register"]

    # ── Build GoJS nodeDataArray ──────────────────────────────────
    node_data = []

    # root group
    node_data.append({
        "key": "root",
        "category": "Group",
        "isGroup": True,
        "text": "All",
    })

    # functions container group
    node_data.append({
        "key": "functions-group",
        "category": "Group",
        "isGroup": True,
        "group": "root",
        "text": "Functions",
        "node_type": "function",
        "count": len(func_nodes),
    })

    # individual function nodes (all are groups)
    for n in func_nodes:
        nid = n["id"]
        attrs = n.get("attributes", {})
        node_data.append({
            "key": nid,
            "category": "Group",
            "isGroup": True,
            "group": "functions-group",
            "text": nid,
            "node_type": "function",
            "file": attrs.get("file", ""),
            "short_file": _short_file(attrs.get("file", "")),
            "return_type": attrs.get("return_type", ""),
            "parameters": attrs.get("parameters", []),
            "calls": attrs.get("calls", []),
        })

    # registers container group
    node_data.append({
        "key": "registers-group",
        "category": "Group",
        "isGroup": True,
        "group": "root",
        "text": "Registers",
        "node_type": "register",
        "count": len(reg_nodes),
    })

    # individual register nodes (all are groups)
    for n in reg_nodes:
        nid = n["id"]
        attrs = n.get("attributes", {})
        node_data.append({
            "key": nid,
            "category": "Group",
            "isGroup": True,
            "group": "registers-group",
            "text": nid,
            "node_type": "register",
            "type": attrs.get("type", ""),
            "file": attrs.get("file", ""),
            "short_file": _short_file(attrs.get("file", "")),
            "line": attrs.get("line", 0),
            "kind": attrs.get("kind", ""),
        })

    # ── Build GoJS linkDataArray ──────────────────────────────────
    link_data = []
    for e in src_edges:
        link_data.append({
            "from": e["source"],
            "to": e["target"],
            "key": e.get("key", ""),
            "text": e.get("key", ""),
        })

    output = {
        "class": "go.GraphLinksModel",
        "nodeDataArray": node_data,
        "linkDataArray": link_data,
    }

    # ── Write output ──────────────────────────────────────────────
    DST.parent.mkdir(parents=True, exist_ok=True)
    with open(DST, "w", encoding="utf-8") as f:
        json.dump(output, f, indent=2, ensure_ascii=False)

    logger.info("Written: %s", DST)
    logger.info("  nodeDataArray: %d entries (%d functions, %d registers, 2 containers, 1 root)",
                len(node_data), len(func_nodes), len(reg_nodes))
    logger.info("  linkDataArray: %d entries", len(link_data))


if __name__ == "__main__":
    convert()