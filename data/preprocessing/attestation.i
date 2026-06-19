# 1 "D:\\programming\\sw_model\\fw_samples\\lib\\attestation.c"
# 1 "<built-in>" 1
# 1 "<built-in>" 3
# 415 "<built-in>" 3
# 1 "<command line>" 1
# 1 "<built-in>" 2
# 1 "D:\\programming\\sw_model\\fw_samples\\lib\\attestation.c" 2
/**
 * attestation.c — Attestation Service for ARM Cortex-M33 (TF-M)
 *
 * Requirements:
 *   - Global variables: g_attest_key, g_device_id, g_device_id_len,
 *     g_attest_initialized, g_attest_verified, g_claims[8], g_claim_count
 *   - Types: attest_claim_t, attest_token_t
 *   - 8 visible + 1 static = 9 functions
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
# 12 "D:\\programming\\sw_model\\fw_samples\\lib\\attestation.c" 2
# 1 "D:/llvm-mingw/lib/clang/22/include/stdbool.h" 1 3
/*===---- stdbool.h - Standard header for booleans -------------------------===
 *
 * Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
 * See https://llvm.org/LICENSE.txt for license information.
 * SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
 *
 *===-----------------------------------------------------------------------===
 */
# 13 "D:\\programming\\sw_model\\fw_samples\\lib\\attestation.c" 2

/* ------------------------------------------------------------------ */
/*  Types                                                              */
/* ------------------------------------------------------------------ */
typedef struct {
    char name[32];
    uint8_t value[64];
    uint32_t length;
} attest_claim_t;

typedef struct {
    uint8_t data[256];
    uint32_t len;
} attest_token_t;

/* ------------------------------------------------------------------ */
/*  Global variables                                                   */
/* ------------------------------------------------------------------ */
static uint8_t g_attest_key[32];
static uint8_t g_device_id[32];
static uint32_t g_device_id_len = 0;
static _Bool g_attest_initialized = 0;
static _Bool g_attest_verified = 0;
static attest_claim_t g_claims[8];
static uint32_t g_claim_count = 0;

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
    g_attest_verified = 0;
    g_claim_count = 0;
    (void)__builtin_memset(g_claims, 0, sizeof(g_claims));
    g_attest_initialized = 1;
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

    g_attest_verified = 1;
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
    g_attest_verified = 0;
    return 0;
}

/**
 * ATTEST_IsVerified — Check whether the attestation has been verified.
 * @return true if verified, false otherwise.
 */
_Bool ATTEST_IsVerified(void)
{
    return g_attest_verified;
}
