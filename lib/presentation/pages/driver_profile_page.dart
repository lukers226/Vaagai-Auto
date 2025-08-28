import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/user_model.dart';
import '../../data/services/api_service.dart';

class DriverProfilePage extends StatefulWidget {
  final UserModel user;

  const DriverProfilePage({super.key, required this.user});

  @override
  DriverProfilePageState createState() => DriverProfilePageState();
}

class DriverProfilePageState extends State<DriverProfilePage> {
  final ApiService _apiService = ApiService();
  
  // State variables for user stats
  int _totalTrips = 0;
  double _totalEarnings = 0.0;
  bool _isLoading = true;
  String _errorMessage = '';
  bool _hasLoadedFromCache = false;

  @override
  void initState() {
    super.initState();
    _initializeStats();
  }

  // Initialize stats: Load from cache first, then from API
  Future<void> _initializeStats() async {
    await _loadCachedStats();
    await _loadUserStatsFromAPI();
  }

  // Load cached statistics from SharedPreferences
  Future<void> _loadCachedStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = widget.user.id;
      
      final cachedTrips = prefs.getInt('total_trips_$userId') ?? 0;
      final cachedEarnings = prefs.getDouble('total_earnings_$userId') ?? 0.0;
      final lastUpdated = prefs.getString('stats_last_updated_$userId') ?? '';
      
      if (cachedTrips > 0 || cachedEarnings > 0) {
        setState(() {
          _totalTrips = cachedTrips;
          _totalEarnings = cachedEarnings;
          _hasLoadedFromCache = true;
          _isLoading = false; // Show cached data immediately
        });
        debugPrint('Loaded cached stats: trips=$cachedTrips, earnings=$cachedEarnings, lastUpdated=$lastUpdated');
      }
    } catch (e) {
      debugPrint('Error loading cached stats: $e');
    }
  }

  // Save statistics to SharedPreferences
  Future<void> _saveCachedStats(int trips, double earnings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = widget.user.id;
      final timestamp = DateTime.now().toIso8601String();
      
      await prefs.setInt('total_trips_$userId', trips);
      await prefs.setDouble('total_earnings_$userId', earnings);
      await prefs.setString('stats_last_updated_$userId', timestamp);
      
      debugPrint('Cached stats saved: trips=$trips, earnings=$earnings');
    } catch (e) {
      debugPrint('Error saving cached stats: $e');
    }
  }

  // Load user statistics from backend API
  Future<void> _loadUserStatsFromAPI() async {
    try {
      setState(() {
        if (!_hasLoadedFromCache) {
          _isLoading = true;
        }
        _errorMessage = '';
      });

      // Get user ID with validation
      String userId = widget.user.id;
      
      debugPrint('Loading stats from API for user ID: $userId');

      if (userId.isEmpty) {
        throw Exception('Invalid user ID');
      }

      // Fetch user statistics from backend
      final userStats = await _apiService.getUserStats(userId);

      if (userStats != null) {
        int newTotalTrips = 0;
        double newTotalEarnings = 0.0;

        // Parse totalTrips - handle both String and int types
        if (userStats['totalTrips'] != null) {
          if (userStats['totalTrips'] is Map && userStats['totalTrips']['\$numberInt'] != null) {
            newTotalTrips = int.tryParse(userStats['totalTrips']['\$numberInt'].toString()) ?? 0;
          } else {
            newTotalTrips = int.tryParse(userStats['totalTrips'].toString()) ?? 0;
          }
        }

        // Parse totalEarnings - handle both String and double types
        if (userStats['totalEarnings'] != null) {
          if (userStats['totalEarnings'] is Map && userStats['totalEarnings']['\$numberInt'] != null) {
            newTotalEarnings = double.tryParse(userStats['totalEarnings']['\$numberInt'].toString()) ?? 0.0;
          } else {
            newTotalEarnings = double.tryParse(userStats['totalEarnings'].toString()) ?? 0.0;
          }
        }

        // Save to cache and update UI
        await _saveCachedStats(newTotalTrips, newTotalEarnings);

        setState(() {
          _totalTrips = newTotalTrips;
          _totalEarnings = newTotalEarnings;
          _isLoading = false;
          _errorMessage = '';
        });

        debugPrint('Stats loaded successfully from API: trips=$newTotalTrips, earnings=$newTotalEarnings');
      } else {
        setState(() {
          _isLoading = false;
          if (!_hasLoadedFromCache) {
            _errorMessage = 'No data found';
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading user stats from API: $e');
      setState(() {
        _isLoading = false;
        if (!_hasLoadedFromCache) {
          _errorMessage = 'Failed to load statistics. Showing offline data.';
        } else {
          _errorMessage = 'Failed to refresh data from server';
        }
      });
    }
  }

  // Pull to refresh functionality
  Future<void> _refreshStats() async {
    setState(() {
      _hasLoadedFromCache = false;
    });
    await _loadUserStatsFromAPI();
  }

  // Get last updated timestamp
  String _getLastUpdatedTime() {
    try {
      final now = DateTime.now();
      return '${now.day}/${now.month}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Unknown';
    }
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
            onPressed: _isLoading ? null : _refreshStats,
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
                      color: Colors.grey.withValues(alpha: 0.08),
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

              // Statistics Card with persistent data
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.08),
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

                    // Show offline indicator if using cached data
                    if (_hasLoadedFromCache && _errorMessage.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        margin: EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.offline_bolt_outlined, color: Colors.orange[600], size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Showing offline data. Pull down to refresh.',
                                style: TextStyle(
                                  color: Colors.orange[700],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Show error message only if no cached data available
                    if (_errorMessage.isNotEmpty && !_hasLoadedFromCache)
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
                            _isLoading && !_hasLoadedFromCache ? '...' : '$_totalTrips', 
                            Icons.route,
                            Colors.blue[600]!,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Total Earnings', 
                            _isLoading && !_hasLoadedFromCache ? '...' : '₹${_totalEarnings.toStringAsFixed(2)}',
                            Icons.monetization_on,
                            Colors.green[600]!,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16),

                    // Last updated info
                    if (!_isLoading || _hasLoadedFromCache)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _hasLoadedFromCache 
                            ? 'Data: ${_errorMessage.isEmpty ? 'Live' : 'Offline'} • Updated: ${_getLastUpdatedTime()}'
                            : 'Last updated: ${_getLastUpdatedTime()}',
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
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
