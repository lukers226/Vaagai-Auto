import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/user_model.dart';
import '../../data/services/api_service.dart';

class DriverEarningsPage extends StatefulWidget {
  final UserModel user;

  const DriverEarningsPage({Key? key, required this.user}) : super(key: key);

  @override
  _DriverEarningsPageState createState() => _DriverEarningsPageState();
}

class _DriverEarningsPageState extends State<DriverEarningsPage> {
  final ApiService _apiService = ApiService();
  
  // State variables for user stats
  int _totalRides = 0;
  int _cancelledRides = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEarningsData();
  }

  // NEW: Load earnings data from backend
  Future<void> _loadEarningsData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Get user ID with validation
      String userId = widget.user.id ?? '';
      
      print('Loading earnings data for user ID: $userId');

      if (userId.isEmpty || userId == 'null' || userId == 'undefined') {
        throw Exception('Invalid user ID');
      }

      // Fetch user statistics from backend
      final userStats = await _apiService.getUserStats(userId);

      if (userStats != null) {
        setState(() {
          // Parse totalRides - handle both String and int types
          if (userStats['totalRides'] != null) {
            if (userStats['totalRides'] is Map && userStats['totalRides']['\$numberInt'] != null) {
              _totalRides = int.tryParse(userStats['totalRides']['\$numberInt'].toString()) ?? 0;
            } else {
              _totalRides = int.tryParse(userStats['totalRides'].toString()) ?? 0;
            }
          }

          // Parse cancelledRides - handle both String and int types
          if (userStats['cancelledRides'] != null) {
            if (userStats['cancelledRides'] is Map && userStats['cancelledRides']['\$numberInt'] != null) {
              _cancelledRides = int.tryParse(userStats['cancelledRides']['\$numberInt'].toString()) ?? 0;
            } else {
              _cancelledRides = int.tryParse(userStats['cancelledRides'].toString()) ?? 0;
            }
          }

          _isLoading = false;
        });

        print('Earnings data loaded successfully: totalRides=$_totalRides, cancelledRides=$_cancelledRides');
      } else {
        setState(() {
          _isLoading = false;
          // Set default values on no data
          _totalRides = 0;
          _cancelledRides = 0;
        });
      }
    } catch (e) {
      print('Error loading earnings data: $e');
      setState(() {
        _isLoading = false;
        // Set default values on error
        _totalRides = 0;
        _cancelledRides = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Performance Summary',style: GoogleFonts.poppins(fontWeight: FontWeight.bold,color: Colors.black)),
        centerTitle: false,
        backgroundColor: Colors.yellow,
        iconTheme: IconThemeData(
          color: Colors.black
        ),
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
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
                    'Performance Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryItem(
                          'Total Rides',
                          _isLoading ? '...' : '$_totalRides', // CHANGED: Now shows database value
                          Icons.directions_car,
                          Colors.blue[600]!,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey[200],
                      ),
                      Expanded(
                        child: _buildSummaryItem(
                          'Cancel Rides',
                          _isLoading ? '...' : '$_cancelledRides', // CHANGED: Now shows database value
                          Icons.trending_up,
                          Colors.red[600]!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningCard(String period, String amount, IconData icon, Color color) {
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
              Icon(icon, color: color, size: 18),
              Spacer(),
            ],
          ),
          SizedBox(height: 8),
          Text(
            amount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            period,
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

  Widget _buildSummaryItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
