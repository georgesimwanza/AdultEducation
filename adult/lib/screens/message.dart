import 'package:flutter/material.dart';

class Message extends StatefulWidget {
  const Message({super.key});

  @override
  State<Message> createState() => MessageState();
}

class MessageState extends State<Message> {
  final TextEditingController controller = TextEditingController();

  List<ChatMessage> messages = [
    ChatMessage(text: "Hello", isMe: false),
    ChatMessage(text: "How are you", isMe: false),
    ChatMessage(text: "Hello", isMe: false),
    ChatMessage(text: "Hi there!", isMe: true),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: Column(
        children: [
          /// MESSAGE LIST
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return _buildMessage(messages[index]);
              },
            ),
          ),

          _buildInputArea(),
        ],
      ),
    );
  }

  /// MESSAGE BUBBLE
  Widget _buildMessage(ChatMessage message) {
    return Row(
      mainAxisAlignment: message.isMe
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.all(12),
          constraints: const BoxConstraints(maxWidth: 250),
          decoration: BoxDecoration(
            color: message.isMe ? Colors.blue : Colors.green[300],
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            message.text,
            style: TextStyle(color: message.isMe ? Colors.white : Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: (const EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: "Type a message...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              if (controller.text.trim().isEmpty) return;

              setState(() {
                messages.add(ChatMessage(text: controller.text, isMe: true));
              });

              controller.clear();
            },
          ),
        ],
      ),
    );
  }
}

/// DATA MODEL
class ChatMessage {
  final String text;
  final bool isMe;

  ChatMessage({required this.text, required this.isMe});
}
