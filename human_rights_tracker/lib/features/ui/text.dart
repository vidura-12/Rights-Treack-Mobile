import 'package:flutter/material.dart';
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
			'text': 'Hi! How can we help you today? You can ask about help center, tickets, FAQ, or report a blocker.'
		},
	];

	void _sendMessage() {
		final text = _messageController.text.trim();
		if (text.isEmpty) return;
		setState(() {
			_chat.add({'role': 'user', 'text': text});
			_chat.add({
				'role': 'support',
				'text': _getBotReply(text),
			});
			_messageController.clear();
		});
	}

	String _getBotReply(String userText) {
		// Simple bot logic for demo
		if (userText.toLowerCase().contains('ticket')) {
			return 'To create a support ticket, please provide details of your issue.';
		} else if (userText.toLowerCase().contains('faq')) {
			return 'Visit our FAQ section for common questions or ask here.';
		} else if (userText.toLowerCase().contains('blocker')) {
			return 'Describe the blocker you are facing. Our team will assist you.';
		} else if (userText.toLowerCase().contains('help center')) {
			return 'You can access the help center from the main menu or ask your question here.';
		}
		return 'Thank you for reaching out! We will get back to you soon.';
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
							children: [
								const Icon(Icons.support_agent, color: Color(0xFFE53E3E), size: 32),
								const SizedBox(width: 12),
								const Text(
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
							'Facilitates Scrum events, removes blockers; leads support flows (help center, tickets, FAQ)',
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
											'Chatbot',
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
														alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
														child: Container(
															margin: const EdgeInsets.symmetric(vertical: 4),
															padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
															decoration: BoxDecoration(
																color: isUser ? const Color(0xFF3182CE) : const Color(0xFFF7FAFC),
																borderRadius: BorderRadius.circular(12),
															),
															child: Text(
																msg['text'] ?? '',
																style: TextStyle(
																	color: isUser ? Colors.white : const Color(0xFF2D3748),
																	fontSize: 15,
																),
															),
														),
													);
												},
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
															contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
														),
														onSubmitted: (_) => _sendMessage(),
													),
												),
												IconButton(
													icon: const Icon(Icons.send, color: Color(0xFF3182CE)),
													onPressed: _sendMessage,
												),
											],
										),
									],
								),
							),
						),
						const SizedBox(height: 24),
						Padding(
							padding: const EdgeInsets.symmetric(horizontal: 16),
							child: Row(
								mainAxisAlignment: MainAxisAlignment.spaceBetween,
								children: [
									Column(
										crossAxisAlignment: CrossAxisAlignment.start,
										children: const [
											Text('Help Center', style: TextStyle(color: Color(0xFF2D3748), fontWeight: FontWeight.bold)),
											Text('FAQ', style: TextStyle(color: Color(0xFF2D3748))),
											Text('Tickets', style: TextStyle(color: Color(0xFF2D3748))),
										],
									),
									const Icon(Icons.info_outline, color: Color(0xFFE53E3E)),
								],
							),
						),
						const SizedBox(height: 16),
					],
				),
			),
		);
	}
}
