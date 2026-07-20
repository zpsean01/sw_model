/**
 * ipc.c — Inter-Process Communication for ARM Cortex-M33 (TF-M)
 *
 * Requirements:
 *   - Global variables: g_endpoints[8], g_msg_queue[16], g_endpoint_count,
 *     g_msg_count, g_ipc_initialized
 *   - Types: ipc_msg_type_t, ipc_endpoint_t, ipc_msg_t
 *   - 8 visible + 2 static = 10 functions
 */

#include <stdint.h>
#include <stdbool.h>

/* ------------------------------------------------------------------ */
/*  Types                                                              */
/* ------------------------------------------------------------------ */
typedef enum {
    IPC_MSG_REQUEST  = 0,
    IPC_MSG_RESPONSE = 1,
    IPC_MSG_NOTIFY   = 2
} ipc_msg_type_t;

typedef struct {
    uint32_t endpoint_id;
    uint32_t attr;
    bool     active;
} ipc_endpoint_t;

typedef struct {
    ipc_msg_type_t type;
    uint32_t       src;
    uint32_t       dst;
    uint8_t        data[128];
    uint32_t       len;
} ipc_msg_t;

/* ------------------------------------------------------------------ */
/*  Global variables                                                   */
/* ------------------------------------------------------------------ */
static ipc_endpoint_t g_endpoints[8];
static ipc_msg_t      g_msg_queue[16];
static uint32_t       g_endpoint_count = 0;
static uint32_t       g_msg_count = 0;
static bool           g_ipc_initialized = false;

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
    g_ipc_initialized = true;
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
    g_endpoints[idx].active = true;
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

    g_endpoints[idx].active = false;
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