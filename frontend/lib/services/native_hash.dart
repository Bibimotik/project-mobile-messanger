import 'dart:typed_data';
import 'package:flutter/services.dart';

class NativeHash {
  static const platform = MethodChannel('com.example.mobile_messanger/hash');

  static Future<Uint8List> hashPassword(String password) async {
    try {
      final result = await platform.invokeMethod<Uint8List>('hashPassword', {
        'password': password,
      });
      if (result == null) {
        throw Exception('Failed to hash password: result is null');
      }
      return result;
    } on PlatformException catch (e) {
      throw Exception('Failed to hash password: ${e.message}');
    }
  }

  static Future<bool> verifyPassword(String password, Uint8List storedHash) async {
    try {
      final result = await platform.invokeMethod<bool>('verifyPassword', {
        'password': password,
        'storedHash': storedHash,
      });
      if (result == null) {
        throw Exception('Failed to verify password: result is null');
      }
      return result;
    } on PlatformException catch (e) {
      throw Exception('Failed to verify password: ${e.message}');
    }
  }
} 