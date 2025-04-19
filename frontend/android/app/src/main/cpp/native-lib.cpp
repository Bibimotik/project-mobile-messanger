#include "native-lib.h"
#include <string>
#include <android/log.h>

#define LOG_TAG "NativeLib"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)

extern "C" JNIEXPORT jbyteArray JNICALL
Java_com_example_mobile_1messanger_HashHelper_hashPassword(
    JNIEnv* env,
    jobject /* this */,
    jstring password,
    jint iterations) {
    
    // Получаем строку из Java
    const char* passwordStr = env->GetStringUTFChars(password, nullptr);
    size_t passwordLen = env->GetStringUTFLength(password);
    
    // Создаем структуру для результата
    password_hash_t result;
    
    // Вызываем функцию хеширования с переданным количеством итераций
    hash_password(passwordStr, passwordLen, iterations, &result);
    
    // Освобождаем строку
    env->ReleaseStringUTFChars(password, passwordStr);
    
    // Создаем массив для возврата (хеш + соль)
    jbyteArray output = env->NewByteArray(sizeof(password_hash_t));
    env->SetByteArrayRegion(output, 0, sizeof(password_hash_t), (jbyte*)&result);
    
    return output;
}

extern "C" JNIEXPORT jboolean JNICALL
Java_com_example_mobile_1messanger_HashHelper_verifyPassword(
    JNIEnv* env,
    jobject /* this */,
    jstring password,
    jbyteArray storedHash,
    jint iterations) {
    
    // Получаем строку из Java
    const char* passwordStr = env->GetStringUTFChars(password, nullptr);
    size_t passwordLen = env->GetStringUTFLength(password);
    
    // Получаем сохраненные данные
    password_hash_t storedHashData;
    env->GetByteArrayRegion(storedHash, 0, sizeof(password_hash_t), (jbyte*)&storedHashData);
    
    // Проверяем пароль с переданным количеством итераций
    int result = verify_password(passwordStr, passwordLen, &storedHashData, iterations);
    
    // Освобождаем строку
    env->ReleaseStringUTFChars(password, passwordStr);
    
    return result == 1;
} 