import 'package:flutter/material.dart';

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
  final TextEditingController victimGenderController = TextEditingController();
  final TextEditingController abuserGenderController = TextEditingController();

  String? category;
  DateTime? fromDate;
  DateTime? toDate;

  final List<String> categories = [
    'Police Brutality',
    'Discrimination',
    'Freedom of Speech',
    'Unlawful Detention',
    'Others'
  ];

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

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Right now, only showing data in console (in-memory)
      print("Case Number: ${caseNumberController.text}");
      print("Category: $category");
      print("Location: ${locationController.text}");
      print("Victim Gender: ${victimGenderController.text}");
      print("Abuser Gender: ${abuserGenderController.text}");
      print("From Date: $fromDate");
      print("To Date: $toDate");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Case reported successfully (in-memory)!')),
      );
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

              // Victim Gender
              TextFormField(
                controller: victimGenderController,
                decoration: const InputDecoration(
                  labelText: 'Victim Gender',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Abuser Gender
              TextFormField(
                controller: abuserGenderController,
                decoration: const InputDecoration(
                  labelText: 'Abuser Gender',
                  border: OutlineInputBorder(),
                ),
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
