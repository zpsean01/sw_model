"""
Deep probe: use angr CFG + source-level analysis to locate DDR5 functions.
Also checks the source files for function signatures to understand
what symbolic patterns we should be looking for.
"""
import angr
import re
from pathlib import Path

proj = angr.Project(
    "fw_samples/build/bin/firmware_tfm.elf",
    auto_load_libs=False,
)

# 1. Try CFG analysis to find functions
print("=== CFG Function Discovery ===")
try:
    cfg = proj.analyses.CFGFast()
    print(f"CFG found {len(cfg.functions)} functions")
    # List all functions
    for addr, func in sorted(cfg.functions.items())[:50]:
        print(f"  0x{addr:08x}: {func.name} (calls={len(func.call_sites)})")
except Exception as e:
    print(f"CFGFast failed: {e}")
    # Try CFGEmulated
    try:
        cfg = proj.analyses.CFGEmulated()
        print(f"CFGEmulated found {len(cfg.functions)} functions")
        for addr, func in sorted(cfg.functions.items())[:50]:
            print(f"  0x{addr:08x}: {func.name} (calls={len(func.call_sites)})")
    except Exception as e:
        print(f"CFGEmulated also failed: {e}")

# 2. Read source files to find potential entry points
print("\n=== Source-level Function Discovery ===")
src_root = Path("fw_samples/src")
lib_root = Path("fw_samples/lib")
all_funcs = []

for root in [src_root, lib_root]:
    for fpath in root.rglob("*.c"):
        with open(fpath) as f:
            content = f.read()
        # Find function definitions (simple heuristic)
        matches = re.findall(
            r"^(?:static\s+)?(?:\w+\s+)+(\w+)\s*\([^)]*\)\s*\{",
            content, re.MULTILINE
        )
        for m in matches:
            all_funcs.append((str(fpath.relative_to("fw_samples")), m))

# Filter DDR5-specific
ddr_funcs = [(f, n) for f, n in all_funcs 
             if any(kw in n.lower() for kw in ["ddr5", "ddr", "vref", "mr_", "zq_", "ca_train", "dq_train"])]

print(f"\nSource-level DDR5 functions ({len(ddr_funcs)}):")
for f, n in sorted(ddr_funcs, key=lambda x: x[1]):
    print(f"  {n:40s} in {f}")

# Also show ALL main.c functions (to find main's callees)
print(f"\nAll functions in src/ddr:")
for f, n in sorted(all_funcs, key=lambda x: x[1]):
    if "ddr" in f:
        print(f"  {n:40s} in {f}")