# Symbolic Execution Trace: `gicv3_rdistif_init`

- **Max depth**: 2
- **Events**: 42
- **Findings**: 0

## Event Log

| # | Type | Function | Depth | Details |
|---|------|----------|-------|---------|
| 0 | entry_start | `gicv3_rdistif_init` | 0 | address=0x210704; max_depth=2; entry_args=[] |
| 1 | hook_triggered | `gicv3_rdistif_on` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. reg_x0_180_64[31:0]>', 'r1': '<BV64 0x200198>', 'r2': '<BV64 0 |
| 2 | symbolic_var_created | `gicv3_rdistif_on` | 2 |  |
| 3 | hook_triggered | `gicv3_rdistif_on` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. reg_x0_180_64[31:0]>', 'r1': '<BV64 0x200198>', 'r2': '<BV64 0 |
| 4 | symbolic_var_created | `gicv3_rdistif_on` | 2 |  |
| 5 | hook_triggered | `gicv3_ppi_sgi_config_defaults` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. mem_ffe0000000000000_186_32>', 'r1': '<BV64 0x200198>', 'r2':  |
| 6 | symbolic_var_created | `gicv3_ppi_sgi_config_defaults` | 2 |  |
| 7 | hook_triggered | `gicv3_secure_ppi_sgi_config_props` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. mem_ffe0000000000000_186_32>', 'r1': '<BV64 mem_20_191_64>', ' |
| 8 | symbolic_var_created | `gicv3_secure_ppi_sgi_config_props` | 2 |  |
| 9 | hook_triggered | `gicv3_rdistif_on` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. reg_x0_180_64[31:0]>', 'r1': '<BV64 0x200198>', 'r2': '<BV64 0 |
| 10 | symbolic_var_created | `gicv3_rdistif_on` | 2 |  |
| 11 | hook_triggered | `gicv3_ppi_sgi_config_defaults` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. (if mem_10_182_64 == 0xffe0000000000000 + 0xffffffffffffffff * |
| 12 | symbolic_var_created | `gicv3_ppi_sgi_config_defaults` | 2 |  |
| 13 | hook_triggered | `gicv3_secure_ppi_sgi_config_props` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. (if mem_10_182_64 == 0xffe0000000000000 + 0xffffffffffffffff * |
| 14 | symbolic_var_created | `gicv3_secure_ppi_sgi_config_props` | 2 |  |
| 15 | hook_triggered | `gicv3_rdistif_on` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. reg_x0_180_64[31:0]>', 'r1': '<BV64 0x200198>', 'r2': '<BV64 0 |
| 16 | symbolic_var_created | `gicv3_rdistif_on` | 2 |  |
| 17 | hook_triggered | `gicv3_ppi_sgi_config_defaults` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. (if mem_10_182_64 == 0xfffffffffffffffb + 0xffffffffffffffff * |
| 18 | symbolic_var_created | `gicv3_ppi_sgi_config_defaults` | 2 |  |
| 19 | hook_triggered | `gicv3_secure_ppi_sgi_config_props` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. (if mem_10_182_64 == 0xfffffffffffffffb + 0xffffffffffffffff * |
| 20 | symbolic_var_created | `gicv3_secure_ppi_sgi_config_props` | 2 |  |
| 21 | hook_triggered | `gicv3_rdistif_on` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. reg_x0_180_64[31:0]>', 'r1': '<BV64 0x200198>', 'r2': '<BV64 0 |
| 22 | symbolic_var_created | `gicv3_rdistif_on` | 2 |  |
| 23 | hook_triggered | `gicv3_ppi_sgi_config_defaults` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. (if mem_10_182_64 == 0x3fffff000 + 0xffffffffffffffff * (0x0 . |
| 24 | symbolic_var_created | `gicv3_ppi_sgi_config_defaults` | 2 |  |
| 25 | hook_triggered | `gicv3_secure_ppi_sgi_config_props` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. (if mem_10_182_64 == 0x3fffff000 + 0xffffffffffffffff * (0x0 . |
| 26 | symbolic_var_created | `gicv3_secure_ppi_sgi_config_props` | 2 |  |
| 27 | hook_triggered | `gicv3_rdistif_on` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. reg_x0_180_64[31:0]>', 'r1': '<BV64 0x200198>', 'r2': '<BV64 0 |
| 28 | symbolic_var_created | `gicv3_rdistif_on` | 2 |  |
| 29 | hook_triggered | `gicv3_ppi_sgi_config_defaults` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. mem_3fffff000_208_32>', 'r1': '<BV64 0x200198>', 'r2': '<BV64  |
| 30 | symbolic_var_created | `gicv3_ppi_sgi_config_defaults` | 2 |  |
| 31 | hook_triggered | `gicv3_secure_ppi_sgi_config_props` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. mem_3fffff000_208_32>', 'r1': '<BV64 mem_20_191_64>', 'r2': '< |
| 32 | symbolic_var_created | `gicv3_secure_ppi_sgi_config_props` | 2 |  |
| 33 | hook_triggered | `gicv3_ppi_sgi_config_defaults` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. mem_3fffff000_215_32>', 'r1': '<BV64 0x200198>', 'r2': '<BV64  |
| 34 | symbolic_var_created | `gicv3_ppi_sgi_config_defaults` | 2 |  |
| 35 | hook_triggered | `gicv3_secure_ppi_sgi_config_props` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. mem_3fffff000_215_32>', 'r1': '<BV64 mem_20_191_64>', 'r2': '< |
| 36 | symbolic_var_created | `gicv3_secure_ppi_sgi_config_props` | 2 |  |
| 37 | hook_triggered | `gicv3_ppi_sgi_config_defaults` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. mem_3fffff000_215_32>', 'r1': '<BV64 0x200198>', 'r2': '<BV64  |
| 38 | symbolic_var_created | `gicv3_ppi_sgi_config_defaults` | 2 |  |
| 39 | hook_triggered | `gicv3_secure_ppi_sgi_config_props` | 2 | hook_type=symbolic_return; registers={'r0': '<BV64 0x0 .. mem_3fffff000_215_32>', 'r1': '<BV64 mem_20_191_64>', 'r2': '< |
| 40 | symbolic_var_created | `gicv3_secure_ppi_sgi_config_props` | 2 |  |
| 41 | entry_end | `gicv3_rdistif_init` | 0 | status=completed; active_paths=0; deadended_paths=13; total_events=41 |