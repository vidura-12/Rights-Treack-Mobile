import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'case_charts_page.dart';

class CaseListPage extends StatefulWidget {
  const CaseListPage({super.key});

  @override
  State<CaseListPage> createState() => _CaseListPageState();
}

class _CaseListPageState extends State<CaseListPage> {
  String _searchQuery = "";
  bool _isDarkTheme = true;

  final List<String> statuses = [
    'Open',
    'In Progress',
    'Investigation',
    'In Court',
    'Resolved',
    'Closed',
  ];

  // Theme colors
  Color get _backgroundColor =>
      _isDarkTheme ? const Color(0xFF0F1419) : const Color(0xFFF8FAFC);
  Color get _cardColor => _isDarkTheme ? const Color(0xFF1C2128) : Colors.white;
  Color get _appBarColor =>
      _isDarkTheme ? const Color(0xFF1C2128) : Colors.white;
  Color get _textColor => _isDarkTheme ? Colors.white : Colors.black87;
  Color get _secondaryTextColor =>
      _isDarkTheme ? Colors.grey[400]! : Colors.grey[600]!;
  Color get _iconColor => _isDarkTheme ? Colors.white : Colors.black87;
  Color get _accentColor => const Color(0xFF6366F1);
  Color get _inputBackgroundColor =>
      _isDarkTheme ? const Color(0xFF2D3748) : Colors.grey[100]!;
  Color get _chipBackgroundColor =>
      _isDarkTheme ? const Color(0xFF2D3748) : const Color(0xFFF1F5F9);

  void _toggleTheme() {
    setState(() {
      _isDarkTheme = !_isDarkTheme;
    });
  }

  // Helper method to display base64 images
  Widget _buildImage(String? imageData) {
    if (imageData == null || imageData.isEmpty) {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _chipBackgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt, color: _secondaryTextColor, size: 50),
            const SizedBox(height: 8),
            Text(
              'No Image',
              style: TextStyle(color: _secondaryTextColor, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (imageData.startsWith('data:image')) {
      // Base64 image
      try {
        final base64Data = imageData.split(',').last;
        final bytes = base64Decode(base64Data);
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            bytes,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 200,
                decoration: BoxDecoration(
                  color: _chipBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.broken_image,
                      color: _secondaryTextColor,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Failed to load image',
                      style: TextStyle(
                        color: _secondaryTextColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      } catch (e) {
        return Container(
          height: 200,
          decoration: BoxDecoration(
            color: _chipBackgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: _secondaryTextColor, size: 48),
              const SizedBox(height: 8),
              Text(
                'Invalid image data',
                style: TextStyle(color: _secondaryTextColor, fontSize: 14),
              ),
            ],
          ),
        );
      }
    } else {
      // Regular URL (fallback)
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageData,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 200,
              decoration: BoxDecoration(
                color: _chipBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image,
                    color: _secondaryTextColor,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to load image',
                    style: TextStyle(color: _secondaryTextColor, fontSize: 14),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          "My Reported Cases",
          style: TextStyle(color: _textColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: _appBarColor,
        elevation: 4,
        iconTheme: IconThemeData(color: _iconColor),
        actions: [
          IconButton(
            icon: Icon(
              _isDarkTheme ? Icons.light_mode : Icons.dark_mode,
              color: _iconColor,
            ),
            onPressed: _toggleTheme,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: _inputBackgroundColor,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                style: TextStyle(color: _textColor),
                decoration: InputDecoration(
                  hintText: "🔍 Search cases...",
                  hintStyle: TextStyle(color: _secondaryTextColor),
                  filled: true,
                  fillColor: Colors.transparent,
                  prefixIcon: Icon(Icons.search, color: _secondaryTextColor),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide(color: _accentColor, width: 2),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
          ),
        ),
      ),
      body: userEmail == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: _secondaryTextColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "You must be logged in to view cases.",
                    style: TextStyle(fontSize: 16, color: _secondaryTextColor),
                  ),
                ],
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("cases")
                  .where("reportedByEmail", isEqualTo: userEmail)
                  .orderBy("createdAt", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: _accentColor),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          "Error loading cases",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: _secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accentColor,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text("Try Again"),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 64,
                          color: _secondaryTextColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No cases reported yet.",
                          style: TextStyle(
                            fontSize: 18,
                            color: _secondaryTextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Start by reporting your first case",
                          style: TextStyle(
                            fontSize: 14,
                            color: _secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final cases = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final text =
                      "${data['category']} ${data['location']} ${data['status']}"
                          .toLowerCase();
                  return text.contains(_searchQuery);
                }).toList();

                if (cases.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: _secondaryTextColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No matching cases found.",
                          style: TextStyle(
                            fontSize: 18,
                            color: _secondaryTextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Try adjusting your search terms",
                          style: TextStyle(
                            fontSize: 14,
                            color: _secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cases.length,
                  itemBuilder: (context, index) {
                    final doc = cases[index];
                    final caseData = doc.data() as Map<String, dynamic>;
                    final status = caseData['status'] ?? 'Open';

                    final currentStep = statuses.indexWhere(
                      (s) => s.toLowerCase() == status.toLowerCase(),
                    );
                    final progress = currentStep >= 0
                        ? (currentStep + 1) / statuses.length
                        : 0.0;

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header with status and actions
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(
                                      status,
                                    ).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _getStatusColor(
                                        status,
                                      ).withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: TextStyle(
                                      color: _getStatusColor(status),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit,
                                        color: _accentColor,
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => CaseDetailsPage(
                                              caseId: doc.id,
                                              caseData: caseData,
                                              isDarkTheme: _isDarkTheme,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            backgroundColor: _cardColor,
                                            title: Text(
                                              "Delete Case",
                                              style: TextStyle(
                                                color: _textColor,
                                              ),
                                            ),
                                            content: Text(
                                              "Are you sure you want to delete this case?",
                                              style: TextStyle(
                                                color: _secondaryTextColor,
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, false),
                                                child: Text(
                                                  "Cancel",
                                                  style: TextStyle(
                                                    color: _secondaryTextColor,
                                                  ),
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, true),
                                                child: const Text(
                                                  "Delete",
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirm == true) {
                                          await FirebaseFirestore.instance
                                              .collection("cases")
                                              .doc(doc.id)
                                              .delete();
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Progress bar
                            LinearProgressIndicator(
                              value: progress,
                              backgroundColor: _chipBackgroundColor,
                              color: _getStatusColor(status),
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(3),
                            ),

                            const SizedBox(height: 12),

                            // Progress steps
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: statuses.map((s) {
                                final stepIndex = statuses.indexOf(s);
                                final isCompleted = stepIndex <= currentStep;
                                return Column(
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: isCompleted
                                            ? _getStatusColor(status)
                                            : _chipBackgroundColor,
                                        shape: BoxShape.circle,
                                        border: isCompleted
                                            ? null
                                            : Border.all(
                                                color: _secondaryTextColor
                                                    .withOpacity(0.3),
                                              ),
                                      ),
                                      child: isCompleted
                                          ? Icon(
                                              Icons.check,
                                              size: 12,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      s,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: isCompleted
                                            ? _getStatusColor(status)
                                            : _secondaryTextColor,
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),

                            const SizedBox(height: 20),

                            // Case details
                            _buildInfoRow(
                              icon: Icons.category,
                              iconColor: _accentColor,
                              text: caseData['category'] ?? 'Not specified',
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              icon: Icons.location_on,
                              iconColor: Colors.redAccent,
                              text:
                                  caseData['location'] ??
                                  'Location not specified',
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              icon: Icons.person,
                              iconColor: Colors.blue,
                              text:
                                  "Victim: ${caseData['victimGender'] ?? 'Not specified'}",
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              icon: Icons.person_off,
                              iconColor: Colors.orange,
                              text:
                                  "Abuser: ${caseData['abuserGender'] ?? 'Not specified'}",
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              icon: Icons.date_range,
                              iconColor: Colors.green,
                              text:
                                  "From: ${_formatDate(caseData['fromDate'])}\nTo: ${_formatDate(caseData['toDate'])}",
                              isMultiLine: true,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String text,
    bool isMultiLine = false,
  }) {
    return Row(
      crossAxisAlignment: isMultiLine
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: _textColor,
              height: isMultiLine ? 1.4 : 1.2,
            ),
            maxLines: isMultiLine ? 2 : 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'open':
        return const Color(0xFFF59E0B);
      case 'in progress':
        return const Color(0xFF3B82F6);
      case 'investigation':
        return const Color(0xFF8B5CF6);
      case 'in court':
        return const Color(0xFFEF4444);
      case 'resolved':
        return const Color(0xFF10B981);
      case 'closed':
        return const Color(0xFF6B7280);
      default:
        return _accentColor;
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Not specified';
    if (date is Timestamp) {
      final d = date.toDate();
      return "${d.day}/${d.month}/${d.year}";
    }
    if (date is String) {
      try {
        final d = DateTime.parse(date);
        return "${d.day}/${d.month}/${d.year}";
      } catch (e) {
        return date;
      }
    }
    return date.toString();
  }
}

class CaseDetailsPage extends StatefulWidget {
  final String caseId;
  final Map<String, dynamic> caseData;
  final bool isDarkTheme;

  const CaseDetailsPage({
    super.key,
    required this.caseId,
    required this.caseData,
    required this.isDarkTheme,
  });

  @override
  State<CaseDetailsPage> createState() => _CaseDetailsPageState();
}

class _CaseDetailsPageState extends State<CaseDetailsPage> {
  late TextEditingController descriptionController;
  late TextEditingController locationController;
  File? _newImage;
  Uint8List? _pickedBytes;

  final List<String> categories = [
    'Human Trafficking',
    'Gender-Based Violence',
    'Child Abuse',
    'Sextortion',
    'Rape',
    'Domestic Abuse',
    'Jungle Justice',
    'Other Abuses',
  ];

  final List<String> genders = [
    'Male',
    'Female',
    'Non-binary',
    'Prefer not to Say',
  ];
  final List<String> abusers = ['Male', 'Female', 'Prefer not to Say'];

  final List<String> statuses = [
    'Open',
    'In Progress',
    'Investigation',
    'In Court',
    'Resolved',
    'Closed',
  ];

  String? selectedCategory;
  String? selectedVictim;
  String? selectedAbuser;
  String? selectedStatus;

  // Theme colors
  Color get _backgroundColor =>
      widget.isDarkTheme ? const Color(0xFF0F1419) : const Color(0xFFF8FAFC);
  Color get _cardColor =>
      widget.isDarkTheme ? const Color(0xFF1C2128) : Colors.white;
  Color get _appBarColor =>
      widget.isDarkTheme ? const Color(0xFF1C2128) : Colors.white;
  Color get _textColor => widget.isDarkTheme ? Colors.white : Colors.black87;
  Color get _secondaryTextColor =>
      widget.isDarkTheme ? Colors.grey[400]! : Colors.grey[600]!;
  Color get _iconColor => widget.isDarkTheme ? Colors.white : Colors.black87;
  Color get _accentColor => const Color(0xFF6366F1);
  Color get _inputBackgroundColor =>
      widget.isDarkTheme ? const Color(0xFF2D3748) : Colors.grey[100]!;
  Color get _borderColor =>
      widget.isDarkTheme ? const Color(0xFF374151) : Colors.grey[300]!;

  @override
  void initState() {
    super.initState();
    descriptionController = TextEditingController(
      text: widget.caseData['description'] ?? '',
    );
    locationController = TextEditingController(
      text: widget.caseData['location'] ?? '',
    );
    selectedCategory = widget.caseData['category'];
    selectedVictim = widget.caseData['victimGender'];
    selectedAbuser = widget.caseData['abuserGender'];
    selectedStatus = widget.caseData['status'];
  }

  Future<void> _pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked != null) {
        if (kIsWeb) {
          final bytes = await picked.readAsBytes();
          setState(() {
            _pickedBytes = bytes;
            _newImage = null;
          });
        } else {
          setState(() {
            _newImage = File(picked.path);
            _pickedBytes = null;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Helper method to display images
  Widget _buildImage() {
    if (_newImage != null) {
      return Image.file(
        _newImage!,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    } else if (_pickedBytes != null) {
      return Image.memory(
        _pickedBytes!,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    } else if (widget.caseData['imageData'] != null &&
        widget.caseData['imageData'].isNotEmpty) {
      // Base64 image from Firestore
      final imageData = widget.caseData['imageData'];
      if (imageData.startsWith('data:image')) {
        try {
          final base64Data = imageData.split(',').last;
          final bytes = base64Decode(base64Data);
          return Image.memory(
            bytes,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
          );
        } catch (e) {
          return _buildPlaceholderImage();
        }
      }
    } else if (widget.caseData['imageUrl'] != null &&
        widget.caseData['imageUrl'].isNotEmpty) {
      // Fallback for old imageUrl format
      return Image.network(
        widget.caseData['imageUrl'],
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }

    return _buildPlaceholderImage();
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: _inputBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_alt, size: 50, color: _secondaryTextColor),
          const SizedBox(height: 8),
          Text(
            'Tap to add image',
            style: TextStyle(color: _secondaryTextColor),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          "Case Details",
          style: TextStyle(color: _textColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: _appBarColor,
        elevation: 4,
        iconTheme: IconThemeData(color: _iconColor),
        actions: [
          IconButton(
            icon: Icon(Icons.pie_chart, color: _iconColor),
            tooltip: "View Charts",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      CaseChartsPage(isDarkTheme: widget.isDarkTheme),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // Image Section
            GestureDetector(
              onTap: _pickImage,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildImage(),
              ),
            ),
            const SizedBox(height: 20),

            // Description
            Text(
              "Description",
              style: TextStyle(
                color: _textColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: _inputBackgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _borderColor),
              ),
              child: TextField(
                controller: descriptionController,
                maxLines: 3,
                style: TextStyle(color: _textColor),
                decoration: InputDecoration(
                  hintText: "Enter case description...",
                  hintStyle: TextStyle(color: _secondaryTextColor),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Category
            Text(
              "Category",
              style: TextStyle(
                color: _textColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: _inputBackgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _borderColor),
              ),
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: genders.contains(selectedVictim) ? selectedVictim : null,
                hint: Text(
                  "Select Victim Gender",
                  style: TextStyle(color: _secondaryTextColor),
                ),
                items: genders
                    .map(
                      (gender) => DropdownMenuItem(
                        value: gender,
                        child: Text(
                          gender,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: _textColor),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => selectedVictim = value),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                ),
                dropdownColor: _cardColor,
                style: TextStyle(color: _textColor),
              ),
            ),
            const SizedBox(height: 16),

            // Location
            Text(
              "Location",
              style: TextStyle(
                color: _textColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: _inputBackgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _borderColor),
              ),
              child: TextField(
                controller: locationController,
                style: TextStyle(color: _textColor),
                decoration: InputDecoration(
                  hintText: "Enter location...",
                  hintStyle: TextStyle(color: _secondaryTextColor),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Victim & Abuser Gender
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Victim Gender",
                        style: TextStyle(
                          color: _textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: _inputBackgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _borderColor),
                        ),
                        child: DropdownButtonFormField<String>(
                          initialValue: genders.contains(selectedVictim)
                              ? selectedVictim
                              : null,
                          hint: Text(
                            "Select Victim Gender",
                            style: TextStyle(color: _secondaryTextColor),
                          ),
                          items: genders
                              .map(
                                (gender) => DropdownMenuItem(
                                  value: gender,
                                  child: Text(
                                    gender,
                                    style: TextStyle(color: _textColor),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() => selectedVictim = value);
                          },
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                          ),
                          dropdownColor: _cardColor,
                          style: TextStyle(color: _textColor),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Abuser Gender",
                        style: TextStyle(
                          color: _textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: _inputBackgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _borderColor),
                        ),
                        child: DropdownButtonFormField<String>(
                          initialValue: genders.contains(selectedAbuser)
                              ? selectedAbuser
                              : null,
                          hint: Text(
                            "Select Abuser Gender",
                            style: TextStyle(color: _secondaryTextColor),
                          ),
                          items: genders
                              .map(
                                (gender) => DropdownMenuItem(
                                  value: gender,
                                  child: Text(
                                    gender,
                                    style: TextStyle(color: _textColor),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() => selectedAbuser = value);
                          },
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                          ),
                          dropdownColor: _cardColor,
                          style: TextStyle(color: _textColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Case Status
            Text(
              "Case Status",
              style: TextStyle(
                color: _textColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: _inputBackgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _borderColor),
              ),
              child: DropdownButtonFormField<String>(
                initialValue: statuses.contains(selectedStatus)
                    ? selectedStatus
                    : null,
                hint: Text(
                  "Select Case Status",
                  style: TextStyle(color: _secondaryTextColor),
                ),
                items: statuses
                    .map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text(
                          status,
                          style: TextStyle(color: _textColor),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() => selectedStatus = value);
                },
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                ),
                dropdownColor: _cardColor,
                style: TextStyle(color: _textColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    descriptionController.dispose();
    locationController.dispose();
    super.dispose();
  }
}
