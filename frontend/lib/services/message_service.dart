import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class MessageService {
  static const String _baseUrl = 'http://10.0.2.2:8000';

  // Получить сообщения чата
  static Future<List<dynamic>> getMessages(String chatId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('User is not authenticated');
      final response = await http.get(
        Uri.parse('$_baseUrl/chats/$chatId/messages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return data;
        if (data is Map && data.containsKey('messages')) return data['messages'];
        return [];
      } else {
        throw Exception('Failed to load messages');
      }
    } catch (e) {
      throw Exception('Error loading messages: $e');
    }
  }

  // Отправить сообщение
  static Future<void> sendMessage(String chatId, String content) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('User is not authenticated');
      final response = await http.post(
        Uri.parse('$_baseUrl/chats/$chatId/messages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'content': content}),
      );
      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception('Failed to send message');
      }
    } catch (e) {
      throw Exception('Error sending message: $e');
    }
  }

  // Удалить сообщение
  static Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('User is not authenticated');
      final response = await http.delete(
        Uri.parse('$_baseUrl/chats/$chatId/messages/$messageId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to delete message');
      }
    } catch (e) {
      throw Exception('Error deleting message: $e');
    }
  }

  // Редактировать сообщение
  static Future<void> editMessage(String chatId, String messageId, String content) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('User is not authenticated');
      final response = await http.put(
        Uri.parse('$_baseUrl/chats/$chatId/messages/$messageId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'content': content}),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to edit message');
      }
    } catch (e) {
      throw Exception('Error editing message: $e');
    }
  }
} 