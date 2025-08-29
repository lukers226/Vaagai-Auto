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
    
    // Initialize components first
    _rideController = RideController();
    _widgets = RideWidgets(context);
    _initializeAnimations();
    
    // Initialize ride controller
    _rideController.initialize(
      onLocationUpdate: _onLocationUpdate,
      onStatusChange: _onStatusChange,
      onShowSnackBar: _showSnackBar,
    );
    
    // Load fare data from database FIRST, then mark as initialized
    _initializeApp();
    
    // Prevent call interruptions from ending ride
    _preventCallInterruption();
  }

  // ENHANCED: Complete app initialization flow
  Future<void> _initializeApp() async {
    try {
      debugPrint('📱 Starting app initialization...');
      
      // Step 1: Load fare data from database
      await _loadFareDataFromDatabase();
      
      // Step 2: Mark as initialized
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
          _isInitialized = true; // Still mark as initialized to show UI
        });
        _showSnackBar('⚠️ Initialization completed with warnings', false);
      }
    }
  }

  // ENHANCED: Load fare data with comprehensive error handling
Future<void> _loadFareDataFromDatabase() async {
  try {
    debugPrint('🔄 Starting fare data load from database...');
    
    // Make API call to get fare data
    Map<String, dynamic> fareData = await _apiService.getFareData();
    debugPrint('✅ Raw fare data received: $fareData');
    
    if (fareData.isNotEmpty) {
      // Set the fare data in the controller
      _rideController.setFareDataFromDB(fareData);
      
      if (mounted && !_isDisposed) {
        setState(() {
          _fareDataLoaded = true;
        });
        
        debugPrint('💯 Database fare data loaded successfully:');
        debugPrint('   📊 Base Fare: ₹${_rideController.baseFareFromDB}');
        debugPrint('   ⏱️ Waiting Charges: ${_rideController.waitingChargesFromDB}');
        
        // Show success message after a short delay to avoid context issues
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


  // ENHANCED: Handle fare data loading errors
  void _handleFareDataError(String message) {
    if (mounted && !_isDisposed) {
      setState(() {
        _fareDataLoaded = false;
      });
      
      _showSnackBar('⚠️ $message', false);
      
      // Set default values if database fails
      _rideController.setFareDataFromDB({
        'baseFare': 100,
        'waiting5min': 10,
        'waiting10min': 20,
        'waiting15min': 30,
        'waiting20min': 40,
        'waiting25min': 50,
        'waiting30min': 60,
      });
      
      setState(() {
        _fareDataLoaded = true;
      });
      
      debugPrint('🔧 Default fare values set as fallback');
    }
  }

  // Prevent call interruption from ending rides
  void _preventCallInterruption() {
    try {
      WidgetsBinding.instance.addObserver(_AppLifecycleObserver(_rideController));
      debugPrint('🔒 App lifecycle observer added');
    } catch (e) {
      debugPrint('⚠️ Failed to add lifecycle observer: $e');
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
    
    // Check if app is initialized
    if (!_isInitialized) {
      _showSnackBar('⏳ Please wait for app to finish loading...', false);
      return;
    }
    
    // Check if fare data is loaded
    if (!_fareDataLoaded) {
      _showSnackBar('⏳ Please wait for fare data to load...', false);
      // Try to reload fare data
      _loadFareDataFromDatabase();
      return;
    }
    
    try {
      bool success = await _rideController.startRide();
      if (success && mounted && !_isDisposed) {
        _showSnackBar(
          '🚗 Ride started! Base fare: ₹${_rideController.baseFareFromDB.toStringAsFixed(0)}', 
          true
        );
      } else {
        _showSnackBar('❌ Failed to start ride. Please check GPS permissions.', false);
      }
    } catch (e) {
      debugPrint('❌ Error starting ride: $e');
      _showSnackBar('❌ Error starting ride. Please try again.', false);
    }
  }

  // UPDATED: End ride now pauses the ride instead of stopping completely
  void _endRide() {
    if (!mounted || _isDisposed) return;
    try {
      _rideController.stopRide(); // This now pauses the ride
      _showTripSummary();
    } catch (e) {
      debugPrint('❌ Error ending ride: $e');
      _showSnackBar('❌ Error ending ride. Please try again.', false);
    }
  }

  void _showCancelRideConfirmation() {
    if (!mounted || _isDisposed) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: EdgeInsets.zero,
          content: Container(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1), 
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.warning, color: Colors.red[600], size: 30),
                ),
                SizedBox(height: 20),
                Text(
                  'Confirm Cancel Ride',
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
                SizedBox(height: 12),
                Text(
                  _rideController.isMeterOn
                      ? 'Are you sure you want to cancel the ongoing ride? This action cannot be undone.'
                      : 'Are you sure you want to cancel and go back to the homepage?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.4),
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          if (mounted && !_isDisposed) Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text('No, Keep Ride', style: TextStyle(color: Colors.grey[600])),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (mounted && !_isDisposed) {
                            Navigator.pop(context);
                            _cancelRideAndRedirect();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        child: Text('Yes, Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _cancelRideAndRedirect() async {
    if (!mounted || _isDisposed) return;
    
    try {
      _rideController.cancelRide();
      
      String userId = widget.user.id ?? '';
      if (userId.isEmpty || userId == 'null' || userId == 'undefined') {
        _showSnackBar('Error: User session invalid. Please login again.', false);
        Navigator.of(context).pop();
        return;
      }
      
      if (!RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(userId)) {
        _showSnackBar('Error: Invalid user ID format. Please login again.', false);
        Navigator.of(context).pop();
        return;
      }
      
      _showSnackBar('Updating database...', true);
      bool success = await _apiService.updateCancelledRides(userId);
      
      if (!mounted || _isDisposed) return;
      
      if (success) {
        Navigator.of(context).pop();
        _showSnackBar('Ride cancelled successfully', true);
      } else {
        _showSnackBar('Ride cancelled but database update failed', false);
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('❌ Error cancelling ride: $e');
      _showSnackBar('Ride cancelled but database error occurred', false);
      if (mounted && !_isDisposed) {
        Navigator.of(context).pop();
      }
    }
  }

  // UPDATED: Enhanced trip summary with proper continue/complete functionality
  void _showTripSummary() {
    if (!mounted || _isDisposed) return;
    _widgets.showTripSummary(
      context: context,
      distance: _rideController.formatDistance(),
      duration: _rideController.formatTime(),
      baseFare: _rideController.fare,
      waitingCharge: _rideController.waitingCharge,
      totalFare: _rideController.totalFare,
      driverName: widget.user.name ?? "Driver",
      tripStartTime: _rideController.getTripStartTime(),
      tripEndTime: _rideController.getTripEndTime(),
      onContinue: () {
        if (mounted && !_isDisposed) {
          Navigator.of(context).pop();
          _rideController.resumeRide(); // NEW: Resume the ride
          _showSnackBar('Ride resumed successfully', true);
        }
      },
      onComplete: () {
        if (mounted && !_isDisposed) {
          Navigator.of(context).pop();
          _rideController.completeRide(); // NEW: Complete the ride permanently
          _handleCompleteRide();
        }
      },
      onShareCustomer: _showCustomerPhoneInput,
    );
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

  Future<void> _handleCompleteRide() async {
    if (!mounted || _isDisposed) return;
    
    try {
      String userId = widget.user.id ?? '';
      if (userId.isEmpty || userId == 'null' || userId == 'undefined') {
        _showSnackBar('Error: User session invalid. Please login again.', false);
        Navigator.of(context).pop();
        return;
      }
      
      if (!RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(userId)) {
        _showSnackBar('Error: Invalid user ID format. Please login again.', false);
        Navigator.of(context).pop();
        return;
      }
      
      double rideEarnings = _rideController.totalFare;
      _showSnackBar('Updating earnings...', true);
      
      Map<String, dynamic> tripData = {
        'distance': _rideController.formatDistance(),
        'duration': _rideController.formatTime(),
        'baseFare': _rideController.fare,
        'waitingCharge': _rideController.waitingCharge,
        'totalFare': _rideController.totalFare,
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

  void _showCustomerPhoneInput() {
    if (!mounted || _isDisposed) return;
    final TextEditingController phoneController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
            child: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        color: Color(0xFF25D366).withOpacity(0.1), 
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.image, color: Color(0xFF25D366), size: 30),
                    ),
                    SizedBox(height: 16),
                    Text('Share Trip Bill', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87)),
                    SizedBox(height: 10),
                    Text('Generate and share bill image with customer', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.3)),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey[300]!),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text('Cancel', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _generateAndShareBillImage(phoneController.text.trim());
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF25D366),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image, size: 18),
                                SizedBox(width: 6),
                                Text('Generate & Share', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _generateAndShareBillImage(String phoneNumber) async {
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
        _buildUltraCompactBillWidget(),
        delay: Duration(milliseconds: 500),
        pixelRatio: 2.0,
        targetSize: Size(350, 600),
      );
      
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'vaagai_bill_$timestamp.png';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(imageBytes);
      
      if (!await file.exists() || await file.length() == 0) {
        throw Exception('Failed to generate bill image');
      }
      
      String shareMessage = '''🚗 *Vaagai Auto - Trip Receipt*

📍 Distance: ${_rideController.formatDistance()} km
⏱️ Duration: ${_rideController.formatTime()}
💰 Total Fare: ₹${_rideController.totalFare.toStringAsFixed(2)}

👨‍💼 Driver: ${widget.user.name ?? "Driver"}
🕐 ${_rideController.getTripStartTime()} - ${_rideController.getTripEndTime()}

Thank you for choosing Vaagai Auto! 🙏''';
      
      await Share.shareXFiles(
        [XFile(file.path)],
        text: shareMessage,
        subject: 'Vaagai Auto - Trip Receipt',
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

  Widget _buildUltraCompactBillWidget() {
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
                        'VAAGAI AUTO',
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
                        _buildMicroBillRow('Driver', widget.user.name ?? "Driver"),
                        _buildMicroBillRow('Date', '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}'),
                        _buildMicroBillRow('Time', '${_rideController.getTripStartTime()} - ${_rideController.getTripEndTime()}'),
                        _buildMicroBillRow('Distance', '${_rideController.formatDistance()} km'),
                        _buildMicroBillRow('Duration', _rideController.formatTime()),
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
                        _buildMicroBillRow('Base Fare', '₹${_rideController.baseFareFromDB.toStringAsFixed(2)}'),
                        if (_rideController.distance > 1.0)
                          _buildMicroBillRow('Extra (₹18/km)', '₹${(_rideController.fare - _rideController.baseFareFromDB).toStringAsFixed(2)}'),
                        if (_rideController.waitingCharge > 0)
                          _buildMicroBillRow('Waiting', '₹${_rideController.waitingCharge.toStringAsFixed(2)}'),
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
                        Text('🙏 Thank You for Choosing Vaagai Auto!', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87), textAlign: TextAlign.center),
                        SizedBox(height: 4),
                        Text('Have a safe journey! ✨', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.grey[600]), textAlign: TextAlign.center),
                        SizedBox(height: 6),
                        Text('📞 Support: +91-XXXXXXXXXX', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w500, color: Colors.grey[600]), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Generated: ${now.day}/${now.month}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                    style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w500, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMicroBillRow(String label, String value) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            _widgets.buildHeader(
              title: 'Vaagai Auto',
              onBackPressed: () {
                if (mounted && !_isDisposed) Navigator.pop(context);
              },
              showCancelRide: true,
              onCancelRide: _showCancelRideConfirmation,
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
                        _widgets.buildLocationStatus(
                          isLocationServiceEnabled: _rideController.isLocationServiceEnabled,
                          hasLocationPermission: _rideController.hasLocationPermission,
                          currentPosition: _rideController.currentPosition,
                        ),
                        SizedBox(height: 20),
                        _rideController.isMeterOn
                            ? _buildActiveRideUI()
                            : _buildStartRideUI(),
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

  // Loading view while app initializes
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
            'Initializing Vaagai Auto...',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Loading fare data and GPS settings',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartRideUI() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: _widgets.buildStartRideUI(onStartRide: _startRide),
    );
  }

  Widget _buildActiveRideUI() {
    return _widgets.buildActiveRideUI(
      rideController: _rideController,
      pulseAnimation: _pulseAnimation,
      onEndRide: _endRide,
      onWaitingTimeChanged: (int newValue) {
   
      },
    );
  }
}

class _AppLifecycleObserver extends WidgetsBindingObserver {
  final RideController rideController;

  _AppLifecycleObserver(this.rideController);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Prevent ride from ending when app goes to background (call interruption)
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      debugPrint('App paused/inactive - Ride continues running');
    } else if (state == AppLifecycleState.resumed) {
      debugPrint('App resumed - Ride still running');
    }
  }
}
