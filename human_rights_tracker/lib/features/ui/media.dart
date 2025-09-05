import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class MediaPage extends StatefulWidget {
  const MediaPage({Key? key}) : super(key: key);

  @override
  State<MediaPage> createState() => _MediaPageState();
}

class Post {
  final List<String>? paths; // mobile/desktop file paths
  final List<Uint8List>? bytes; // web file data
  final List<String>? imageUrls; // network images
  final String description;
  final String userName;
  final String userAvatar;
  final List<String> comments;
  final Set<String> likedBy;

  Post({
    this.paths,
    this.bytes,
    this.imageUrls,
    required this.description,
    required this.userName,
    required this.userAvatar,
    this.comments = const [],
    Set<String>? likedBy,
  }) : likedBy = likedBy ?? {};
}

class _MediaPageState extends State<MediaPage> {
  final TextEditingController _descController = TextEditingController();
  final List<Post> _posts = [];

  List<String>? _selectedPaths;
  List<Uint8List>? _pickedBytes;

  final ImagePicker _picker = ImagePicker();

  final String currentUser = "You";
  final String currentUserAvatar =
      "https://cdn-icons-png.flaticon.com/512/149/149071.png"; // simple clipart

  @override
  void initState() {
    super.initState();
    // Add dummy post with network image
    _posts.add(
      Post(
        description:
            "Observed child labor in a factory in Colombo. Immediate action needed!",
        userName: "Kamal Perera",
        userAvatar: "https://randomuser.me/api/portraits/men/32.jpg",
        comments: ["We should report this to authorities.", "Awful! Thanks for sharing."],
        imageUrls: [
          "https://images.unsplash.com/photo-1581093588401-57f1d338ea7f?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=MnwxMjA3fDB8MXxzZWFyY2h8MXx8Y2hpbGQlMjBsYWJvcnxlbnwwfHx8fDE2OTMxOTg4Njk&ixlib=rb-4.0.3&q=80&w=400"
        ],
      ),
    );
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

  void _uploadPost() {
    if ((_selectedPaths != null && _selectedPaths!.isNotEmpty) ||
        (_pickedBytes != null && _pickedBytes!.isNotEmpty) ||
        _descController.text.isNotEmpty) {
      setState(() {
        _posts.insert(
          0,
          Post(
            paths: _selectedPaths,
            bytes: _pickedBytes,
            description: _descController.text,
            userName: currentUser,
            userAvatar: currentUserAvatar,
          ),
        );
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
    final images = kIsWeb ? post.bytes : post.paths;

    // If there are network images in dummy post, use them
    if (post.imageUrls != null && post.imageUrls!.isNotEmpty) {
      return SizedBox(
        height: 200,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: post.imageUrls!
              .map((url) => Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(url, height: 200, fit: BoxFit.cover)),
                  ))
              .toList(),
        ),
      );
    }

    if (images == null || images.isEmpty) return const SizedBox.shrink();

    List<Widget> imageWidgets = [];
    int total = images.length;
    int displayCount = total > 3 ? 3 : total;

    for (int i = 0; i < displayCount; i++) {
      Widget img = kIsWeb
          ? Image.memory(post.bytes![i], fit: BoxFit.cover)
          : Image.file(File(post.paths![i]), fit: BoxFit.cover);
      imageWidgets.add(Expanded(
        child: Container(
          margin: const EdgeInsets.all(2),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: img,
          ),
        ),
      ));
    }

    Widget overlay = total > 3
        ? Positioned.fill(
            child: Container(
              color: Colors.black45,
              alignment: Alignment.center,
              child: Text(
                "#${total - 1} more",
                style: const TextStyle(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          )
        : const SizedBox.shrink();

    return SizedBox(
      height: 200,
      child: Stack(
        children: [
          Row(children: imageWidgets),
          overlay,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const darkBlue = Color(0xFF0A1628);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Human Rights Cases', style: TextStyle(color: Colors.white)),
        backgroundColor: darkBlue,
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Post creation box
            Card(
              margin: const EdgeInsets.all(12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _descController,
                      decoration: const InputDecoration(
                        hintText: "Share a human rights case...",
                        border: InputBorder.none,
                      ),
                      maxLines: null,
                    ),
                    if ((_pickedBytes != null && _pickedBytes!.isNotEmpty) ||
                        (_selectedPaths != null && _selectedPaths!.isNotEmpty)) ...[
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: (kIsWeb
                                  ? _pickedBytes!.map((b) => Image.memory(b, height: 100, fit: BoxFit.cover))
                                  : _selectedPaths!.map((p) => Image.file(File(p), height: 100, fit: BoxFit.cover)))
                              .map((img) => Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: img,
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: _pickMedia,
                          icon: const Icon(Icons.photo, color: darkBlue),
                          label: const Text("Add Photos", style: TextStyle(color: darkBlue)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: darkBlue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _uploadPost,
                          child: const Text("Share", style: TextStyle(color: Colors.white)),
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
              child: _posts.isEmpty
                  ? const Center(
                      child: Text("No cases shared yet", style: TextStyle(color: Colors.black54)),
                    )
                  : ListView.builder(
                      itemCount: _posts.length,
                      itemBuilder: (context, index) {
                        final post = _posts[index];
                        final commentController = TextEditingController();
                        bool showComments = false;

                        return StatefulBuilder(
                          builder: (context, setInnerState) {
                            return Card(
                              margin: const EdgeInsets.all(12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 5,
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
                                          radius: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(post.userName,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    _buildImages(post),
                                    if (post.description.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(post.description, style: const TextStyle(fontSize: 15)),
                                    ],
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(post.likedBy.contains(currentUser) ? Icons.favorite : Icons.favorite_border,
                                              color: post.likedBy.contains(currentUser) ? Colors.red : null),
                                          onPressed: () => _toggleLike(post),
                                        ),
                                        Text("${post.likedBy.length} likes"),
                                        const Spacer(),
                                        TextButton(
                                          onPressed: () => setInnerState(() => showComments = !showComments),
                                          child: Text(showComments ? "Hide comments" : "View comments", style: const TextStyle(color: darkBlue)),
                                        ),
                                      ],
                                    ),
                                    if (showComments) ...[
                                      const Divider(),
                                      ...post.comments.map((c) => Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 2),
                                            child: Row(children: [
                                              const Icon(Icons.comment, size: 16, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Expanded(child: Text(c)),
                                            ]),
                                          )),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: commentController,
                                              decoration: const InputDecoration(hintText: "Add a comment..."),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.send, color: darkBlue),
                                            onPressed: () {
                                              if (commentController.text.isNotEmpty) {
                                                _addComment(post, commentController.text);
                                                commentController.clear();
                                                setInnerState(() {});
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
