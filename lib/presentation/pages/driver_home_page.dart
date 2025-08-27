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

  const DriverHomePage({Key? key, required this.user}) : super(key: key);

  @override
  _DriverHomePageState createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> {
  int _todayTrips = 0;
  double _todayEarnings = 0.0;

  @override
  void initState() {
    super.initState();
    _loadDailyStats();
  }

  // FIXED: Load user-specific daily stats from SharedPreferences
  Future<void> _loadDailyStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentDate = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD format
      
      // Get user ID for user-specific storage keys
      final userId = widget.user.id ?? 'unknown_user';
      
      // USER-SPECIFIC KEYS - Each user has their own stats
      final userTripsKey = 'today_trips_$userId';
      final userEarningsKey = 'today_earnings_$userId';
      final userDateKey = 'daily_stats_date_$userId';
      
      // Get stored stats date to check if it's a new day FOR THIS USER
      final storedDate = prefs.getString(userDateKey) ?? '';
      
      print('Loading stats for user: $userId');
      print('Current date: $currentDate, Stored date: $storedDate');
      
      if (storedDate != currentDate) {
        // New day detected FOR THIS USER, reset stats to 0
        await prefs.setInt(userTripsKey, 0);
        await prefs.setDouble(userEarningsKey, 0.0);
        await prefs.setString(userDateKey, currentDate);
        
        if (mounted) {
          setState(() {
            _todayTrips = 0;
            _todayEarnings = 0.0;
          });
        }
        print('Daily stats reset for user $userId on new day: $currentDate');
      } else {
        // Same day, load existing stats FOR THIS USER
        final trips = prefs.getInt(userTripsKey) ?? 0;
        final earnings = prefs.getDouble(userEarningsKey) ?? 0.0;
        
        if (mounted) {
          setState(() {
            _todayTrips = trips;
            _todayEarnings = earnings;
          });
        }
        print('Daily stats loaded for user $userId: trips=$trips, earnings=$earnings');
      }
    } catch (e) {
      print('Error loading daily stats: $e');
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
                
                // Clear login status from local storage
                await _clearLoginStatus();
                
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
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

  // Clear login status from local storage (but keep user-specific daily stats)
  Future<void> _clearLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('is_logged_in');
      await prefs.remove('user_type');
      await prefs.remove('phone_number');
      await prefs.remove('user_name');
      await prefs.remove('login_timestamp');
      
      // NOTE: We don't clear user-specific daily stats here
      // so they persist even after logout/login on the same day
    } catch (e) {
      print('Error clearing login status: $e');
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
                    widget.user.name ?? 'Driver',
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
                    'ID: ${widget.user.id ?? 'N/A'}',
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
                            builder: (context) => DriverProfilePage(user: widget.user),
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
                            builder: (context) => DriverEarningsPage(user: widget.user),
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
                border: Border.all(color: Colors.black!),
              ),
              child: Center(
                child: Text(
                  '${_getGreeting()} ${widget.user.name ?? 'Driver'}!',
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
            Container(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () async {
                  // Navigate to Start Ride and refresh stats when returning
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StartRidePage(user: widget.user),
                    ),
                  );
                  // Refresh stats when returning from ride page
                  _loadDailyStats();
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
