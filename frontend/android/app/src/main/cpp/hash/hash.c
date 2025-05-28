#include <jni.h>
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

// Правильное имя функции с учетом подчеркивания в имени пакета
JNIEXPORT jint JNICALL
Java_com_example_mobile_1messanger_MainActivity_calculateHash(
        JNIEnv* env,
        jobject thiz,
        jstring input) {

    const char* str = (*env)->GetStringUTFChars(env, input, 0);
    uint32_t hash = hash_string(str);
    (*env)->ReleaseStringUTFChars(env, input, str);

    return (jint)hash;
}