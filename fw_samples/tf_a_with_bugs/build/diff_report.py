"""Compare correct vs buggy pipeline outputs at every stage."""
import json
from pathlib import Path
from collections import Counter

BASE = Path("D:/programming/sw_model")

def load(p):
    try:
        with open(p) as f:
            return json.load(f)
    except Exception:
        return None

def check_cg_diff():
    """Stage 3: call graph edge comparison."""
    correct = load(BASE / "data/binary/ARM_CORELINK_GIC_700_r4p0/call_graph/call_graph_binary.json")
    buggy  = load(BASE / "data/binary/ARM_CORELINK_GIC_700_r4p0_with_bugs/call_graph/call_graph_binary.json")
    if not correct or not buggy:
        return "MISSING"

    c_edges = {(e["source"], e["target"]) for e in correct["edges"]}
    b_edges = {(e["source"], e["target"]) for e in buggy["edges"]}

    missing = c_edges - b_edges
    added  = b_edges - c_edges
    same   = c_edges & b_edges

    return {
        "correct_nodes": len(correct["nodes"]),
        "buggy_nodes": len(buggy["nodes"]),
        "correct_edges": len(correct["edges"]),
        "buggy_edges": len(buggy["edges"]),
        "edges_removed": sorted(f"{s}→{t}" for s, t in missing),
        "edges_added":   sorted(f"{s}→{t}" for s, t in added),
        "edges_shared":  len(same),
    }

def check_unified_cg_diff():
    correct = load(BASE / "data/modeling/ARM_CORELINK_GIC_700_r4p0/call_graph_unified.json")
    buggy  = load(BASE / "data/modeling/ARM_CORELINK_GIC_700_r4p0_with_bugs/call_graph_unified.json")
    if not correct or not buggy:
        return "MISSING"
    c_edges = {(e["source"], e["target"]) for e in correct["edges"]}
    b_edges = {(e["source"], e["target"]) for e in buggy["edges"]}
    return {
        "correct": f'{len(correct["nodes"])}n/{len(correct["edges"])}e',
        "buggy":   f'{len(buggy["nodes"])}n/{len(buggy["edges"])}e',
        "diff_edges": sorted((c_edges - b_edges) | (b_edges - c_edges)),
    }

def check_symbolic_diff():
    """Stage 5: trigger count comparison."""
    correct = load(BASE / "data/sym_execution/ARM_CORELINK_GIC_700_r4p0/symbolic_report.json")
    buggy  = load(BASE / "data/sym_execution/ARM_CORELINK_GIC_700_r4p0_with_bugs/symbolic_report.json")
    if not correct or not buggy:
        return "MISSING"

    def triggers_by_entry(r):
        return {e["entry_function"]: len(e.get("inspect_triggers", [])) for e in r["entry_results"]}

    c_trig = triggers_by_entry(correct)
    b_trig = triggers_by_entry(buggy)

    return {
        "correct_summary": correct["summary"],
        "buggy_summary": buggy["summary"],
        "triggers_correct": c_trig,
        "triggers_buggy": b_trig,
    }

def check_risk_diff():
    """Stage 6: risk registry comparison."""
    correct = load(BASE / "data/risks/ARM_CORELINK_GIC_700_r4p0/protocol_conformance/risk_registry.json")
    buggy  = load(BASE / "data/risks/ARM_CORELINK_GIC_700_r4p0_with_bugs/protocol_conformance/risk_registry.json")
    if not correct or not buggy:
        return "MISSING"

    return {
        "correct_summary": correct["summary"],
        "buggy_summary": buggy["summary"],
    }

print("=" * 60)
print("DIFFERENTIAL VALIDATION REPORT")
print("Correct:   fw_samples/tf_a (ARM_CORELINK_GIC_700_r4p0)")
print("Buggy:     fw_samples/tf_a_with_bugs (ARM_CORELINK_GIC_700_r4p0_with_bugs)")
print("=" * 60)

print("\n=== [Stage 3] Binary Call Graph ===")
cg = check_cg_diff()
if isinstance(cg, dict):
    print(f"  Nodes:      correct={cg['correct_nodes']}  buggy={cg['buggy_nodes']}")
    print(f"  Edges:      correct={cg['correct_edges']}  buggy={cg['buggy_edges']}")
    print(f"  Shared:     {cg['edges_shared']}")
    print(f"  Removed:    {cg['edges_removed']}")
    print(f"  Added:      {cg['edges_added']}")
    note = []
    if "gicd_set_ctlr→gicd_wait_for_pending_write" in cg["edges_removed"]:
        note.append("[OK] Bug1 detected: RWP poll removed from gicd_set_ctlr")
    if "gicd_read_ctlr→mmio_read_32" in cg["edges_removed"]:
        note.append("[OK] Bug2 detected: mmio_read_32 call removed from gicd_read_ctlr")
    if "gicv3_distif_init→mmio_write_32" in cg["edges_added"]:
        note.append("[OK] Bug3 detected: rogue mmio_write_32 added in gicv3_distif_init")
    for n in note:
        print(f"  {n}")
    if not note:
        print("  [WARN] No expected bug signatures found in call graph!")
else:
    print(f"  {cg}")

print("\n=== [Stage 3] Unified Call Graph ===")
ucg = check_unified_cg_diff()
if isinstance(ucg, dict):
    print(f"  Correct:  {ucg['correct']}")
    print(f"  Buggy:    {ucg['buggy']}")
    print(f"  Diff edges: {ucg['diff_edges']}")
else:
    print(f"  {ucg}")

print("\n=== [Stage 5] Symbolic Execution ===")
sym = check_symbolic_diff()
if isinstance(sym, dict):
    print(f"  Correct triggers: {sym['triggers_correct']}")
    print(f"  Buggy triggers:   {sym['triggers_buggy']}")
    print(f"  Equal: {sym['triggers_correct'] == sym['triggers_buggy']}")
else:
    print(f"  {sym}")

print("\n=== [Stage 6] Risk Registry ===")
risk = check_risk_diff()
if isinstance(risk, dict):
    print(f"  Correct: total={risk['correct_summary']['total_risks']} "
          f"v={risk['correct_summary']['verified']} r={risk['correct_summary']['residual']}")
    print(f"  Buggy:   total={risk['buggy_summary']['total_risks']} "
          f"v={risk['buggy_summary']['verified']} r={risk['buggy_summary']['residual']}")
    print(f"  Equal: {risk['correct_summary'] == risk['buggy_summary']}")
else:
    print(f"  {risk}")
