import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/user_model.dart';
import '../../data/services/api_service.dart';

class DriverProfilePage extends StatefulWidget {
  final UserModel user;

  const DriverProfilePage({Key? key, required this.user}) : super(key: key);

  @override
  _DriverProfilePageState createState() => _DriverProfilePageState();
}

class _DriverProfilePageState extends State<DriverProfilePage> {
  final ApiService _apiService = ApiService();
  
  // State variables for user stats
  int _totalTrips = 0;
  double _totalEarnings = 0.0;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUserStats();
  }

  // NEW: Load user statistics from backend
  Future<void> _loadUserStats() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Get user ID with validation
      String userId = widget.user.id ?? '';
      
      print('Loading stats for user ID: $userId');

      if (userId.isEmpty || userId == 'null' || userId == 'undefined') {
        throw Exception('Invalid user ID');
      }

      // Fetch user statistics from backend
      final userStats = await _apiService.getUserStats(userId);

      if (userStats != null) {
        setState(() {
          // Parse totalTrips - handle both String and int types
          if (userStats['totalTrips'] != null) {
            if (userStats['totalTrips'] is Map && userStats['totalTrips']['\$numberInt'] != null) {
              _totalTrips = int.tryParse(userStats['totalTrips']['\$numberInt'].toString()) ?? 0;
            } else {
              _totalTrips = int.tryParse(userStats['totalTrips'].toString()) ?? 0;
            }
          }

          // Parse totalEarnings - handle both String and double types
          if (userStats['totalEarnings'] != null) {
            if (userStats['totalEarnings'] is Map && userStats['totalEarnings']['\$numberInt'] != null) {
              _totalEarnings = double.tryParse(userStats['totalEarnings']['\$numberInt'].toString()) ?? 0.0;
            } else {
              _totalEarnings = double.tryParse(userStats['totalEarnings'].toString()) ?? 0.0;
            }
          }

          _isLoading = false;
        });

        print('Stats loaded successfully: trips=$_totalTrips, earnings=$_totalEarnings');
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No data found';
        });
      }
    } catch (e) {
      print('Error loading user stats: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load statistics';
        // Set default values on error
        _totalTrips = 0;
        _totalEarnings = 0.0;
      });
    }
  }

  // NEW: Pull to refresh functionality
  Future<void> _refreshStats() async {
    await _loadUserStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.black),
        backgroundColor: Colors.yellow,
        foregroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.black),
            onPressed: _refreshStats,
            tooltip: 'Refresh Statistics',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshStats,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              // Driver Information Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.08),
                      spreadRadius: 1,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Driver Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildInfoRow(Icons.person_outline, 'Full Name', widget.user.name ?? 'Driver'),
                    _buildInfoRow(Icons.phone_outlined, 'Phone Number', widget.user.phoneNumber),
                    _buildInfoRow(Icons.verified_user_outlined, 'Status', 'Verified Driver'),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // Statistics Card with dynamic data
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.08),
                      spreadRadius: 1,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Statistics',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        if (_isLoading)
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.yellow[700],
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 16),
                    
                    if (_errorMessage.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        margin: EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red[600], size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage,
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _refreshStats,
                              child: Text(
                                'Retry',
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total Trips', 
                            _isLoading ? '...' : '$_totalTrips', 
                            Icons.route,
                            Colors.blue[600]!,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Total Earnings', 
                            _isLoading ? '...' : '₹${_totalEarnings.toStringAsFixed(2)}',
                            Icons.monetization_on,
                            Colors.green[600]!,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16),

                    // Last updated info
                    if (!_isLoading && _errorMessage.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Last updated: ${DateTime.now().toString().substring(0, 16)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),

              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon, 
              size: 18, 
              color: Colors.grey[600]
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              Spacer(),
            ],
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
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
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
