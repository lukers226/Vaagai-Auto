import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vaagaiauto/presentation/widgets/ride_widgets.dart';
import 'package:vaagaiauto/data/services/api_service.dart';
import '../../data/models/user_model.dart';
import 'ride_controller.dart';

class StartRidePage extends StatefulWidget {
  final UserModel user;

  const StartRidePage({Key? key, required this.user}) : super(key: key);

  @override
  _StartRidePageState createState() => _StartRidePageState();
}

class _StartRidePageState extends State<StartRidePage> with TickerProviderStateMixin {
  late RideController _rideController;
  late RideWidgets _widgets;
  final ScreenshotController _screenshotController = ScreenshotController();
  final ApiService _apiService = ApiService();

  bool _isDisposed = false;
  bool _fareDataLoaded = false;
  bool _isInitialized = false;

  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    debugPrint('🚀 StartRidePage initState started for user: ${widget.user.name} (ID: ${widget.user.id})');
    
    _rideController = RideController();
    _widgets = RideWidgets(context);
    _initializeAnimations();
    
    _rideController.initialize(
      onLocationUpdate: _onLocationUpdate,
      onStatusChange: _onStatusChange,
      onShowSnackBar: _showSnackBar,
    );
    
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      debugPrint('📱 Starting app initialization...');
      await _loadFareDataFromDatabase();
      
      if (mounted && !_isDisposed) {
        setState(() {
          _isInitialized = true;
        });
        debugPrint('✅ App initialization complete');
      }
      
    } catch (e) {
      debugPrint('❌ App initialization failed: $e');
      if (mounted && !_isDisposed) {
        setState(() {
          _isInitialized = true;
        });
        _showSnackBar('⚠️ Initialization completed with warnings', false);
      }
    }
  }

  Future<void> _loadFareDataFromDatabase() async {
    try {
      debugPrint('🔄 Starting fare data load from database...');
      
      Map<String, dynamic> fareData = await _apiService.getFareData();
      debugPrint('✅ Raw fare data received: $fareData');
      
      if (fareData.isNotEmpty) {
        _rideController.setFareDataFromDB(fareData);
        
        if (mounted && !_isDisposed) {
          setState(() {
            _fareDataLoaded = true;
          });
          
          debugPrint('💯 Database fare data loaded successfully:');
          debugPrint('   📊 Base Fare: ₹${_rideController.baseFareFromDB}');
          
          Future.delayed(Duration(milliseconds: 500), () {
            if (mounted && !_isDisposed) {
              _showSnackBar(
                '✅ Ready to start! Base fare: ₹${_rideController.baseFareFromDB.toStringAsFixed(0)}', 
                true
              );
            }
          });
        }
      } else {
        throw Exception('Empty fare data received from server');
      }
    } on TimeoutException {
      debugPrint('⏱️ Timeout while loading fare data');
      _handleFareDataError('Connection timeout. Using default rates.');
    } on SocketException {
      debugPrint('🌐 Network error while loading fare data');
      _handleFareDataError('Network error. Using default rates.');
    } on FormatException {
      debugPrint('🔧 Format error while parsing fare data');
      _handleFareDataError('Data format error. Using default rates.');
    } catch (e) {
      debugPrint('❌ Unexpected error loading fare data: $e');
      _handleFareDataError('Server error. Using default rates.');
    }
  }

  void _handleFareDataError(String message) {
    if (mounted && !_isDisposed) {
      setState(() {
        _fareDataLoaded = false;
      });
      
      _showSnackBar('⚠️ $message', false);
      
      _rideController.setFareDataFromDB({
        'baseFare': 59,
        'perKmRate': 18,
        'waiting5min': 50,
        'waiting10min': 60,
        'waiting15min': 70,
        'waiting20min': 80,
        'waiting25min': 90,
        'waiting30min': 100,
      });
      
      setState(() {
        _fareDataLoaded = true;
      });
      
      debugPrint('🔧 Default fare values set as fallback');
    }
  }

  void _initializeAnimations() {
    try {
      _pulseController = AnimationController(
        duration: Duration(milliseconds: 2000),
        vsync: this,
      )..repeat(reverse: true);

      _slideController = AnimationController(
        duration: Duration(milliseconds: 800),
        vsync: this,
      )..forward();

      _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
      );

      _slideAnimation = Tween<Offset>(
        begin: Offset(0, 0.3),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

      _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
      );
      
      debugPrint('🎬 Animations initialized successfully');
    } catch (e) {
      debugPrint('⚠️ Animation initialization failed: $e');
    }
  }

  void _onLocationUpdate() {
    if (mounted && !_isDisposed) {
      setState(() {});
    }
  }

  void _onStatusChange() {
    if (mounted && !_isDisposed) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    debugPrint('🗑️ StartRidePage disposing...');
    _isDisposed = true;
    try {
      _pulseController.dispose();
      _slideController.dispose();
      _rideController.dispose();
    } catch (e) {
      debugPrint('⚠️ Error during dispose: $e');
    }
    super.dispose();
  }

  void _showSnackBar(String message, bool isSuccess) {
    if (!mounted || _isDisposed) return;
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(isSuccess ? Icons.check_circle : Icons.error, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: isSuccess ? Color(0xFF00B562) : Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: EdgeInsets.all(16),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('⚠️ Error showing snackbar: $e');
    }
  }

  Future<void> _startRide() async {
    if (!mounted || _isDisposed) return;
    
    if (!_isInitialized) {
      _showSnackBar('⏳ Please wait for app to finish loading...', false);
      return;
    }
    
    if (!_fareDataLoaded) {
      _showSnackBar('⏳ Please wait for fare data to load...', false);
      _loadFareDataFromDatabase();
      return;
    }
    
    try {
      bool success = await _rideController.startRide();
      if (success && mounted && !_isDisposed) {
        _showSnackBar('🚗 Ride started!', true);
      } else {
        _showSnackBar('❌ Failed to start ride. Please check GPS permissions.', false);
      }
    } catch (e) {
      debugPrint('❌ Error starting ride: $e');
      _showSnackBar('❌ Error starting ride. Please try again.', false);
    }
  }

  void _endRide() {
    if (!mounted || _isDisposed) return;
    try {
      _rideController.endRide();
      _showCompletionDialog();
    } catch (e) {
      debugPrint('❌ Error ending ride: $e');
      _showSnackBar('❌ Error ending ride. Please try again.', false);
    }
  }

  void _showCompletionDialog() {
    if (!mounted || _isDisposed) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Color(0xFF00B562).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Color(0xFF00B562),
                    size: 30,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Trip Completed!',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildSummaryRow('Distance', '${_rideController.formatDistance()} km'),
                      _buildSummaryRow('Duration', _rideController.formatTime()),
                      _buildSummaryRow('Base Fare', '₹${_rideController.baseFareFromDB.toStringAsFixed(2)}'),
                      if (_rideController.waitingSeconds > 0)
                        _buildSummaryRow('Waiting Time', _rideController.getWaitingTimeDisplay()),
                      if (_rideController.totalWaitingFare > 0)
                        _buildSummaryRow('Waiting Charge', '₹${_rideController.totalWaitingFare.toStringAsFixed(2)}'),
                      Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Fare',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            '₹${_rideController.totalFare.toStringAsFixed(2)}',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF00B562),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => _generateAndShareBill(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.share, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Share Bill',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      _completeRideAndReturn();
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      'Back to Home',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _completeRideAndReturn() async {
    if (!mounted || _isDisposed) return;
    
    try {
      String userId = widget.user.id ?? '';
      if (userId.isEmpty || userId == 'null' || userId == 'undefined') {
        _showSnackBar('Error: User session invalid. Please login again.', false);
        Navigator.of(context).pop();
        return;
      }
      
      double rideEarnings = _rideController.totalFare;
      _showSnackBar('Updating earnings...', true);
      
      Map<String, dynamic> tripData = {
        'distance': _rideController.formatDistance(),
        'duration': _rideController.formatTime(),
        'baseFare': _rideController.baseFareFromDB,
        'totalFare': _rideController.totalFare,
        'waitingTime': _rideController.getWaitingTimeDisplay(),
        'waitingCharge': _rideController.totalWaitingFare,
        'startTime': _rideController.getTripStartTime(),
        'endTime': _rideController.getTripEndTime(),
        'completedAt': DateTime.now().toIso8601String(),
      };
      
      bool success = await _apiService.updateCompletedRide(
        userId: userId,
        rideEarnings: rideEarnings,
        tripData: tripData,
      );
      
      await _updateDailyStats(rideEarnings);
      
      if (!mounted || _isDisposed) return;
      
      if (success) {
        Navigator.of(context).pop();
        _showSnackBar('Trip completed! Earnings updated: ₹${rideEarnings.toStringAsFixed(2)}', true);
      } else {
        _showSnackBar('Trip completed but database update failed', false);
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('❌ Error completing ride: $e');
      _showSnackBar('Trip completed but database error occurred', false);
      if (mounted && !_isDisposed) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _updateDailyStats(double earnings) async {
    try {
      final userId = widget.user.id;
      if (userId == null || userId.isEmpty) return;
      
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final userTripsKey = 'today_trips_$userId';
      final userEarningsKey = 'today_earnings_$userId';
      final userLastResetKey = 'last_reset_timestamp_$userId';
      
      final lastResetTimestamp = prefs.getInt(userLastResetKey) ?? 0;
      final lastResetDate = DateTime.fromMillisecondsSinceEpoch(lastResetTimestamp);
      
      bool needsReset = false;
      if (lastResetTimestamp == 0) {
        needsReset = true;
      } else {
        final todayMidnight = DateTime(now.year, now.month, now.day, 23, 59, 59);
        if (now.isAfter(todayMidnight) && lastResetDate.isBefore(todayMidnight)) {
          needsReset = true;
        } else if (now.day != lastResetDate.day || now.month != lastResetDate.month || now.year != lastResetDate.year) {
          needsReset = true;
        }
      }
      
      if (needsReset) {
        await prefs.setInt(userTripsKey, 1);
        await prefs.setDouble(userEarningsKey, earnings);
        await prefs.setInt(userLastResetKey, now.millisecondsSinceEpoch);
      } else {
        final currentTrips = prefs.getInt(userTripsKey) ?? 0;
        final currentEarnings = prefs.getDouble(userEarningsKey) ?? 0.0;
        await prefs.setInt(userTripsKey, currentTrips + 1);
        await prefs.setDouble(userEarningsKey, currentEarnings + earnings);
      }
    } catch (e) {
      debugPrint('⚠️ Error updating daily stats: $e');
    }
  }

  Future<void> _generateAndShareBill() async {
    if (!mounted || _isDisposed) return;
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))),
              SizedBox(width: 12),
              Text('Generating bill image...'),
            ],
          ),
          backgroundColor: Color(0xFF00B562),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: EdgeInsets.all(16),
          duration: Duration(seconds: 3),
        ),
      );
      
      final Uint8List imageBytes = await _screenshotController.captureFromWidget(
        _buildBillWidget(),
        delay: Duration(milliseconds: 500),
        pixelRatio: 2.0,
        targetSize: Size(350, 600),
      );
      
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'vaagai_bill_$timestamp.png';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(imageBytes);
      
      String shareMessage = '''🚗 *Vaagai Meter Auto - Trip Receipt*

📍 Distance: ${_rideController.formatDistance()} km
⏱️ Duration: ${_rideController.formatTime()}
💰 Total Fare: ₹${_rideController.totalFare.toStringAsFixed(2)}

👨‍💼 Driver: ${widget.user.name ?? "Driver"}
🕐 ${_rideController.getTripStartTime()} - ${_rideController.getTripEndTime()}

Thank you for choosing Vaagai Meter Auto! 🙏''';
      
      await Share.shareXFiles(
        [XFile(file.path)],
        text: shareMessage,
        subject: 'Vaagai Meter Auto - Trip Receipt',
      );
      
      if (mounted && !_isDisposed) {
        _showSnackBar('Bill shared successfully!', true);
      }
      
      Timer(Duration(minutes: 2), () async {
        try { 
          if (await file.exists()) await file.delete(); 
        } catch (_) {}
      });
    } catch (e) {
      debugPrint('❌ Error generating bill: $e');
      if (mounted && !_isDisposed) {
        _showSnackBar('Failed to generate bill. Please try again.', false);
      }
    }
  }

  Widget _buildBillWidget() {
    final DateTime now = DateTime.now();
    final String receiptId = 'VA${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    return Material(
      color: Colors.white,
      child: Container(
        width: 350,
        decoration: BoxDecoration(color: Colors.white),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF00B562), Color(0xFF00A855)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('🚗', style: TextStyle(fontSize: 20)),
                      SizedBox(width: 6),
                      Text(
                        'VAAGAI Meter AUTO',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    'TRIP RECEIPT',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 6),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'ID: $receiptId',
                      style: GoogleFonts.inter(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(12),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('📋 TRIP DETAILS', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black87)),
                        SizedBox(height: 8),
                        _buildBillRow('Driver', widget.user.name ?? "Driver"),
                        _buildBillRow('Date', '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}'),
                        _buildBillRow('Time', '${_rideController.getTripStartTime()} - ${_rideController.getTripEndTime()}'),
                        _buildBillRow('Distance', '${_rideController.formatDistance()} km'),
                        _buildBillRow('Duration', _rideController.formatTime()),
                        if (_rideController.waitingSeconds > 0)
                          _buildBillRow('Waiting Time', _rideController.getWaitingTimeDisplay()),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('💰 FARE BREAKDOWN', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black87)),
                        SizedBox(height: 8),
                        _buildBillRow('Base Fare', '₹${_rideController.baseFareFromDB.toStringAsFixed(2)}'),
                        if (_rideController.distance > 1.0)
                          _buildBillRow('Extra Distance', '₹${((_rideController.distance - 1.0) * _rideController.perKmRateFromDB).toStringAsFixed(2)}'),
                        if (_rideController.totalWaitingFare > 0)
                          _buildBillRow('Waiting Charge', '₹${_rideController.totalWaitingFare.toStringAsFixed(2)}'),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF00B562).withOpacity(0.1),
                          Color(0xFF00A855).withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Color(0xFF00B562), width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('TOTAL AMOUNT', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF00B562))),
                        Text('₹${_rideController.totalFare.toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF00B562))),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      children: [
                        Text('🙏 Thank You for Choosing Vaagai Meter Auto!', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87), textAlign: TextAlign.center),
                        SizedBox(height: 4),
                        Text('Have a safe journey! ✨', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.grey[600]), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.grey[700])),
          Text(value, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            _widgets.buildHeader(
              title: 'Vaagai Meter Auto',
              onBackPressed: () {
                if (mounted && !_isDisposed) Navigator.pop(context);
              },
              showCancelRide: false,
            ),
            Expanded(
              child: _isInitialized ? SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _widgets.buildDriverCard(
                          user: widget.user,
                          isOnline: true,
                        ),
                        SizedBox(height: 16),
                        // Single row with Start Ride and End Ride buttons
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _rideController.isMeterOn ? null : _startRide,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _rideController.isMeterOn ? Colors.grey : Colors.yellow,
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    'START RIDE',
                                    style: GoogleFonts.lato(
                                      fontSize: 16,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _rideController.isMeterOn ? _endRide : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _rideController.isMeterOn ? Colors.red[600] : Colors.grey,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    'END RIDE',
                                    style: GoogleFonts.lato(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        _buildFareDisplay(),
                        SizedBox(height: 16),
                        _buildMetricsGrid(),
                      ],
                    ),
                  ),
                ),
              ) : _buildLoadingView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00B562)),
          ),
          SizedBox(height: 20),
          Text(
            'Initializing Vaagai Meter Auto...',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFareDisplay() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(

          
          // **ACTIVE AND MOVING**
          scale: (_rideController.isMeterOn && _rideController.isVehicleMoving) ? _pulseAnimation.value : 1.0,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1F2937), Color(0xFF111827)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'CURRENT FARE',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white60,
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '₹${_rideController.isMeterOn ? _rideController.currentFare.toStringAsFixed(2) : "0.00"}',
                  style: GoogleFonts.inter(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricsGrid() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildMetric(
                'Distance', 
                _rideController.isMeterOn ? '${_rideController.formatDistance()} km' : '0.00 km', 
                Icons.straighten
              )),
              Container(width: 1, height: 40, color: Colors.grey[300]),
              Expanded(child: _buildMetric(
                'Base Fare', 
                '₹${_rideController.baseFareFromDB.toStringAsFixed(2)}', 
                Icons.currency_rupee
              )),
            ],
          ),
          Divider(height: 24, color: Colors.grey[200]),
          Row(
            children: [
              Expanded(child: _buildMetric(
                'Total Time', 
                // Real Time Showing
                _rideController.isMeterOn ? _rideController.formatTime() : '00:00', 
                Icons.timer
              )),
              Container(width: 1, height: 40, color: Colors.grey[300]),
              Expanded(child: _buildMetric(
                'Status', 
                // Real Time Status
                _rideController.isMeterOn ? _rideController.getMovementStatus() : 'Ready to Start', 
                Icons.info
              )),
            ],
          ),
          // Waiting Time show
          if (_rideController.isMeterOn && _rideController.waitingSeconds > 0) ...[
            Divider(height: 24, color: Colors.grey[200]),
            Row(
              children: [
                Expanded(child: _buildMetric('Waiting Time', _rideController.getWaitingTimeDisplay(), Icons.access_time)),
                Container(width: 1, height: 40, color: Colors.grey[300]),
                Expanded(child: _buildMetric('Waiting Charge', '₹${_rideController.totalWaitingFare.toStringAsFixed(2)}', Icons.schedule)),
              ],
            ),
          ],
          // **SHOW EXTRA DISTANCE ONLY WHEN THERE'S EXTRA DISTANCE**
          if (_rideController.isMeterOn && _rideController.distance > 1.0) ...[
            Divider(height: 24, color: Colors.grey[200]),
            Row(
              children: [
                Expanded(child: _buildMetric('Extra Distance', '${(_rideController.distance - 1.0).toStringAsFixed(3)} km', Icons.timeline)),
                Container(width: 1, height: 40, color: Colors.grey[300]),
                Expanded(child: _buildMetric('Extra Charge', '₹${((_rideController.distance - 1.0) * _rideController.perKmRateFromDB).toStringAsFixed(2)}', Icons.add)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetric(String title, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Icon(icon, size: 20, color: Color(0xFF00B562)),
          SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
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
