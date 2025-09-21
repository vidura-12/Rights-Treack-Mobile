// lib/media.dart
// Extended with summarization support + UI for summary fields

import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class MediaPage extends StatefulWidget {
  const MediaPage({Key? key}) : super(key: key);

  @override
  State<MediaPage> createState() => _MediaPageState();
}

class Post {
  final List<String>? paths;
  final List<Uint8List>? bytes;
  final List<String>? imageUrls;
  final String description;
  final String userName;
  final String userAvatar;
  final List<String> comments;
  final Set<String> likedBy;
  final Map<String, String> summary; // NEW: structured summary

  Post({
    this.paths,
    this.bytes,
    this.imageUrls,
    required this.description,
    required this.userName,
    required this.userAvatar,
    this.comments = const [],
    Set<String>? likedBy,
    Map<String, String>? summary,
  })  : likedBy = likedBy ?? {},
        summary = summary ?? {};
}

class _MediaPageState extends State<MediaPage> {
  final TextEditingController _descController = TextEditingController();
  final List<Post> _posts = [];
  final Map<Post, TextEditingController> _commentControllers = {};

  List<String>? _selectedPaths;
  List<Uint8List>? _pickedBytes;

  final ImagePicker _picker = ImagePicker();

  final String currentUser = "You";
  final String currentUserAvatar =
      "https://cdn-icons-png.flaticon.com/512/149/149071.png";

  // 🔑 Optional: configure a backend endpoint for summarization
  final String? remoteSummarizerUrl = "http://localhost:3000/summarize"; // e.g. "https://your-api/summarize"
  final bool useRemoteSummarizer = true;

  bool _isSummarizing = false;

  @override
  void initState() {
    super.initState();
    _initDummyPost();
  }

  Future<void> _initDummyPost() async {
    final description =
        "Observed child labor in a factory in Colombo. Immediate action needed! Contact: 077-1234567. Reported to local NGO.";
    final summary = await _summarizeDescription(description);
    final dummyPost = Post(
      description: description,
      userName: "Kamal Perera",
      userAvatar: "https://cdn-icons-png.flaticon.com/512/147/147144.png",
      comments: [
        "We should report this to authorities.",
        "Awful! Thanks for sharing."
      ],
      imageUrls: ["https://picsum.photos/400/200"],
      summary: summary,
    );
    setState(() {
      _posts.add(dummyPost);
      _commentControllers[dummyPost] = TextEditingController();
    });
  }

  Future<void> _pickMedia() async {
    if (kIsWeb) {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
        allowMultiple: true,
      );
      if (result != null) {
        setState(() {
          _pickedBytes = result.files.map((f) => f.bytes!).toList();
          _selectedPaths = result.files.map((f) => f.name).toList();
        });
      }
    } else {
      final List<XFile>? files = await _picker.pickMultiImage();
      if (files != null && files.isNotEmpty) {
        setState(() {
          _selectedPaths = files.map((f) => f.path).toList();
        });
      }
    }
  }

  // 🔎 Summarization entry point
  Future<Map<String, String>> _summarizeDescription(String text) async {
    if (useRemoteSummarizer && remoteSummarizerUrl != null) {
      try {
        final resp = await http.post(
          Uri.parse(remoteSummarizerUrl!),
          body: jsonEncode({'text': text}),
          headers: {'Content-Type': 'application/json'},
        );
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body);
          return (data as Map<String, dynamic>)
              .map((k, v) => MapEntry(k, v?.toString() ?? ""));
        }
      } catch (_) {}
    }
    return _localHeuristicSummary(text); // fallback
  }

  Map<String, String> _localHeuristicSummary(String text) {
    final lower = text.toLowerCase();

    String caseType = '';
    if (lower.contains('child')) caseType = 'Child rights';
    if (lower.contains('arrest')) caseType = 'Arrest/Detention';
    if (lower.contains('torture')) caseType = 'Torture/Abuse';

    final phoneRe = RegExp(r'\\d{7,12}');
    final phone = phoneRe.firstMatch(text)?.group(0) ?? '';

    final placeRe = RegExp(r'in\\s+([A-Z][a-z]+)');
    final place = placeRe.firstMatch(text)?.group(1) ?? '';

    final actions = lower.contains('reported') ? 'Reported' : '';

    String short = text;
    if (short.length > 150) short = short.substring(0, 150) + '...';

    return {
      'case_type': caseType,
      'place': place,
      'date': '',
      'contact': phone,
      'actions': actions,
      'short_summary': short
    };
  }

  Future<void> _uploadPost() async {
    final description = _descController.text.trim();
    if ((_selectedPaths != null && _selectedPaths!.isNotEmpty) ||
        (_pickedBytes != null && _pickedBytes!.isNotEmpty) ||
        description.isNotEmpty) {
      setState(() { _isSummarizing = true; });
      final summary = await _summarizeDescription(description);
      setState(() { _isSummarizing = false; });
      final newPost = Post(
        paths: _selectedPaths,
        bytes: _pickedBytes,
        description: description,
        userName: currentUser,
        userAvatar: currentUserAvatar,
        summary: summary,
      );
      setState(() {
        _posts.insert(0, newPost);
        _commentControllers[newPost] = TextEditingController();
        _descController.clear();
        _selectedPaths = null;
        _pickedBytes = null;
      });
    }
  }

  void _toggleLike(Post post) {
    setState(() {
      if (post.likedBy.contains(currentUser)) {
        post.likedBy.remove(currentUser);
      } else {
        post.likedBy.add(currentUser);
      }
    });
  }

  void _addComment(Post post, String comment) {
    setState(() {
      post.comments.add(comment);
    });
  }

  Widget _buildImages(Post post) {
    if (post.imageUrls != null && post.imageUrls!.isNotEmpty) {
      return Image.network(post.imageUrls!.first,
          height: 200, fit: BoxFit.cover);
    }

    final images = kIsWeb ? post.bytes : post.paths;
    if (images == null || images.isEmpty) return const SizedBox.shrink();

    return kIsWeb
        ? Image.memory(post.bytes!.first, height: 200, fit: BoxFit.cover)
        : Image.file(File(post.paths!.first), height: 200, fit: BoxFit.cover);
  }

  @override
  Widget build(BuildContext context) {
    const darkBlue = Color(0xFF0A1628);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: darkBlue,
        title: const Text("Media on Human Rights Abuses"),
      ),
      body: Column(
        children: [
          if (_isSummarizing)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          // Composer
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: _descController,
                    decoration: const InputDecoration(
                      hintText: "What's on your mind?",
                      border: InputBorder.none,
                    ),
                    maxLines: null,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: _pickMedia,
                        icon: const Icon(Icons.photo, color: darkBlue),
                        label: const Text("Add Photo"),
                      ),
                      ElevatedButton(
                        onPressed: _uploadPost,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: darkBlue),
                        child: const Text("Share"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          // Feed
          Expanded(
            child: ListView.builder(
              itemCount: _posts.length,
              itemBuilder: (context, index) {
                final post = _posts[index];
                final commentController =
                    _commentControllers[post] ??= TextEditingController();
                return Card(
                  margin: const EdgeInsets.all(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundImage: NetworkImage(post.userAvatar),
                            ),
                            const SizedBox(width: 8),
                            Text(post.userName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildImages(post),
                        if (post.description.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(post.description),
                        ],
                        if (post.summary.isNotEmpty) ...[
                          const Divider(),
                          Wrap(
                            spacing: 8,
                            children: [
                              if ((post.summary['case_type'] ?? '').isNotEmpty)
                                Chip(label: Text("Case: ${post.summary['case_type']}")),
                              if ((post.summary['place'] ?? '').isNotEmpty)
                                Chip(label: Text("Place: ${post.summary['place']}")),
                              if ((post.summary['contact'] ?? '').isNotEmpty)
                                Chip(label: Text("Contact: ${post.summary['contact']}")),
                              if ((post.summary['actions'] ?? '').isNotEmpty)
                                Chip(label: Text("Action: ${post.summary['actions']}")),
                              if ((post.summary['date'] ?? '').isNotEmpty)
                                Chip(label: Text("Date: ${post.summary['date']}")),
                              if ((post.summary['short_summary'] ?? '').isNotEmpty)
                                Chip(label: Text("Summary: ${post.summary['short_summary']}")),
                            ],
                          )
                        ],
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                post.likedBy.contains(currentUser)
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: post.likedBy.contains(currentUser)
                                    ? Colors.red
                                    : null,
                              ),
                              onPressed: () => _toggleLike(post),
                            ),
                            Text("${post.likedBy.length} likes"),
                          ],
                        ),
                        TextField(
                          controller: commentController,
                          decoration: const InputDecoration(
                              hintText: "Add a comment..."),
                          onSubmitted: (val) {
                            if (val.isNotEmpty) {
                              _addComment(post, val);
                              commentController.clear();
                              setState(() {});
                            }
                          },
                        ),
                        ...post.comments
                            .map((c) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 2),
                                  child: Text("💬 $c"),
                                ))
                            .toList(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
