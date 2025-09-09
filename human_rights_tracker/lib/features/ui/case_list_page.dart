import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CaseListPage extends StatelessWidget {
  const CaseListPage({super.key});

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
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    "Error loading cases",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
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

          final cases = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cases.length,
            itemBuilder: (context, index) {
              final caseData = cases[index].data() as Map<String, dynamic>;

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
                      // Case Number + Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "Case #${caseData['caseNumber'] ?? 'N/A'}",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Chip(
                            label: Text(
                              (caseData['status'] ?? 'Unknown').toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                            backgroundColor: _getStatusColor(caseData['status']),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Category
                      _buildInfoRow(
                        icon: Icons.category,
                        iconColor: Colors.deepPurple,
                        text: caseData['category'] ?? 'Not specified',
                      ),
                      const SizedBox(height: 8),

                      // Location
                      _buildInfoRow(
                        icon: Icons.location_on,
                        iconColor: Colors.redAccent,
                        text: caseData['location'] ?? 'Location not specified',
                      ),
                      const SizedBox(height: 8),

                      // Victim Gender
                      _buildInfoRow(
                        icon: Icons.person,
                        iconColor: Colors.blue,
                        text: "Victim: ${caseData['victimGender'] ?? 'Not specified'}",
                      ),
                      const SizedBox(height: 8),

                      // Abuser Gender
                      _buildInfoRow(
                        icon: Icons.person_off,
                        iconColor: Colors.orange,
                        text: "Abuser: ${caseData['abuserGender'] ?? 'Not specified'}",
                      ),
                      const SizedBox(height: 8),

                      // Dates (only date, no time)
                      _buildInfoRow(
                        icon: Icons.date_range,
                        iconColor: Colors.green,
                        text:
                        "From: ${_formatDate(caseData['fromDate'])}\nTo: ${_formatDate(caseData['toDate'])}",
                        isMultiLine: true,
                      ),
                      const SizedBox(height: 12),

                      // View Details Button
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CaseDetailsPage(caseData: caseData),
                              ),
                            );
                          },
                          child: const Text(
                            "VIEW DETAILS →",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                        ),
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
      crossAxisAlignment: isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
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
      return "${d.day}/${d.month}/${d.year}"; // ✅ only date
    }
    return date.toString();
  }
}

// ✅ New Page for Details
class CaseDetailsPage extends StatelessWidget {
  final Map<String, dynamic> caseData;

  const CaseDetailsPage({super.key, required this.caseData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Case #${caseData['caseNumber']}"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            if (caseData['imageUrl'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  caseData['imageUrl'],
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),

            Text(
              caseData['description'] ?? "No description provided.",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),

            _buildDetail("Category", caseData['category']),
            _buildDetail("Location", caseData['location']),
            _buildDetail("Victim Gender", caseData['victimGender']),
            _buildDetail("Abuser Gender", caseData['abuserGender']),
            _buildDetail("From Date", caseData['fromDate']),
            _buildDetail("To Date", caseData['toDate']),
          ],
        ),
      ),
    );
  }

  Widget _buildDetail(String label, dynamic value) {
    String textValue = "Not specified";
    if (value != null) {
      if (value is Timestamp) {
        final d = value.toDate();
        textValue = "${d.day}/${d.month}/${d.year}";
      } else {
        textValue = value.toString();
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(textValue)),
        ],
      ),
    );
  }
}
