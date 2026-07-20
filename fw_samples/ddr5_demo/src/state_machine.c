/**
 * state_machine.c — System State Machine
 *
 * Compile: armv7-w64-mingw32-clang.exe -mcpu=cortex-m33 -mthumb -std=c99 -Wall -O1 -g3 -ffunction-sections -fdata-sections -c
 */

#include <stdint.h>
#include <stdbool.h>

/* ---------------------------------------------------------------------------
 * Type definitions
 * --------------------------------------------------------------------------- */

/** System states */
typedef enum
{
    STATE_INIT     = 0,
    STATE_IDLE     = 1,
    STATE_ACTIVE   = 2,
    STATE_ERROR    = 3,
    STATE_SHUTDOWN = 4
} system_state_t;

/** State transition record */
typedef struct
{
    system_state_t from;
    system_state_t to;
    bool           valid;
} state_transition_t;

/** State-machine handler type: returns 0 on success, non-zero on error */
typedef int32_t (*sm_handler_t)(void *arg);

/* ---------------------------------------------------------------------------
 * Global variables
 * --------------------------------------------------------------------------- */
static system_state_t g_current_state = STATE_INIT;

/* Handler table — one entry per state */
static sm_handler_t g_sm_handlers[5] = {
    (sm_handler_t)0,  /* STATE_INIT */
    (sm_handler_t)0,  /* STATE_IDLE */
    (sm_handler_t)0,  /* STATE_ACTIVE */
    (sm_handler_t)0,  /* STATE_ERROR */
    (sm_handler_t)0   /* STATE_SHUTDOWN */
};

/* Transition validity table — at least 10 valid transitions */
static state_transition_t g_transition_table[] = {
    /* from             to               valid */
    { STATE_INIT,       STATE_IDLE,      true    },
    { STATE_IDLE,       STATE_ACTIVE,    true    },
    { STATE_ACTIVE,     STATE_IDLE,      true    },
    { STATE_ACTIVE,     STATE_ERROR,     true    },
    { STATE_IDLE,       STATE_ERROR,     true    },
    { STATE_ERROR,      STATE_IDLE,      true    },
    { STATE_ERROR,      STATE_SHUTDOWN,  true    },
    { STATE_IDLE,       STATE_SHUTDOWN,  true    },
    { STATE_ACTIVE,     STATE_SHUTDOWN,  true    },
    { STATE_INIT,       STATE_ERROR,     true    },   /* 10th valid transition */
    { STATE_INIT,       STATE_ACTIVE,    false   },
    { STATE_ACTIVE,     STATE_INIT,      false   },
    { STATE_SHUTDOWN,   STATE_INIT,      false   },
    { STATE_SHUTDOWN,   STATE_IDLE,      false   },
    { STATE_ERROR,      STATE_INIT,      false   },
    { STATE_SHUTDOWN,   STATE_ACTIVE,    false   },
    { STATE_SHUTDOWN,   STATE_ERROR,     false   },
};

static const uint32_t g_transition_count =
    sizeof(g_transition_table) / sizeof(g_transition_table[0]);

/* ---------------------------------------------------------------------------
 * Forward declarations
 * --------------------------------------------------------------------------- */
static int32_t sm_default_handler(void *arg);

/* ---------------------------------------------------------------------------
 * SM_Init
 * --------------------------------------------------------------------------- */
void SM_Init(void)
{
    g_current_state = STATE_INIT;

    /* Register default handlers for all states */
    for (uint32_t i = 0u; i < 5u; i++)
    {
        g_sm_handlers[i] = sm_default_handler;
    }
}

/* ---------------------------------------------------------------------------
 * SM_Transition — transition from current state to 'to' state
 * --------------------------------------------------------------------------- */
int32_t SM_Transition(system_state_t to, void *arg)
{
    system_state_t from = g_current_state;

    /* Check validity */
    bool valid = false;
    for (uint32_t i = 0u; i < g_transition_count; i++)
    {
        if (g_transition_table[i].from == from &&
            g_transition_table[i].to   == to)
        {
            valid = g_transition_table[i].valid;
            break;
        }
    }

    if (!valid)
    {
        return -1;  /* invalid transition */
    }

    /* Call exit handler for old state (handler[from] with arg) */
    if (g_sm_handlers[from] != (sm_handler_t)0)
    {
        int32_t ret = g_sm_handlers[from](arg);
        if (ret != 0)
        {
            return ret;  /* exit handler rejected transition */
        }
    }

    g_current_state = to;

    /* Call entry handler for new state */
    if (g_sm_handlers[to] != (sm_handler_t)0)
    {
        int32_t ret = g_sm_handlers[to](arg);
        if (ret != 0)
        {
            /* Entry handler failed — stay in new state but report error */
            return ret;
        }
    }

    return 0;
}

/* ---------------------------------------------------------------------------
 * SM_GetCurrentState
 * --------------------------------------------------------------------------- */
system_state_t SM_GetCurrentState(void)
{
    return g_current_state;
}

/* ---------------------------------------------------------------------------
 * SM_StateToString — return a human-readable state name
 * --------------------------------------------------------------------------- */
const char *SM_StateToString(system_state_t state)
{
    switch (state)
    {
        case STATE_INIT:     return "STATE_INIT";
        case STATE_IDLE:     return "STATE_IDLE";
        case STATE_ACTIVE:   return "STATE_ACTIVE";
        case STATE_ERROR:    return "STATE_ERROR";
        case STATE_SHUTDOWN: return "STATE_SHUTDOWN";
        default:             return "UNKNOWN";
    }
}

/* ---------------------------------------------------------------------------
 * SM_RegisterHandler — set a handler for a given state
 * --------------------------------------------------------------------------- */
void SM_RegisterHandler(system_state_t state, sm_handler_t handler)
{
    if (state < 5u)
    {
        g_sm_handlers[state] = (handler != (sm_handler_t)0)
                                   ? handler
                                   : sm_default_handler;
    }
}

/* ---------------------------------------------------------------------------
 * SM_ProcessEvent — evaluate event and transition if applicable
 * --------------------------------------------------------------------------- */
int32_t SM_ProcessEvent(uint32_t event, void *arg)
{
    /* Simple event-to-state mapping example */
    system_state_t target = g_current_state;

    switch (event)
    {
        case 0u: target = STATE_IDLE;     break;
        case 1u: target = STATE_ACTIVE;   break;
        case 2u: target = STATE_ERROR;    break;
        case 3u: target = STATE_SHUTDOWN; break;
        default: return -1;               /* unknown event */
    }

    return SM_Transition(target, arg);
}

/* ---------------------------------------------------------------------------
 * SM_IsValidTransition
 * --------------------------------------------------------------------------- */
bool SM_IsValidTransition(system_state_t to)
{
    system_state_t from = g_current_state;

    for (uint32_t i = 0u; i < g_transition_count; i++)
    {
        if (g_transition_table[i].from == from &&
            g_transition_table[i].to   == to)
        {
            return g_transition_table[i].valid;
        }
    }

    return false;
}

/* ---------------------------------------------------------------------------
 * sm_default_handler — default state handler (no-op)
 * --------------------------------------------------------------------------- */
static int32_t sm_default_handler(void *arg)
{
    (void)arg;
    return 0;
}