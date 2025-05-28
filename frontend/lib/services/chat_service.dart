import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'package:http/io_client.dart';

Future<http.Client> createSslClient() async {
  HttpClient client = HttpClient(context: SecurityContext.defaultContext);
  client.badCertificateCallback =
      ((X509Certificate cert, String host, int port) => true);

  return IOClient(client);
}

class ChatService {
  static const String _baseUrl = 'https://10.0.2.2:443';

  static Future<List<dynamic>> getUserChats({int limit = 20}) async {
    http.Client? client;
    try {
      final token = await AuthService.getToken();
      final userId = await AuthService.getUserId();
      
      if (token == null || userId == null) {
        throw Exception('User is not authenticated');
      }

      client = await createSslClient();
      final response = await client.get(
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
    } finally {
      client?.close();
    }
  }

  static Future<Map<String, dynamic>> createChat(String name, List<String> participantIds) async {
    http.Client? client;
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('User is not authenticated');
      }
      client = await createSslClient();
      final response = await client.post(
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
    } finally {
      client?.close();
    }
  }

  static Future<void> deleteChat(String chatId) async {
    http.Client? client;
    try {
      final token = await AuthService.getToken();
      
      if (token == null) {
        throw Exception('User is not authenticated');
      }

      client = await createSslClient();
      final response = await client.delete(
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
    } finally {
      client?.close();
    }
  }

  static Future<Map<String, dynamic>> editChat(String chatId, String name) async {
    http.Client? client;
    try {
      final token = await AuthService.getToken();

      if (token == null) {
        throw Exception('User is not authenticated');
      }

      client = await createSslClient();
      final response = await client.patch(
        Uri.parse('$_baseUrl/chats/$chatId'),
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
        throw Exception('Failed to edit chat: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error editing chat: $e');
    } finally {
      client?.close();
    }
  }

  static Future<void> addParticipant(String chatId, String userId) async {
    http.Client? client;
    try {
      final token = await AuthService.getToken();
      
      if (token == null) {
        throw Exception('User is not authenticated');
      }

      client = await createSslClient();
      final response = await client.post(
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
    } finally {
      client?.close();
    }
  }

  static Future<void> removeParticipant(String chatId, String userId) async {
    http.Client? client;
    try {
      final token = await AuthService.getToken();
      
      if (token == null) {
        throw Exception('User is not authenticated');
      }

      client = await createSslClient();
      final response = await client.delete(
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
    } finally {
      client?.close();
    }
  }

  static Future<List<dynamic>> getParticipants(String chatId) async {
    http.Client? client;
    try {
      final token = await AuthService.getToken();

      if (token == null) {
        throw Exception('User is not authenticated');
      }

      client = await createSslClient();
      final response = await client.get(
        Uri.parse('$_baseUrl/chats/$chatId/participants'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data;
        } else if (data is Map && data.containsKey('participants')) {
          return data['participants'] ?? [];
        } else {
          return [];
        }
      } else {
        throw Exception('Failed to load participants: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading participants: $e');
    } finally {
      client?.close();
    }
  }
} 