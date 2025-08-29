import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vaagaiauto/data/services/admin_service.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  AdminProfilePageState createState() => AdminProfilePageState();
}

class AdminProfilePageState extends State<AdminProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadAdminProfile();
  }

  // Load current admin profile data
  Future<void> _loadAdminProfile() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await AdminService.getAdminProfile();
      
      if (result['success'] && result['data'] != null) {
        final adminData = result['data'];
        setState(() {
          _nameController.text = adminData['name'] ?? '';
          _phoneController.text = adminData['phoneNumber'] ?? '';
          _passwordController.text = adminData['password'] ?? '';
        });
      } else {
        _showErrorDialog(result['message'] ?? 'Failed to load profile');
      }
    } catch (e) {
      _showErrorDialog('Failed to load profile: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Update admin profile
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // Show confirmation dialog first
    final shouldUpdate = await _showConfirmationDialog();
    if (!shouldUpdate) return;

    setState(() => _isUpdating = true);

    try {
      final result = await AdminService.updateAdminProfile(
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (result['success']) {
        _showSuccessDialog(result['data']);
      } else {
        _showErrorDialog(result['message'] ?? 'Update failed');
      }
    } catch (e) {
      _showErrorDialog('Error: ${e.toString()}');
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  // Show confirmation dialog before updating
  Future<bool> _showConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange[600]),
              SizedBox(width: 8),
              Text(
                'Confirm Update',
                style: GoogleFonts.lato(
                  color: Colors.orange[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to update your profile with these details?',
                style: GoogleFonts.lato(),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildConfirmDetailRow('Name', _nameController.text.trim()),
                    SizedBox(height: 6),
                    _buildConfirmDetailRow('Phone', _phoneController.text.trim()),
                    SizedBox(height: 6),
                    _buildConfirmDetailRow('Password', '•' * _passwordController.text.trim().length),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.lato(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Update',
                style: GoogleFonts.lato(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    ) ?? false;
  }

  // Show success popup with updated details
  void _showSuccessDialog(Map<String, dynamic> updatedData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, color: Colors.green[600], size: 24),
              ),
              SizedBox(width: 12),
              Text(
                'Profile Updated!',
                style: GoogleFonts.lato(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[600],
                ),
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your admin profile has been successfully updated with the following details:',
                  style: GoogleFonts.lato(fontSize: 14, color: Colors.grey[600]),
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person, color: Colors.green[600], size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Updated Profile Details',
                            style: GoogleFonts.lato(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                      Divider(color: Colors.green[300]),
                      SizedBox(height: 8),
                      _buildDetailRow('Admin Name', updatedData['name'] ?? 'N/A'),
                      SizedBox(height: 8),
                      _buildDetailRow('Phone Number', updatedData['phoneNumber'] ?? 'N/A'),
                      SizedBox(height: 8),
                      _buildDetailRow('Password', '•' * (updatedData['password']?.length ?? 3)),
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.green[700], size: 16),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Changes saved successfully',
                                style: GoogleFonts.lato(
                                  fontSize: 12,
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: Text(
                'Perfect!',
                style: GoogleFonts.lato(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Helper method to build detail rows in popup
  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: GoogleFonts.lato(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.lato(
              color: Colors.black,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // Helper method for confirmation dialog details
  Widget _buildConfirmDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            '$label:',
            style: GoogleFonts.lato(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.lato(
              color: Colors.black,
              fontSize: 13,
            ),
          ),
        ),
      ],
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
              Icon(Icons.error, color: Colors.red[600]),
              SizedBox(width: 8),
              Text(
                'Error',
                style: GoogleFonts.lato(
                  color: Colors.red[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: GoogleFonts.lato(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: GoogleFonts.lato(
                  color: Colors.red[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
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
      body: _isLoading 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow[600]!),
                ),
                SizedBox(height: 16),
                Text(
                  'Loading admin profile...',
                  style: GoogleFonts.lato(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
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
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter admin name';
                            }
                            if (value.trim().length < 2) {
                              return 'Name must be at least 2 characters';
                            }
                            return null;
                          },
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
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter phone number';
                            }
                            if (value.trim().length != 10) {
                              return 'Phone number must be 10 digits';
                            }
                            if (!RegExp(r'^[0-9]+$').hasMatch(value.trim())) {
                              return 'Phone number must contain only digits';
                            }
                            return null;
                          },
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
                          ),
                        ),
                        
                        SizedBox(height: 20),
                        
                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter password';
                            }
                            if (value.trim().length < 3) {
                              return 'Password must be at least 3 characters';
                            }
                            return null;
                          },
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
                            onPressed: (_isUpdating) ? null : _updateProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.yellow,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isUpdating
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'Updating...',
                                        style: GoogleFonts.lato(
                                          color: Colors.black,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
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
          ),
    );
  }
}
