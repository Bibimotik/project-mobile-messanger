#ifndef NATIVE_LIB_H
#define NATIVE_LIB_H

#include <jni.h>
#include "hash/hash.h"

#ifdef __cplusplus
extern "C" {
#endif

JNIEXPORT jbyteArray JNICALL
Java_com_example_mobile_1messanger_HashHelper_hashPassword(
    JNIEnv* env,
    jobject thiz,
    jstring password,
    jint iterations);

JNIEXPORT jboolean JNICALL
Java_com_example_mobile_1messanger_HashHelper_verifyPassword(
    JNIEnv* env,
    jobject thiz,
    jstring password,
    jbyteArray storedHash,
    jint iterations);

#ifdef __cplusplus
}
#endif

#endif // NATIVE_LIB_H 