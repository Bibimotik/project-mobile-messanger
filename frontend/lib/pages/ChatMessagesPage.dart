import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/message_service.dart';
import '../services/chat_service.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';

class ChatMessagesPage extends StatefulWidget {
  final String chatId;
  final String chatName;
  final Future<void> Function()? onChatsChanged;
  const ChatMessagesPage({super.key, required this.chatId, required this.chatName, this.onChatsChanged});

  @override
  State<ChatMessagesPage> createState() => _ChatMessagesPageState();
}

class _ChatMessagesPageState extends State<ChatMessagesPage> {
  List<dynamic> _messages = [];
  bool _isLoading = false;
  final TextEditingController _controller = TextEditingController();
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserIdAndMessages();
  }

  Future<void> _loadUserIdAndMessages() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('userId');
    });
    await _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final msgs = await MessageService.getMessages(widget.chatId);
      if (msgs.isNotEmpty) {
        // Выводим структуру первого сообщения в консоль
        // ignore: avoid_print
        print('Первое сообщение: ' + msgs.first.toString());
      }
      setState(() {
        _messages = msgs;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки сообщений: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await MessageService.sendMessage(widget.chatId, text);
      _controller.clear();
      await _loadMessages();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка отправки: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteChat() async {
    setState(() => _isLoading = true);
    try {
      await ChatService.deleteChat(widget.chatId);
      if (widget.onChatsChanged != null) {
        await widget.onChatsChanged!();
      }
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Чат удалён'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка удаления чата: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _leaveChat() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final myUserId = prefs.getString('userId');
      final token = await AuthService.getToken();
      final response = await http.delete(
        Uri.parse('http://10.0.2.2:8000/chats/${widget.chatId}/participants?userId=$myUserId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Вы покинули чат'), backgroundColor: Colors.green),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка выхода: ${response.body}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка выхода: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAddParticipantDialog() {
    showDialog(
      context: context,
      builder: (context) => AddParticipantDialog(chatId: widget.chatId),
    );
  }

  void _showRemoveParticipantDialog() {
    showDialog(
      context: context,
      builder: (context) => RemoveParticipantDialog(chatId: widget.chatId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatName),
        backgroundColor: Colors.blueAccent,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'add') {
                _showAddParticipantDialog();
              } else if (value == 'remove') {
                _showRemoveParticipantDialog();
              } else if (value == 'delete') {
                _deleteChat();
              } else if (value == 'leave') {
                _leaveChat();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'add',
                child: Text('Добавить участника'),
              ),
              const PopupMenuItem(
                value: 'remove',
                child: Text('Удалить участника'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Удалить чат'),
              ),
              const PopupMenuItem(
                value: 'leave',
                child: Text('Покинуть чат'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(child: Text('Нет сообщений'))
                    : ListView.builder(
                        reverse: true,
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[_messages.length - 1 - index];
                          final content = msg['text'] ?? msg['content'] ?? msg['message'] ?? '';
                          final senderId = (msg['senderId']?.toString() ?? '').toLowerCase().trim();
                          final myId = (_userId ?? '').toLowerCase().trim();
                          final isMine = myId.isNotEmpty && senderId == myId;
                          return Align(
                            alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                              decoration: BoxDecoration(
                                color: isMine ? Colors.blueAccent : Colors.grey[300],
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: isMine ? const Radius.circular(16) : const Radius.circular(4),
                                  bottomRight: isMine ? const Radius.circular(4) : const Radius.circular(16),
                                ),
                              ),
                              child: Text(
                                content,
                                style: TextStyle(
                                  color: isMine ? Colors.white : Colors.black87,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Введите сообщение...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: _isLoading ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AddParticipantDialog extends StatefulWidget {
  final String chatId;
  const AddParticipantDialog({super.key, required this.chatId});

  @override
  State<AddParticipantDialog> createState() => _AddParticipantDialogState();
}

class _AddParticipantDialogState extends State<AddParticipantDialog> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<dynamic> _results = [];
  bool _isLoading = false;
  String? _myUserId;

  @override
  void initState() {
    super.initState();
    _loadMyUserId();
  }

  Future<void> _addUserToChat(String userId) async {
    setState(() => _isLoading = true);
    try {
      final token = await AuthService.getToken();
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/chats/${widget.chatId}/participants'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({ 'userId': userId }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Пользователь добавлен!'), backgroundColor: Colors.green),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка добавления: ${response.body}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка добавления: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMyUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _myUserId = prefs.getString('userId');
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(seconds: 1), () {
      _searchUsers(_searchController.text.trim());
    });
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/user/search?name=$query&limit=5'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> users = data is List ? data : (data['users'] ?? []);
        // Фильтруем себя
        if (_myUserId != null) {
          users = users.where((u) => (u['id']?.toString() ?? '') != _myUserId).toList();
        }
        setState(() => _results = users);
      } else {
        setState(() => _results = []);
      }
    } catch (e) {
      setState(() => _results = []);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Добавить участника'),
      content: SizedBox(
        width: 350,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(hintText: 'Имя пользователя'),
              onChanged: (_) => _onSearchChanged(),
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_results.isEmpty)
              const Text('Ничего не найдено')
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final user = _results[index];
                    return ListTile(
                      title: Text(user['username'] ?? user['name'] ?? user['login'] ?? user.toString()),
                      onTap: () => _addUserToChat(user['id'].toString()),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Закрыть'),
        ),
      ],
    );
  }
}

class RemoveParticipantDialog extends StatefulWidget {
  final String chatId;
  const RemoveParticipantDialog({super.key, required this.chatId});

  @override
  State<RemoveParticipantDialog> createState() => _RemoveParticipantDialogState();
}

class _RemoveParticipantDialogState extends State<RemoveParticipantDialog> {
  List<dynamic> _participants = [];
  bool _isLoading = false;
  String? _myUserId;

  @override
  void initState() {
    super.initState();
    _loadMyUserIdAndParticipants();
  }

  Future<void> _loadMyUserIdAndParticipants() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    _myUserId = prefs.getString('userId');
    try {
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/chats/${widget.chatId}/participants'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _participants = data is List ? data : (data['participants'] ?? []);
        });
      } else {
        setState(() => _participants = []);
      }
    } catch (e) {
      setState(() => _participants = []);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeUserFromChat(String userId) async {
    setState(() => _isLoading = true);
    try {
      final token = await AuthService.getToken();
      final response = await http.delete(
        Uri.parse('http://10.0.2.2:8000/chats/${widget.chatId}/participants?userId=$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        if (userId == _myUserId) {
          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Вы покинули чат'), backgroundColor: Colors.green),
            );
          }
        } else {
          await _loadMyUserIdAndParticipants();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Пользователь удалён'), backgroundColor: Colors.green),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка удаления: ${response.body}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка удаления: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Удалить участника'),
      content: SizedBox(
        width: 350,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _participants.isEmpty
                ? const Text('Нет участников')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _participants.length,
                    itemBuilder: (context, index) {
                      final user = _participants[index];
                      final userId = user['id']?.toString() ?? user['userId']?.toString() ?? '';
                      final isMe = _myUserId != null && userId == _myUserId;
                      return ListTile(
                        title: Text(user['username'] ?? user['name'] ?? user['login'] ?? user.toString()),
                        trailing: isMe
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeUserFromChat(userId),
                              ),
                      );
                    },
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Закрыть'),
        ),
      ],
    );
  }
} 