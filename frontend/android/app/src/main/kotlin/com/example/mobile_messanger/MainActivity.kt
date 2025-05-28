package com.example.mobile_messanger

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.mobile_messanger/hash"

    // Объявляем нативный метод
    external fun calculateHash(input: String): Int

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Загружаем библиотеку
        System.loadLibrary("hash")

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call, result ->
            when (call.method) {
                "calculateHash" -> {
                    val input = call.arguments as String
                    result.success(calculateHash(input))
                }
                else -> result.notImplemented()
            }
        }
    }
}