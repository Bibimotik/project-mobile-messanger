#ifndef HASH_H
#define HASH_H

#include <stdint.h>
#include <stddef.h>

#define HASH_SIZE 32
#define SALT_SIZE 16

#ifdef __cplusplus
extern "C" {
#endif

// Структура для хранения хеша пароля
typedef struct {
    uint8_t hash[HASH_SIZE];
} password_hash_t;

// Функции для работы с хешем
void hash_password(const char* password, size_t password_len, uint32_t iterations, password_hash_t* result);

int verify_password(const char* password, size_t password_len, const password_hash_t* stored_hash, uint32_t iterations);

#ifdef __cplusplus
}
#endif

#endif // HASH_H 