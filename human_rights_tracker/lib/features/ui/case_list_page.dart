import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'case_charts_page.dart';

class CaseListPage extends StatefulWidget {
  const CaseListPage({super.key});

  @override
  State<CaseListPage> createState() => _CaseListPageState();
}

class _CaseListPageState extends State<CaseListPage> {
  String _searchQuery = "";

  final List<String> statuses = [
    'Open',
    'In Progress',
    'Investigation',
    'In Court',
    'Resolved',
    'Closed'
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Reported Cases"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        elevation: 4,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "🔍 Search cases...",
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
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
      body: userEmail == null
          ? const Center(
        child: Text(
          "You must be logged in to view cases.",
          style: TextStyle(fontSize: 16, color: Colors.grey),
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
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    "Error loading cases",
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style:
                    const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text("Try Again"),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "🚫 No cases reported yet.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
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
            return const Center(
              child: Text(
                "No matching cases found.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
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
                      (s) => s.toLowerCase() == status.toLowerCase());
              final progress =
              currentStep >= 0 ? (currentStep + 1) / statuses.length : 0.0;

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 6,
                shadowColor: Colors.deepPurple.withOpacity(0.3),
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Chip(
                            label: Text(
                              status.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                            backgroundColor: _getStatusColor(status),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.deepPurple),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CaseDetailsPage(
                                        caseId: doc.id,
                                        caseData: caseData,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon:
                                const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text("Delete Case"),
                                      content: const Text(
                                          "Are you sure you want to delete this case?"),
                                      actions: [
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: const Text("Cancel")),
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            child: const Text("Delete",
                                                style: TextStyle(
                                                    color: Colors.red))),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    if (caseData['imageUrl'] != null &&
                                        caseData['imageUrl']
                                            .toString()
                                            .isNotEmpty) {
                                      try {
                                        await FirebaseStorage.instance
                                            .refFromURL(
                                            caseData['imageUrl'])
                                            .delete();
                                      } catch (e) {}
                                    }
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
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[300],
                        color: _getStatusColor(status),
                        minHeight: 6,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: statuses.map((s) {
                          final stepIndex = statuses.indexOf(s);
                          final isCompleted = stepIndex <= currentStep;
                          return Column(
                            children: [
                              CircleAvatar(
                                radius: 10,
                                backgroundColor: isCompleted
                                    ? _getStatusColor(status)
                                    : Colors.grey[300],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                s,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isCompleted
                                      ? _getStatusColor(status)
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        icon: Icons.category,
                        iconColor: Colors.deepPurple,
                        text: caseData['category'] ?? 'Not specified',
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        icon: Icons.location_on,
                        iconColor: Colors.redAccent,
                        text: caseData['location'] ?? 'Location not specified',
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
      crossAxisAlignment:
      isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 16),
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
        return Colors.orange;
      case 'in progress':
        return Colors.blue;
      case 'investigation':
        return Colors.indigo;
      case 'in court':
        return Colors.deepOrange;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.deepPurple;
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Not specified';
    if (date is Timestamp) {
      final d = date.toDate();
      return "${d.day}/${d.month}/${d.year}";
    }
    return date.toString();
  }
}

// ✅ Case Details Page (fixed AppBar)
class CaseDetailsPage extends StatefulWidget {
  final String caseId;
  final Map<String, dynamic> caseData;

  const CaseDetailsPage({
    super.key,
    required this.caseId,
    required this.caseData,
  });

  @override
  State<CaseDetailsPage> createState() => _CaseDetailsPageState();
}

class _CaseDetailsPageState extends State<CaseDetailsPage> {
  late TextEditingController descriptionController;
  late TextEditingController locationController;
  File? _newImage;

  final List<String> categories = [
    'Human Trafficking',
    'Gender-Based Violence',
    'Child Abuse',
    'Sextortion',
    'Rape',
    'Domestic Abuse',
    'Jungle Justice',
    'Other Abuses'
  ];

  final List<String> genders = ['Male', 'Female', 'Prefer not to Say'];

  final List<String> statuses = [
    'Open',
    'In Progress',
    'Investigation',
    'In Court',
    'Resolved',
    'Closed'
  ];

  String? selectedCategory;
  String? selectedVictim;
  String? selectedAbuser;
  String? selectedStatus;

  @override
  void initState() {
    super.initState();
    descriptionController =
        TextEditingController(text: widget.caseData['description']);
    locationController =
        TextEditingController(text: widget.caseData['location']);
    selectedCategory = widget.caseData['category'];
    selectedVictim = widget.caseData['victimGender'];
    selectedAbuser = widget.caseData['abuserGender'];
    selectedStatus = widget.caseData['status'];
  }

  Future<void> _pickImage() async {
    final picked =
    await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _newImage = File(picked.path);
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Reported Cases"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.pie_chart, color: Colors.white),
            tooltip: "View Charts",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CaseChartsPage()),
              );
            },
          ),
        ],
      ), // ✅ <- AppBar closed

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: _newImage != null
                  ? Image.file(_newImage!,
                  height: 200, width: double.infinity, fit: BoxFit.cover)
                  : (widget.caseData['imageUrl'] != null
                  ? Image.network(
                widget.caseData['imageUrl'],
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              )
                  : Container(
                height: 200,
                color: Colors.grey[300],
                child: const Icon(Icons.camera_alt, size: 50),
              )),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              items: categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => selectedCategory = v),
              decoration: const InputDecoration(
                labelText: "Category",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(
                labelText: "Location",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedVictim,
              items: genders
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (v) => setState(() => selectedVictim = v),
              decoration: const InputDecoration(
                labelText: "Victim Gender",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedAbuser,
              items: genders
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (v) => setState(() => selectedAbuser = v),
              decoration: const InputDecoration(
                labelText: "Abuser Gender",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value:
              statuses.contains(selectedStatus) ? selectedStatus : null,
              items: statuses
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => selectedStatus = v),
              decoration: const InputDecoration(
                labelText: "Case Status",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
