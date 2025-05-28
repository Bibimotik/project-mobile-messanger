#include <stdint.h>
#include <string.h>

static uint32_t hash_string(const char* str) {
    uint32_t hash = 5381;
    int c;

    while ((c = *str++)) {
        hash = ((hash << 5) + hash) + c;
    }
    return hash;
}

uint32_t calculate_hash(const char* input) {
    return hash_string(input);
}