import 'package:flutter/material.dart';
import 'package:mobile_messanger/services/auth_service.dart';
import 'package:mobile_messanger/services/chat_service.dart';
import 'AuthPage.dart';
import 'ChatMessagesPage.dart';

class HomePage extends StatefulWidget {
  final List<dynamic> initialChats;
  
  const HomePage({super.key, required this.initialChats});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<dynamic> _chats;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _chats = widget.initialChats;
  }

  Future<void> _refreshChats() async {
    setState(() => _isLoading = true);
    try {
      final chats = await ChatService.getUserChats();
      setState(() {
        _chats = chats;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки чатов: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AuthPage()),
    );
  }

  Future<bool?> _showCreateChatDialog() async {
    final _chatNameController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Создать чат'),
          content: TextField(
            controller: _chatNameController,
            decoration: const InputDecoration(hintText: 'Название чата'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = _chatNameController.text.trim();
                if (name.isEmpty) return;
                setState(() => _isLoading = true);
                try {
                  await ChatService.createChat(name, []);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Чат создан!'), backgroundColor: Colors.green),
                  );
                  Navigator.of(context).pop(true);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка создания чата: $e'), backgroundColor: Colors.red),
                  );
                  Navigator.of(context).pop(false);
                } finally {
                  setState(() => _isLoading = false);
                }
              },
              child: const Text('Создать'),
            ),
          ],
        );
      },
    );
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Чаты',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        elevation: 10,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshChats,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _chats.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'У вас пока нет чатов',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final created = await _showCreateChatDialog();
                            if (created == true) await _refreshChats();
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Создать чат'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _chats.length,
                    itemBuilder: (context, index) {
                      final chat = _chats[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blueAccent,
                          child: Text(
                            chat['name'][0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          chat['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          'Участников: ${chat['participants']?.length ?? 0}',
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatMessagesPage(
                                chatId: chat['id'].toString(),
                                chatName: chat['name'] ?? 'Чат',
                                onChatsChanged: _refreshChats,
                              ),
                            ),
                          );
                          if (result == true) {
                            await _refreshChats();
                          }
                        },
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await _showCreateChatDialog();
          if (created == true) await _refreshChats();
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
      ),
    );
  }
}
