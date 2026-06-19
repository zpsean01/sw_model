/**
 * attestation.c — Attestation Service for ARM Cortex-M33 (TF-M)
 *
 * Requirements:
 *   - Global variables: g_attest_key, g_device_id, g_device_id_len,
 *     g_attest_initialized, g_attest_verified, g_claims[8], g_claim_count
 *   - Types: attest_claim_t, attest_token_t
 *   - 8 visible + 1 static = 9 functions
 */

#include <stdint.h>
#include <stdbool.h>

/* ------------------------------------------------------------------ */
/*  Types                                                              */
/* ------------------------------------------------------------------ */
typedef struct {
    char     name[32];
    uint8_t  value[64];
    uint32_t length;
} attest_claim_t;

typedef struct {
    uint8_t  data[256];
    uint32_t len;
} attest_token_t;

/* ------------------------------------------------------------------ */
/*  Global variables                                                   */
/* ------------------------------------------------------------------ */
static uint8_t       g_attest_key[32];
static uint8_t       g_device_id[32];
static uint32_t      g_device_id_len = 0;
static bool          g_attest_initialized = false;
static bool          g_attest_verified = false;
static attest_claim_t g_claims[8];
static uint32_t       g_claim_count = 0;

/* ------------------------------------------------------------------ */
/*  Static helpers                                                     */
/* ------------------------------------------------------------------ */

/**
 * attest_compute_token — Build an attestation token from claims and device ID.
 * @param token  output token buffer.
 */
static void attest_compute_token(attest_token_t *token)
{
    uint32_t offset = 0;

    /* Magic header */
    token->data[offset++] = 'A';
    token->data[offset++] = 'T';
    token->data[offset++] = 'T';
    token->data[offset++] = 'N';

    /* Device ID */
    token->data[offset++] = (uint8_t)(g_device_id_len & 0xFFU);
    if (offset + g_device_id_len <= 256) {
        (void)__builtin_memcpy(&token->data[offset], g_device_id, g_device_id_len);
        offset += g_device_id_len;
    }

    /* Claims */
    uint32_t claim_count = (g_claim_count < 8U) ? g_claim_count : 8U;
    token->data[offset++] = (uint8_t)(claim_count & 0xFFU);
    for (uint32_t i = 0; i < claim_count; ++i) {
        if (offset + 1U > 256) break;
        token->data[offset++] = (uint8_t)(g_claims[i].length & 0xFFU);
        if (offset + g_claims[i].length <= 256) {
            (void)__builtin_memcpy(&token->data[offset], g_claims[i].value,
                         g_claims[i].length);
            offset += g_claims[i].length;
        }
    }

    token->len = offset;
}

/* ------------------------------------------------------------------ */
/*  Public functions                                                   */
/* ------------------------------------------------------------------ */

/**
 * ATTEST_Init — Initialise the attestation service.
 */
void ATTEST_Init(void)
{
    (void)__builtin_memset(g_attest_key, 0, sizeof(g_attest_key));
    (void)__builtin_memset(g_device_id, 0, sizeof(g_device_id));
    g_device_id_len = 0;
    g_attest_verified = false;
    g_claim_count = 0;
    (void)__builtin_memset(g_claims, 0, sizeof(g_claims));
    g_attest_initialized = true;
}

/**
 * ATTEST_GetToken — Retrieve the current attestation token.
 * @param token  output token structure.
 * @return 0 on success, -1 if not initialised.
 */
int32_t ATTEST_GetToken(attest_token_t *token)
{
    if (!g_attest_initialized) return -1;

    attest_compute_token(token);
    return 0;
}

/**
 * ATTEST_VerifyToken — Verify an attestation token.
 * @param token  token to verify.
 * @return 0 if valid, -1 if invalid or not initialised.
 */
int32_t ATTEST_VerifyToken(const attest_token_t *token)
{
    if (!g_attest_initialized) return -1;
    if (token->len < 4) return -1;

    /* Check magic header */
    if (token->data[0] != 'A' || token->data[1] != 'T' ||
        token->data[2] != 'T' || token->data[3] != 'N') {
        return -1;
    }

    g_attest_verified = true;
    return 0;
}

/**
 * ATTEST_GetPlatformClaim — Retrieve a platform claim value.
 * @param claim_name  name of the claim to retrieve.
 * @param value       output buffer for claim value.
 * @param value_len   output: length of the claim value.
 * @return 0 on success, -1 if not found.
 */
int32_t ATTEST_GetPlatformClaim(const char *claim_name,
                                uint8_t *value, uint32_t *value_len)
{
    if (!g_attest_initialized) return -1;

    for (uint32_t i = 0; i < g_claim_count; ++i) {
        if (__builtin_strncmp(g_claims[i].name, claim_name, 32) == 0) {
            *value_len = g_claims[i].length;
            (void)__builtin_memcpy(value, g_claims[i].value, g_claims[i].length);
            return 0;
        }
    }
    return -1;
}

/**
 * ATTEST_SetDeviceId — Set the device identity.
 * @param id    device ID bytes.
 * @param len   length of device ID.
 */
void ATTEST_SetDeviceId(const uint8_t *id, uint32_t len)
{
    if (len > 32) len = 32;
    g_device_id_len = len;
    (void)__builtin_memcpy(g_device_id, id, len);
}

/**
 * ATTEST_GetChallenge — Get an attestation challenge (pseudo-random).
 * @param challenge  output buffer (16 bytes).
 * @param len        number of challenge bytes to generate.
 */
void ATTEST_GetChallenge(uint8_t *challenge, uint32_t len)
{
    if (len > 32) len = 32;

    uint32_t lfsr = 0xCAFEUL;
    for (uint32_t i = 0; i < len; ++i) {
        uint8_t byte = 0;
        for (uint32_t b = 0; b < 8; ++b) {
            lfsr = ((lfsr >> 1) ^ ((-(lfsr & 1U)) & 0xB400UL));
            byte = (uint8_t)((byte << 1) | (lfsr & 1U));
        }
        challenge[i] = byte;
    }
}

/**
 * ATTEST_RotateKey — Rotate the attestation signing key.
 * @param new_key  32-byte new key.
 * @param key_len  length of the new key (max 32).
 * @return 0 on success, -1 if not initialised.
 */
int32_t ATTEST_RotateKey(const uint8_t *new_key, uint32_t key_len)
{
    if (!g_attest_initialized) return -1;
    if (key_len > 32) return -1;

    (void)__builtin_memset(g_attest_key, 0, 32);
    (void)__builtin_memcpy(g_attest_key, new_key, key_len);
    g_attest_verified = false;
    return 0;
}

/**
 * ATTEST_IsVerified — Check whether the attestation has been verified.
 * @return true if verified, false otherwise.
 */
bool ATTEST_IsVerified(void)
{
    return g_attest_verified;
}