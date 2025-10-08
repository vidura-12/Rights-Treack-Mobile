import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:human_rights_tracker/models/user_profile.dart';

class ProfilePage extends StatefulWidget {
  final bool isDarkTheme;
  
  const ProfilePage({super.key, required this.isDarkTheme});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  late UserProfile _userProfile;
  bool _isLoading = true;
  bool _isEditing = false;
  
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _countryController = TextEditingController();
  final _stateController = TextEditingController();

  // Theme colors based on parent theme
  Color get _backgroundColor => widget.isDarkTheme ? const Color(0xFF0A1628) : Colors.white;
  Color get _cardColor => widget.isDarkTheme ? const Color(0xFF1A243A) : const Color(0xFFFAFAFA);
  Color get _appBarColor => widget.isDarkTheme ? const Color(0xFF0A1628) : Colors.white;
  Color get _textColor => widget.isDarkTheme ? Colors.white : Colors.black87;
  Color get _secondaryTextColor => widget.isDarkTheme ? Colors.grey[400]! : Colors.grey[600]!;
  Color get _iconColor => widget.isDarkTheme ? Colors.white : Colors.black87;
  Color get _dividerColor => widget.isDarkTheme ? const Color(0xFF2D3748) : Colors.grey[300]!;
  Color get _headerColor => widget.isDarkTheme ? const Color(0xFF2D3748) : Colors.grey[200]!;
  Color get _enabledFieldColor => widget.isDarkTheme ? const Color(0xFF2D3748) : Colors.grey[100]!;
  Color get _disabledFieldColor => widget.isDarkTheme ? const Color(0xFF1A243A) : Colors.grey[50]!;
  Color get _fieldBorderColor => widget.isDarkTheme ? const Color(0xFF2D3748) : Colors.grey[400]!;
  Color get _cancelButtonColor => widget.isDarkTheme ? const Color(0xFF2D3748) : Colors.grey[300]!;
  Color get _cancelButtonTextColor => widget.isDarkTheme ? Colors.white : Colors.black87;
  Color get _accentColor => const Color(0xFFE53E3E);

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    if (_currentUser == null) return;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(_currentUser.uid)
          .get();

      if (doc.exists) {
        setState(() {
          _userProfile = UserProfile.fromFirestore(doc.data()!);
          _populateControllers();
          _isLoading = false;
        });
      } else {
        // Create default profile if doesn't exist
        setState(() {
          _userProfile = UserProfile(
            email: _currentUser.email ?? '',
            firstName: '',
            lastName: '',
          );
          _populateControllers();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Failed to load profile');
    }
  }

  void _populateControllers() {
    _firstNameController.text = _userProfile.firstName;
    _lastNameController.text = _userProfile.lastName;
    _phoneController.text = _userProfile.phone ?? '';
    _countryController.text = _userProfile.country ?? '';
    _stateController.text = _userProfile.state ?? '';
  }

  Future<void> _saveProfile() async {
    if (_currentUser == null || !_formKey.currentState!.validate()) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final updatedProfile = _userProfile.copyWith(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _phoneController.text.trim(),
        country: _countryController.text.trim(),
        state: _stateController.text.trim(),
      );

      await _firestore
          .collection('users')
          .doc(_currentUser.uid)
          .set(updatedProfile.toFirestore(), SetOptions(merge: true));

      setState(() {
        _userProfile = updatedProfile;
        _isEditing = false;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated successfully'),
          backgroundColor: widget.isDarkTheme ? const Color(0xFF388E3C) : Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Failed to update profile');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: widget.isDarkTheme ? const Color(0xFFD32F2F) : Colors.red,
      ),
    );
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _populateControllers(); // Reset to original values
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _countryController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _appBarColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _iconColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Profile',
          style: TextStyle(
            color: _textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (!_isEditing && !_isLoading)
            IconButton(
              icon: Icon(Icons.edit, color: _iconColor),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: _accentColor,
              ),
            )
          : _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Profile Header
          _buildProfileHeader(),
          const SizedBox(height: 32),
          
          // Profile Form
          _buildProfileForm(),
          
          const SizedBox(height: 20),
          
          // Action Buttons
          if (_isEditing) _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: widget.isDarkTheme ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _accentColor,
              shape: BoxShape.circle,
              border: Border.all(color: widget.isDarkTheme ? Colors.white : Colors.grey[300]!, width: 3),
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_userProfile.firstName} ${_userProfile.lastName}'.trim(),
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _userProfile.email,
                  style: TextStyle(
                    color: _secondaryTextColor,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_userProfile.phone != null && _userProfile.phone!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _userProfile.phone!,
                      style: TextStyle(
                        color: _secondaryTextColor,
                        fontSize: 14,
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

  Widget _buildProfileForm() {
    return Form(
      key: _formKey,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: TextStyle(
                color: _textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // First Name & Last Name Row
            Row(
              children: [
                Expanded(
                  child: _buildFormField(
                    controller: _firstNameController,
                    label: 'First Name',
                    icon: Icons.person,
                    isEnabled: _isEditing,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter first name';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildFormField(
                    controller: _lastNameController,
                    label: 'Last Name',
                    icon: Icons.person_outline,
                    isEnabled: _isEditing,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter last name';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Email (Read-only)
            _buildFormField(
              controller: TextEditingController(text: _userProfile.email),
              label: 'Email',
              icon: Icons.email,
              isEnabled: false,
            ),
            const SizedBox(height: 16),
            
            // Phone
            _buildFormField(
              controller: _phoneController,
              label: 'Phone Number',
              icon: Icons.phone,
              isEnabled: _isEditing,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            
            // Country & State Row
            Row(
              children: [
                Expanded(
                  child: _buildFormField(
                    controller: _countryController,
                    label: 'Country',
                    icon: Icons.location_on,
                    isEnabled: _isEditing,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildFormField(
                    controller: _stateController,
                    label: 'State/Region',
                    icon: Icons.map,
                    isEnabled: _isEditing,
                  ),
                ),
              ],
            ),
            
            // Account Created Date
            if (_userProfile.createdAt != null) ...[
              const SizedBox(height: 20),
              Divider(color: _dividerColor),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.calendar_today, color: _secondaryTextColor, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Member since ${_formatDate(_userProfile.createdAt!)}',
                    style: TextStyle(
                      color: _secondaryTextColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isEnabled,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: isEnabled,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: _textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _secondaryTextColor),
        prefixIcon: Icon(icon, color: _secondaryTextColor),
        enabled: isEnabled,
        filled: true,
        fillColor: isEnabled ? _enabledFieldColor : _disabledFieldColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _fieldBorderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _accentColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD32F2F)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD32F2F)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(color: _secondaryTextColor),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _cancelEdit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _cancelButtonColor,
              foregroundColor: _cancelButtonTextColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Save Changes'),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}