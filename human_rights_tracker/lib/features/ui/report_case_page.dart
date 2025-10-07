import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../Services/auth_service.dart';

class ReportCasePage extends StatefulWidget {
  final bool isDarkTheme;

  const ReportCasePage({super.key, required this.isDarkTheme});

  @override
  State<ReportCasePage> createState() => _ReportCasePageState();
}

class _ReportCasePageState extends State<ReportCasePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  // Controllers
  final TextEditingController locationController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  String? caseNumber;
  String? category;
  String? victimGender;
  String? abuserGender;
  DateTime? fromDate;
  DateTime? toDate;

  File? _selectedImage;

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

  final List<String> victims = ['Male', 'Female', 'Non-binary', 'Prefer not to Say'];
  final List<String> abusers = ['Male', 'Female',  'Prefer not to Say'];

  // Theme colors
  Color get _backgroundColor =>
      widget.isDarkTheme ? const Color(0xFF0A1628) : Colors.white;
  Color get _cardColor =>
      widget.isDarkTheme ? const Color(0xFF1A243A) : const Color(0xFFFAFAFA);
  Color get _appBarColor =>
      widget.isDarkTheme ? const Color(0xFF0A1628) : Colors.white;
  Color get _textColor => widget.isDarkTheme ? Colors.white : Colors.black87;
  Color get _secondaryTextColor =>
      widget.isDarkTheme ? Colors.grey[400]! : Colors.grey[600]!;
  Color get _iconColor => widget.isDarkTheme ? Colors.white : Colors.black87;
  Color get _accentColor => const Color(0xFFE53E3E);
  Color get _borderColor =>
      widget.isDarkTheme ? const Color(0xFF2D3748) : Colors.grey[300]!;
  Color get _inputBackgroundColor =>
      widget.isDarkTheme ? const Color(0xFF2D3748) : Colors.grey[100]!;

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDate({required bool isFromDate}) async {
    DateTime initialDate = isFromDate
        ? DateTime.now()
        : (fromDate ?? DateTime.now());
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
          if (toDate != null && toDate!.isBefore(picked)) {
            toDate = null;
          }
        } else {
          toDate = picked;
        }
      });
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(
        "case_images/${DateTime.now().millisecondsSinceEpoch}.jpg",
      );
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      print("Image upload error: $e");
      return null;
    }
  }

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

      await FirebaseFirestore.instance
          .collection("notifications")
          .add(notificationData);
    } catch (e) {
      print("Error saving notification: $e");
    }
  }

  void _submitForm() async {
    if (_isSubmitting) return;

    final user = AuthService().currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("You must be logged in to report a case."),
          backgroundColor: _accentColor,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      if (fromDate != null && toDate != null && toDate!.isBefore(fromDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("To date cannot be before from date."),
            backgroundColor: _accentColor,
          ),
        );
        return;
      }

      setState(() {
        _isSubmitting = true;
      });

      try {
        final userEmail = user.email ?? "Unknown User";

        // Auto-generate case number
        caseNumber = "CASE-${DateTime.now().millisecondsSinceEpoch}";

        String? imageUrl;
        if (_selectedImage != null) {
          imageUrl = await _uploadImage(_selectedImage!);
        }

        final caseData = {
          "caseNumber": caseNumber,
          "category": category,
          "location": locationController.text,
          "description": descriptionController.text,
          "victimGender": victimGender,
          "abuserGender": abuserGender,
          "fromDate": fromDate?.toIso8601String(),
          "toDate": toDate?.toIso8601String(),
          "createdAt": FieldValue.serverTimestamp(),
          "reportedBy": user.uid,
          "reportedByEmail": userEmail,
          "status": "reported",
          "lastUpdated": FieldValue.serverTimestamp(),
          "imageUrl": imageUrl,
        };

        await FirebaseFirestore.instance.collection("cases").add(caseData);
        await _saveNotification(caseNumber!, userEmail);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Case $caseNumber reported successfully!"),
            backgroundColor: Colors.green,
          ),
        );

        _formKey.currentState!.reset();
        locationController.clear();
        descriptionController.clear();
        setState(() {
          caseNumber = null;
          category = null;
          victimGender = null;
          abuserGender = null;
          fromDate = null;
          toDate = null;
          _selectedImage = null;
        });
      } catch (e) {
        String errorMessage = "Failed to save case";

        if (e.toString().contains('permission-denied')) {
          errorMessage =
              "Permission denied. Please check your authentication status.";
        } else if (e.toString().contains('network')) {
          errorMessage = "Network error. Please check your connection.";
        } else {
          errorMessage = "Error: $e";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: _accentColor),
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
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          "Report Case",
          style: TextStyle(color: _textColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _appBarColor,
        elevation: 0,
        iconTheme: IconThemeData(color: _iconColor),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Header Card
              Card(
                color: _cardColor,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.report, color: _accentColor, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'Report Human Rights Abuse',
                            style: TextStyle(
                              color: _textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Fill in the details below to report a case. All information is confidential.',
                        style: TextStyle(
                          color: _secondaryTextColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              if (caseNumber != null)
                Card(
                  color: _cardColor,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.numbers, color: _accentColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Case Number',
                                style: TextStyle(
                                  color: _secondaryTextColor,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                caseNumber!,
                                style: TextStyle(
                                  color: _textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (caseNumber != null) const SizedBox(height: 16),

              // Category
              _buildSectionHeader('Case Details'),
              _buildDropdownFormField(
                value: category,
                items: categories,
                label: 'Category',
                icon: Icons.category,
                validator: (value) =>
                    value == null ? 'Select a category' : null,
                onChanged: (val) => setState(() => category = val),
              ),
              const SizedBox(height: 16),

              // Location
              _buildTextFormField(
                controller: locationController,
                label: 'Location',
                icon: Icons.location_on,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter location' : null,
              ),
              const SizedBox(height: 16),

              // Victim & Abuser Gender Row
              Row(
                children: [
                  Expanded(
                    child: _buildDropdownFormField(
                      value: victimGender,
                      items: victims,
                      label: 'Victim Gender',
                      icon: Icons.person,
                      validator: (value) =>
                          value == null ? 'Select victim gender' : null,
                      onChanged: (val) => setState(() => victimGender = val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDropdownFormField(
                      value: abuserGender,
                      items: abusers,
                      label: 'Abuser Gender',
                      icon: Icons.warning,
                      validator: (value) =>
                          value == null ? 'Select abuser gender' : null,
                      onChanged: (val) => setState(() => abuserGender = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Date Selection
              _buildSectionHeader('Time Period'),
              Row(
                children: [
                  Expanded(
                    child: _buildDatePicker(
                      date: fromDate,
                      label: 'From Date',
                      onTap: () => _pickDate(isFromDate: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDatePicker(
                      date: toDate,
                      label: 'To Date',
                      onTap: () => _pickDate(isFromDate: false),
                    ),
                  ),
                ],
              ),
              if (fromDate != null &&
                  toDate != null &&
                  toDate!.isBefore(fromDate!))
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'To date cannot be before from date',
                    style: TextStyle(color: _accentColor, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 24),

              // Description
              _buildSectionHeader('Description & Evidence'),
              _buildTextFormField(
                controller: descriptionController,
                label: 'Description',
                icon: Icons.description,
                maxLines: 4,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter description' : null,
              ),
              const SizedBox(height: 16),

              // Image Upload
              Card(
                color: _cardColor,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upload Evidence',
                        style: TextStyle(
                          color: _textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: Icon(Icons.photo, color: Colors.white),
                        label: Text(
                          "Upload Photo",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                      if (_selectedImage != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _borderColor),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              Container(
                height: 60,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: _accentColor.withOpacity(0.5),
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
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.report_problem, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Report Case',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          color: _textColor,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDropdownFormField({
    required String? value,
    required List<String> items,
    required String label,
    required IconData icon,
    required String? Function(String?)? validator,
    required Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _inputBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          value: value,
          isExpanded: true, // Critical for preventing overflow
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Container(
                    width: double.infinity, // Force full width
                    child: Text(
                      item,
                      style: TextStyle(color: _textColor, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: _secondaryTextColor, fontSize: 14),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
            isDense: true, // Reduces vertical padding
          ),
          style: TextStyle(color: _textColor, fontSize: 14),
          dropdownColor: _cardColor,
          icon: Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Icon(Icons.arrow_drop_down, color: _secondaryTextColor),
          ),
          iconSize: 20,
          validator: validator,
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    required String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _inputBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
      ),
      child: TextFormField(
        controller: controller,
        style: TextStyle(color: _textColor),
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: _secondaryTextColor),
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: _secondaryTextColor),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDatePicker({
    required DateTime? date,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: _inputBackgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _borderColor),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(Icons.calendar_today, color: _secondaryTextColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: _secondaryTextColor,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      date == null ? 'Select Date' : _formatDate(date),
                      style: TextStyle(
                        color: date == null ? _secondaryTextColor : _textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
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
    locationController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}
