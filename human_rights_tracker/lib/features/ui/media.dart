import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class MediaPage extends StatefulWidget {
  final bool isDarkTheme;
  
  const MediaPage({super.key, required this.isDarkTheme});

  @override
  State<MediaPage> createState() => _MediaPageState();
}

class _MediaPageState extends State<MediaPage> {
  final TextEditingController _descController = TextEditingController();
  final Map<String, TextEditingController> _commentControllers = {};

  List<String>? _selectedPaths;
  List<Uint8List>? _pickedBytes;

  final ImagePicker _picker = ImagePicker();

  final String? remoteSummarizerUrl = "http://localhost:3000/summarize";
  final bool useRemoteSummarizer = false;

  bool _isUploading = false;

  // Modern theme colors
  Color get _backgroundColor => widget.isDarkTheme ? const Color(0xFF0F1419) : const Color(0xFFF8FAFC);
  Color get _cardColor => widget.isDarkTheme ? const Color(0xFF1C2128) : Colors.white;
  Color get _textColor => widget.isDarkTheme ? Colors.white : Colors.black87;
  Color get _secondaryTextColor => widget.isDarkTheme ? Colors.grey[400]! : Colors.grey[600]!;
  Color get _accentColor => const Color(0xFF6366F1);
  Color get _inputBackgroundColor => widget.isDarkTheme ? const Color(0xFF1C2128) : Colors.white;
  Color get _chipBackgroundColor => widget.isDarkTheme ? const Color(0xFF2D3748) : const Color(0xFFF1F5F9);

  User? get currentUser => FirebaseAuth.instance.currentUser;

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

  Future<List<String>> _uploadImages() async {
    List<String> imageUrls = [];
    
    if (kIsWeb && _pickedBytes != null) {
      for (int i = 0; i < _pickedBytes!.length; i++) {
        final fileName = 'posts/${currentUser!.uid}/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final ref = FirebaseStorage.instance.ref().child(fileName);
        await ref.putData(_pickedBytes![i]);
        final url = await ref.getDownloadURL();
        imageUrls.add(url);
      }
    } else if (_selectedPaths != null) {
      for (int i = 0; i < _selectedPaths!.length; i++) {
        final fileName = 'posts/${currentUser!.uid}/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final ref = FirebaseStorage.instance.ref().child(fileName);
        await ref.putFile(File(_selectedPaths![i]));
        final url = await ref.getDownloadURL();
        imageUrls.add(url);
      }
    }
    
    return imageUrls;
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
    return _localHeuristicSummary(text);
  }

  Map<String, String> _localHeuristicSummary(String text) {
    final lower = text.toLowerCase();

    String caseType = '';
    if (lower.contains('child')) caseType = 'Child rights';
    if (lower.contains('arrest')) caseType = 'Arrest/Detention';
    if (lower.contains('torture')) caseType = 'Torture/Abuse';
    if (lower.contains('discrimination')) caseType = 'Discrimination';

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

  Future<void> _saveNotification(String postId, String action) async {
    try {
      final notificationData = {
        "title": "New $action",
        "message": "${currentUser!.email} $action a post",
        "type": "media_post",
        "postId": postId,
        "reportedBy": currentUser!.email,
        "timestamp": FieldValue.serverTimestamp(),
        "read": false,
      };

      await FirebaseFirestore.instance
          .collection("notifications")
          .add(notificationData);
    } catch (e) {
      debugPrint("Error saving notification: $e");
    }
  }

  Future<void> _uploadPost() async {
    final description = _descController.text.trim();
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to post')),
      );
      return;
    }

    if (description.isEmpty && _selectedPaths == null && _pickedBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add content or images')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final imageUrls = await _uploadImages();
      final summary = await _summarizeDescription(description);

      final postData = {
        'description': description,
        'imageUrls': imageUrls,
        'userId': currentUser!.uid,
        'userEmail': currentUser!.email,
        'userName': currentUser!.displayName ?? currentUser!.email!.split('@')[0],
        'timestamp': FieldValue.serverTimestamp(),
        'likes': [],
        'likeCount': 0,
        'commentCount': 0,
        'summary': summary,
      };

      final docRef = await FirebaseFirestore.instance
          .collection('media_posts')
          .add(postData);

      await _saveNotification(docRef.id, "created");

      setState(() {
        _descController.clear();
        _selectedPaths = null;
        _pickedBytes = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post shared successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error posting: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _toggleLike(String postId, List<dynamic> currentLikes) async {
    if (currentUser == null) return;

    final userId = currentUser!.uid;
    final postRef = FirebaseFirestore.instance.collection('media_posts').doc(postId);

    if (currentLikes.contains(userId)) {
      await postRef.update({
        'likes': FieldValue.arrayRemove([userId]),
        'likeCount': FieldValue.increment(-1),
      });
    } else {
      await postRef.update({
        'likes': FieldValue.arrayUnion([userId]),
        'likeCount': FieldValue.increment(1),
      });
    }
  }

  Future<void> _addComment(String postId, String comment) async {
    if (currentUser == null || comment.trim().isEmpty) return;

    final commentData = {
      'postId': postId,
      'userId': currentUser!.uid,
      'userEmail': currentUser!.email,
      'userName': currentUser!.displayName ?? currentUser!.email!.split('@')[0],
      'comment': comment.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance.collection('comments').add(commentData);

    await FirebaseFirestore.instance
        .collection('media_posts')
        .doc(postId)
        .update({
      'commentCount': FieldValue.increment(1),
    });

    _commentControllers[postId]?.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.photo_library, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Community Feed',
              style: TextStyle(
                color: _textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Post Composer
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: _accentColor.withOpacity(0.2),
                      child: Icon(Icons.person, color: _accentColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: _inputBackgroundColor,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: widget.isDarkTheme
                                  ? Colors.grey[700]!
                                  : Colors.grey[300]!,
                            ),
                          ),
                          child: Text(
                            'Share your thoughts...',
                            style: TextStyle(
                              color: _secondaryTextColor,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_selectedPaths != null || _pickedBytes != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: _chipBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(
                            Icons.image,
                            color: _accentColor,
                            size: 40,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedPaths = null;
                                _pickedBytes = null;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: _pickMedia,
                      icon: Icon(Icons.image_outlined, color: _accentColor, size: 20),
                      label: Text(
                        'Photo',
                        style: TextStyle(color: _accentColor, fontSize: 14),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _isUploading ? null : () => _showPostDialog(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                      child: _isUploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Post'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Posts Feed
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('media_posts')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading posts',
                      style: TextStyle(color: _textColor),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: _accentColor),
                  );
                }

                final posts = snapshot.data?.docs ?? [];

                if (posts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.photo_library_outlined,
                          size: 64,
                          color: _secondaryTextColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No posts yet',
                          style: TextStyle(
                            color: _textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Be the first to share',
                          style: TextStyle(
                            color: _secondaryTextColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    final postData = post.data() as Map<String, dynamic>;
                    final postId = post.id;

                    return _buildPostCard(postId, postData);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(String postId, Map<String, dynamic> postData) {
    final likes = List<String>.from(postData['likes'] ?? []);
    final isLiked = currentUser != null && likes.contains(currentUser!.uid);
    final imageUrls = List<String>.from(postData['imageUrls'] ?? []);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _accentColor.withOpacity(0.2),
                  child: Icon(Icons.person, color: _accentColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        postData['userName'] ?? 'Anonymous',
                        style: TextStyle(
                          color: _textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        _formatTimestamp(postData['timestamp']),
                        style: TextStyle(
                          color: _secondaryTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Post description
          if (postData['description'] != null && postData['description'].isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                postData['description'],
                style: TextStyle(
                  color: _textColor,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),

          // Images
          if (imageUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrls.first,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 250,
                    color: _chipBackgroundColor,
                    child: Icon(
                      Icons.broken_image,
                      color: _secondaryTextColor,
                      size: 48,
                    ),
                  );
                },
              ),
            ),
          ],

          // Summary chips
          if (postData['summary'] != null)
            _buildSummaryChips(postData['summary'] as Map<String, dynamic>),

          // Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                InkWell(
                  onTap: () => _toggleLike(postId, likes),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isLiked
                          ? _accentColor.withOpacity(0.1)
                          : _chipBackgroundColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? _accentColor : _secondaryTextColor,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${postData['likeCount'] ?? 0}',
                          style: TextStyle(
                            color: isLiked ? _accentColor : _textColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () => _showCommentsSheet(postId),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _chipBackgroundColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          color: _secondaryTextColor,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${postData['commentCount'] ?? 0}',
                          style: TextStyle(
                            color: _textColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChips(Map<String, dynamic> summary) {
    if (summary.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if ((summary['case_type'] ?? '').isNotEmpty)
            _buildChip('${summary['case_type']}', Icons.category_outlined),
          if ((summary['place'] ?? '').isNotEmpty)
            _buildChip('${summary['place']}', Icons.location_on_outlined),
          if ((summary['contact'] ?? '').isNotEmpty)
            _buildChip('${summary['contact']}', Icons.phone_outlined),
        ],
      ),
    );
  }

  Widget _buildChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _chipBackgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _accentColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: _textColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Just now';
    
    try {
      final DateTime dateTime = (timestamp as Timestamp).toDate();
      final Duration diff = DateTime.now().difference(dateTime);

      if (diff.inDays > 0) {
        return '${diff.inDays}d ago';
      } else if (diff.inHours > 0) {
        return '${diff.inHours}h ago';
      } else if (diff.inMinutes > 0) {
        return '${diff.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Just now';
    }
  }

  void _showPostDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Create Post',
          style: TextStyle(color: _textColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _descController,
              style: TextStyle(color: _textColor),
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'What\'s happening?',
                hintStyle: TextStyle(color: _secondaryTextColor),
                filled: true,
                fillColor: _inputBackgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: _secondaryTextColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _uploadPost();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }

  void _showCommentsSheet(String postId) {
    _commentControllers[postId] ??= TextEditingController();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _secondaryTextColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Comments',
                style: TextStyle(
                  color: _textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('comments')
                    .where('postId', isEqualTo: postId)
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(color: _accentColor),
                    );
                  }

                  final comments = snapshot.data!.docs;

                  if (comments.isEmpty) {
                    return Center(
                      child: Text(
                        'No comments yet',
                        style: TextStyle(color: _secondaryTextColor),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index].data() as Map<String, dynamic>;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: _accentColor.withOpacity(0.2),
                              child: Icon(Icons.person, color: _accentColor, size: 16),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    comment['userName'] ?? 'Anonymous',
                                    style: TextStyle(
                                      color: _textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    comment['comment'] ?? '',
                                    style: TextStyle(
                                      color: _textColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _cardColor,
                border: Border(
                  top: BorderSide(
                    color: widget.isDarkTheme
                        ? Colors.grey[800]!
                        : Colors.grey[200]!,
                  ),
                ),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentControllers[postId],
                        style: TextStyle(color: _textColor),
                        decoration: InputDecoration(
                          hintText: 'Add a comment...',
                          hintStyle: TextStyle(color: _secondaryTextColor),
                          filled: true,
                          fillColor: _inputBackgroundColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: widget.isDarkTheme
                                  ? Colors.grey[700]!
                                  : Colors.grey[300]!,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: widget.isDarkTheme
                                  ? Colors.grey[700]!
                                  : Colors.grey[300]!,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send_rounded, color: Colors.white),
                        onPressed: () {
                          final comment = _commentControllers[postId]?.text ?? '';
                          if (comment.isNotEmpty) {
                            _addComment(postId, comment);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _descController.dispose();
    for (var controller in _commentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}