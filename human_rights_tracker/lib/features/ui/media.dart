import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class MediaPage extends StatefulWidget {
  final bool isDarkTheme;
  
  const MediaPage({super.key, required this.isDarkTheme});

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
  final Map<String, String> summary;

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

  final String? remoteSummarizerUrl = "http://localhost:3000/summarize"; 
  final bool useRemoteSummarizer = true;

  bool _isSummarizing = false;

  // Theme colors based on parent theme
  Color get _backgroundColor => widget.isDarkTheme ? const Color(0xFF0A1628) : Colors.white;
  Color get _cardColor => widget.isDarkTheme ? const Color(0xFF1A243A) : const Color(0xFFFAFAFA);
  Color get _appBarColor => widget.isDarkTheme ? const Color(0xFF0A1628) : Colors.white;
  Color get _textColor => widget.isDarkTheme ? Colors.white : Colors.black87;
  Color get _secondaryTextColor => widget.isDarkTheme ? Colors.grey[400]! : Colors.grey[600]!;
  Color get _iconColor => widget.isDarkTheme ? Colors.white : Colors.black87;
  Color get _accentColor => const Color(0xFFE53E3E);
  Color get _dividerColor => widget.isDarkTheme ? const Color(0xFF2D3748) : Colors.grey[300]!;
  Color get _inputBackgroundColor => widget.isDarkTheme ? const Color(0xFF2D3748) : Colors.grey[100]!;
  Color get _chipBackgroundColor => widget.isDarkTheme ? const Color(0xFF2D3748) : Colors.grey[200]!;
  Color get _chipTextColor => widget.isDarkTheme ? Colors.white : Colors.black87;

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
      final List<XFile> files = await _picker.pickMultiImage();
      if (files.isNotEmpty) {
        setState(() {
          _selectedPaths = files.map((f) => f.path).toList();
        });
      }
    }
  }

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

    final phoneRe = RegExp(r'\d{7,12}');
    final phone = phoneRe.firstMatch(text)?.group(0) ?? '';

    final placeRe = RegExp(r'in\s+([A-Z][a-z]+)');
    final place = placeRe.firstMatch(text)?.group(1) ?? '';

    final actions = lower.contains('reported') ? 'Reported' : '';

    String short = text;
    if (short.length > 150) short = '${short.substring(0, 150)}...';

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
      return Image.network(
        post.imageUrls!.first,
        height: 200, 
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }

    final images = kIsWeb ? post.bytes : post.paths;
    if (images == null || images.isEmpty) return const SizedBox.shrink();

    return kIsWeb
        ? Image.memory(
            post.bytes!.first, 
            height: 200, 
            width: double.infinity,
            fit: BoxFit.cover,
          )
        : Image.file(
            File(post.paths!.first), 
            height: 200, 
            width: double.infinity,
            fit: BoxFit.cover,
          );
  }

  Widget _buildSummaryChips(Post post) {
    final summary = post.summary;
    if (summary.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Case Summary:',
          style: TextStyle(
            color: _textColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if ((summary['case_type'] ?? '').isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _chipBackgroundColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Case: ${summary['case_type']}",
                  style: TextStyle(
                    color: _chipTextColor,
                    fontSize: 12,
                  ),
                ),
              ),
            if ((summary['place'] ?? '').isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _chipBackgroundColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Place: ${summary['place']}",
                  style: TextStyle(
                    color: _chipTextColor,
                    fontSize: 12,
                  ),
                ),
              ),
            if ((summary['contact'] ?? '').isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _chipBackgroundColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Contact: ${summary['contact']}",
                  style: TextStyle(
                    color: _chipTextColor,
                    fontSize: 12,
                  ),
                ),
              ),
            if ((summary['actions'] ?? '').isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _chipBackgroundColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Action: ${summary['actions']}",
                  style: TextStyle(
                    color: _chipTextColor,
                    fontSize: 12,
                  ),
                ),
              ),
            if ((summary['date'] ?? '').isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _chipBackgroundColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Date: ${summary['date']}",
                  style: TextStyle(
                    color: _chipTextColor,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        if ((summary['short_summary'] ?? '').isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _chipBackgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              summary['short_summary']!,
              style: TextStyle(
                color: _chipTextColor,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _appBarColor,
        elevation: 0,
        title: Text(
          "Media on Human Rights Abuses",
          style: TextStyle(
            color: _textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: _iconColor),
      ),
      body: Column(
        children: [
          if (_isSummarizing)
            Container(
              padding: const EdgeInsets.all(8.0),
              color: _backgroundColor,
              child: Center(
                child: CircularProgressIndicator(color: _accentColor),
              ),
            ),
          // Composer
          Card(
            margin: const EdgeInsets.all(12),
            color: _cardColor,
            elevation: widget.isDarkTheme ? 4 : 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: _inputBackgroundColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _descController,
                      style: TextStyle(color: _textColor),
                      decoration: InputDecoration(
                        hintText: "What's on your mind?",
                        hintStyle: TextStyle(color: _secondaryTextColor),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: _pickMedia,
                        icon: Icon(Icons.photo, color: _accentColor),
                        label: Text(
                          "Add Photo",
                          style: TextStyle(color: _accentColor),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _uploadPost,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("Share"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Divider(color: _dividerColor, thickness: 1),
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
                  color: _cardColor,
                  elevation: widget.isDarkTheme ? 4 : 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User info
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundImage: NetworkImage(post.userAvatar),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              post.userName,
                              style: TextStyle(
                                color: _textColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Image
                        _buildImages(post),
                        
                        // Description
                        if (post.description.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            post.description,
                            style: TextStyle(
                              color: _textColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                        
                        // Summary
                        _buildSummaryChips(post),
                        
                        // Likes section
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                post.likedBy.contains(currentUser)
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: post.likedBy.contains(currentUser)
                                    ? _accentColor
                                    : _secondaryTextColor,
                              ),
                              onPressed: () => _toggleLike(post),
                            ),
                            Text(
                              "${post.likedBy.length} likes",
                              style: TextStyle(
                                color: _secondaryTextColor,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        
                        // Comments section
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: _inputBackgroundColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            controller: commentController,
                            style: TextStyle(color: _textColor),
                            decoration: InputDecoration(
                              hintText: "Add a comment...",
                              hintStyle: TextStyle(color: _secondaryTextColor),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(12),
                            ),
                            onSubmitted: (val) {
                              if (val.isNotEmpty) {
                                _addComment(post, val);
                                commentController.clear();
                                setState(() {});
                              }
                            },
                          ),
                        ),
                        
                        // Existing comments
                        if (post.comments.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          ...post.comments.map((comment) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.comment,
                                      color: _secondaryTextColor,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        comment,
                                        style: TextStyle(
                                          color: _textColor,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
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