import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ChatService {
  static const String _baseUrl = 'http://10.0.2.2:8000';

  // Получение всех чатов пользователя
  static Future<List<dynamic>> getUserChats({int limit = 20}) async {
    try {
      final token = await AuthService.getToken();
      final userId = await AuthService.getUserId();
      
      if (token == null || userId == null) {
        throw Exception('User is not authenticated');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/users/$userId/chats?limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData is List) {
          return responseData;
        } else if (responseData is Map && responseData.containsKey('chats')) {
          return responseData['chats'] ?? [];
        } else {
          return [];
        }
      } else {
        throw Exception('Failed to load chats');
      }
    } catch (e) {
      throw Exception('Error loading chats: $e');
    }
  }

  // Создание нового чата
  static Future<Map<String, dynamic>> createChat(String name, List<String> participantIds) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('User is not authenticated');
      }
      final response = await http.post(
        Uri.parse('$_baseUrl/chats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'participantIds': participantIds,
        }),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create chat');
      }
    } catch (e) {
      throw Exception('Error creating chat: $e');
    }
  }

  // Удаление чата
  static Future<void> deleteChat(String chatId) async {
    try {
      final token = await AuthService.getToken();
      
      if (token == null) {
        throw Exception('User is not authenticated');
      }

      final response = await http.delete(
        Uri.parse('$_baseUrl/chats/$chatId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete chat');
      }
    } catch (e) {
      throw Exception('Error deleting chat: $e');
    }
  }

  // Редактирование чата
  static Future<Map<String, dynamic>> editChat(String chatId, String name) async {
    try {
      final token = await AuthService.getToken();
      
      if (token == null) {
        throw Exception('User is not authenticated');
      }

      final response = await http.put(
        Uri.parse('$_baseUrl/$chatId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to edit chat');
      }
    } catch (e) {
      throw Exception('Error editing chat: $e');
    }
  }

  // Добавление участника в чат
  static Future<void> addParticipant(String chatId, String userId) async {
    try {
      final token = await AuthService.getToken();
      
      if (token == null) {
        throw Exception('User is not authenticated');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/$chatId/participants'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'userId': userId,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to add participant');
      }
    } catch (e) {
      throw Exception('Error adding participant: $e');
    }
  }

  // Удаление участника из чата
  static Future<void> removeParticipant(String chatId, String userId) async {
    try {
      final token = await AuthService.getToken();
      
      if (token == null) {
        throw Exception('User is not authenticated');
      }

      final response = await http.delete(
        Uri.parse('$_baseUrl/$chatId/participants/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to remove participant');
      }
    } catch (e) {
      throw Exception('Error removing participant: $e');
    }
  }
} 