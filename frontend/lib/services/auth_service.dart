import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_messanger/services/password_service.dart';
import 'dart:typed_data';

class AuthService {
  static const String _baseUrl = 'http://10.0.2.2:8000/user';
  static final _passwordService = PasswordService();

  // Хеширование пароля через нативную библиотеку
  static Future<String> _hashPassword(String password) async {
    try {
      final Uint8List hashedBytes = await _passwordService.hashPassword(password);
      // Конвертируем байты в base64 строку для хранения в БД
      return base64Encode(hashedBytes);
    } catch (e) {
      throw Exception('Error hashing password: $e');
    }
  }

  // Проверка пароля через нативную библиоте222ку
  static Future<bool> _verifyPassword(String password, String hashedPassword) async {
    try {
      // Декодируем base64 строку обратно в байты
      final Uint8List storedHash = base64Decode(hashedPassword);
      return await _passwordService.verifyPassword(password, storedHash);
    } catch (e) {
      throw Exception('Error verifying password: $e');
    }
  }

  static Future<Map<String, dynamic>> register(
      String username, String password) async {
    try {
      // Хешируем пароль перед отправкой
      final hashedPassword = await _hashPassword(password);

      final response = await http.post(
        Uri.parse('$_baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': hashedPassword, // Отправляем хешированный пароль
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        if (responseData['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', responseData['token']);
        }
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
      // Хешируем пароль перед отправкой
      final hashedPassword = await _hashPassword(password);

      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': hashedPassword, // Отправляем хешированный пароль
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (responseData['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', responseData['token']);
        }
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