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

class MessageService {
  static const String _baseUrl = 'https://10.0.2.2:443';

  static Future<List<dynamic>> getMessages(String chatId) async {
    http.Client? client;
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('User is not authenticated');

      client = await createSslClient();
      final response = await client.get(
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
    } finally {
      client?.close();
    }
  }

  static Future<void> sendMessage(String chatId, String content) async {
    http.Client? client;
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('User is not authenticated');

      client = await createSslClient();
      final response = await client.post(
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
    } finally {
      client?.close();
    }
  }

  static Future<void> deleteMessage(String chatId, String messageId) async {
    http.Client? client;
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('User is not authenticated');

      client = await createSslClient();
      final response = await client.delete(
        Uri.parse('$_baseUrl/chats/$chatId/messages/$messageId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to delete message: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting message: $e');
    } finally {
      client?.close();
    }
  }

  static Future<void> editMessage(String chatId, String messageId, String content) async {
    http.Client? client;
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('User is not authenticated');

      client = await createSslClient();
      final response = await client.patch(
        Uri.parse('$_baseUrl/chats/$chatId/messages/$messageId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'content': content}),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to edit message: ${response.statusCode}. Response body: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error editing message: $e');
    } finally {
      client?.close();
    }
  }
} 