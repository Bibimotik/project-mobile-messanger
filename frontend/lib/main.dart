import 'package:flutter/material.dart';
import 'package:mobile_messanger/services/auth_service.dart';
import 'package:mobile_messanger/services/chat_service.dart';
import 'pages/AuthPage.dart';
import 'pages/HomePage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<String?>(
        future: AuthService.getToken(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (snapshot.hasData && snapshot.data != null) {
            return FutureBuilder<List<dynamic>>(
              future: ChatService.getUserChats(),
              builder: (context, chatsSnapshot) {
                if (chatsSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (chatsSnapshot.hasData) {
                  return HomePage(initialChats: chatsSnapshot.data!);
                }

                return const AuthPage();
              },
            );
          }

          return const AuthPage();
        },
      ),
    );
  }
}
