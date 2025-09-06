import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Services/auth_service.dart';

class ReportCasePage extends StatefulWidget {
  const ReportCasePage({super.key});

  @override
  State<ReportCasePage> createState() => _ReportCasePageState();
}

class _ReportCasePageState extends State<ReportCasePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  // Controllers
  final TextEditingController caseNumberController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  String? category;
  String? victimGender;
  String? abuserGender;
  DateTime? fromDate;
  DateTime? toDate;

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

  final List<String> victims = ['Male', 'Female', 'Prefer not to Say'];
  final List<String> abusers = ['Male', 'Female', 'Prefer not to Say'];

  // Helper function to format dates without intl package
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDate({required bool isFromDate}) async {
    DateTime initialDate = isFromDate ? DateTime.now() : (fromDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isFromDate) {
          fromDate = picked;
          // Reset toDate if it's before fromDate
          if (toDate != null && toDate!.isBefore(picked)) {
            toDate = null;
          }
        } else {
          toDate = picked;
        }
      });
    }
  }

  // Save notification to Firestore
  Future<void> _saveNotification(String caseNumber, String userEmail) async {
    try {
      final notificationData = {
        "title": "New Case Reported",
        "message": "Case #$caseNumber reported by $userEmail",
        "type": "case_report",
        "caseNumber": caseNumber,
        "reportedBy": userEmail,
        "timestamp": FieldValue.serverTimestamp(),
        "read": false,
      };

      await FirebaseFirestore.instance.collection("notifications").add(notificationData);
    } catch (e) {
      print("Error saving notification: $e");
    }
  }

  // 🔥 Save to Firebase Firestore
  void _submitForm() async {
    if (_isSubmitting) return;
    
    final user = AuthService().currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must be logged in to report a case.")),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      // Validate date range
      if (fromDate != null && toDate != null && toDate!.isBefore(fromDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("To date cannot be before from date.")),
        );
        return;
      }
      
      setState(() {
        _isSubmitting = true;
      });
      
      try {
        final caseNumber = caseNumberController.text;
        final userEmail = user.email ?? "Unknown User";
        
        final caseData = {
          "caseNumber": caseNumber,
          "category": category,
          "location": locationController.text,
          "victimGender": victimGender,
          "abuserGender": abuserGender,
          "fromDate": fromDate?.toIso8601String(),
          "toDate": toDate?.toIso8601String(),
          "createdAt": FieldValue.serverTimestamp(),
          "reportedBy": user.uid,
          "reportedByEmail": userEmail, // Save user's email
          "status": "reported",
          "lastUpdated": FieldValue.serverTimestamp(),
        };

        await FirebaseFirestore.instance.collection("cases").add(caseData);
        
        // Save notification
        await _saveNotification(caseNumber, userEmail);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Case reported successfully!")),
        );

        // Reset form after save
        _formKey.currentState!.reset();
        caseNumberController.clear();
        locationController.clear();
        setState(() {
          category = null;
          victimGender = null;
          abuserGender = null;
          fromDate = null;
          toDate = null;
        });
      } catch (e) {
        String errorMessage = "Failed to save case";
        
        if (e.toString().contains('permission-denied')) {
          errorMessage = "Permission denied. Please check your authentication status.";
        } else if (e.toString().contains('network')) {
          errorMessage = "Network error. Please check your connection.";
        } else {
          errorMessage = "Error: $e";
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Report Case"),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Navigate to notifications page
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsPage()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Case Number
              TextFormField(
                controller: caseNumberController,
                decoration: const InputDecoration(
                  labelText: 'Case Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
                validator: (value) =>
                value == null || value.isEmpty ? 'Enter case number' : null,
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              DropdownButtonFormField<String>(
                value: category,
                items: categories
                    .map((cat) => DropdownMenuItem(
                  value: cat,
                  child: Text(cat),
                ))
                    .toList(),
                onChanged: (val) => setState(() => category = val),
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                validator: (value) =>
                value == null ? 'Select a category' : null,
              ),
              const SizedBox(height: 16),

              // Location
              TextFormField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) =>
                value == null || value.isEmpty ? 'Enter location' : null,
              ),
              const SizedBox(height: 16),

              // Victim Gender Dropdown
              DropdownButtonFormField<String>(
                value: victimGender,
                items: victims
                    .map((v) => DropdownMenuItem(
                  value: v,
                  child: Text(v),
                ))
                    .toList(),
                onChanged: (val) => setState(() => victimGender = val),
                decoration: const InputDecoration(
                  labelText: 'Victim Gender',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) =>
                value == null ? 'Select victim gender' : null,
              ),
              const SizedBox(height: 16),

              // Abuser Gender Dropdown
              DropdownButtonFormField<String>(
                value: abuserGender,
                items: abusers
                    .map((a) => DropdownMenuItem(
                  value: a,
                  child: Text(a),
                ))
                    .toList(),
                onChanged: (val) => setState(() => abuserGender = val),
                decoration: const InputDecoration(
                  labelText: 'Abuser Gender',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.warning),
                ),
                validator: (value) =>
                value == null ? 'Select abuser gender' : null,
              ),
              const SizedBox(height: 16),

              // From Date
              ListTile(
                title: Text(fromDate == null
                    ? 'Select From Date'
                    : 'From: ${_formatDate(fromDate!)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _pickDate(isFromDate: true),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Colors.grey, width: 1),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const SizedBox(height: 8),

              // To Date
              ListTile(
                title: Text(toDate == null
                    ? 'Select To Date'
                    : 'To: ${_formatDate(toDate!)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _pickDate(isFromDate: false),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Colors.grey, width: 1),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              if (fromDate != null && toDate != null && toDate!.isBefore(fromDate!))
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    'To date cannot be before from date',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  disabledBackgroundColor: Colors.deepPurple.withOpacity(0.5),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Report Case',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    caseNumberController.dispose();
    locationController.dispose();
    super.dispose();
  }
}

// Notifications Page
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No notifications yet'));
          }

          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data = document.data() as Map<String, dynamic>;
              
              // Format timestamp
              String timeText = "Recently";
              if (data['timestamp'] != null) {
                final timestamp = data['timestamp'] as Timestamp;
                final now = DateTime.now();
                final difference = now.difference(timestamp.toDate());
                
                if (difference.inMinutes < 1) {
                  timeText = "Just now";
                } else if (difference.inHours < 1) {
                  timeText = "${difference.inMinutes} min ago";
                } else if (difference.inDays < 1) {
                  timeText = "${difference.inHours} hours ago";
                } else {
                  timeText = "${difference.inDays} days ago";
                }
              }
              
              return ListTile(
                leading: const Icon(Icons.notifications, color: Colors.deepPurple),
                title: Text(data['title'] ?? 'Notification'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['message'] ?? ''),
                    const SizedBox(height: 4),
                    Text(
                      timeText,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                trailing: data['read'] == true 
                    ? null 
                    : const Icon(Icons.circle, color: Colors.red, size: 12),
                onTap: () {
                  // Mark as read when tapped
                  document.reference.update({'read': true});
                  
                  // If it's a case notification, you could navigate to case details
                  if (data['type'] == 'case_report') {
                    // Navigate to case details page
                  }
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}