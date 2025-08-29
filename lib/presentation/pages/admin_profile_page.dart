import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vaagaiauto/data/services/admin_service.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  AdminProfilePageState createState() => AdminProfilePageState();
}

class AdminProfilePageState extends State<AdminProfilePage> {
  // Current credentials controllers (Step 1)
  final TextEditingController _currentNameController = TextEditingController();
  final TextEditingController _currentPhoneController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  
  // New credentials controllers (Step 2)
  final TextEditingController _newNameController = TextEditingController();
  final TextEditingController _newPhoneController = TextEditingController();
  
  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();

  bool _isCurrentPasswordVisible = false;
  bool _isLoading = false;
  bool _isValidating = false;
  bool _isUpdating = false;
  bool _isStep2 = false; // Track which step we're on
  
  Map<String, dynamic>? _currentAdminData; // Store current admin data

  @override
  void initState() {
    super.initState();
    _loadAdminProfile();
  }

  // Load current admin profile data (only for display purposes)
  Future<void> _loadAdminProfile() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await AdminService.getAdminProfile();
      
      if (result['success'] && result['data'] != null) {
        _currentAdminData = result['data'];
      } else {
        _showErrorDialog('Failed to load profile: ${result['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      _showErrorDialog('Failed to load profile: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Step 1: Validate current credentials
  Future<void> _validateCurrentCredentials() async {
    if (!_step1FormKey.currentState!.validate()) return;

    setState(() => _isValidating = true);

    try {
      // Check if entered credentials match the current admin data
      if (_currentAdminData == null) {
        _showErrorDialog('Admin data not loaded. Please refresh the page.');
        return;
      }

      final enteredName = _currentNameController.text.trim();
      final enteredPhone = _currentPhoneController.text.trim();
      final enteredPassword = _currentPasswordController.text.trim();

      final currentName = _currentAdminData!['name']?.toString().trim() ?? '';
      final currentPhone = _currentAdminData!['phoneNumber']?.toString().trim() ?? '';
      final currentPassword = _currentAdminData!['password']?.toString().trim() ?? '';

      // Validate each field
      List<String> errors = [];
      
      if (enteredName != currentName) {
        errors.add('Admin name does not match current profile');
      }
      
      if (enteredPhone != currentPhone) {
        errors.add('Phone number does not match current profile');
      }
      
      if (enteredPassword != currentPassword) {
        errors.add('Password does not match current profile');
      }

      if (errors.isNotEmpty) {
        _showErrorDialog('Credential validation failed:\n• ${errors.join('\n• ')}');
        return;
      }

      // Credentials match - proceed to step 2
      _showValidationSuccessDialog();

    } catch (e) {
      _showErrorDialog('Validation error: ${e.toString()}');
    } finally {
      setState(() => _isValidating = false);
    }
  }

  // Show validation success and move to step 2
  void _showValidationSuccessDialog() {
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
                child: Icon(Icons.verified, color: Colors.green[600], size: 24),
              ),
              SizedBox(width: 12),
              Text(
                'Credentials Verified!',
                style: GoogleFonts.lato(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[600],
                ),
              ),
            ],
          ),
          content: Text(
            'Your current credentials have been verified successfully. You can now enter your new profile details.',
            style: GoogleFonts.lato(fontSize: 14, color: Colors.grey[600]),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _isStep2 = true;
                  // Pre-fill with current data for easy editing
                  _newNameController.text = _currentAdminData!['name'] ?? '';
                  _newPhoneController.text = _currentAdminData!['phoneNumber'] ?? '';
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Continue',
                style: GoogleFonts.lato(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  // Step 2: Update profile with new credentials
  Future<void> _updateProfile() async {
    if (!_step2FormKey.currentState!.validate()) return;

    // Show confirmation dialog first
    final shouldUpdate = await _showUpdateConfirmationDialog();
    if (!shouldUpdate) return;

    setState(() => _isUpdating = true);

    try {
      final result = await AdminService.updateAdminProfile(
        name: _newNameController.text.trim(),
        phoneNumber: _newPhoneController.text.trim(),
        password: _currentPasswordController.text.trim(), // Keep the same password
      );

      if (result['success']) {
        _showUpdateSuccessDialog(result['data']);
      } else {
        _showErrorDialog(result['message'] ?? 'Update failed');
      }
    } catch (e) {
      _showErrorDialog('Error: ${e.toString()}');
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  // Show update confirmation dialog
  Future<bool> _showUpdateConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(Icons.update, color: Colors.blue[600]),
              SizedBox(width: 8),
              Text(
                'Confirm Profile Update',
                style: GoogleFonts.lato(
                  color: Colors.blue[600],
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
                'Are you sure you want to update your profile with these new details?',
                style: GoogleFonts.lato(),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'New Profile Details:',
                      style: GoogleFonts.lato(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    _buildConfirmDetailRow('New Name', _newNameController.text.trim()),
                    SizedBox(height: 6),
                    _buildConfirmDetailRow('New Phone', _newPhoneController.text.trim()),
                    SizedBox(height: 6),
                    _buildConfirmDetailRow('Password', 'Unchanged'),
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
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Update Profile',
                style: GoogleFonts.lato(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    ) ?? false;
  }

  // Show success popup with updated details (password not shown)
  void _showUpdateSuccessDialog(Map<String, dynamic> updatedData) {
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
                child: Icon(Icons.check_circle, color: Colors.green[600], size: 24),
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
                      _buildDetailRow('Password', 'Protected (Not Displayed)'),
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.security, color: Colors.green[700], size: 16),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Password remains secure and unchanged',
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
                // Reset to step 1
                _resetToStep1();
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
                style: GoogleFonts.lato(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  // Reset to step 1
  void _resetToStep1() {
    setState(() {
      _isStep2 = false;
      _currentNameController.clear();
      _currentPhoneController.clear();
      _currentPasswordController.clear();
      _newNameController.clear();
      _newPhoneController.clear();
    });
    _loadAdminProfile(); // Refresh admin data
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
    _currentNameController.dispose();
    _currentPhoneController.dispose();
    _currentPasswordController.dispose();
    _newNameController.dispose();
    _newPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _isStep2 ? 'Update Admin Profile' : 'Verify Admin Profile',
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
        leading: _isStep2 ? IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            setState(() {
              _isStep2 = false;
            });
          },
        ) : null,
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
            child: _isStep2 ? _buildStep2UI() : _buildStep1UI(),
          ),
    );
  }

  // Build Step 1 UI - Verify Current Credentials
  Widget _buildStep1UI() {
    return Form(
      key: _step1FormKey,
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
                
               
                Text(
                  'Verify Current Credentials',
                  style: GoogleFonts.lato(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
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
                  'Current Admin Credentials',
                  style: GoogleFonts.lato(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 24),
                
                // Current Name Field
                TextFormField(
                  controller: _currentNameController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter current admin name';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Admin Name',
                    hintText: 'Enter your current admin name',
                    prefixIcon: Icon(Icons.person_outline, color: Colors.black),
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
                
                // Current Phone Field
                TextFormField(
                  controller: _currentPhoneController,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter current phone number';
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
                    hintText: 'Enter your current phone number',
                    prefixIcon: Icon(Icons.phone_outlined, color: Colors.black),
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
                
                // Current Password Field
                TextFormField(
                  controller: _currentPasswordController,
                  obscureText: !_isCurrentPasswordVisible,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter current password';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your current password',
                    prefixIcon: Icon(Icons.lock_outline, color: Colors.black),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isCurrentPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: Colors.red[600],
                      ),
                      onPressed: () {
                        setState(() {
                          _isCurrentPasswordVisible = !_isCurrentPasswordVisible;
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
                
                // Verify Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isValidating ? null : _validateCurrentCredentials,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow[600],
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isValidating
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Verifying...',
                                style: GoogleFonts.lato(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            'Verify Credentials',
                            style: GoogleFonts.lato(
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
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.security,
                  color: Colors.orange[700],
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Enter your exact current credentials to proceed with profile update.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange[800],
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

  // Build Step 2 UI - Enter New Credentials
  Widget _buildStep2UI() {
    return Form(
      key: _step2FormKey,
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
               
                SizedBox(height: 16),
                Text(
                  'Update Profile Details',
                  style: GoogleFonts.lato(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Enter your new admin name and phone number',
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
                  'New Admin Information',
                  style: GoogleFonts.lato(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 24),
                
                // New Name Field
                TextFormField(
                  controller: _newNameController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter new admin name';
                    }
                    if (value.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'New Admin Name',
                    hintText: 'Enter new admin name',
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
                
                // New Phone Field
                TextFormField(
                  controller: _newPhoneController,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter new phone number';
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
                    labelText: 'New Phone Number',
                    hintText: 'Enter new phone number',
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
                
                // Password Info
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock, color: Colors.grey[600], size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Password will remain unchanged for security',
                          style: GoogleFonts.lato(
                            fontSize: 14,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 32),
                
                // Update Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isUpdating ? null : _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow[600],
                      foregroundColor: Colors.black,
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
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Updating Profile...',
                                style: GoogleFonts.lato(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            'Update Profile',
                            style: GoogleFonts.lato(
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
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue[700],
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Review your new details carefully before confirming the update.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue[800],
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
}
