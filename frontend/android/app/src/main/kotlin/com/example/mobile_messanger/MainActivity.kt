package com.example.mobile_messanger

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.nio.ByteBuffer

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.mobile_messanger/hash"
    private val hashHelper = HashHelper()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "hashPassword" -> {
                    val password = call.argument<String>("password")
                    if (password != null) {
                        try {
                            val hashData = hashHelper.hashPassword(password)
                            result.success(hashData)
                        } catch (e: Exception) {
                            result.error("HASH_ERROR", "Error hashing password", e.message)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "Password cannot be null", null)
                    }
                }
                "verifyPassword" -> {
                    val password = call.argument<String>("password")
                    val storedHash = call.argument<ByteArray>("storedHash")
                    if (password != null && storedHash != null) {
                        try {
                            val isValid = hashHelper.verifyPassword(password, storedHash)
                            result.success(isValid)
                        } catch (e: Exception) {
                            result.error("VERIFY_ERROR", "Error verifying password", e.message)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "Password and storedHash cannot be null", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
