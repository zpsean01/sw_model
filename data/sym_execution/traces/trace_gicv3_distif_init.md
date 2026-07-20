# Symbolic Execution Trace: `gicv3_distif_init`

- **Max depth**: 2
- **Events**: 38
- **Findings**: 0

## Event Log

| # | Type | Function | Depth | Details |
|---|------|----------|-------|---------|
| 0 | entry_start | `gicv3_distif_init` | 0 | address=0x21064c; max_depth=2; entry_args=[] |
| 1 | hook_triggered | `gicd_read_ctlr` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. mem_0_20_32>', 'r1': '<BV64 0x7>', 'r2': '<BV64 0x1>', 'r3': ' |
| 2 | symbolic_var_created | `gicd_read_ctlr` | 2 |  |
| 3 | hook_triggered | `gicd_read_ctlr` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. mem_0_20_32>', 'r1': '<BV64 0x7>', 'r2': '<BV64 0x1>', 'r3': ' |
| 4 | symbolic_var_created | `gicd_read_ctlr` | 2 |  |
| 5 | hook_triggered | `gicd_write_ctlr` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. mem_0_20_32>', 'r1': '<BV64 0x0 .. inspect_gicd_read_ctlr_ret_ |
| 6 | symbolic_var_created | `gicd_write_ctlr` | 2 |  |
| 7 | hook_triggered | `gicd_write_ctlr` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. mem_0_20_32>', 'r1': '<BV64 0x0 .. inspect_gicd_read_ctlr_ret_ |
| 8 | symbolic_var_created | `gicd_write_ctlr` | 2 |  |
| 9 | hook_triggered | `gicd_wait_for_pending_write` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. mem_0_20_32>', 'r1': '<BV64 0x0 .. inspect_gicd_read_ctlr_ret_ |
| 10 | symbolic_var_created | `gicd_wait_for_pending_write` | 2 |  |
| 11 | hook_triggered | `gicd_wait_for_pending_write` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. mem_0_20_32>', 'r1': '<BV64 0x0 .. inspect_gicd_read_ctlr_ret_ |
| 12 | symbolic_var_created | `gicd_wait_for_pending_write` | 2 |  |
| 13 | hook_triggered | `gicd_read_ctlr` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. mem_0_20_32>', 'r1': '<BV64 0x30>', 'r2': '<BV64 0x1>', 'r3':  |
| 14 | symbolic_var_created | `gicd_read_ctlr` | 2 |  |
| 15 | hook_triggered | `gicd_read_ctlr` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. mem_0_20_32>', 'r1': '<BV64 0x30>', 'r2': '<BV64 0x1>', 'r3':  |
| 16 | symbolic_var_created | `gicd_read_ctlr` | 2 |  |
| 17 | hook_triggered | `gicd_write_ctlr` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. mem_0_20_32>', 'r1': '<BV64 0x0 .. inspect_gicd_read_ctlr_ret_ |
| 18 | symbolic_var_created | `gicd_write_ctlr` | 2 |  |
| 19 | hook_triggered | `gicd_write_ctlr` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. mem_0_20_32>', 'r1': '<BV64 0x0 .. inspect_gicd_read_ctlr_ret_ |
| 20 | symbolic_var_created | `gicd_write_ctlr` | 2 |  |
| 21 | hook_triggered | `gicd_wait_for_pending_write` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. mem_0_20_32>', 'r1': '<BV64 0x0 .. inspect_gicd_read_ctlr_ret_ |
| 22 | symbolic_var_created | `gicd_wait_for_pending_write` | 2 |  |
| 23 | hook_triggered | `gicd_wait_for_pending_write` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. mem_0_20_32>', 'r1': '<BV64 0x0 .. inspect_gicd_read_ctlr_ret_ |
| 24 | symbolic_var_created | `gicd_wait_for_pending_write` | 2 |  |
| 25 | hook_triggered | `gicd_read_ctlr` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. mem_0_20_32>', 'r1': '<BV64 0x0>', 'r2': '<BV64 0x1>', 'r3': ' |
| 26 | symbolic_var_created | `gicd_read_ctlr` | 2 |  |
| 27 | hook_triggered | `gicd_read_ctlr` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. mem_0_20_32>', 'r1': '<BV64 0x0>', 'r2': '<BV64 0x1>', 'r3': ' |
| 28 | symbolic_var_created | `gicd_read_ctlr` | 2 |  |
| 29 | hook_triggered | `gicd_write_ctlr` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. mem_0_20_32>', 'r1': '<BV64 0x0 .. inspect_gicd_read_ctlr_ret_ |
| 30 | symbolic_var_created | `gicd_write_ctlr` | 2 |  |
| 31 | hook_triggered | `gicd_write_ctlr` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. mem_0_20_32>', 'r1': '<BV64 0x0 .. inspect_gicd_read_ctlr_ret_ |
| 32 | symbolic_var_created | `gicd_write_ctlr` | 2 |  |
| 33 | hook_triggered | `gicd_wait_for_pending_write` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. mem_0_20_32>', 'r1': '<BV64 0x0 .. inspect_gicd_read_ctlr_ret_ |
| 34 | symbolic_var_created | `gicd_wait_for_pending_write` | 2 |  |
| 35 | hook_triggered | `gicd_wait_for_pending_write` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. mem_0_20_32>', 'r1': '<BV64 0x0 .. inspect_gicd_read_ctlr_ret_ |
| 36 | symbolic_var_created | `gicd_wait_for_pending_write` | 2 |  |
| 37 | entry_end | `gicv3_distif_init` | 0 | status=completed; active_paths=0; deadended_paths=2; total_events=37 |