# 1 "D:\\programming\\sw_model\\fw_samples\\src\\state_machine.c"
# 1 "<built-in>" 1
# 1 "<built-in>" 3
# 415 "<built-in>" 3
# 1 "<command line>" 1
# 1 "<built-in>" 2
# 1 "D:\\programming\\sw_model\\fw_samples\\src\\state_machine.c" 2
/**
 * state_machine.c — System State Machine
 *
 * Compile: armv7-w64-mingw32-clang.exe -mcpu=cortex-m33 -mthumb -std=c99 -Wall -O1 -g3 -ffunction-sections -fdata-sections -c
 */

# 1 "D:/llvm-mingw/lib/clang/22/include/stdint.h" 1 3
/*===---- stdint.h - Standard header for sized integer types --------------===*\
 *
 * Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
 * See https://llvm.org/LICENSE.txt for license information.
 * SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
 *
\*===----------------------------------------------------------------------===*/


// AIX system headers need stdint.h to be re-enterable while _STD_TYPES_T
// is defined until an inclusion of it without _STD_TYPES_T occurs, in which
// case the header guard macro is defined.








/* If we're hosted, fall back to the system's stdint.h, which might have
 * additional definitions.
 */
# 69 "D:/llvm-mingw/lib/clang/22/include/stdint.h" 3
/* C99 7.18.1.1 Exact-width integer types.
 * C99 7.18.1.2 Minimum-width integer types.
 * C99 7.18.1.3 Fastest minimum-width integer types.
 *
 * The standard requires that exact-width type be defined for 8-, 16-, 32-, and
 * 64-bit types if they are implemented. Other exact width types are optional.
 * This implementation defines an exact-width types for every integer width
 * that is represented in the standard integer types.
 *
 * The standard also requires minimum-width types be defined for 8-, 16-, 32-,
 * and 64-bit widths regardless of whether there are corresponding exact-width
 * types.
 *
 * To accommodate targets that are missing types that are exactly 8, 16, 32, or
 * 64 bits wide, this implementation takes an approach of cascading
 * redefinitions, redefining __int_leastN_t to successively smaller exact-width
 * types. It is therefore important that the types are defined in order of
 * descending widths.
 *
 * We currently assume that the minimum-width types and the fastest
 * minimum-width types are the same. This is allowed by the standard, but is
 * suboptimal.
 *
 * In violation of the standard, some targets do not implement a type that is
 * wide enough to represent all of the required widths (8-, 16-, 32-, 64-bit).
 * To accommodate these targets, a required minimum-width type is only
 * defined if there exists an exact-width type of equal or greater width.
 */



typedef long long int int64_t;

typedef long long unsigned int uint64_t;
# 122 "D:/llvm-mingw/lib/clang/22/include/stdint.h" 3
typedef int64_t int_least64_t;
typedef uint64_t uint_least64_t;
typedef int64_t int_fast64_t;
typedef uint64_t uint_fast64_t;
# 197 "D:/llvm-mingw/lib/clang/22/include/stdint.h" 3
typedef int int32_t;




typedef unsigned int uint32_t;
# 220 "D:/llvm-mingw/lib/clang/22/include/stdint.h" 3
typedef int32_t int_least32_t;
typedef uint32_t uint_least32_t;
typedef int32_t int_fast32_t;
typedef uint32_t uint_fast32_t;
# 245 "D:/llvm-mingw/lib/clang/22/include/stdint.h" 3
typedef short int16_t;

typedef unsigned short uint16_t;
# 259 "D:/llvm-mingw/lib/clang/22/include/stdint.h" 3
typedef int16_t int_least16_t;
typedef uint16_t uint_least16_t;
typedef int16_t int_fast16_t;
typedef uint16_t uint_fast16_t;





typedef signed char int8_t;

typedef unsigned char uint8_t;







typedef int8_t int_least8_t;
typedef uint8_t uint_least8_t;
typedef int8_t int_fast8_t;
typedef uint8_t uint_fast8_t;


/* prevent glibc sys/types.h from defining conflicting types */




/* C99 7.18.1.4 Integer types capable of holding object pointers.
 */




typedef int intptr_t;






typedef unsigned int uintptr_t;



/* C99 7.18.1.5 Greatest-width integer types.
 */
typedef long long int intmax_t;
typedef long long unsigned int uintmax_t;

/* C99 7.18.4 Macros for minimum-width integer constants.
 *
 * The standard requires that integer constant macros be defined for all the
 * minimum-width types defined above. As 8-, 16-, 32-, and 64-bit minimum-width
 * types are required, the corresponding integer constant macros are defined
 * here. This implementation also defines minimum-width types for every other
 * integer width that the target implements, so corresponding macros are
 * defined below, too.
 *
 * Note that C++ should not check __STDC_CONSTANT_MACROS here, contrary to the
 * claims of the C standard (see C++ 18.3.1p2, [cstdint.syn]).
 */
# 372 "D:/llvm-mingw/lib/clang/22/include/stdint.h" 3
/* C99 7.18.2.1 Limits of exact-width integer types.
 * C99 7.18.2.2 Limits of minimum-width integer types.
 * C99 7.18.2.3 Limits of fastest minimum-width integer types.
 *
 * The presence of limit macros are completely optional in C99.  This
 * implementation defines limits for all of the types (exact- and
 * minimum-width) that it defines above, using the limits of the minimum-width
 * type for any types that do not have exact-width representations.
 *
 * As in the type definitions, this section takes an approach of
 * successive-shrinking to determine which limits to use for the standard (8,
 * 16, 32, 64) bit widths when they don't have exact representations. It is
 * therefore important that the definitions be kept in order of decending
 * widths.
 *
 * Note that C++ should not check __STDC_LIMIT_MACROS here, contrary to the
 * claims of the C standard (see C++ 18.3.1p2, [cstdint.syn]).
 */
# 763 "D:/llvm-mingw/lib/clang/22/include/stdint.h" 3
/* Some utility macros */






/* C99 7.18.2.4 Limits of integer types capable of holding object pointers. */
/* C99 7.18.3 Limits of other integer types. */
# 780 "D:/llvm-mingw/lib/clang/22/include/stdint.h" 3
/* C23 7.22.2.4 Width of integer types capable of holding object pointers. */







/* ISO9899:2011 7.20 (C11 Annex K): Define RSIZE_MAX if __STDC_WANT_LIB_EXT1__
 * is enabled. */




/* C99 7.18.2.5 Limits of greatest-width integer types. */




/* C23 7.22.2.5 Width of greatest-width integer types. */







/* C99 7.18.3 Limits of other integer types. */
# 829 "D:/llvm-mingw/lib/clang/22/include/stdint.h" 3
/* 7.18.4.2 Macros for greatest-width integer constants. */



/* C23 7.22.3.x Width of other integer types. */
# 8 "D:\\programming\\sw_model\\fw_samples\\src\\state_machine.c" 2
# 1 "D:/llvm-mingw/lib/clang/22/include/stdbool.h" 1 3
/*===---- stdbool.h - Standard header for booleans -------------------------===
 *
 * Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
 * See https://llvm.org/LICENSE.txt for license information.
 * SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
 *
 *===-----------------------------------------------------------------------===
 */
# 9 "D:\\programming\\sw_model\\fw_samples\\src\\state_machine.c" 2

/* ---------------------------------------------------------------------------
 * Type definitions
 * --------------------------------------------------------------------------- */

/** System states */
typedef enum
{
    STATE_INIT = 0,
    STATE_IDLE = 1,
    STATE_ACTIVE = 2,
    STATE_ERROR = 3,
    STATE_SHUTDOWN = 4
} system_state_t;

/** State transition record */
typedef struct
{
    system_state_t from;
    system_state_t to;
    _Bool valid;
} state_transition_t;

/** State-machine handler type: returns 0 on success, non-zero on error */
typedef int32_t (*sm_handler_t)(void *arg);

/* ---------------------------------------------------------------------------
 * Global variables
 * --------------------------------------------------------------------------- */
static system_state_t g_current_state = STATE_INIT;

/* Handler table — one entry per state */
static sm_handler_t g_sm_handlers[5] = {
    (sm_handler_t)0, /* STATE_INIT */
    (sm_handler_t)0, /* STATE_IDLE */
    (sm_handler_t)0, /* STATE_ACTIVE */
    (sm_handler_t)0, /* STATE_ERROR */
    (sm_handler_t)0 /* STATE_SHUTDOWN */
};

/* Transition validity table — at least 10 valid transitions */
static state_transition_t g_transition_table[] = {
    /* from             to               valid */
    { STATE_INIT, STATE_IDLE, 1 },
    { STATE_IDLE, STATE_ACTIVE, 1 },
    { STATE_ACTIVE, STATE_IDLE, 1 },
    { STATE_ACTIVE, STATE_ERROR, 1 },
    { STATE_IDLE, STATE_ERROR, 1 },
    { STATE_ERROR, STATE_IDLE, 1 },
    { STATE_ERROR, STATE_SHUTDOWN, 1 },
    { STATE_IDLE, STATE_SHUTDOWN, 1 },
    { STATE_ACTIVE, STATE_SHUTDOWN, 1 },
    { STATE_INIT, STATE_ERROR, 1 }, /* 10th valid transition */
    { STATE_INIT, STATE_ACTIVE, 0 },
    { STATE_ACTIVE, STATE_INIT, 0 },
    { STATE_SHUTDOWN, STATE_INIT, 0 },
    { STATE_SHUTDOWN, STATE_IDLE, 0 },
    { STATE_ERROR, STATE_INIT, 0 },
    { STATE_SHUTDOWN, STATE_ACTIVE, 0 },
    { STATE_SHUTDOWN, STATE_ERROR, 0 },
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
    _Bool valid = 0;
    for (uint32_t i = 0u; i < g_transition_count; i++)
    {
        if (g_transition_table[i].from == from &&
            g_transition_table[i].to == to)
        {
            valid = g_transition_table[i].valid;
            break;
        }
    }

    if (!valid)
    {
        return -1; /* invalid transition */
    }

    /* Call exit handler for old state (handler[from] with arg) */
    if (g_sm_handlers[from] != (sm_handler_t)0)
    {
        int32_t ret = g_sm_handlers[from](arg);
        if (ret != 0)
        {
            return ret; /* exit handler rejected transition */
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
        case STATE_INIT: return "STATE_INIT";
        case STATE_IDLE: return "STATE_IDLE";
        case STATE_ACTIVE: return "STATE_ACTIVE";
        case STATE_ERROR: return "STATE_ERROR";
        case STATE_SHUTDOWN: return "STATE_SHUTDOWN";
        default: return "UNKNOWN";
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
        case 0u: target = STATE_IDLE; break;
        case 1u: target = STATE_ACTIVE; break;
        case 2u: target = STATE_ERROR; break;
        case 3u: target = STATE_SHUTDOWN; break;
        default: return -1; /* unknown event */
    }

    return SM_Transition(target, arg);
}

/* ---------------------------------------------------------------------------
 * SM_IsValidTransition
 * --------------------------------------------------------------------------- */
_Bool SM_IsValidTransition(system_state_t to)
{
    system_state_t from = g_current_state;

    for (uint32_t i = 0u; i < g_transition_count; i++)
    {
        if (g_transition_table[i].from == from &&
            g_transition_table[i].to == to)
        {
            return g_transition_table[i].valid;
        }
    }

    return 0;
}

/* ---------------------------------------------------------------------------
 * sm_default_handler — default state handler (no-op)
 * --------------------------------------------------------------------------- */
static int32_t sm_default_handler(void *arg)
{
    (void)arg;
    return 0;
}
