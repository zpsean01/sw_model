# 1 "D:\\programming\\sw_model\\fw_samples\\lib\\ipc.c"
# 1 "<built-in>" 1
# 1 "<built-in>" 3
# 415 "<built-in>" 3
# 1 "<command line>" 1
# 1 "<built-in>" 2
# 1 "D:\\programming\\sw_model\\fw_samples\\lib\\ipc.c" 2
/**
 * ipc.c — Inter-Process Communication for ARM Cortex-M33 (TF-M)
 *
 * Requirements:
 *   - Global variables: g_endpoints[8], g_msg_queue[16], g_endpoint_count,
 *     g_msg_count, g_ipc_initialized
 *   - Types: ipc_msg_type_t, ipc_endpoint_t, ipc_msg_t
 *   - 8 visible + 2 static = 10 functions
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
# 12 "D:\\programming\\sw_model\\fw_samples\\lib\\ipc.c" 2
# 1 "D:/llvm-mingw/lib/clang/22/include/stdbool.h" 1 3
/*===---- stdbool.h - Standard header for booleans -------------------------===
 *
 * Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
 * See https://llvm.org/LICENSE.txt for license information.
 * SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
 *
 *===-----------------------------------------------------------------------===
 */
# 13 "D:\\programming\\sw_model\\fw_samples\\lib\\ipc.c" 2

/* ------------------------------------------------------------------ */
/*  Types                                                              */
/* ------------------------------------------------------------------ */
typedef enum {
    IPC_MSG_REQUEST = 0,
    IPC_MSG_RESPONSE = 1,
    IPC_MSG_NOTIFY = 2
} ipc_msg_type_t;

typedef struct {
    uint32_t endpoint_id;
    uint32_t attr;
    _Bool active;
} ipc_endpoint_t;

typedef struct {
    ipc_msg_type_t type;
    uint32_t src;
    uint32_t dst;
    uint8_t data[128];
    uint32_t len;
} ipc_msg_t;

/* ------------------------------------------------------------------ */
/*  Global variables                                                   */
/* ------------------------------------------------------------------ */
static ipc_endpoint_t g_endpoints[8];
static ipc_msg_t g_msg_queue[16];
static uint32_t g_endpoint_count = 0;
static uint32_t g_msg_count = 0;
static _Bool g_ipc_initialized = 0;

/* ------------------------------------------------------------------ */
/*  Static helpers                                                     */
/* ------------------------------------------------------------------ */

/**
 * ipc_find_endpoint — Find an endpoint by its ID.
 * @param endpoint_id  endpoint identifier.
 * @return index into g_endpoints, or -1 if not found.
 */
static int32_t ipc_find_endpoint(uint32_t endpoint_id)
{
    for (int32_t i = 0; i < (int32_t)g_endpoint_count; ++i) {
        if (g_endpoints[i].active && g_endpoints[i].endpoint_id == endpoint_id) {
            return i;
        }
    }
    return -1;
}

/**
 * ipc_find_free_slot — Find a free slot in the message queue.
 * @return index into g_msg_queue, or -1 if full.
 */
static int32_t ipc_find_free_slot(void)
{
    if (g_msg_count >= 16) return -1;

    for (int32_t i = 0; i < 16; ++i) {
        /* A slot is free when type == 0 and len == 0 (unused) */
        if (g_msg_queue[i].len == 0 && g_msg_queue[i].type == 0) {
            return i;
        }
    }
    return -1;
}

/* ------------------------------------------------------------------ */
/*  Public functions                                                   */
/* ------------------------------------------------------------------ */

/**
 * IPC_Init — Initialise the IPC subsystem.
 */
void IPC_Init(void)
{
    (void)__builtin_memset(g_endpoints, 0, sizeof(g_endpoints));
    (void)__builtin_memset(g_msg_queue, 0, sizeof(g_msg_queue));
    g_endpoint_count = 0;
    g_msg_count = 0;
    g_ipc_initialized = 1;
}

/**
 * IPC_EndpointCreate — Create a new IPC endpoint.
 * @param endpoint_id  desired endpoint ID.
 * @param attr         endpoint attributes.
 * @return 0 on success, -1 on failure (duplicate or full).
 */
int32_t IPC_EndpointCreate(uint32_t endpoint_id, uint32_t attr)
{
    if (!g_ipc_initialized) return -1;
    if (ipc_find_endpoint(endpoint_id) >= 0) return -1;
    if (g_endpoint_count >= 8) return -1;

    uint32_t idx = g_endpoint_count;
    g_endpoints[idx].endpoint_id = endpoint_id;
    g_endpoints[idx].attr = attr;
    g_endpoints[idx].active = 1;
    ++g_endpoint_count;
    return 0;
}

/**
 * IPC_Send — Send a message to an endpoint.
 * @param src   source endpoint ID.
 * @param dst   destination endpoint ID.
 * @param data  message payload.
 * @param len   payload length (max 128).
 * @return 0 on success, -1 on failure.
 */
int32_t IPC_Send(uint32_t src, uint32_t dst, const uint8_t *data, uint32_t len)
{
    if (!g_ipc_initialized) return -1;
    if (len > 128) return -1;
    if (ipc_find_endpoint(src) < 0) return -1;
    if (ipc_find_endpoint(dst) < 0) return -1;

    int32_t slot = ipc_find_free_slot();
    if (slot < 0) return -1;

    g_msg_queue[slot].type = IPC_MSG_REQUEST;
    g_msg_queue[slot].src = src;
    g_msg_queue[slot].dst = dst;
    g_msg_queue[slot].len = len;
    (void)__builtin_memcpy(g_msg_queue[slot].data, data, len);
    ++g_msg_count;
    return 0;
}

/**
 * IPC_Receive — Receive a message destined for the given endpoint.
 * @param endpoint_id  receiving endpoint.
 * @param msg          output message.
 * @return 0 on success, -1 if no message pending.
 */
int32_t IPC_Receive(uint32_t endpoint_id, ipc_msg_t *msg)
{
    if (!g_ipc_initialized) return -1;

    for (int32_t i = 0; i < 16; ++i) {
        if (g_msg_queue[i].len > 0 && g_msg_queue[i].dst == endpoint_id) {
            (void)__builtin_memcpy(msg, &g_msg_queue[i], sizeof(ipc_msg_t));
            (void)__builtin_memset(&g_msg_queue[i], 0, sizeof(ipc_msg_t));
            --g_msg_count;
            return 0;
        }
    }
    return -1;
}

/**
 * IPC_Reply — Send a reply to a prior request.
 * @param dst   destination endpoint (original sender).
 * @param data  reply payload.
 * @param len   payload length (max 128).
 * @return 0 on success, -1 on failure.
 */
int32_t IPC_Reply(uint32_t src, uint32_t dst, const uint8_t *data, uint32_t len)
{
    if (!g_ipc_initialized) return -1;
    if (len > 128) return -1;
    if (ipc_find_endpoint(src) < 0) return -1;
    if (ipc_find_endpoint(dst) < 0) return -1;

    int32_t slot = ipc_find_free_slot();
    if (slot < 0) return -1;

    g_msg_queue[slot].type = IPC_MSG_RESPONSE;
    g_msg_queue[slot].src = src;
    g_msg_queue[slot].dst = dst;
    g_msg_queue[slot].len = len;
    (void)__builtin_memcpy(g_msg_queue[slot].data, data, len);
    ++g_msg_count;
    return 0;
}

/**
 * IPC_Notify — Send an asynchronous notification.
 * @param dst   destination endpoint.
 * @param data  notification payload.
 * @param len   payload length (max 128).
 * @return 0 on success, -1 on failure.
 */
int32_t IPC_Notify(uint32_t src, uint32_t dst, const uint8_t *data, uint32_t len)
{
    if (!g_ipc_initialized) return -1;
    if (len > 128) return -1;
    if (ipc_find_endpoint(src) < 0) return -1;
    if (ipc_find_endpoint(dst) < 0) return -1;

    int32_t slot = ipc_find_free_slot();
    if (slot < 0) return -1;

    g_msg_queue[slot].type = IPC_MSG_NOTIFY;
    g_msg_queue[slot].src = src;
    g_msg_queue[slot].dst = dst;
    g_msg_queue[slot].len = len;
    (void)__builtin_memcpy(g_msg_queue[slot].data, data, len);
    ++g_msg_count;
    return 0;
}

/**
 * IPC_Wait — Block (spin) until a message is available for the endpoint.
 * @param endpoint_id  endpoint to wait on.
 * @param msg          output message.
 * @return 0 when a message is received.
 */
int32_t IPC_Wait(uint32_t endpoint_id, ipc_msg_t *msg)
{
    if (!g_ipc_initialized) return -1;

    /* Simple spin-loop waiting for a message */
    int32_t result;
    do {
        result = IPC_Receive(endpoint_id, msg);
    } while (result != 0);

    return 0;
}

/**
 * IPC_EndpointDestroy — Destroy an existing endpoint.
 * @param endpoint_id  endpoint to destroy.
 * @return 0 on success, -1 if not found.
 */
int32_t IPC_EndpointDestroy(uint32_t endpoint_id)
{
    if (!g_ipc_initialized) return -1;

    int32_t idx = ipc_find_endpoint(endpoint_id);
    if (idx < 0) return -1;

    g_endpoints[idx].active = 0;
    (void)__builtin_memset(&g_endpoints[idx], 0, sizeof(ipc_endpoint_t));

    /* Compact the endpoint array */
    uint32_t count = g_endpoint_count - (uint32_t)idx - 1U;
    if (count > 0U) {
        (void)__builtin_memmove(&g_endpoints[idx], &g_endpoints[idx + 1],
                      count * sizeof(ipc_endpoint_t));
    }
    --g_endpoint_count;
    return 0;
}
