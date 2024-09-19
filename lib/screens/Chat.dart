
import 'package:flutter/material.dart';
import 'package:ksvideo/screens/sign_in_screen.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';


class Chat extends StatelessWidget {
  const Chat({
    super.key,
    required this.client,
  });

  final StreamChatClient client;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) => StreamChat(
        client: client,
        child: child,
      ),
      home: SignInScreen(),
    );
  }
}