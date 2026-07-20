/*
 * Stub implementations of external functions referenced by the GIC driver.
 * These are defined in other TF-A source files; here we provide minimal stubs
 * so that the GIC driver can be linked into a standalone ELF for angr.
 */
typedef unsigned int uint32_t;
typedef unsigned long long uint64_t;
typedef unsigned int uintptr_t;

uint32_t mmio_read_32(uintptr_t addr) { (void)addr; return 0; }
void mmio_write_32(uintptr_t addr, uint32_t val) { (void)addr; (void)val; }

void gicv3_rdistif_base_addrs_probe(uintptr_t *base_addrs,
    unsigned int num, uintptr_t gicr_base,
    unsigned int (*mpidr_to_core_pos)(unsigned long)) {
    (void)base_addrs; (void)num; (void)gicr_base; (void)mpidr_to_core_pos;
}

void gicv3_check_erratas_applies(uintptr_t gicd_base) { (void)gicd_base; }
void gicv3_spis_config_defaults(uintptr_t gicd_base) { (void)gicd_base; }

unsigned int gicv3_secure_spis_config_props(uintptr_t gicd_base,
    const void *props, unsigned int num) {
    (void)gicd_base; (void)props; (void)num; return 0;
}

void gicv3_ppi_sgi_config_defaults(uintptr_t gicr_base) { (void)gicr_base; }

unsigned int gicv3_secure_ppi_sgi_config_props(uintptr_t gicr_base,
    const void *props, unsigned int num) {
    (void)gicr_base; (void)props; (void)num; return 0;
}

void __assert_fail(const char *expr, const char *file, int line, const char *func) {
    (void)expr; (void)file; (void)line; (void)func;
}

/* Harness: call the GIC driver init functions */
extern void gicv3_driver_init(const void *plat_driver_data);
extern void gicv3_distif_init(void);
extern void gicv3_rdistif_init(unsigned int proc_num);

/* Minimal driver data for the harness */
static unsigned int rdistif_base_addrs[1] = { 0x2f000000 };
static unsigned int mpidr_to_core_pos(unsigned long mpidr) {
    (void)mpidr; return 0;
}

static struct {
    uintptr_t gicd_base;
    uintptr_t gicr_base;
    unsigned int rdistif_num;
    uintptr_t *rdistif_base_addrs;
    unsigned int interrupt_props_num;
    const void *interrupt_props;
    unsigned int (*mpidr_to_core_pos)(unsigned long);
} driver_data = {
    .gicd_base = 0x2f000000,
    .gicr_base = 0x2f000000,
    .rdistif_num = 1,
    .rdistif_base_addrs = rdistif_base_addrs,
    .interrupt_props_num = 0,
    .interrupt_props = 0,
    .mpidr_to_core_pos = mpidr_to_core_pos,
};

void _start(void) {
    gicv3_driver_init(&driver_data);
    gicv3_distif_init();
    gicv3_rdistif_init(0);
    while (1);
}
