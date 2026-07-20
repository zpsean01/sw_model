# Symbolic Execution Trace: `gicv3_distif_init`

- **Max depth**: 2
- **Events**: 62
- **Findings**: 12

## Event Log

| # | Type | Function | Depth | Details |
|---|------|----------|-------|---------|
| 0 | entry_start | `gicv3_distif_init` | 0 | address=0x21064c; max_depth=2; entry_args=[] |
| 1 | hook_triggered | `__assert_fail` | 2 | hook_type=concrete_stub; registers={'r0': '<BV64 0x2001d8>', 'r1': '<BV64 0x20021c>', 'r2': '<BV64 0x6d>', 'r3': '<BV64  |
| 2 | symbolic_var_created | `__assert_fail` | 2 |  |
| 3 | hook_triggered | `__assert_fail` | 2 | hook_type=concrete_stub; registers={'r0': '<BV64 0x2002c4>', 'r1': '<BV64 0x20021c>', 'r2': '<BV64 0x6e>', 'r3': '<BV64  |
| 4 | symbolic_var_created | `__assert_fail` | 2 |  |
| 5 | hook_triggered | `gicd_read_ctlr` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. mem_0_24_32>', 'r1': '<BV64 0x7>', 'r2': '<BV64 0x1>', 'r3': ' |
| 6 | symbolic_var_created | `gicd_read_ctlr` | 2 |  |
| 7 | hook_triggered | `gicd_read_ctlr` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. mem_0_24_32>', 'r1': '<BV64 0x7>', 'r2': '<BV64 0x1>', 'r3': ' |
| 8 | symbolic_var_created | `gicd_read_ctlr` | 2 |  |
| 9 | hook_triggered | `gicd_write_ctlr` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. mem_0_24_32>', 'r1': '<BV64 0x0 .. inspect_gicd_read_ctlr_ret_ |
| 10 | finding | `gicd_write_ctlr` | 2 | message=GICD_CTLR register write — protocol critical; risk_level=warning; risk_tags=['register_write']; hook_type=symbol |
| 11 | symbolic_var_created | `gicd_write_ctlr` | 2 |  |
| 12 | hook_triggered | `gicd_write_ctlr` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. mem_0_24_32>', 'r1': '<BV64 0x0 .. inspect_gicd_read_ctlr_ret_ |
| 13 | finding | `gicd_write_ctlr` | 2 | message=GICD_CTLR register write — protocol critical; risk_level=warning; risk_tags=['register_write']; hook_type=symbol |
| 14 | symbolic_var_created | `gicd_write_ctlr` | 2 |  |
| 15 | hook_triggered | `gicd_wait_for_pending_write` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. mem_0_24_32>', 'r1': '<BV64 0x0 .. inspect_gicd_read_ctlr_ret_ |
| 16 | finding | `gicd_wait_for_pending_write` | 2 | message=RWP polling after GICD_CTLR write — MUST be present per GIC spec; risk_level=critical; risk_tags=['protocol_comp |
| 17 | symbolic_var_created | `gicd_wait_for_pending_write` | 2 |  |
| 18 | hook_triggered | `gicd_wait_for_pending_write` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. mem_0_24_32>', 'r1': '<BV64 0x0 .. inspect_gicd_read_ctlr_ret_ |
| 19 | finding | `gicd_wait_for_pending_write` | 2 | message=RWP polling after GICD_CTLR write — MUST be present per GIC spec; risk_level=critical; risk_tags=['protocol_comp |
| 20 | symbolic_var_created | `gicd_wait_for_pending_write` | 2 |  |
| 21 | hook_triggered | `gicd_read_ctlr` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. mem_0_24_32>', 'r1': '<BV64 0x30>', 'r2': '<BV64 0x1>', 'r3':  |
| 22 | symbolic_var_created | `gicd_read_ctlr` | 2 |  |
| 23 | hook_triggered | `gicd_read_ctlr` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. mem_0_24_32>', 'r1': '<BV64 0x30>', 'r2': '<BV64 0x1>', 'r3':  |
| 24 | symbolic_var_created | `gicd_read_ctlr` | 2 |  |
| 25 | hook_triggered | `gicd_write_ctlr` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. mem_0_24_32>', 'r1': '<BV64 0x0 .. inspect_gicd_read_ctlr_ret_ |
| 26 | finding | `gicd_write_ctlr` | 2 | message=GICD_CTLR register write — protocol critical; risk_level=warning; risk_tags=['register_write']; hook_type=symbol |
| 27 | symbolic_var_created | `gicd_write_ctlr` | 2 |  |
| 28 | hook_triggered | `gicd_write_ctlr` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. mem_0_24_32>', 'r1': '<BV64 0x0 .. inspect_gicd_read_ctlr_ret_ |
| 29 | finding | `gicd_write_ctlr` | 2 | message=GICD_CTLR register write — protocol critical; risk_level=warning; risk_tags=['register_write']; hook_type=symbol |
| 30 | symbolic_var_created | `gicd_write_ctlr` | 2 |  |
| 31 | hook_triggered | `gicd_wait_for_pending_write` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. mem_0_24_32>', 'r1': '<BV64 0x0 .. inspect_gicd_read_ctlr_ret_ |
| 32 | finding | `gicd_wait_for_pending_write` | 2 | message=RWP polling after GICD_CTLR write — MUST be present per GIC spec; risk_level=critical; risk_tags=['protocol_comp |
| 33 | symbolic_var_created | `gicd_wait_for_pending_write` | 2 |  |
| 34 | hook_triggered | `gicd_wait_for_pending_write` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. mem_0_24_32>', 'r1': '<BV64 0x0 .. inspect_gicd_read_ctlr_ret_ |
| 35 | finding | `gicd_wait_for_pending_write` | 2 | message=RWP polling after GICD_CTLR write — MUST be present per GIC spec; risk_level=critical; risk_tags=['protocol_comp |
| 36 | symbolic_var_created | `gicd_wait_for_pending_write` | 2 |  |
| 37 | hook_triggered | `gicv3_spis_config_defaults` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. mem_0_24_32>', 'r1': '<BV64 0x0 .. inspect_gicd_read_ctlr_ret_ |
| 38 | symbolic_var_created | `gicv3_spis_config_defaults` | 2 |  |
| 39 | hook_triggered | `gicv3_spis_config_defaults` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. mem_0_24_32>', 'r1': '<BV64 0x0 .. inspect_gicd_read_ctlr_ret_ |
| 40 | symbolic_var_created | `gicv3_spis_config_defaults` | 2 |  |
| 41 | hook_triggered | `gicv3_secure_spis_config_props` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. mem_0_24_32>', 'r1': '<BV64 mem_20_55_64>', 'r2': '<BV64 0x0 . |
| 42 | symbolic_var_created | `gicv3_secure_spis_config_props` | 2 |  |
| 43 | hook_triggered | `gicv3_secure_spis_config_props` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. mem_0_24_32>', 'r1': '<BV64 mem_20_55_64>', 'r2': '<BV64 0x0 . |
| 44 | symbolic_var_created | `gicv3_secure_spis_config_props` | 2 |  |
| 45 | hook_triggered | `gicd_read_ctlr` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. mem_0_24_32>', 'r1': '<BV64 0x0 .. inspect_gicv3_secure_spis_c |
| 46 | symbolic_var_created | `gicd_read_ctlr` | 2 |  |
| 47 | hook_triggered | `gicd_read_ctlr` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. mem_0_24_32>', 'r1': '<BV64 0x0 .. inspect_gicv3_secure_spis_c |
| 48 | symbolic_var_created | `gicd_read_ctlr` | 2 |  |
| 49 | hook_triggered | `gicd_write_ctlr` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. mem_0_24_32>', 'r1': '<BV64 0x0 .. inspect_gicd_read_ctlr_ret_ |
| 50 | finding | `gicd_write_ctlr` | 2 | message=GICD_CTLR register write — protocol critical; risk_level=warning; risk_tags=['register_write']; hook_type=symbol |
| 51 | symbolic_var_created | `gicd_write_ctlr` | 2 |  |
| 52 | hook_triggered | `gicd_write_ctlr` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. mem_0_24_32>', 'r1': '<BV64 0x0 .. inspect_gicd_read_ctlr_ret_ |
| 53 | finding | `gicd_write_ctlr` | 2 | message=GICD_CTLR register write — protocol critical; risk_level=warning; risk_tags=['register_write']; hook_type=symbol |
| 54 | symbolic_var_created | `gicd_write_ctlr` | 2 |  |
| 55 | hook_triggered | `gicd_wait_for_pending_write` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. mem_0_24_32>', 'r1': '<BV64 0x0 .. inspect_gicd_read_ctlr_ret_ |
| 56 | finding | `gicd_wait_for_pending_write` | 2 | message=RWP polling after GICD_CTLR write — MUST be present per GIC spec; risk_level=critical; risk_tags=['protocol_comp |
| 57 | symbolic_var_created | `gicd_wait_for_pending_write` | 2 |  |
| 58 | hook_triggered | `gicd_wait_for_pending_write` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. mem_0_24_32>', 'r1': '<BV64 0x0 .. inspect_gicd_read_ctlr_ret_ |
| 59 | finding | `gicd_wait_for_pending_write` | 2 | message=RWP polling after GICD_CTLR write — MUST be present per GIC spec; risk_level=critical; risk_tags=['protocol_comp |
| 60 | symbolic_var_created | `gicd_wait_for_pending_write` | 2 |  |
| 61 | entry_end | `gicv3_distif_init` | 0 | status=completed; active_paths=0; deadended_paths=2; total_events=61 |

## Findings

### Finding: F-gicd_write_ctlr-2
- **Function**: `gicd_write_ctlr` (depth=2)
- **Message**: GICD_CTLR register write — protocol critical
- **Symbolic var**: `inspect_gicd_write_ctlr_ret` (32 bit) — GICD_CTLR register write — protocol critical
- **Constraint**: `<Bool mem_0_24_32 != 0x0>`

### Finding: F-gicd_write_ctlr-2
- **Function**: `gicd_write_ctlr` (depth=2)
- **Message**: GICD_CTLR register write — protocol critical
- **Symbolic var**: `inspect_gicd_write_ctlr_ret` (32 bit) — GICD_CTLR register write — protocol critical
- **Constraint**: `<Bool mem_0_24_32 == 0x0>`

### Finding: F-gicd_wait_for_pending_write-2
- **Function**: `gicd_wait_for_pending_write` (depth=2)
- **Message**: RWP polling after GICD_CTLR write — MUST be present per GIC spec
- **Symbolic var**: `inspect_gicd_wait_for_pending_write_ret` (32 bit) — RWP polling after GICD_CTLR write — MUST be present per GIC spec
- **Constraint**: `<Bool mem_0_24_32 != 0x0>`

### Finding: F-gicd_wait_for_pending_write-2
- **Function**: `gicd_wait_for_pending_write` (depth=2)
- **Message**: RWP polling after GICD_CTLR write — MUST be present per GIC spec
- **Symbolic var**: `inspect_gicd_wait_for_pending_write_ret` (32 bit) — RWP polling after GICD_CTLR write — MUST be present per GIC spec
- **Constraint**: `<Bool mem_0_24_32 == 0x0>`

### Finding: F-gicd_write_ctlr-2
- **Function**: `gicd_write_ctlr` (depth=2)
- **Message**: GICD_CTLR register write — protocol critical
- **Symbolic var**: `inspect_gicd_write_ctlr_ret` (32 bit) — GICD_CTLR register write — protocol critical
- **Constraint**: `<Bool mem_0_24_32 != 0x0>`

### Finding: F-gicd_write_ctlr-2
- **Function**: `gicd_write_ctlr` (depth=2)
- **Message**: GICD_CTLR register write — protocol critical
- **Symbolic var**: `inspect_gicd_write_ctlr_ret` (32 bit) — GICD_CTLR register write — protocol critical
- **Constraint**: `<Bool mem_0_24_32 == 0x0>`

### Finding: F-gicd_wait_for_pending_write-2
- **Function**: `gicd_wait_for_pending_write` (depth=2)
- **Message**: RWP polling after GICD_CTLR write — MUST be present per GIC spec
- **Symbolic var**: `inspect_gicd_wait_for_pending_write_ret` (32 bit) — RWP polling after GICD_CTLR write — MUST be present per GIC spec
- **Constraint**: `<Bool mem_0_24_32 != 0x0>`

### Finding: F-gicd_wait_for_pending_write-2
- **Function**: `gicd_wait_for_pending_write` (depth=2)
- **Message**: RWP polling after GICD_CTLR write — MUST be present per GIC spec
- **Symbolic var**: `inspect_gicd_wait_for_pending_write_ret` (32 bit) — RWP polling after GICD_CTLR write — MUST be present per GIC spec
- **Constraint**: `<Bool mem_0_24_32 == 0x0>`

### Finding: F-gicd_write_ctlr-2
- **Function**: `gicd_write_ctlr` (depth=2)
- **Message**: GICD_CTLR register write — protocol critical
- **Symbolic var**: `inspect_gicd_write_ctlr_ret` (32 bit) — GICD_CTLR register write — protocol critical
- **Constraint**: `<Bool mem_0_24_32 != 0x0>`

### Finding: F-gicd_write_ctlr-2
- **Function**: `gicd_write_ctlr` (depth=2)
- **Message**: GICD_CTLR register write — protocol critical
- **Symbolic var**: `inspect_gicd_write_ctlr_ret` (32 bit) — GICD_CTLR register write — protocol critical
- **Constraint**: `<Bool mem_0_24_32 == 0x0>`

### Finding: F-gicd_wait_for_pending_write-2
- **Function**: `gicd_wait_for_pending_write` (depth=2)
- **Message**: RWP polling after GICD_CTLR write — MUST be present per GIC spec
- **Symbolic var**: `inspect_gicd_wait_for_pending_write_ret` (32 bit) — RWP polling after GICD_CTLR write — MUST be present per GIC spec
- **Constraint**: `<Bool mem_0_24_32 != 0x0>`

### Finding: F-gicd_wait_for_pending_write-2
- **Function**: `gicd_wait_for_pending_write` (depth=2)
- **Message**: RWP polling after GICD_CTLR write — MUST be present per GIC spec
- **Symbolic var**: `inspect_gicd_wait_for_pending_write_ret` (32 bit) — RWP polling after GICD_CTLR write — MUST be present per GIC spec
- **Constraint**: `<Bool mem_0_24_32 == 0x0>`
