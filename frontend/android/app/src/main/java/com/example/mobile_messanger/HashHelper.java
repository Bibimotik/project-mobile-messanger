package com.example.mobile_messanger;

public class HashHelper {
    static {
        System.loadLibrary("native-lib");
    }

    // Нативные методы
    private native byte[] hashPassword(String password, int iterations);
    private native boolean verifyPassword(String password, byte[] storedHashData, int iterations);

    // Константы
    private static final int DEFAULT_ITERATIONS = 100000;

    // Публичные методы для использования в Dart
    public byte[] hashPassword(String password) {
        return hashPassword(password, DEFAULT_ITERATIONS);
    }

    public boolean verifyPassword(String password, byte[] storedHashData) {
        return verifyPassword(password, storedHashData, DEFAULT_ITERATIONS);
    }
} 