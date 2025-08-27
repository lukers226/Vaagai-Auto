import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import 'login_page.dart';

class SplashPage extends StatefulWidget {
  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _leftTextController;
  late AnimationController _rightTextController;
  late AnimationController _fadeController;
  
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _leftTextAnimation;
  late Animation<Offset> _rightTextAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _scaleController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _leftTextController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _rightTextController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Define animations
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    // Left text slides from left to center
    _leftTextAnimation = Tween<Offset>(
      begin: Offset(-2.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _leftTextController,
      curve: Curves.easeOutBack,
    ));
    
    // Right text slides from right to center
    _rightTextAnimation = Tween<Offset>(
      begin: Offset(2.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _rightTextController,
      curve: Curves.easeOutBack,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    // Start animations
    _startAnimations();
    _navigateToLogin();
  }

  void _startAnimations() async {
    // Start image scale animation
    await Future.delayed(Duration(milliseconds: 300));
    _scaleController.forward();
    
    // Start both text animations simultaneously with slight delay
    await Future.delayed(Duration(milliseconds: 600));
    _leftTextController.forward();
    _rightTextController.forward();
    
    // Start loading indicator fade animation
    await Future.delayed(Duration(milliseconds: 400));
    _fadeController.forward();
  }

  _navigateToLogin() async {
    await Future.delayed(Duration(seconds: AppConstants.splashDuration));
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _leftTextController.dispose();
    _rightTextController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.amber[400]!,
              Colors.amber[600]!,
              Colors.amber[800]!,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Image in Center
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 180,
                  height: 180,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.amber[600]!, Colors.amber[400]!],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.directions_car,
                            size: 80,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
 
              
              // Animated App Name with Split Text Animation
              Container(
                height: 50, // Fixed height to prevent layout shifts
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // "Vaagai" text sliding from left
                    SlideTransition(
                      position: _leftTextAnimation,
                      child: Text(
                        'Vaagai',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 2),
                              blurRadius: 4,
                              color: Colors.black.withOpacity(0.3),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    SizedBox(width: 8), // Space between words
                    
                    // "Auto" text sliding from right
                    SlideTransition(
                      position: _rightTextAnimation,
                      child: Text(
                        'Auto',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 2),
                              blurRadius: 4,
                              color: Colors.black.withOpacity(0.3),
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
}
