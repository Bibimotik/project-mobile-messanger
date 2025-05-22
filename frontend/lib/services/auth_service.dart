import 'dart:convert';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Подключение нативной библиотеки для хеширования
final DynamicLibrary nativeLib = DynamicLibrary.open('hash.dll');
typedef CalculateHashNative = Uint32 Function(Pointer<Utf8>);
typedef CalculateHash = int Function(Pointer<Utf8>);

final CalculateHash _calculateHash = nativeLib
    .lookup<NativeFunction<CalculateHashNative>>('calculate_hash')
    .asFunction();

class AuthService {
  static const String _baseUrl = 'http://10.0.2.2:8000/user';

  // Хеширование пароля через нативную библиотеку
  static String _hashPassword(String password) {
    final pointer = password.toNativeUtf8();
    try {
      return _calculateHash(pointer).toString();
    } finally {
      malloc.free(pointer);
    }
  }

  static Future<Map<String, dynamic>> register(
      String username, String password) async {
    try {
      final hashedPassword = _hashPassword(password);

      final response = await http.post(
        Uri.parse('$_baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': hashedPassword,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Registration error: $e');
    }
  }

  static Future<Map<String, dynamic>> login(
      String username, String password) async {
    try {
      final hashedPassword = _hashPassword(password);

      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': hashedPassword,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
}