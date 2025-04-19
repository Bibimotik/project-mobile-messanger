import 'package:flutter/services.dart';

class PasswordService {
  static const platform = MethodChannel('com.example.mobile_messanger/hash');
  
  /// Хеширует пароль используя нативную реализацию
  Future<Uint8List> hashPassword(String password) async {
    try {
      final result = await platform.invokeMethod<Uint8List>(
        'hashPassword',
        {'password': password},
      );
      return result ?? Uint8List(0);
    } on PlatformException catch (e) {
      throw Exception('Failed to hash password: ${e.message}');
    }
  }

  /// Проверяет пароль с сохраненным хешем
  Future<bool> verifyPassword(String password, Uint8List storedHash) async {
    try {
      final result = await platform.invokeMethod<bool>(
        'verifyPassword',
        {
          'password': password,
          'storedHash': storedHash,
        },
      );
      return result ?? false;
    } on PlatformException catch (e) {
      throw Exception('Failed to verify password: ${e.message}');
    }
  }
} 