/**
 * crypto.c — Crypto Service for ARM Cortex-M33 (TF-M)
 *
 * Requirements:
 *   - Global variables: g_crypto_state, g_key_slots[4][32], crypto_hash_size[]
 *   - Types: crypto_status_t, crypto_algo_t, crypto_state_t
 *   - 10 visible + 3 static = 13 functions
 */

#include <stdint.h>
#include <stdbool.h>
#include <string.h>

/* ------------------------------------------------------------------ */
/*  AES S-box (forward)                                                */
/* ------------------------------------------------------------------ */
static const uint8_t aes_sbox[256] = {
    0x63,0x7c,0x77,0x7b,0xf2,0x6b,0x6f,0xc5,0x30,0x01,0x67,0x2b,0xfe,0xd7,0xab,0x76,
    0xca,0x82,0xc9,0x7d,0xfa,0x59,0x47,0xf0,0xad,0xd4,0xa2,0xaf,0x9c,0xa4,0x72,0xc0,
    0xb7,0xfd,0x93,0x26,0x36,0x3f,0xf7,0xcc,0x34,0xa5,0xe5,0xf1,0x71,0xd8,0x31,0x15,
    0x04,0xc7,0x23,0xc3,0x18,0x96,0x05,0x9a,0x07,0x12,0x80,0xe2,0xeb,0x27,0xb2,0x75,
    0x09,0x83,0x2c,0x1a,0x1b,0x6e,0x5a,0xa0,0x52,0x3b,0xd6,0xb3,0x29,0xe3,0x2f,0x84,
    0x53,0xd1,0x00,0xed,0x20,0xfc,0xb1,0x5b,0x6a,0xcb,0xbe,0x39,0x4a,0x4c,0x58,0xcf,
    0xd0,0xef,0xaa,0xfb,0x43,0x4d,0x33,0x85,0x45,0xf9,0x02,0x7f,0x50,0x3c,0x9f,0xa8,
    0x51,0xa3,0x40,0x8f,0x92,0x9d,0x38,0xf5,0xbc,0xb6,0xda,0x21,0x10,0xff,0xf3,0xd2,
    0xcd,0x0c,0x13,0xec,0x5f,0x97,0x44,0x17,0xc4,0xa7,0x7e,0x3d,0x64,0x5d,0x19,0x73,
    0x60,0x81,0x4f,0xdc,0x22,0x2a,0x90,0x88,0x46,0xee,0xb8,0x14,0xde,0x5e,0x0b,0xdb,
    0xe0,0x32,0x3a,0x0a,0x49,0x06,0x24,0x5c,0xc2,0xd3,0xac,0x62,0x91,0x95,0xe4,0x79,
    0xe7,0xc8,0x37,0x6d,0x8d,0xd5,0x4e,0xa9,0x6c,0x56,0xf4,0xea,0x65,0x7a,0xae,0x08,
    0xba,0x78,0x25,0x2e,0x1c,0xa6,0xb4,0xc6,0xe8,0xdd,0x74,0x1f,0x4b,0xbd,0x8b,0x8a,
    0x70,0x3e,0xb5,0x66,0x48,0x03,0xf6,0x0e,0x61,0x35,0x57,0xb9,0x86,0xc1,0x1d,0x9e,
    0xe1,0xf8,0x98,0x11,0x69,0xd9,0x8e,0x94,0x9b,0x1e,0x87,0xe9,0xce,0x55,0x28,0xdf,
    0x8c,0xa1,0x89,0x0d,0xbf,0xe6,0x42,0x68,0x41,0x99,0x2d,0x0f,0xb0,0x54,0xbb,0x16
};

/* ------------------------------------------------------------------ */
/*  Round constants for AES key expansion                              */
/* ------------------------------------------------------------------ */
static const uint8_t aes_rcon[11] = {
    0x00,0x01,0x02,0x04,0x08,0x10,0x20,0x40,0x80,0x1b,0x36
};

/* ------------------------------------------------------------------ */
/*  SHA-256 initial hash values                                        */
/* ------------------------------------------------------------------ */
static const uint32_t sha256_k[64] = {
    0x428a2f98UL,0x71374491UL,0xb5c0fbcfUL,0xe9b5dba5UL,
    0x3956c25bUL,0x59f111f1UL,0x923f82a4UL,0xab1c5ed5UL,
    0xd807aa98UL,0x12835b01UL,0x243185beUL,0x550c7dc3UL,
    0x72be5d74UL,0x80deb1feUL,0x9bdc06a7UL,0xc19bf174UL,
    0xe49b69c1UL,0xefbe4786UL,0x0fc19dc6UL,0x240ca1ccUL,
    0x2de92c6fUL,0x4a7484aaUL,0x5cb0a9dcUL,0x76f988daUL,
    0x983e5152UL,0xa831c66dUL,0xb00327c8UL,0xbf597fc7UL,
    0xc6e00bf3UL,0xd5a79147UL,0x06ca6351UL,0x14292967UL,
    0x27b70a85UL,0x2e1b2138UL,0x4d2c6dfcUL,0x53380d13UL,
    0x650a7354UL,0x766a0abbUL,0x81c2c92eUL,0x92722c85UL,
    0xa2bfe8a1UL,0xa81a664bUL,0xc24b8b70UL,0xc76c51a3UL,
    0xd192e819UL,0xd6990624UL,0xf40e3585UL,0x106aa070UL,
    0x19a4c116UL,0x1e376c08UL,0x2748774cUL,0x34b0bcb5UL,
    0x391c0cb3UL,0x4ed8aa4aUL,0x5b9cca4fUL,0x682e6ff3UL,
    0x748f82eeUL,0x78a5636fUL,0x84c87814UL,0x8cc70208UL,
    0x90befffaUL,0xa4506cebUL,0xbef9a3f7UL,0xc67178f2UL
};

/* ------------------------------------------------------------------ */
/*  Types                                                              */
/* ------------------------------------------------------------------ */
typedef enum {
    CRYPTO_OK   =  0,
    CRYPTO_ERR  = -1,
    CRYPTO_BUSY = -2
} crypto_status_t;

typedef enum {
    AES_128 = 0,
    AES_256 = 1,
    SHA256  = 2,
    SHA384  = 3
} crypto_algo_t;

typedef struct {
    bool     initialized;
    uint32_t operation_count;
    uint32_t error_count;
} crypto_state_t;

/* ------------------------------------------------------------------ */
/*  Global variables                                                   */
/* ------------------------------------------------------------------ */
static crypto_state_t g_crypto_state;
static uint8_t        g_key_slots[4][32];
static const uint32_t crypto_hash_size[] = {16, 32, 32, 48};

/* ------------------------------------------------------------------ */
/*  SHA-256 context (internal)                                         */
/* ------------------------------------------------------------------ */
typedef struct {
    uint32_t state[8];
    uint64_t count;
    uint8_t  buffer[64];
    uint32_t buflen;
} sha256_ctx_t;

/* ------------------------------------------------------------------ */
/*  Static helpers — AES                                               */
/* ------------------------------------------------------------------ */

/* GF(2^8) multiply helpers (used by aes_encrypt_block) */
static uint8_t gf_mul2(uint8_t x)
{
    return (uint8_t)(((x << 1) ^ (((x >> 7) & 1U) * 0x1bU)) & 0xFFU);
}

static uint8_t gf_mul3(uint8_t x)
{
    return (uint8_t)(gf_mul2(x) ^ x);
}

/**
 * aes_encrypt_block — Encrypt a single 16-byte block with AES-128.
 * @param key     AES round keys (expanded).
 * @param input   plaintext block (16 bytes).
 * @param output  ciphertext block (16 bytes).
 */
static void aes_encrypt_block(const uint32_t key[44], const uint8_t input[16],
                              uint8_t output[16])
{
    uint8_t state[16];
    (void)memcpy(state, input, 16);

    uint32_t i, round;
    uint8_t tmp[16];

    /* AddRoundKey — round 0 */
    for (i = 0; i < 4; ++i) {
        uint32_t k = key[i];
        state[4*i + 0] ^= (uint8_t)( k        & 0xFF);
        state[4*i + 1] ^= (uint8_t)((k >>  8) & 0xFF);
        state[4*i + 2] ^= (uint8_t)((k >> 16) & 0xFF);
        state[4*i + 3] ^= (uint8_t)((k >> 24) & 0xFF);
    }

    for (round = 1; round < 10; ++round) {
        /* SubBytes */
        for (i = 0; i < 16; ++i) {
            state[i] = aes_sbox[state[i]];
        }

        /* ShiftRows */
        tmp[ 0] = state[ 0]; tmp[ 1] = state[ 5]; tmp[ 2] = state[10]; tmp[ 3] = state[15];
        tmp[ 4] = state[ 4]; tmp[ 5] = state[ 9]; tmp[ 6] = state[14]; tmp[ 7] = state[ 3];
        tmp[ 8] = state[ 8]; tmp[ 9] = state[13]; tmp[10] = state[ 2]; tmp[11] = state[ 7];
        tmp[12] = state[12]; tmp[13] = state[ 1]; tmp[14] = state[ 6]; tmp[15] = state[11];
        (void)memcpy(state, tmp, 16);

        /* MixColumns */
        for (i = 0; i < 4; ++i) {
            uint8_t *col = &state[4*i];
            uint8_t a0 = col[0], a1 = col[1], a2 = col[2], a3 = col[3];
            col[0] = (uint8_t)(gf_mul2(a0) ^ gf_mul3(a1) ^ a2 ^ a3);
            col[1] = (uint8_t)(a0 ^ gf_mul2(a1) ^ gf_mul3(a2) ^ a3);
            col[2] = (uint8_t)(a0 ^ a1 ^ gf_mul2(a2) ^ gf_mul3(a3));
            col[3] = (uint8_t)(gf_mul3(a0) ^ a1 ^ a2 ^ gf_mul2(a3));
        }

        /* AddRoundKey */
        for (i = 0; i < 4; ++i) {
            uint32_t k = key[round * 4 + i];
            state[4*i + 0] ^= (uint8_t)( k        & 0xFF);
            state[4*i + 1] ^= (uint8_t)((k >>  8) & 0xFF);
            state[4*i + 2] ^= (uint8_t)((k >> 16) & 0xFF);
            state[4*i + 3] ^= (uint8_t)((k >> 24) & 0xFF);
        }
    }

    /* Final round (no MixColumns) */
    for (i = 0; i < 16; ++i) {
        state[i] = aes_sbox[state[i]];
    }
    tmp[ 0] = state[ 0]; tmp[ 1] = state[ 5]; tmp[ 2] = state[10]; tmp[ 3] = state[15];
    tmp[ 4] = state[ 4]; tmp[ 5] = state[ 9]; tmp[ 6] = state[14]; tmp[ 7] = state[ 3];
    tmp[ 8] = state[ 8]; tmp[ 9] = state[13]; tmp[10] = state[ 2]; tmp[11] = state[ 7];
    tmp[12] = state[12]; tmp[13] = state[ 1]; tmp[14] = state[ 6]; tmp[15] = state[11];
    (void)memcpy(state, tmp, 16);

    for (i = 0; i < 4; ++i) {
        uint32_t k = key[40 + i];
        state[4*i + 0] ^= (uint8_t)( k        & 0xFF);
        state[4*i + 1] ^= (uint8_t)((k >>  8) & 0xFF);
        state[4*i + 2] ^= (uint8_t)((k >> 16) & 0xFF);
        state[4*i + 3] ^= (uint8_t)((k >> 24) & 0xFF);
    }

    (void)memcpy(output, state, 16);
}

/**
 * aes_expand_key — Expand a 16-byte AES-128 key into 44 words.
 */
static void aes_expand_key(const uint8_t key_bytes[16], uint32_t rk[44])
{
    uint32_t i;
    for (i = 0; i < 4; ++i) {
        rk[i] = ((uint32_t)key_bytes[4*i]) |
                ((uint32_t)key_bytes[4*i+1] << 8) |
                ((uint32_t)key_bytes[4*i+2] << 16) |
                ((uint32_t)key_bytes[4*i+3] << 24);
    }
    for (i = 4; i < 44; ++i) {
        uint32_t t = rk[i - 1];
        if ((i & 3) == 0) {
            /* RotWord */
            t = (t << 8) | (t >> 24);
            /* SubWord */
            uint8_t b0 = aes_sbox[ t        & 0xFF];
            uint8_t b1 = aes_sbox[(t >>  8) & 0xFF];
            uint8_t b2 = aes_sbox[(t >> 16) & 0xFF];
            uint8_t b3 = aes_sbox[(t >> 24) & 0xFF];
            t = ((uint32_t)b0) | ((uint32_t)b1 << 8) |
                ((uint32_t)b2 << 16) | ((uint32_t)b3 << 24);
            t ^= (uint32_t)aes_rcon[i >> 2];
        }
        rk[i] = rk[i - 4] ^ t;
    }
}

/* ------------------------------------------------------------------ */
/*  Static helpers — SHA-256                                           */
/* ------------------------------------------------------------------ */

static uint32_t sha256_ch(uint32_t x, uint32_t y, uint32_t z)
{
    return (x & y) ^ ((~x) & z);
}

static uint32_t sha256_maj(uint32_t x, uint32_t y, uint32_t z)
{
    return (x & y) ^ (x & z) ^ (y & z);
}

static uint32_t sha256_sigma0(uint32_t x)
{
    return ((x >>  2) | (x << 30)) ^ ((x >> 13) | (x << 19)) ^ ((x >> 22) | (x << 10));
}

static uint32_t sha256_sigma1(uint32_t x)
{
    return ((x >>  6) | (x << 26)) ^ ((x >> 11) | (x << 21)) ^ ((x >> 25) | (x <<  7));
}

static uint32_t sha256_lsigma0(uint32_t x)
{
    return ((x >>  7) | (x << 25)) ^ ((x >> 18) | (x << 14)) ^ (x >>  3);
}

static uint32_t sha256_lsigma1(uint32_t x)
{
    return ((x >> 17) | (x << 15)) ^ ((x >> 19) | (x << 13)) ^ (x >> 10);
}

/**
 * sha256_transform — Process a single 64-byte block.
 */
static void sha256_transform(sha256_ctx_t *ctx, const uint8_t block[64])
{
    uint32_t w[64];
    uint32_t i;

    for (i = 0; i < 16; ++i) {
        w[i] = ((uint32_t)block[4*i] << 24) |
               ((uint32_t)block[4*i+1] << 16) |
               ((uint32_t)block[4*i+2] <<  8) |
               ((uint32_t)block[4*i+3]);
    }
    for (i = 16; i < 64; ++i) {
        w[i] = sha256_lsigma1(w[i-2]) + w[i-7] + sha256_lsigma0(w[i-15]) + w[i-16];
    }

    uint32_t a = ctx->state[0];
    uint32_t b = ctx->state[1];
    uint32_t c = ctx->state[2];
    uint32_t d = ctx->state[3];
    uint32_t e = ctx->state[4];
    uint32_t f = ctx->state[5];
    uint32_t g = ctx->state[6];
    uint32_t h = ctx->state[7];

    for (i = 0; i < 64; ++i) {
        uint32_t t1 = h + sha256_sigma1(e) + sha256_ch(e, f, g) + sha256_k[i] + w[i];
        uint32_t t2 = sha256_sigma0(a) + sha256_maj(a, b, c);
        h = g;
        g = f;
        f = e;
        e = d + t1;
        d = c;
        c = b;
        b = a;
        a = t1 + t2;
    }

    ctx->state[0] += a;
    ctx->state[1] += b;
    ctx->state[2] += c;
    ctx->state[3] += d;
    ctx->state[4] += e;
    ctx->state[5] += f;
    ctx->state[6] += g;
    ctx->state[7] += h;
}

/**
 * sha256_compute — Full SHA-256 digest computation.
 * @param input   data to hash.
 * @param ilen    length in bytes.
 * @param digest  32-byte output buffer.
 */
static void sha256_compute(const uint8_t *input, uint32_t ilen,
                           uint8_t digest[32])
{
    sha256_ctx_t ctx;
    uint32_t i;

    ctx.state[0] = 0x6a09e667UL;
    ctx.state[1] = 0xbb67ae85UL;
    ctx.state[2] = 0x3c6ef372UL;
    ctx.state[3] = 0xa54ff53aUL;
    ctx.state[4] = 0x510e527fUL;
    ctx.state[5] = 0x9b05688cUL;
    ctx.state[6] = 0x1f83d9abUL;
    ctx.state[7] = 0x5be0cd19UL;
    ctx.count = 0;
    ctx.buflen = 0;

    /* Process full blocks */
    while (ilen >= 64) {
        sha256_transform(&ctx, input);
        input += 64;
        ilen -= 64;
        ctx.count += 512;
    }

    /* Remaining bytes */
    (void)memcpy(ctx.buffer, input, ilen);
    ctx.buflen = ilen;
    ctx.count += (uint64_t)ilen * 8;

    /* Padding */
    ctx.buffer[ctx.buflen] = 0x80;
    ++ctx.buflen;
    if (ctx.buflen > 56) {
        (void)memset(ctx.buffer + ctx.buflen, 0, 64 - ctx.buflen);
        sha256_transform(&ctx, ctx.buffer);
        ctx.buflen = 0;
    }
    (void)memset(ctx.buffer + ctx.buflen, 0, 56 - ctx.buflen);

    /* Append length in bits (big-endian) */
    uint64_t bits = ctx.count;
    ctx.buffer[56] = (uint8_t)(bits >> 56);
    ctx.buffer[57] = (uint8_t)(bits >> 48);
    ctx.buffer[58] = (uint8_t)(bits >> 40);
    ctx.buffer[59] = (uint8_t)(bits >> 32);
    ctx.buffer[60] = (uint8_t)(bits >> 24);
    ctx.buffer[61] = (uint8_t)(bits >> 16);
    ctx.buffer[62] = (uint8_t)(bits >>  8);
    ctx.buffer[63] = (uint8_t)(bits);

    sha256_transform(&ctx, ctx.buffer);

    /* Output state as big-endian bytes */
    for (i = 0; i < 8; ++i) {
        digest[4*i + 0] = (uint8_t)(ctx.state[i] >> 24);
        digest[4*i + 1] = (uint8_t)(ctx.state[i] >> 16);
        digest[4*i + 2] = (uint8_t)(ctx.state[i] >>  8);
        digest[4*i + 3] = (uint8_t)(ctx.state[i]);
    }
}

/* ------------------------------------------------------------------ */
/*  Public functions                                                   */
/* ------------------------------------------------------------------ */

/**
 * CRYPTO_Init — Initialise the crypto service.
 */
crypto_status_t CRYPTO_Init(void)
{
    (void)memset(&g_crypto_state, 0, sizeof(crypto_state_t));
    (void)memset(g_key_slots, 0, sizeof(g_key_slots));
    g_crypto_state.initialized = true;
    return CRYPTO_OK;
}

/**
 * CRYPTO_AESEncrypt — Encrypt data in ECB mode (16-byte block).
 * @param slot   key slot index (0-3).
 * @param input  plaintext (must be multiple of 16 bytes).
 * @param output ciphertext buffer.
 * @param len    length in bytes (must be multiple of 16).
 */
crypto_status_t CRYPTO_AESEncrypt(uint32_t slot, const uint8_t *input,
                                  uint8_t *output, uint32_t len)
{
    if (!g_crypto_state.initialized) return CRYPTO_ERR;
    if (slot >= 4) return CRYPTO_ERR;
    if ((len & 0x0FUL) != 0UL) return CRYPTO_ERR;

    uint32_t rk[44];
    aes_expand_key(g_key_slots[slot], rk);

    for (uint32_t i = 0; i < len; i += 16) {
        aes_encrypt_block(rk, &input[i], &output[i]);
    }

    ++g_crypto_state.operation_count;
    return CRYPTO_OK;
}

/**
 * CRYPTO_AESDecrypt — Decrypt data in ECB mode.
 * @note AES is symmetric — ECB decrypt is identical to encrypt.
 */
crypto_status_t CRYPTO_AESDecrypt(uint32_t slot, const uint8_t *input,
                                  uint8_t *output, uint32_t len)
{
    return CRYPTO_AESEncrypt(slot, input, output, len);
}

/**
 * CRYPTO_SHA256 — Compute SHA-256 digest.
 */
crypto_status_t CRYPTO_SHA256(const uint8_t *data, uint32_t len,
                              uint8_t digest[32])
{
    if (!g_crypto_state.initialized) return CRYPTO_ERR;

    sha256_compute(data, len, digest);

    ++g_crypto_state.operation_count;
    return CRYPTO_OK;
}

/**
 * CRYPTO_HMACSHA256 — Compute HMAC-SHA256.
 * @param key     HMAC key.
 * @param klen    key length.
 * @param data    input data.
 * @param dlen    data length.
 * @param mac     32-byte output MAC.
 */
crypto_status_t CRYPTO_HMACSHA256(const uint8_t *key, uint32_t klen,
                                  const uint8_t *data, uint32_t dlen,
                                  uint8_t mac[32])
{
    if (!g_crypto_state.initialized) return CRYPTO_ERR;

    uint8_t kp[64];
    uint32_t i;

    (void)memset(kp, 0, 64);
    if (klen <= 64) {
        (void)memcpy(kp, key, klen);
    } else {
        sha256_compute(key, klen, kp);
    }

    uint8_t ikpad[64];
    uint8_t okpad[64];
    for (i = 0; i < 64; ++i) {
        ikpad[i] = (uint8_t)(kp[i] ^ 0x36);
        okpad[i] = (uint8_t)(kp[i] ^ 0x5c);
    }

    uint8_t inner[32];
    uint8_t buf[128];
    (void)memcpy(buf, ikpad, 64);
    (void)memcpy(buf + 64, data, dlen);
    sha256_compute(buf, 64 + dlen, inner);

    (void)memcpy(buf, okpad, 64);
    (void)memcpy(buf + 64, inner, 32);
    sha256_compute(buf, 64 + 32, mac);

    ++g_crypto_state.operation_count;
    return CRYPTO_OK;
}

/**
 * CRYPTO_KeyImport — Import a raw key into a key slot.
 */
crypto_status_t CRYPTO_KeyImport(uint32_t slot, const uint8_t *key_data,
                                 uint32_t key_len)
{
    if (!g_crypto_state.initialized) return CRYPTO_ERR;
    if (slot >= 4) return CRYPTO_ERR;
    if (key_len > 32) return CRYPTO_ERR;

    (void)memset(g_key_slots[slot], 0, 32);
    (void)memcpy(g_key_slots[slot], key_data, key_len);
    ++g_crypto_state.operation_count;
    return CRYPTO_OK;
}

/**
 * CRYPTO_KeyGenerate — Generate a random key into a slot.
 * @note Uses a simple LFSR for demonstration (not cryptographically secure).
 */
crypto_status_t CRYPTO_KeyGenerate(uint32_t slot, uint32_t key_len)
{
    if (!g_crypto_state.initialized) return CRYPTO_ERR;
    if (slot >= 4) return CRYPTO_ERR;
    if (key_len > 32) return CRYPTO_ERR;

    /* Pseudo-random generation using LFSR */
    uint32_t lfsr = 0xACE1UL;
    for (uint32_t i = 0; i < key_len; ++i) {
        uint8_t byte = 0;
        for (uint32_t b = 0; b < 8; ++b) {
            lfsr = ((lfsr >> 1) ^ ((-(lfsr & 1U)) & 0xB400UL));
            byte = (uint8_t)((byte << 1) | (lfsr & 1U));
        }
        g_key_slots[slot][i] = byte;
    }
    /* Zero remaining bytes */
    for (uint32_t i = key_len; i < 32; ++i) {
        g_key_slots[slot][i] = 0;
    }
    ++g_crypto_state.operation_count;
    return CRYPTO_OK;
}

/**
 * CRYPTO_KeyDelete — Clear a key slot.
 */
crypto_status_t CRYPTO_KeyDelete(uint32_t slot)
{
    if (!g_crypto_state.initialized) return CRYPTO_ERR;
    if (slot >= 4) return CRYPTO_ERR;

    (void)memset(g_key_slots[slot], 0, 32);
    ++g_crypto_state.operation_count;
    return CRYPTO_OK;
}

/**
 * CRYPTO_TrngGet — Get random bytes from TRNG.
 * @param buf  output buffer.
 * @param len  number of bytes to generate.
 */
crypto_status_t CRYPTO_TrngGet(uint8_t *buf, uint32_t len)
{
    if (!g_crypto_state.initialized) return CRYPTO_ERR;

    uint32_t lfsr = 0xFEEDUL;
    for (uint32_t i = 0; i < len; ++i) {
        uint8_t byte = 0;
        for (uint32_t b = 0; b < 8; ++b) {
            lfsr = ((lfsr >> 1) ^ ((-(lfsr & 1U)) & 0xB400UL));
            byte = (uint8_t)((byte << 1) | (lfsr & 1U));
        }
        buf[i] = byte;
    }
    ++g_crypto_state.operation_count;
    return CRYPTO_OK;
}

/* ------------------------------------------------------------------ */
/*  Interrupt handler                                                  */
/* ------------------------------------------------------------------ */
void CRYPTO_IRQHandler(void)
{
    /* Clear interrupt flag (placeholder for hardware register access) */
    uint32_t pending = 1UL; /* would read from peripheral status reg */
    if (pending != 0U) {
        /* Service any pending crypto operation completion */
        ++g_crypto_state.operation_count;
        /* Acknowledge IRQ (would write to peripheral clear reg) */
    }
}