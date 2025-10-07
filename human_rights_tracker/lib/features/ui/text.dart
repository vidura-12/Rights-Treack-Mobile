import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UserSupportPage extends StatefulWidget {
  final bool isDarkTheme;
  
  const UserSupportPage({super.key, required this.isDarkTheme});

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

  bool _isLoading = false;
  bool _connectionError = false;

  // Theme colors based on parent theme
  Color get _backgroundColor => widget.isDarkTheme ? const Color(0xFF0A1628) : Colors.white;
  Color get _cardColor => widget.isDarkTheme ? const Color(0xFF1A243A) : const Color(0xFFFAFAFA);
  Color get _appBarColor => widget.isDarkTheme ? const Color(0xFF0A1628) : Colors.white;
  Color get _textColor => widget.isDarkTheme ? Colors.white : Colors.black87;
  Color get _secondaryTextColor => widget.isDarkTheme ? Colors.grey[400]! : Colors.grey[600]!;
  Color get _iconColor => widget.isDarkTheme ? Colors.white : Colors.black87;
  Color get _accentColor => const Color(0xFFE53E3E);
  Color get _userMessageColor => widget.isDarkTheme ? const Color(0xFF3182CE) : const Color(0xFF3182CE);
  Color get _botMessageColor => widget.isDarkTheme ? const Color(0xFF2D3748) : const Color(0xFFF7FAFC);
  Color get _inputBackgroundColor => widget.isDarkTheme ? const Color(0xFF2D3748) : Colors.grey[100]!;
  Color get _borderColor => widget.isDarkTheme ? const Color(0xFF2D3748) : Colors.grey[300]!;

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _chat.add({'role': 'user', 'text': text});
      _isLoading = true;
      _connectionError = false;
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
    // Try multiple endpoints for better compatibility
    final endpoints = [
      "http://localhost:5000/chat",
      "http://10.0.2.2:5000/chat", // For Android emulator
      "http://127.0.0.1:5000/chat",
    ];

    for (final endpoint in endpoints) {
      try {
        final response = await http.post(
          Uri.parse(endpoint),
          headers: {
            "Content-Type": "application/json",
          },
          body: jsonEncode({
            "message": userText,
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data["reply"] ?? "I received your message but couldn't generate a proper response.";
        }
      } catch (e) {
        // Continue to next endpoint
        if (endpoint == endpoints.last) {
          // Last endpoint failed
          setState(() {
            _connectionError = true;
          });
          return _getFallbackResponse(userText);
        }
      }
    }
    
    return _getFallbackResponse(userText);
  }

  String _getFallbackResponse(String userText) {
    final lowerText = userText.toLowerCase();
    
    if (lowerText.contains('hello') || lowerText.contains('hi')) {
      return "Hello! I'm here to help. It seems I'm having connection issues, but I can still assist with basic questions about human rights, case reporting, or using this app.";
    } else if (lowerText.contains('report') || lowerText.contains('case')) {
      return "To report a case, go to the 'Report Abuse' section from the home page. You can provide details, upload evidence, and track your case status.";
    } else if (lowerText.contains('right') || lowerText.contains('help')) {
      return "This app helps you report human rights violations. You can document cases, get legal guidance, and connect with support organizations.";
    } else if (lowerText.contains('contact') || lowerText.contains('emergency')) {
      return "For emergencies, contact local authorities immediately. You can also check the 'Directory' section for support organizations.";
    } else {
      return "I understand you're asking about: '$userText'. Currently, I'm experiencing connection issues. Please try again later or contact support through other channels. In the meantime, you can browse our FAQ section for immediate help.";
    }
  }

  void _retryConnection() {
    setState(() {
      _connectionError = false;
    });
    if (_chat.last['role'] == 'user') {
      _sendMessage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _appBarColor,
        elevation: 0,
        title: Text(
          'AI Support Assistant',
          style: TextStyle(
            color: _textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: _iconColor),
      ),
      body: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.support_agent, color: _accentColor, size: 32),
                    const SizedBox(width: 12),
                    Text(
                      'User Support Management',
                      style: TextStyle(
                        color: _textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Ask me anything! I am powered by AI to help with support.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _secondaryTextColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Connection Error Banner
          if (_connectionError)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange[800]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Connection issue. Using fallback responses.',
                      style: TextStyle(
                        color: Colors.orange[800],
                        fontSize: 14,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _retryConnection,
                    child: Text(
                      'Retry',
                      style: TextStyle(
                        color: Colors.orange[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Chat Container
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: widget.isDarkTheme 
                        ? Colors.black.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Chat Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: widget.isDarkTheme 
                          ? const Color(0xFF2D3748) 
                          : Colors.grey[50],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'AI Support Assistant',
                          style: TextStyle(
                            color: _textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        if (_connectionError)
                          Icon(Icons.wifi_off, color: Colors.orange, size: 16),
                      ],
                    ),
                  ),

                  // Messages Area
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: ListView.builder(
                        reverse: false,
                        itemCount: _chat.length,
                        itemBuilder: (context, index) {
                          final msg = _chat[index];
                          final isUser = msg['role'] == 'user';
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment: isUser 
                                  ? MainAxisAlignment.end 
                                  : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isUser)
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: _accentColor,
                                    child: Icon(
                                      Icons.support_agent,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isUser 
                                          ? _userMessageColor 
                                          : _botMessageColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      msg['text'] ?? '',
                                      style: TextStyle(
                                        color: isUser 
                                            ? Colors.white 
                                            : _textColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                if (isUser)
                                  const SizedBox(width: 8),
                                if (isUser)
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.grey[300],
                                    child: Icon(
                                      Icons.person,
                                      color: Colors.grey[600],
                                      size: 16,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Loading Indicator
                  if (_isLoading)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: _accentColor,
                            child: Icon(
                              Icons.support_agent,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _botMessageColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: _accentColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Thinking...',
                                  style: TextStyle(
                                    color: _secondaryTextColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Input Area
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: widget.isDarkTheme 
                          ? const Color(0xFF2D3748) 
                          : Colors.grey[50],
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: _inputBackgroundColor,
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(color: _borderColor),
                            ),
                            child: TextField(
                              controller: _messageController,
                              style: TextStyle(color: _textColor),
                              decoration: InputDecoration(
                                hintText: 'Type your message...',
                                hintStyle: TextStyle(color: _secondaryTextColor),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: _accentColor,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.send, color: Colors.white),
                            onPressed: _sendMessage,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}