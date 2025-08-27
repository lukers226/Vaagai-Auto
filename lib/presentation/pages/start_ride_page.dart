import 'package:flutter/material.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/user_model.dart';

class StartRidePage extends StatefulWidget {
  final UserModel user;

  const StartRidePage({Key? key, required this.user}) : super(key: key);

  @override
  _StartRidePageState createState() => _StartRidePageState();
}

class _StartRidePageState extends State<StartRidePage> with TickerProviderStateMixin {
  double distance = 0.0;
  int secondsPassed = 0;
  double fare = 59.0;
  double waitingCharge = 0.0;
  int selectedWaitingTime = 0;
  List<int> waitingTimes = [0, 5, 10, 15, 20, 25, 30];
  Timer? meterTimer;
  Timer? locationTimer;
  Timer? gpsMonitorTimer; // NEW: GPS monitoring timer
  bool isMeterOn = false;
  int waitingSeconds = 0;
  
  // GPS tracking variables
  Position? lastPosition;
  Position? currentPosition;
  bool isMoving = false;
  double totalDistanceTravelled = 0.0;
  
  // Location tracking settings
  static const double MOVEMENT_THRESHOLD = 3.0;
  static const int LOCATION_UPDATE_INTERVAL = 2;
  
  // Location permission and service status
  bool isLocationServiceEnabled = false;
  bool hasLocationPermission = false;

  // Animations
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
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
    
    _checkLocationStatus();
    _startGpsMonitoring(); // NEW: Start GPS monitoring
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    meterTimer?.cancel();
    locationTimer?.cancel();
    gpsMonitorTimer?.cancel(); // NEW: Cancel GPS monitoring timer
    super.dispose();
  }

  double get totalFare => fare + waitingCharge;

  // NEW: Start GPS monitoring to detect disconnections
  void _startGpsMonitoring() {
    gpsMonitorTimer = Timer.periodic(Duration(seconds: 3), (timer) async {
      await _monitorGpsStatus();
    });
  }

  // NEW: Monitor GPS status continuously
  Future<void> _monitorGpsStatus() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();
      bool permissionGranted = permission == LocationPermission.whileInUse || 
                              permission == LocationPermission.always;
      
      bool previousGpsStatus = isLocationServiceEnabled && hasLocationPermission;
      bool currentGpsStatus = serviceEnabled && permissionGranted;
      
      // Check if GPS status changed from connected to disconnected
      if (previousGpsStatus && !currentGpsStatus) {
        // GPS was connected but now disconnected
        _showSnackBar('GPS disconnected! Location tracking may be affected.', false);
      } else if (!previousGpsStatus && currentGpsStatus) {
        // GPS was disconnected but now connected
        _showSnackBar('GPS reconnected successfully!', true);
      }
      
      setState(() {
        isLocationServiceEnabled = serviceEnabled;
        hasLocationPermission = permissionGranted;
      });
    } catch (e) {
      // If there's an error checking GPS status, consider it disconnected
      bool wasConnected = isLocationServiceEnabled && hasLocationPermission;
      if (wasConnected) {
        _showSnackBar('GPS connection lost! Please check your location settings.', false);
      }
      
      setState(() {
        isLocationServiceEnabled = false;
        hasLocationPermission = false;
      });
    }
  }

  Future<void> _checkLocationStatus() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();
      bool permissionGranted = permission == LocationPermission.whileInUse || 
                              permission == LocationPermission.always;
      
      setState(() {
        isLocationServiceEnabled = serviceEnabled;
        hasLocationPermission = permissionGranted;
      });
    } catch (e) {
      setState(() {
        isLocationServiceEnabled = false;
        hasLocationPermission = false;
      });
      _showSnackBar('Location services error. Please check permissions.', false);
    }
  }

  Future<bool> _requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showLocationDialog();
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackBar('Location permission denied', false);
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showSettingsDialog();
      return false;
    }

    setState(() {
      hasLocationPermission = true;
      isLocationServiceEnabled = true;
    });
    
    return true;
  }

  void _showLocationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: EdgeInsets.zero,
        content: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.location_on, color: Colors.orange, size: 30),
              ),
              SizedBox(height: 20),
              Text(
                'Enable Location',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'We need location access to provide accurate ride tracking and fare calculation.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
              SizedBox(height: 24),
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
                      child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await Geolocator.openLocationSettings();
                        Timer(Duration(seconds: 2), _checkLocationStatus);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF00B562),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      child: Text('Enable', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Permission Required', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        content: Text('Please enable location permission from app settings to continue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openAppSettings();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00B562)),
            child: Text('Settings', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void startMeter() async {
    meterTimer?.cancel();
    locationTimer?.cancel();
    
    meterTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!isMeterOn) return;
      
      setState(() {
        secondsPassed++;
        
        if (!isMoving && selectedWaitingTime == 0) {
          waitingSeconds++;
          if (waitingSeconds >= 300) {
            updateWaitingCharge();
          }
        } else if (isMoving) {
          waitingSeconds = 0;
          if (selectedWaitingTime == 0) {
            waitingCharge = 0.0;
          }
        }
      });
    });

    locationTimer = Timer.periodic(Duration(seconds: LOCATION_UPDATE_INTERVAL), (timer) async {
      if (!isMeterOn) return;
      await _updateLocation();
    });

    await _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );
      
      setState(() {
        lastPosition = position;
        currentPosition = position;
      });
    } catch (e) {
      _showSnackBar('Unable to get location. Check GPS.', false);
    }
  }

  Future<void> _updateLocation() async {
    try {
      Position newPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 8),
      );

      if (lastPosition != null) {
        double distanceInMeters = Geolocator.distanceBetween(
          lastPosition!.latitude,
          lastPosition!.longitude,
          newPosition.latitude,
          newPosition.longitude,
        );

        if (distanceInMeters >= MOVEMENT_THRESHOLD && newPosition.accuracy <= 20) {
          setState(() {
            isMoving = true;
            double distanceInKm = distanceInMeters / 1000;
            distance += distanceInKm;
            totalDistanceTravelled += distanceInKm;
            updateFare();
            lastPosition = newPosition;
          });
        } else {
          setState(() {
            isMoving = false;
          });
        }

        if (distanceInMeters < MOVEMENT_THRESHOLD) {
          lastPosition = newPosition;
        }
      } else {
        setState(() {
          lastPosition = newPosition;
        });
      }

      setState(() {
        currentPosition = newPosition;
      });

    } catch (e) {
      print('Location update error: $e');
    }
  }

  void toggleMeter(bool enable) async {
    if (enable) {
      bool hasPermission = await _requestLocationPermission();
      if (!hasPermission) return;
    }

    setState(() {
      isMeterOn = enable;
      if (isMeterOn) {
        startMeter();
        _showSnackBar('Ride started successfully!', true);
      } else {
        stopMeter();
        resetMeter();
      }
    });
  }

  void stopMeter() {
    meterTimer?.cancel();
    locationTimer?.cancel();
  }

  void resetMeter() {
    distance = 0.0;
    totalDistanceTravelled = 0.0;
    secondsPassed = 0;
    fare = 59.0;
    waitingCharge = 0.0;
    waitingSeconds = 0;
    selectedWaitingTime = 0;
    isMoving = false;
    lastPosition = null;
    currentPosition = null;
  }

  void updateFare() {
    if (distance <= 1.0) {
      fare = 59.0;
    } else {
      double extraDistance = distance - 1.0;
      fare = 59.0 + (extraDistance * 18.0);
    }
  }

  void updateWaitingCharge() {
    int minutes = waitingSeconds ~/ 60;
    if (minutes >= 10) {
      waitingCharge = 20.0;
    } else if (minutes >= 5) {
      waitingCharge = 10.0;
    } else {
      waitingCharge = 0.0;
    }
  }

  void updateWaitingChargeFromDropdown() {
    if (selectedWaitingTime >= 10) {
      waitingCharge = 20.0;
    } else if (selectedWaitingTime >= 5) {
      waitingCharge = 10.0;
    } else {
      waitingCharge = 0.0;
    }
  }

  String formatDistance() => distance.toStringAsFixed(2);
  
  String formatTime() {
    int minutes = secondsPassed ~/ 60;
    int seconds = secondsPassed % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String getMovementStatus() {
    if (!isMeterOn) return 'Ready to Start';
    return isMoving ? 'On Trip' : 'Waiting';
  }

  Color getStatusColor() {
    if (!isMeterOn) return Colors.grey[600]!;
    return isMoving ? Color(0xFF00B562) : Colors.orange[600]!;
  }

  void _showSnackBar(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isSuccess ? Color(0xFF00B562) : Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildDriverCard(),
                        SizedBox(height: 16),
                        _buildLocationStatus(),
                        SizedBox(height: 20),
                        if (isMeterOn) _buildActiveRideUI() else _buildStartRideUI(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back, color: Colors.black87, size: 24),
            ),
            Expanded(
              child: Text(
                'Vaagai Auto',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Color(0xFF00B562).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'LIVE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF00B562),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF00B562), Color(0xFF00A855)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(Icons.person, color: Colors.white, size: 24),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.user.name ?? "Driver",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Auto Driver • DL12AB1234',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Color(0xFF00B562).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Color(0xFF00B562),
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 4),
                Text(
                  'Online',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF00B562),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStatus() {
    bool isGpsReady = isLocationServiceEnabled && hasLocationPermission;
    
    return AnimatedContainer( // NEW: Added animation for smooth status changes
      duration: Duration(milliseconds: 300),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isGpsReady ? Color(0xFFECFDF3) : Color(0xFFFEF2F2),
        border: Border.all(
          color: isGpsReady ? Color(0xFF00B562).withOpacity(0.2) : Colors.red.withOpacity(0.2),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          AnimatedContainer( // NEW: Added animation for status icon changes
            duration: Duration(milliseconds: 300),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isGpsReady ? Color(0xFF00B562).withOpacity(0.1) : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              isGpsReady ? Icons.gps_fixed : Icons.gps_off,
              color: isGpsReady ? Color(0xFF00B562) : Colors.red[600],
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedDefaultTextStyle( // NEW: Added animation for text changes
                  duration: Duration(milliseconds: 300),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isGpsReady ? Color(0xFF00B562) : Colors.red[600]!,
                  ),
                  child: Text(isGpsReady ? 'GPS Connected' : 'GPS Disconnected'), // NEW: Updated text
                ),
                AnimatedDefaultTextStyle( // NEW: Added animation for subtitle changes
                  duration: Duration(milliseconds: 300),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600]!,
                  ),
                  child: Text(
                    isGpsReady ? 'Location tracking is active' : 'Location tracking unavailable', // NEW: Updated subtitle
                  ),
                ),
              ],
            ),
          ),
          if (currentPosition != null && isGpsReady)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                '±${currentPosition!.accuracy.toStringAsFixed(0)}m',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStartRideUI() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Column(
        children: [
          Container(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF00B562).withOpacity(0.1), Color(0xFF00A855).withOpacity(0.05)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      size: 40,
                      color: Color(0xFF00B562),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Ready to Start Ride',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap the button below to begin tracking',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),
          Container(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => toggleMeter(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF00B562),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'START RIDE',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveRideUI() {
    return Column(
      children: [
        // Status Card
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: getStatusColor(),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: getStatusColor().withOpacity(0.4),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              Text(
                getMovementStatus(),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: getStatusColor(),
                ),
              ),
              Spacer(),
              Text(
                formatTime(),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        
        // Fare Display
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: isMoving ? _pulseAnimation.value : 1.0,
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
                      color: Colors.black.withOpacity(0.2),
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
                      '₹${totalFare.toStringAsFixed(2)}',
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
        ),
        SizedBox(height: 16),
        
        // Metrics Grid
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildMetric('Distance', '${formatDistance()} km', Icons.straighten)),
                  Container(width: 1, height: 40, color: Colors.grey[200]),
                  Expanded(child: _buildMetric('Base Fare', '₹${fare.toStringAsFixed(2)}', Icons.currency_rupee)),
                ],
              ),
              if (waitingCharge > 0) ...[
                Divider(height: 24, color: Colors.grey[200]),
                Row(
                  children: [
                    Expanded(child: _buildMetric('Waiting', '₹${waitingCharge.toStringAsFixed(2)}', Icons.access_time)),
                    Container(width: 1, height: 40, color: Colors.grey[200]),
                    Expanded(child: _buildMetric('Total Time', formatTime(), Icons.timer)),
                  ],
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: 16),
        
        // Waiting Time Selector
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Waiting Time',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8),
              DropdownButton<int>(
                isExpanded: true,
                value: selectedWaitingTime,
                underline: SizedBox(),
                icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
                items: waitingTimes.map((int time) {
                  return DropdownMenuItem<int>(
                    value: time,
                    child: Text(
                      time == 0 ? '🚗 Auto GPS Tracking' : '⏰ $time minutes',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    setState(() {
                      selectedWaitingTime = newValue;
                      if (newValue == 0) {
                        waitingCharge = 0.0;
                      } else {
                        updateWaitingChargeFromDropdown();
                      }
                    });
                  }
                },
              ),
            ],
          ),
        ),
        SizedBox(height: 24),
        
        // End Ride Button
        Container(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              stopMeter();
              _showTripSummary();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.stop, size: 24),
                SizedBox(width: 8),
                Text(
                  'END RIDE',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _showTripSummary() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Color(0xFF00B562).withOpacity(0.1),
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
                Text(
                  'Thank you for riding with us',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 24),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildSummaryRow('Distance Travelled', '${formatDistance()} km'),
                      _buildSummaryRow('Trip Duration', formatTime()),
                      _buildSummaryRow('Base Fare', '₹${fare.toStringAsFixed(2)}'),
                      if (waitingCharge > 0)
                        _buildSummaryRow('Waiting Charges', '₹${waitingCharge.toStringAsFixed(2)}'),
                      Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Amount',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            '₹${totalFare.toStringAsFixed(2)}',
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
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          if (isMeterOn) startMeter();
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text('Continue', style: TextStyle(color: Colors.grey[600])),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                          _showSnackBar('Trip completed successfully! ₹${totalFare.toStringAsFixed(2)}', true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF00B562),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        child: Text('Complete', style: TextStyle(fontWeight: FontWeight.w600)),
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

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
