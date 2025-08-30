import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vaagaiauto/data/models/user_model.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/auth/auth_state.dart';
import '../../core/utils/validators.dart';
import 'admin_page.dart';
import 'driver_home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkLoginStatus();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));
    
    _animationController.forward();
  }

  // Check if user is already logged in (silent check)
  Future<void> _checkLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      final userType = prefs.getString('user_type') ?? '';
      final phoneNumber = prefs.getString('phone_number') ?? '';
      final userName = prefs.getString('user_name') ?? '';

      if (isLoggedIn && phoneNumber.isNotEmpty) {
        // User is already logged in, navigate to appropriate page
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            if (userType == 'admin') {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => AdminPage()),
              );
            } else {
              // Create user model from stored data
              final userModel = UserModel(
                name: userName,
                phoneNumber: phoneNumber,
                userType: userType,
                id: '',
              );
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => DriverHomePage(user: userModel),
                ),
              );
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error checking login status: $e');
    }
  }

  // Save login status to local storage
  Future<void> _saveLoginStatus(AuthSuccess state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setString('user_type', state.user.userType);
      await prefs.setString('phone_number', state.user.phoneNumber);
      await prefs.setString('user_name', state.user.name ?? '');
      await prefs.setString('login_timestamp', DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Error saving login status: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showSuccessAnimation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.check,
              color: Colors.white,
              size: 50,
            ),
          ),
        );
      },
    );
    
    // Auto dismiss after 1 second
    Future.delayed(Duration(seconds: 1), () {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            _showSuccessAnimation();
            
            // Save login status to local storage
            _saveLoginStatus(state);
            
            // Navigate after animation
            Future.delayed(Duration(seconds: 1), () {
              if (mounted) {
                if (state.user.userType == 'admin') {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => AdminPage()),
                  );
                } else {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => DriverHomePage(user: state.user),
                    ),
                  );
                }
              }
            });
          } else if (state is AuthFailure) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.white, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Login Failed..Please check network connection',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              state.message,
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.red[600],
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: EdgeInsets.all(16),
                  duration: Duration(seconds: 4),
                ),
              );
            }
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 60),
                      
                      // Logo Image Container with Enhanced Design
                      Hero(
                        tag: 'app_logo',
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withValues(alpha: 0.3),
                                spreadRadius: 8,
                                blurRadius: 20,
                                offset: Offset(0, 8),
                              ),
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.1),
                                spreadRadius: 2,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [Colors.amber[600]!, Colors.amber[400]!],
                                    ),
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Icon(
                                    Icons.directions_car,
                                    size: 70,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 40),
                      
                      // Brand Title with Animation
                      Text(
                        'Vaagai Meter Auto',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                          letterSpacing: 1.2,
                        ),
                      ),
                      
                      SizedBox(height: 8),
                      
                      Text(
                        'Your trusted auto meter companion',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      SizedBox(height: 50),
                      
                      // Enhanced Login Form Card
                      Container(
                        padding: EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.15),
                              spreadRadius: 3,
                              blurRadius: 15,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Welcome Text
                              Center(
                                child: Column(
                                  children: [
                                    Text(
                                      'Welcome Back!',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Sign in to continue to your account',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              SizedBox(height: 30),
                              
                              Text(
                                'Phone Number',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                              
                              SizedBox(height: 12),
                              
                              // Enhanced Phone Number Field
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                validator: Validators.validatePhoneNumber,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Enter your mobile number',
                                  hintStyle: TextStyle(color: Colors.grey[400]),
                                  prefixIcon: Container(
                                    padding: EdgeInsets.all(12),
                                    child: Icon(
                                      Icons.phone_android,
                                      color: Colors.amber[600],
                                      size: 24,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide(color: Colors.amber[600]!, width: 2),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide(color: Colors.red[400]!, width: 2),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide(color: Colors.red[400]!, width: 2),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                ),
                              ),
                              
                              SizedBox(height: 30),
                              
                              // Enhanced Login Button
                              Container(
                                width: double.infinity,
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  gradient: LinearGradient(
                                    colors: state is AuthLoading 
                                        ? [Colors.grey[400]!, Colors.grey[300]!]
                                        : [Colors.amber[600]!, Colors.amber[500]!],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (state is AuthLoading ? Colors.grey : Colors.amber)
                                          .withValues(alpha: 0.3),
                                      spreadRadius: 1,
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(15),
                                    onTap: state is AuthLoading ? null : () {
                                      if (_formKey.currentState!.validate()) {
                                        context.read<AuthBloc>().add(
                                          LoginRequested(phoneNumber: _phoneController.text.trim()),
                                        );
                                      }
                                    },
                                    child: Center(
                                      child: state is AuthLoading
                                          ? Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 3,
                                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                  ),
                                                ),
                                                SizedBox(width: 15),
                                                Text(
                                                  'Signing In...',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.login,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Continue',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w600,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 30),
                      
                      // Footer
                      Text(
                        '© 2025 Vaagai Meter Auto - All Rights Reserved',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
