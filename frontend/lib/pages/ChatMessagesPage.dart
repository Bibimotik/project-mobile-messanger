import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/message_service.dart';
import '../services/chat_service.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';
import 'dart:io';
import 'package:http/io_client.dart';

Future<http.Client> createSslClient() async {
  HttpClient client = HttpClient(context: SecurityContext.defaultContext);
  client.badCertificateCallback =
      ((X509Certificate cert, String host, int port) => true);

  return IOClient(client);
}

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
  List<dynamic> _participants = [];
  String _currentChatName = '';
  Map<String, dynamic>? _messageToEdit;

  @override
  void initState() {
    super.initState();
    _currentChatName = widget.chatName;
    _loadUserIdAndMessages();
    _loadParticipants();
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

  Future<void> _loadParticipants() async {
    try {
      final participants = await ChatService.getParticipants(widget.chatId);
      setState(() {
        _participants = participants;
      });
    } catch (e) {
      print('Ошибка загрузки участников: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageToEdit != null) {
      final newText = _controller.text.trim();
      final originalText = _messageToEdit!['text'] ?? _messageToEdit!['content'] ?? _messageToEdit!['message'] ?? '';

      if (newText != originalText) {
        setState(() => _isLoading = true);
        try {
          final messageId = _messageToEdit!['id']?.toString();
          if (messageId == null) return;

          await MessageService.editMessage(widget.chatId, messageId, newText);

          _controller.clear();
          _messageToEdit = null;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Сообщение отредактировано!'), backgroundColor: Colors.green),
          );

          await _loadMessages();

        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка редактирования: $e'), backgroundColor: Colors.red),
          );
        } finally {
          setState(() => _isLoading = false);
        }
      } else {
        _controller.clear();
        _messageToEdit = null;
      }
    } else {
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
      final client = await createSslClient();
      final response = await client.delete(
        Uri.parse('https://10.0.2.2:443/chats/${widget.chatId}/participants?userId=$myUserId'),
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
      builder: (context) => AddParticipantDialog(
        chatId: widget.chatId,
        onParticipantAdded: _loadMessages,
      ),
    );
  }

  void _showRemoveParticipantDialog() {
    showDialog(
      context: context,
      builder: (context) => RemoveParticipantDialog(
        chatId: widget.chatId,
        onParticipantRemoved: _loadMessages,
      ),
    );
  }

  void _showEditChatDialog() {
    final _chatNameController = TextEditingController(text: widget.chatName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Редактировать чат'),
          content: TextField(
            controller: _chatNameController,
            decoration: const InputDecoration(hintText: 'Новое название чата'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = _chatNameController.text.trim();
                if (newName.isEmpty) return;

                setState(() {
                  _currentChatName = newName;
                });

                Navigator.of(context).pop();

                try {
                  await ChatService.editChat(widget.chatId, newName);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Чат успешно отредактирован!'), backgroundColor: Colors.green),
                  );
                  if (widget.onChatsChanged != null) {
                    await widget.onChatsChanged!();
                  }
                  await _loadMessages();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка редактирования чата: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }

  void _showMessageOptions(Map<String, dynamic> message) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Редактировать сообщение'),
                onTap: () {
                  Navigator.pop(context);
                  _editMessage(message);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Удалить сообщение'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(message);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _editMessage(Map<String, dynamic> message) {
    setState(() {
      _messageToEdit = message;
      _controller.text = message['text'] ?? message['content'] ?? message['message'] ?? '';
    });
  }

  Future<void> _deleteMessage(Map<String, dynamic> message) async {
    setState(() => _isLoading = true);
    try {
      final messageId = message['id']?.toString();
      if (messageId == null) return;

      await MessageService.deleteMessage(widget.chatId, messageId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сообщение удалено!'), backgroundColor: Colors.green),
      );

      await _loadMessages();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка удаления сообщения: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentChatName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'Участников: ${_participants.length}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
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
              } else if (value == 'edit') {
                _showEditChatDialog();
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
              const PopupMenuItem(
                value: 'edit',
                child: Text('Редактировать чат'),
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

                          final sender = _participants.firstWhere(
                                (p) => (p['id']?.toString() ?? '').toLowerCase().trim() == senderId,
                            orElse: () => null,
                          );
                          final senderName = sender?['username'] ?? sender?['name'] ?? 'Неизвестный';

                          return Align(
                            alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                            child: InkWell(
                              onLongPress: isMine ? () => _showMessageOptions(msg) : null,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                                decoration: BoxDecoration(
                                  color: isMine ? Colors.blueAccent : Colors.grey[300],
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(20),
                                    topRight: const Radius.circular(20),
                                    bottomLeft: isMine ? const Radius.circular(20) : const Radius.circular(8),
                                    bottomRight: isMine ? const Radius.circular(8) : const Radius.circular(20),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [
                                    if (!isMine)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 4.0),
                                        child: Text(
                                          senderName,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ),
                                    Text(
                                      content,
                                      style: TextStyle(
                                        color: isMine ? Colors.white : Colors.black87,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
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
  final VoidCallback? onParticipantAdded;
  const AddParticipantDialog({super.key, required this.chatId, this.onParticipantAdded});

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
      final client = await createSslClient();
      final response = await client.post(
        Uri.parse('https://10.0.2.2:443/chats/${widget.chatId}/participants'),
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
        widget.onParticipantAdded?.call();
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
      final client = await createSslClient();
      final response = await client.get(
        Uri.parse('https://10.0.2.2:443/user/search?name=$query&limit=5'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> users = data is List ? data : (data['users'] ?? []);
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
  final VoidCallback? onParticipantRemoved;
  const RemoveParticipantDialog({super.key, required this.chatId, this.onParticipantRemoved});

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
      final client = await createSslClient();
      final response = await client.get(
        Uri.parse('https://10.0.2.2:443/chats/${widget.chatId}/participants'),
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
      final client = await createSslClient();
      final response = await client.delete(
        Uri.parse('https://10.0.2.2:443/chats/${widget.chatId}/participants?userId=$userId'),
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
          widget.onParticipantRemoved?.call();
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