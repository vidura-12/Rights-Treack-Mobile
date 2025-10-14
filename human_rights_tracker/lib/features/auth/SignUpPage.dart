import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:human_rights_tracker/core/routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  bool _isPasswordVisible = false;
  bool _agreedToTerms = false;
  bool _isLoading = false;
  
  // Form fields
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // Country and state data
  List<dynamic> _countries = [];
  List<dynamic> _states = [];
  String? _selectedCountry;
  String? _selectedState;
  
  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  @override
  void initState() {
    super.initState();
    _fetchCountries();
  }
  
  // Fetch countries from REST Countries API
  Future<void> _fetchCountries() async {
    try {
      final response = await http.get(Uri.parse('https://restcountries.com/v3.1/all'));
      if (response.statusCode == 200) {
        setState(() {
          _countries = json.decode(response.body);
          // Sort countries alphabetically by common name
          _countries.sort((a, b) => a['name']['common'].compareTo(b['name']['common']));
        });
      } else {
        throw Exception('Failed to load countries');
      }
    } catch (e) {
      // Fallback to a few common countries if API fails
      setState(() {
        _countries = [
          {'name': {'common': 'United States'}, 'cca2': 'US'},
          {'name': {'common': 'United Kingdom'}, 'cca2': 'UK'},
          {'name': {'common': 'Canada'}, 'cca2': 'CA'},
          {'name': {'common': 'Australia'}, 'cca2': 'AU'},
          {'name': {'common': 'Germany'}, 'cca2': 'DE'},
          {'name': {'common': 'France'}, 'cca2': 'FR'},
        ];
      });
    }
  }
  
  // Fetch states for selected country
  Future<void> _fetchStates(String countryCode) async {
    final Map<String, List<String>> mockStates = {
      'US': ['California', 'Texas', 'New York', 'Florida', 'Illinois'],
      'UK': ['England', 'Scotland', 'Wales', 'Northern Ireland'],
      'CA': ['Ontario', 'Quebec', 'British Columbia', 'Alberta'],
      'AU': ['New South Wales', 'Victoria', 'Queensland', 'Western Australia'],
      'DE': ['Bavaria', 'Berlin', 'Hamburg', 'North Rhine-Westphalia'],
      'FR': ['Île-de-France', 'Provence-Alpes-Côte d\'Azur', 'Auvergne-Rhône-Alpes'],
    };
    
    setState(() {
      _states = mockStates[countryCode] ?? ['Select a country first'];
      _selectedState = null;
    });
  }

  // Sign up with email and password
  Future<void> _signUp() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the terms and conditions')),
      );
      return;
    }

    if (_firstNameController.text.isEmpty || 
        _lastNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _selectedCountry == null ||
        _selectedState == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create user with email and password
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Update user profile with name
      await userCredential.user!.updateDisplayName(
        '${_firstNameController.text} ${_lastNameController.text}',
      );

      // Save additional user data to Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.isNotEmpty ? _phoneController.text : null,
        'country': _selectedCountry,
        'state': _selectedState,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Navigate to home screen after successful signup
      Navigator.pushReplacementNamed(context, AppRoutes.landing);

    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred. Please try again.';
      
      if (e.code == 'weak-password') {
        errorMessage = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'The account already exists for that email.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is not valid.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred. Please try again.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628), // Dark blue background
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 40),
              
              // Logo and branding
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'RightsTracker',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE53E3E), // Red accent
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chat_bubble,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'IF YOU BE RIGHT AGAIN!',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // White sign up container
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 24),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Fill the form below to create an account',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF718096),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // First Name Field
                    const Text(
                      'First Name *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _firstNameController,
                        decoration: InputDecoration(
                          hintText: 'First Name',
                          hintStyle: const TextStyle(
                            color: Color(0xFFA0AEC0),
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Last Name Field
                    const Text(
                      'Last Name *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _lastNameController,
                        decoration: InputDecoration(
                          hintText: 'Last Name',
                          hintStyle: const TextStyle(
                            color: Color(0xFFA0AEC0),
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Email Address Field
                    const Text(
                      'Email Address *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'E-mail Address',
                          hintStyle: const TextStyle(
                            color: Color(0xFFA0AEC0),
                            fontSize: 16,
                          ),
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            color: Color(0xFF718096),
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Phone Number Field
                    const Text(
                      'Phone Number',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: 'Phone Number',
                          hintStyle: const TextStyle(
                            color: Color(0xFFA0AEC0),
                            fontSize: 16,
                          ),
                          prefixIcon: const Icon(
                            Icons.phone_outlined,
                            color: Color(0xFF718096),
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Country Dropdown
                    const Text(
                      'Country *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedCountry,
                          hint: const Text('Select Country'),
                          items: _countries.map<DropdownMenuItem<String>>((country) {
                            return DropdownMenuItem<String>(
                              value: country['cca2'],
                              child: Text(country['name']['common']),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedCountry = newValue;
                              if (newValue != null) {
                                _fetchStates(newValue);
                              }
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // State Dropdown
                    const Text(
                      'State *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedState,
                          hint: const Text('Select State'),
                          items: _states.map<DropdownMenuItem<String>>((state) {
                            return DropdownMenuItem<String>(
                              value: state,
                              child: Text(state),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedState = newValue;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Password Field
                    const Text(
                      'Password *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          hintText: 'Password',
                          hintStyle: const TextStyle(
                            color: Color(0xFFA0AEC0),
                            fontSize: 16,
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: Color(0xFF718096),
                            size: 20,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: const Color(0xFF718096),
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Terms and Privacy Agreement
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: _agreedToTerms,
                            onChanged: (value) {
                              setState(() {
                                _agreedToTerms = value ?? false;
                              });
                            },
                            activeColor: const Color(0xFFE53E3E),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF718096),
                                height: 1.4,
                              ),
                              children: [
                                TextSpan(
                                  text: 'By signing, I confirm that I have read and agree to the ',
                                ),
                                TextSpan(
                                  text: 'Terms Of Service',
                                  style: TextStyle(
                                    color: Color(0xFF2D3748),
                                    fontWeight: FontWeight.w500,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: TextStyle(
                                    color: Color(0xFF2D3748),
                                    fontWeight: FontWeight.w500,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Create Account Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _agreedToTerms && !_isLoading
                              ? const Color(0xFF2D3748)
                              : const Color(0xFFE2E8F0),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          disabledBackgroundColor: const Color(0xFFE2E8F0),
                          disabledForegroundColor: const Color(0xFFA0AEC0),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Create Account',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Login Link
                    Center(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF718096),
                          ),
                          children: [
                            const TextSpan(text: "Already have an account? "),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(context, AppRoutes.login);
                                },
                                child: const Text(
                                  'Login Here',
                                  style: TextStyle(
                                    color: Color(0xFF2D3748),
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}