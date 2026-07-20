# Symbolic Execution Trace: `gicv3_driver_init`

- **Max depth**: 2
- **Events**: 4
- **Findings**: 0

## Event Log

| # | Type | Function | Depth | Details |
|---|------|----------|-------|---------|
| 0 | entry_start | `gicv3_driver_init` | 0 | address=0x210350; max_depth=2; entry_args=[] |
| 1 | hook_triggered | `gicd_read_pidr2` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. mem_ffffffffffffffe8_136_32>', 'r1': '<BV64 (if mem_9_104_32 ! |
| 2 | symbolic_var_created | `gicd_read_pidr2` | 2 |  |
| 3 | entry_end | `gicv3_driver_init` | 0 | status=completed; active_paths=1; deadended_paths=0; total_events=3 |