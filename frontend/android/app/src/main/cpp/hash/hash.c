#include "hash.h"
#include <string.h>
#include <stdlib.h>
#include <time.h>

// Фиксированный ключ для хеширования (32 байта)
static const uint8_t FIXED_KEY[32] = {
    0x4b, 0x7a, 0xde, 0xf8, 0x3b, 0x2a, 0x99, 0x1c,
    0x5f, 0x8d, 0x6e, 0x4c, 0x7b, 0x2d, 0x9a, 0x3f,
    0x8e, 0x1d, 0x5c, 0x4f, 0x2b, 0x9d, 0x3a, 0x7c,
    0x6f, 0x8b, 0x1e, 0x5d, 0x4a, 0x2c, 0x9b, 0x3e
};

// SHA-256 implementation
#define SHA256_BLOCK_SIZE 64
#define SHA256_DIGEST_SIZE 32

typedef struct {
    uint32_t state[8];
    uint64_t count;
    uint8_t buffer[SHA256_BLOCK_SIZE];
} SHA256_CTX;

// SHA-256 initialization constants
static const uint32_t K[64] = {
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
    0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
    0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
    0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
    0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
    0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
    0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
    0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
    0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
};

// SHA-256 helper functions
#define ROTRIGHT(a,b) (((a) >> (b)) | ((a) << (32-(b))))
#define CH(x,y,z) (((x) & (y)) ^ (~(x) & (z)))
#define MAJ(x,y,z) (((x) & (y)) ^ ((x) & (z)) ^ ((y) & (z)))
#define EP0(x) (ROTRIGHT(x,2) ^ ROTRIGHT(x,13) ^ ROTRIGHT(x,22))
#define EP1(x) (ROTRIGHT(x,6) ^ ROTRIGHT(x,11) ^ ROTRIGHT(x,25))
#define SIG0(x) (ROTRIGHT(x,7) ^ ROTRIGHT(x,18) ^ ((x) >> 3))
#define SIG1(x) (ROTRIGHT(x,17) ^ ROTRIGHT(x,19) ^ ((x) >> 10))

static void sha256_transform(SHA256_CTX *ctx, const uint8_t *data) {
    uint32_t a, b, c, d, e, f, g, h, i, j, t1, t2, m[64];

    for (i = 0, j = 0; i < 16; ++i, j += 4)
        m[i] = (data[j] << 24) | (data[j + 1] << 16) | (data[j + 2] << 8) | (data[j + 3]);
    for (; i < 64; ++i)
        m[i] = SIG1(m[i - 2]) + m[i - 7] + SIG0(m[i - 15]) + m[i - 16];

    a = ctx->state[0];
    b = ctx->state[1];
    c = ctx->state[2];
    d = ctx->state[3];
    e = ctx->state[4];
    f = ctx->state[5];
    g = ctx->state[6];
    h = ctx->state[7];

    for (i = 0; i < 64; ++i) {
        t1 = h + EP1(e) + CH(e,f,g) + K[i] + m[i];
        t2 = EP0(a) + MAJ(a,b,c);
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

static void sha256_init(SHA256_CTX *ctx) {
    ctx->state[0] = 0x6a09e667;
    ctx->state[1] = 0xbb67ae85;
    ctx->state[2] = 0x3c6ef372;
    ctx->state[3] = 0xa54ff53a;
    ctx->state[4] = 0x510e527f;
    ctx->state[5] = 0x9b05688c;
    ctx->state[6] = 0x1f83d9ab;
    ctx->state[7] = 0x5be0cd19;
    ctx->count = 0;
}

static void sha256_update(SHA256_CTX *ctx, const uint8_t *data, size_t len) {
    size_t i;
    for (i = 0; i < len; ++i) {
        ctx->buffer[ctx->count % 64] = data[i];
        ctx->count++;
        if ((ctx->count % 64) == 0)
            sha256_transform(ctx, ctx->buffer);
    }
}

static void sha256_final(SHA256_CTX *ctx, uint8_t *hash) {
    uint64_t i = ctx->count;
    uint8_t finalcount[8];

    for (int j = 0; j < 8; ++j)
        finalcount[j] = (uint8_t)((i << 3) >> (j * 8));

    sha256_update(ctx, (uint8_t*)"\x80", 1);
    while ((ctx->count % 64) != 56)
        sha256_update(ctx, (uint8_t*)"\0", 1);
    sha256_update(ctx, finalcount, 8);

    for (i = 0; i < 4; ++i) {
        hash[i]      = (ctx->state[0] >> (24 - i * 8)) & 0x000000ff;
        hash[i + 4]  = (ctx->state[1] >> (24 - i * 8)) & 0x000000ff;
        hash[i + 8]  = (ctx->state[2] >> (24 - i * 8)) & 0x000000ff;
        hash[i + 12] = (ctx->state[3] >> (24 - i * 8)) & 0x000000ff;
        hash[i + 16] = (ctx->state[4] >> (24 - i * 8)) & 0x000000ff;
        hash[i + 20] = (ctx->state[5] >> (24 - i * 8)) & 0x000000ff;
        hash[i + 24] = (ctx->state[6] >> (24 - i * 8)) & 0x000000ff;
        hash[i + 28] = (ctx->state[7] >> (24 - i * 8)) & 0x000000ff;
    }
}

// Generate random salt
static void generate_salt(uint8_t* salt, size_t salt_len) {
    srand(time(NULL));
    for (size_t i = 0; i < salt_len; i++) {
        salt[i] = (uint8_t)(rand() & 0xFF);
    }
}

// Simple PBKDF2-like function using SHA-256
static void derive_key(const char* password, size_t password_len,
                      uint32_t iterations,
                      uint8_t* output, size_t output_len) {
    uint8_t buffer[SHA256_DIGEST_SIZE];
    SHA256_CTX ctx;

    // Initial hash with password and fixed key
    sha256_init(&ctx);
    sha256_update(&ctx, (const uint8_t*)password, password_len);
    sha256_update(&ctx, FIXED_KEY, sizeof(FIXED_KEY));
    sha256_final(&ctx, buffer);

    memcpy(output, buffer, SHA256_DIGEST_SIZE);

    // Additional iterations
    for (uint32_t i = 1; i < iterations; i++) {
        sha256_init(&ctx);
        sha256_update(&ctx, buffer, SHA256_DIGEST_SIZE);
        sha256_final(&ctx, buffer);
        
        // XOR with previous result
        for (size_t j = 0; j < SHA256_DIGEST_SIZE; j++) {
            output[j] ^= buffer[j];
        }
    }
}

void hash_password(const char* password, size_t password_len,
                  uint32_t iterations, password_hash_t* result) {
    // Derive key using our PBKDF2-like function with fixed key
    derive_key(password, password_len,
              iterations,
              result->hash, sizeof(result->hash));
}

int verify_password(const char* password, size_t password_len,
                   const password_hash_t* stored_hash, uint32_t iterations) {
    password_hash_t computed_hash;
    
    // Compute hash with fixed key
    hash_password(password, password_len, iterations, &computed_hash);
    
    // Compare hashes
    return memcmp(computed_hash.hash, stored_hash->hash, sizeof(computed_hash.hash)) == 0;
} 