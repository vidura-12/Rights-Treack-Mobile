import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CaseListPage extends StatelessWidget {
  const CaseListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reported Cases"),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("cases")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No cases reported yet."),
            );
          }

          final cases = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: cases.length,
            itemBuilder: (context, index) {
              final caseData = cases[index].data() as Map<String, dynamic>;

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Case #${caseData['caseNumber'] ?? ''}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text("📌 Category: ${caseData['category'] ?? ''}"),
                      Text("📍 Location: ${caseData['location'] ?? ''}"),
                      Text("🧑 Victim Gender: ${caseData['victimGender'] ?? ''}"),
                      Text("👤 Abuser Gender: ${caseData['abuserGender'] ?? ''}"),
                      Text("📅 From: ${caseData['fromDate'] ?? ''}"),
                      Text("📅 To: ${caseData['toDate'] ?? ''}"),
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
}
