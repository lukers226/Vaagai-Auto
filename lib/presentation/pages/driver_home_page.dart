import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../../data/models/user_model.dart';
import 'login_page.dart';
import 'driver_profile_page.dart';
import 'driver_earnings_page.dart';
import 'start_ride_page.dart';

class DriverHomePage extends StatefulWidget {
  final UserModel user;

  const DriverHomePage({super.key, required this.user});

  @override
  DriverHomePageState createState() => DriverHomePageState();
}

class DriverHomePageState extends State<DriverHomePage> with WidgetsBindingObserver {
  int _todayTrips = 0;
  double _todayEarnings = 0.0;
  late UserModel _currentUser;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentUser = widget.user;
    debugPrint('DriverHomePage initState - User ID: ${_currentUser.id}');
    _initializeUserData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh stats and user data when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      _initializeUserData();
    }
  }

  // Initialize and validate user data
  Future<void> _initializeUserData() async {
    try {
      // First, try to load user data from SharedPreferences if current user ID is empty
      if (_currentUser.id?.isEmpty ?? true) {
        await _loadUserDataFromPrefs();
      }
      
      // Save current user data to SharedPreferences for persistence
      await _saveUserDataToPrefs();
      
      // Load daily stats
      await _loadDailyStats();
    } catch (e) {
      debugPrint('Error initializing user data: $e');
      // If user data is invalid, redirect to login
      if (_currentUser.id?.isEmpty ?? true) {
        _redirectToLogin();
      }
    }
  }

  // Save user data to SharedPreferences for persistence
  Future<void> _saveUserDataToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_currentUser.id?.isNotEmpty == true) {
        await prefs.setString('saved_user_id', _currentUser.id!);
        await prefs.setString('saved_user_name', _currentUser.name ?? '');
        await prefs.setString('saved_user_phone', _currentUser.phoneNumber);
        await prefs.setString('saved_user_type', _currentUser.userType);
        debugPrint('User data saved to SharedPreferences: ID=${_currentUser.id}');
      }
    } catch (e) {
      debugPrint('Error saving user data: $e');
    }
  }

  // Load user data from SharedPreferences
  Future<void> _loadUserDataFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUserId = prefs.getString('saved_user_id') ?? '';
      final savedUserName = prefs.getString('saved_user_name') ?? '';
      final savedUserPhone = prefs.getString('saved_user_phone') ?? '';
      final savedUserType = prefs.getString('saved_user_type') ?? '';
      
      debugPrint('Loading user data from SharedPreferences:');
      debugPrint('Saved User ID: $savedUserId');
      debugPrint('Saved User Name: $savedUserName');
      debugPrint('Saved User Phone: $savedUserPhone');
      
      if (savedUserId.isNotEmpty) {
        // Create new UserModel with saved data
        _currentUser = UserModel(
          id: savedUserId,
          name: savedUserName,
          phoneNumber: savedUserPhone,
          userType: savedUserType,
        );
        debugPrint('User data restored from SharedPreferences');
      } else {
        debugPrint('No saved user data found in SharedPreferences');
      }
    } catch (e) {
      debugPrint('Error loading user data from SharedPreferences: $e');
    }
  }

  // Redirect to login if user data is invalid
  void _redirectToLogin() {
    debugPrint('Invalid user session detected, redirecting to login');
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
  }

  // FIXED: Proper daily stats management with user validation
  Future<void> _loadDailyStats() async {
    try {
      // Validate user ID first
      if (_currentUser.id?.isEmpty ?? true) {
        debugPrint('Cannot load daily stats: User ID is null or empty');
        setState(() {
          _todayTrips = 0;
          _todayEarnings = 0.0;
        });
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      
      // Get user ID for user-specific storage keys
      final userId = _currentUser.id!;
      
      // USER-SPECIFIC KEYS - Each user has their own stats
      final userTripsKey = 'today_trips_$userId';
      final userEarningsKey = 'today_earnings_$userId';
      final userLastResetKey = 'last_reset_timestamp_$userId';
      
      debugPrint('Loading stats for user: $userId');
      
      // Get the last reset timestamp (when stats were last reset to 0)
      final lastResetTimestamp = prefs.getInt(userLastResetKey) ?? 0;
      final lastResetDate = DateTime.fromMillisecondsSinceEpoch(lastResetTimestamp);
      
      debugPrint('Current time: $now');
      debugPrint('Last reset: $lastResetDate');
      
      // Check if we need to reset stats (new day after 11:59 PM)
      bool needsReset = false;
      
      if (lastResetTimestamp == 0) {
        // First time using the app
        needsReset = true;
        debugPrint('First time use - resetting stats');
      } else {
        // Check if it's a new day (after 11:59 PM)
        final todayMidnight = DateTime(now.year, now.month, now.day, 23, 59, 59);
        
        if (now.isAfter(todayMidnight) && lastResetDate.isBefore(todayMidnight)) {
          needsReset = true;
          debugPrint('New day detected - resetting stats');
        } else if (now.day != lastResetDate.day || now.month != lastResetDate.month || now.year != lastResetDate.year) {
          // Also reset if it's a different calendar day (fallback)
          needsReset = true;
          debugPrint('Different calendar day - resetting stats');
        }
      }
      
      if (needsReset) {
        // Reset stats to 0 for new day
        await prefs.setInt(userTripsKey, 0);
        await prefs.setDouble(userEarningsKey, 0.0);
        await prefs.setInt(userLastResetKey, now.millisecondsSinceEpoch);
        
        if (mounted) {
          setState(() {
            _todayTrips = 0;
            _todayEarnings = 0.0;
          });
        }
        debugPrint('Stats reset for user $userId');
      } else {
        // Load existing stats for the current day
        final trips = prefs.getInt(userTripsKey) ?? 0;
        final earnings = prefs.getDouble(userEarningsKey) ?? 0.0;
        
        if (mounted) {
          setState(() {
            _todayTrips = trips;
            _todayEarnings = earnings;
          });
        }
        debugPrint('Stats loaded for user $userId: trips=$trips, earnings=$earnings');
      }
    } catch (e) {
      debugPrint('Error loading daily stats: $e');
      // Set default values on error
      if (mounted) {
        setState(() {
          _todayTrips = 0;
          _todayEarnings = 0.0;
        });
      }
    }
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              Icon(Icons.logout, color: Colors.red),
              SizedBox(width: 10),
              Text('Logout'),
            ],
          ),
          content: Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                context.read<AuthBloc>().add(LogoutRequested());
                
                // Clear login status and user data from local storage
                await _clearAllUserData();
                
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => LoginPage()),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Logout', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // Clear all user data from local storage including saved user data
  Future<void> _clearAllUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Clear login status
      await prefs.remove('is_logged_in');
      await prefs.remove('user_type');
      await prefs.remove('phone_number');
      await prefs.remove('user_name');
      await prefs.remove('login_timestamp');
      
      // Clear saved user data
      await prefs.remove('saved_user_id');
      await prefs.remove('saved_user_name');
      await prefs.remove('saved_user_phone');
      await prefs.remove('saved_user_type');
      
      // Keep user-specific daily stats for potential re-login
      // (Don't clear today_trips_*, today_earnings_*, last_reset_timestamp_*)
      
      debugPrint('All user data cleared except daily stats');
    } catch (e) {
      debugPrint('Error clearing user data: $e');
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Driver Dashboard', 
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold, 
            color: Colors.black
          ),
        ),
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.black),
        backgroundColor: Colors.yellow,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(20, 50, 20, 20),
              color: Colors.yellow,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(35),
                      child: Image.asset(
                        'assets/images/driver_profile.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.black,
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    _currentUser.name ?? 'Driver',
                    style: GoogleFonts.lato(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Auto Driver',
                    style: GoogleFonts.lato(
                      color: Colors.black,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 8),
                  // Show user ID for debugging (remove in production)
                  Text(
                    'ID: ${_currentUser.id ?? 'N/A'}',
                    style: GoogleFonts.lato(
                      color: Colors.black54,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.white,
                child: ListView(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  children: [
                    _buildDrawerItem(
                      icon: Icons.person,
                      title: 'Profile',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DriverProfilePage(user: _currentUser),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.account_balance_wallet,
                      title: 'Performance Summary',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DriverEarningsPage(user: _currentUser),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.logout,
                      title: 'Logout',
                      textColor: Colors.red,
                      onTap: () {
                        Navigator.pop(context);
                        _logout(context);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Greeting Message Box
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black),
              ),
              child: Center(
                child: Text(
                  '${_getGreeting()} ${_currentUser.name ?? 'Driver'}!',
                  style: GoogleFonts.lato(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellow,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            SizedBox(height: 30),

            // Start Ride Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () async {
                  // Validate user before navigation
                  if (_currentUser.id?.isEmpty ?? true) {
                    _showSnackBar('Please login again to start ride', false);
                    _redirectToLogin();
                    return;
                  }
                  
                  // Navigate to Start Ride and refresh stats when returning
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StartRidePage(user: _currentUser),
                    ),
                  );
                  // Refresh stats when returning from ride page
                  await _initializeUserData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.directions_car, size: 24),
                    SizedBox(width: 10),
                    Text(
                      'Auto Meter is Ready!',
                      style: GoogleFonts.lato(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 30),

            // User-Specific Dynamic Stats Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Today\'s Trips', 
                    '$_todayTrips', 
                    Icons.route, 
                    Colors.blue[600]!
                  ),
                ),
                SizedBox(width: 15),
                Expanded(
                  child: _buildStatCard(
                    'Today Earnings', 
                    '₹${_todayEarnings.toStringAsFixed(2)}', 
                    Icons.monetization_on, 
                    Colors.orange[600]!
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(
        icon, 
        color: textColor ?? Colors.grey[700],
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? Colors.grey[800],
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
