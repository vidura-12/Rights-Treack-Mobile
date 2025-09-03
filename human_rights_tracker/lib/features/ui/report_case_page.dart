import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Services/auth_service.dart'; // ✅ Import your AuthService

class ReportCasePage extends StatefulWidget {
  const ReportCasePage({super.key});

  @override
  State<ReportCasePage> createState() => _ReportCasePageState();
}

class _ReportCasePageState extends State<ReportCasePage> {
  final _formKey = GlobalKey<FormState>();

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

  Future<void> _pickDate({required bool isFromDate}) async {
    DateTime initialDate = DateTime.now();
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
        } else {
          toDate = picked;
        }
      });
    }
  }

  // 🔥 Save to Firebase Firestore
  void _submitForm() async {
    final user = AuthService().currentUser; // ✅ Use AuthService

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must be logged in to report a case.")),
      );
      return; // Stop submission if no user
    }

    if (_formKey.currentState!.validate()) {
      try {
        final caseData = {
          "caseNumber": caseNumberController.text,
          "category": category,
          "location": locationController.text,
          "victimGender": victimGender,
          "abuserGender": abuserGender,
          "fromDate": fromDate?.toIso8601String(),
          "toDate": toDate?.toIso8601String(),
          "createdAt": FieldValue.serverTimestamp(),
          "reportedBy": user.uid, // ✅ Track who reported
        };

        await FirebaseFirestore.instance.collection("cases").add(caseData);

        // ✅ Success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Case reported successfully!")),
        );

        // Reset form after save
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save case: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Report Case"),
        backgroundColor: Colors.deepPurple,
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
                ),
                validator: (value) =>
                value == null ? 'Select abuser gender' : null,
              ),
              const SizedBox(height: 16),

              // From Date
              ListTile(
                title: Text(fromDate == null
                    ? 'Select From Date'
                    : 'From: ${fromDate!.toLocal()}'.split(' ')[0]),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _pickDate(isFromDate: true),
              ),
              const SizedBox(height: 8),

              // To Date
              ListTile(
                title: Text(toDate == null
                    ? 'Select To Date'
                    : 'To: ${toDate!.toLocal()}'.split(' ')[0]),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _pickDate(isFromDate: false),
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
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
}
