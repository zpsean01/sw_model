"""Verify ELF symbols for buggy build."""
import subprocess
import sys
nm = r"D:\llvm-mingw\bin\llvm-nm.exe"
elf = r"D:\programming\sw_model\fw_samples\tf_a_with_bugs\build\gic_harness.elf"
result = subprocess.run([nm, elf], capture_output=True, text=True)
lines = result.stdout.strip().split("\n")
funcs = [l for l in lines if " T " in l or " t " in l]
print(f"Total text symbols: {len(funcs)}")
for f in funcs:
    print(f)
# Check for expected changes
has_mmio_write_32 = any("mmio_write_32" in l for l in lines)
has_gicd_read_ctlr = any("gicd_read_ctlr" in l for l in lines)
has_mmio_read_32 = any("mmio_read_32" in l for l in lines)
has_gicd_wait = any("gicd_wait_for_pending_write" in l for l in lines)
print(f"\n--- Bug impact verification ---")
print(f"mmio_write_32 in ELF (Bug3 adds call): {has_mmio_write_32}")
print(f"gicd_read_ctlr in ELF (Bug2 changes impl): {has_gicd_read_ctlr}")
print(f"mmio_read_32 in ELF (Bug2 removes call): {has_mmio_read_32}")
print(f"gicd_wait_for_pending_write in ELF (Bug1 removes call): {has_gicd_wait}")
