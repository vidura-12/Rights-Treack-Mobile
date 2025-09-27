import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/app_wrapper.dart';

class UserSupportPage extends StatefulWidget {
  const UserSupportPage({super.key});

  @override
  State<UserSupportPage> createState() => _UserSupportPageState();
}

class _UserSupportPageState extends State<UserSupportPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _chat = [
    {
      'role': 'support',
      'text': 'Hi! I am your AI Support Assistant. How can I help you today?'
    },
  ];

  // 🚨 Put your API Key here
  // final String _apiKey = "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";

  bool _isLoading = false;

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _chat.add({'role': 'user', 'text': text});
      _isLoading = true;
      _messageController.clear();
    });

    // Call AI API
    final reply = await _getAIReply(text);

    setState(() {
      _chat.add({'role': 'support', 'text': reply});
      _isLoading = false;
    });
  }

  Future<String> _getAIReply(String userText) async {
  const String apiUrl = "http://localhost:5000/chat";

  try {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "message": userText,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["reply"];
    } else {
      return "Error: {response.statusCode} - {response.body}";
    }
  } catch (e) {
    return "Something went wrong: $e";
  }
  }

  @override
  Widget build(BuildContext context) {
    return AppWrapper(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A1628),
              Color(0xFF1A243A),
            ],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.support_agent, color: Color(0xFFE53E3E), size: 32),
                SizedBox(width: 12),
                Text(
                  'User Support Management',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Ask me anything! I am powered by AI to help with support.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI Chatbot',
                      style: TextStyle(
                        color: Color(0xFF2D3748),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _chat.length,
                        itemBuilder: (context, index) {
                          final msg = _chat[index];
                          final isUser = msg['role'] == 'user';
                          return Align(
                            alignment: isUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isUser
                                    ? const Color(0xFF3182CE)
                                    : const Color(0xFFF7FAFC),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                msg['text'] ?? '',
                                style: TextStyle(
                                  color: isUser
                                      ? Colors.white
                                      : const Color(0xFF2D3748),
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: const InputDecoration(
                              hintText: 'Type your message...',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        IconButton(
                          icon:
                              const Icon(Icons.send, color: Color(0xFF3182CE)),
                          onPressed: _sendMessage,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
