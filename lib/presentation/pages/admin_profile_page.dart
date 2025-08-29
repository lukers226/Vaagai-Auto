import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiConstants {
  static const String baseUrl = "https://vaagai-auto.onrender.com/api";
  static const String adminLoginEndpoint = "/auth/admin-login";
  static const String updateAdminProfileEndpoint = "/auth/admin";
}

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  AdminProfilePageState createState() => AdminProfilePageState();
}

class AdminProfilePageState extends State<AdminProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Controllers for update dialog
  final TextEditingController _newNameController = TextEditingController();
  final TextEditingController _newPhoneController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _newNameController.dispose();
    _newPhoneController.dispose();
    super.dispose();
  }

  // Validate admin credentials using your existing admin-login endpoint
  Future<bool> _validateAdminCredentials() async {
    try {
      setState(() => _isLoading = true);

      // Ensure all fields have values
      final String phoneNumber = _phoneController.text.trim();
      final String password = _passwordController.text.trim();
      final String name = _nameController.text.trim();

      // Check if any field is empty
      if (phoneNumber.isEmpty || password.isEmpty || name.isEmpty) {
        setState(() => _isLoading = false);
        _showErrorDialog('Please fill all fields');
        return false;
      }

      print('Validating credentials for: $phoneNumber with name: $name');

      final Map<String, dynamic> requestBody = {
        'phoneNumber': phoneNumber,
        'password': password,
      };

      print('Request body: $requestBody');

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.adminLoginEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      setState(() => _isLoading = false);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true && data['user'] != null) {
          // Check if the name matches as well
          final String dbName = data['user']['name']?.toString() ?? '';
          if (dbName.toLowerCase() == name.toLowerCase()) {
            return true;
          } else {
            _showErrorDialog('Name does not match our records.\nExpected: $dbName\nEntered: $name');
            return false;
          }
        } else {
          _showErrorDialog(data['message'] ?? 'Invalid credentials');
          return false;
        }
      } else {
        final errorData = jsonDecode(response.body);
        _showErrorDialog(errorData['message'] ?? 'Invalid credentials. Please check your phone number and password.');
        return false;
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('Validation error: $e');
      _showErrorDialog('Network error. Please check your connection and try again.');
      return false;
    }
  }

  // Update admin profile using new endpoint
  Future<void> _updateAdminProfile(String newName, String newPhone) async {
    try {
      setState(() => _isLoading = true);

      // Ensure all parameters have values
      final String currentPhone = _phoneController.text.trim();
      final String password = _passwordController.text.trim();

      if (currentPhone.isEmpty || password.isEmpty || newName.isEmpty || newPhone.isEmpty) {
        setState(() => _isLoading = false);
        _showErrorDialog('All fields are required');
        return;
      }

      final Map<String, dynamic> requestBody = {
        'name': newName,
        'phoneNumber': newPhone,
        'password': password,
      };

      print('Update request body: $requestBody');
      print('Update URL: ${ApiConstants.baseUrl}${ApiConstants.updateAdminProfileEndpoint}/$currentPhone/update');

      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.updateAdminProfileEndpoint}/$currentPhone/update'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      setState(() => _isLoading = false);

      print('Update response status: ${response.statusCode}');
      print('Update response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _showSuccessDialog('Profile updated successfully!');
          // Clear the form
          _nameController.clear();
          _phoneController.clear();
          _passwordController.clear();
        } else {
          _showErrorDialog(data['message'] ?? 'Failed to update profile');
        }
      } else {
        final errorData = jsonDecode(response.body);
        _showErrorDialog(errorData['message'] ?? 'Failed to update profile. Please try again.');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('Update error: $e');
      _showErrorDialog('Network error. Please check your connection and try again.');
    }
  }

  // Show update dialog
  void _showUpdateDialog() {
    // Pre-fill with current values
    _newNameController.text = _nameController.text.trim();
    _newPhoneController.text = _phoneController.text.trim();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Text(
                'Update Profile',
                style: GoogleFonts.lato(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Enter new details to update your profile',
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _newNameController,
                      decoration: InputDecoration(
                        labelText: 'New Name',
                        prefixIcon: Icon(Icons.person, color: Colors.black),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.yellow[600]!, width: 2),
                        ),
                      ),
                      onChanged: (value) {
                        // This ensures the dialog updates when text changes
                        setDialogState(() {});
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _newPhoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      decoration: InputDecoration(
                        labelText: 'New Phone Number',
                        prefixIcon: Icon(Icons.phone, color: Colors.black),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.yellow[600]!, width: 2),
                        ),
                        counterText: '', // Hide character counter
                      ),
                      onChanged: (value) {
                        // Only allow numbers
                        if (value.isNotEmpty && !RegExp(r'^[0-9]+$').hasMatch(value)) {
                          _newPhoneController.text = value.replaceAll(RegExp(r'[^0-9]'), '');
                          _newPhoneController.selection = TextSelection.fromPosition(
                            TextPosition(offset: _newPhoneController.text.length),
                          );
                        }
                        setDialogState(() {});
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                ElevatedButton(
                  onPressed: (_newNameController.text.trim().isEmpty ||
                          _newPhoneController.text.trim().isEmpty ||
                          _newPhoneController.text.trim().length != 10)
                      ? null
                      : () async {
                          final String newName = _newNameController.text.trim();
                          final String newPhone = _newPhoneController.text.trim();

                          // Validate phone number format
                          if (!RegExp(r'^[0-9]{10}$').hasMatch(newPhone)) {
                            _showErrorDialog('Phone number must be exactly 10 digits');
                            return;
                          }

                          // Validate name
                          if (newName.length < 2) {
                            _showErrorDialog('Name must be at least 2 characters');
                            return;
                          }

                          Navigator.of(context).pop();
                          await _updateAdminProfile(newName, newPhone);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Submit',
                    style: GoogleFonts.lato(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('Error'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Show success dialog
  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.green),
              SizedBox(width: 8),
              Text('Success'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Handle update profile button press
  void _handleUpdateProfile() async {
    // Validate form fields
    final String name = _nameController.text.trim();
    final String phone = _phoneController.text.trim();
    final String password = _passwordController.text.trim();

    if (name.isEmpty || phone.isEmpty || password.isEmpty) {
      _showErrorDialog('Please fill all fields');
      return;
    }

    // Validate phone number format
    if (!RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
      _showErrorDialog('Phone number must be exactly 10 digits');
      return;
    }

    // Validate name length
    if (name.length < 2) {
      _showErrorDialog('Name must be at least 2 characters');
      return;
    }

    // Validate credentials first
    bool isValid = await _validateAdminCredentials();
    
    if (isValid) {
      // Show update dialog
      _showUpdateDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Admin Profile',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.black),
        backgroundColor: Colors.yellow,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.yellow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.admin_panel_settings,
                          color: Colors.black,
                          size: 30,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Admin Profile Update',
                        style: GoogleFonts.lato(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Update your profile information',
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 24),
                
                // Form Card
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin Information',
                        style: GoogleFonts.lato(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 24),
                      
                      // Name Field
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Admin Name',
                          hintText: 'Enter full name',
                          prefixIcon: Icon(Icons.person, color: Colors.black),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.yellow[600]!, width: 2),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                      
                      SizedBox(height: 20),
                      
                      // Phone Field
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          hintText: 'Enter mobile number',
                          prefixIcon: Icon(Icons.phone, color: Colors.black),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.yellow[600]!, width: 2),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          counterText: '', // Hide character counter
                        ),
                        onChanged: (value) {
                          // Only allow numbers
                          if (value.isNotEmpty && !RegExp(r'^[0-9]+$').hasMatch(value)) {
                            _phoneController.text = value.replaceAll(RegExp(r'[^0-9]'), '');
                            _phoneController.selection = TextSelection.fromPosition(
                              TextPosition(offset: _phoneController.text.length),
                            );
                          }
                        },
                      ),
                      
                      SizedBox(height: 20),
                      
                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter password',
                          prefixIcon: Icon(Icons.lock, color: Colors.black),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                              color: Colors.black,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.yellow[600]!, width: 2),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                      
                      SizedBox(height: 32),
                      
                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleUpdateProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.yellow,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                )
                              : Text(
                                  'Update Profile',
                                  style: GoogleFonts.lato(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 20),
                
                // Info Card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.amber[700],
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Make sure all information is correct before updating.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.amber[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
