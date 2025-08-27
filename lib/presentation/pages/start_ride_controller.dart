import 'package:flutter/material.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

class StartRideController {
  final VoidCallback onStateChanged;
  final BuildContext context;

  StartRideController({
    required this.onStateChanged,
    required this.context,
  });

  // State variables
  double distance = 0.0;
  int secondsPassed = 0;
  double fare = 59.0;
  double waitingCharge = 0.0;
  int selectedWaitingTime = 0;
  List<int> waitingTimes = [0, 5, 10, 15, 20, 25, 30];
  Timer? meterTimer;
  Timer? locationTimer;
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

  // Calculate total fare
  double get totalFare => fare + waitingCharge;

  Future<void> initialize() async {
    await _checkLocationStatus();
  }

  void dispose() {
    meterTimer?.cancel();
    locationTimer?.cancel();
  }

  Future<void> _checkLocationStatus() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();
      bool permissionGranted = permission == LocationPermission.whileInUse || 
                              permission == LocationPermission.always;
      
      isLocationServiceEnabled = serviceEnabled;
      hasLocationPermission = permissionGranted;
      onStateChanged();
      
      debugPrint('Location service enabled: $serviceEnabled');
      debugPrint('Location permission: $permission');
    } catch (e) {
      debugPrint('Error checking location status: $e');
      isLocationServiceEnabled = false;
      hasLocationPermission = false;
      onStateChanged();
      
      _showErrorSnackBar('Location services not available. Please check app permissions.');
    }
  }

  Future<bool> _requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showLocationServiceDialog();
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showPermissionDeniedDialog();
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showPermissionDeniedForeverDialog();
      return false;
    }

    isLocationServiceEnabled = true;
    hasLocationPermission = true;
    onStateChanged();
    
    return true;
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.location_off, color: Colors.orange[700], size: 24),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Location Required',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          content: Text(
            'This app needs location services to track your ride accurately. Please enable location services in your device settings.',
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Geolocator.openLocationSettings();
                Timer(Duration(seconds: 2), _checkLocationStatus);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Open Settings', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Permission Denied', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          content: Text('Location permission is required to track your ride distance and calculate fare.'),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showPermissionDeniedForeverDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Permission Required', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          content: Text('Location permission is permanently denied. Please enable it in app settings.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Geolocator.openAppSettings();
              },
              child: Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  void startMeter() async {
    meterTimer?.cancel();
    locationTimer?.cancel();
    
    meterTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!isMeterOn) return;
      
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
      
      onStateChanged();
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
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        timeLimit: Duration(seconds: 10),
      );
      
      lastPosition = position;
      currentPosition = position;
      onStateChanged();
      
      debugPrint('Initial position: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      debugPrint('Error getting initial location: $e');
      _showErrorSnackBar('Unable to get current location. Please check GPS.');
    }
  }

  Future<void> _updateLocation() async {
    try {
      Position newPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        timeLimit: Duration(seconds: 8),
      );

      if (lastPosition != null) {
        double distanceInMeters = Geolocator.distanceBetween(
          lastPosition!.latitude,
          lastPosition!.longitude,
          newPosition.latitude,
          newPosition.longitude,
        );

        debugPrint('Distance moved: ${distanceInMeters.toStringAsFixed(2)} meters');
        debugPrint('Speed: ${newPosition.speed.toStringAsFixed(2)} m/s');
        debugPrint('Accuracy: ${newPosition.accuracy.toStringAsFixed(2)} meters');

        if (distanceInMeters >= MOVEMENT_THRESHOLD && newPosition.accuracy <= 15) {
          isMoving = true;
          double distanceInKm = distanceInMeters / 1000;
          distance += distanceInKm;
          totalDistanceTravelled += distanceInKm;
          updateFare();
          lastPosition = newPosition;
          
          debugPrint('Vehicle is moving. Total distance: ${distance.toStringAsFixed(3)} km');
        } else {
          isMoving = false;
        }

        if (distanceInMeters < MOVEMENT_THRESHOLD) {
          lastPosition = newPosition;
        }
      } else {
        lastPosition = newPosition;
      }

      currentPosition = newPosition;
      onStateChanged();

    } catch (e) {
      debugPrint('Error updating location: $e');
    }
  }

  void toggleMeter(bool enable) async {
    if (enable) {
      bool hasPermission = await _requestLocationPermission();
      if (!hasPermission) {
        return;
      }
    }

    isMeterOn = enable;
    if (isMeterOn) {
      startMeter();
    } else {
      stopMeter();
      resetMeter();
    }
    onStateChanged();
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

  String formatDistance() {
    return distance.toStringAsFixed(3);
  }

  String formatTime() {
    int minutes = secondsPassed ~/ 60;
    int seconds = secondsPassed % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String getMovementStatus() {
    if (!isMeterOn) return 'Meter Off';
    if (isMoving) return 'Moving';
    return 'Stationary';
  }

  Color getMovementStatusColor() {
    if (!isMeterOn) return Colors.grey;
    if (isMoving) return Color(0xFF10B981);
    return Color(0xFFF59E0B);
  }

  void onWaitingTimeChanged(int? newValue) {
    if (newValue != null) {
      selectedWaitingTime = newValue;
      if (newValue == 0) {
        waitingCharge = 0.0;
      } else {
        updateWaitingChargeFromDropdown();
      }
      onStateChanged();
    }
  }

  void endRide() {
    stopMeter();
    showTripSummary();
  }

  void showTripSummary() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [Colors.white, Colors.grey[50]!],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green[700],
                    size: 48,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Trip Completed',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 24),
                _buildSummaryRow('Distance', '${formatDistance()} km'),
                _buildSummaryRow('Duration', formatTime()),
                _buildSummaryRow('Base Fare', '₹${fare.toStringAsFixed(2)}'),
                if (waitingCharge > 0)
                  _buildSummaryRow('Waiting Charge', '₹${waitingCharge.toStringAsFixed(2)}'),
                SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'TOTAL AMOUNT',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 14,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '₹${totalFare.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          if (isMeterOn) {
                            startMeter();
                          }
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          'Continue',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.white),
                                  SizedBox(width: 12),
                                  Text('Trip completed! ₹${totalFare.toStringAsFixed(2)}'),
                                ],
                              ),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF10B981),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Complete',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'Settings',
          textColor: Colors.white,
          onPressed: () => Geolocator.openAppSettings(),
        ),
      ),
    );
  }
}
