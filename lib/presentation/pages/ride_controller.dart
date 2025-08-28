import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';

class RideController {
  // Ride metrics
  double distance = 0.0;
  int secondsPassed = 0;
  double fare = 100.0; // Will be updated from database
  double waitingCharge = 0.0;
  
  // Database fare structure
  Map<String, dynamic>? fareData;
  double baseFareFromDB = 100.0;
  Map<int, double> waitingChargesFromDB = {
    5: 10.0,
    10: 20.0,
    15: 30.0,
    20: 40.0,
    25: 50.0,
    30: 60.0,
  };
  
  // Waiting time toggle and timer
  bool isWaitingTimerActive = false;
  int waitingMinutesElapsed = 0;
  int waitingSecondsElapsed = 0;
  Timer? waitingTimer;
  
  // Trip timing
  DateTime? tripStartTime;
  DateTime? tripEndTime;
  
  // Timers
  Timer? meterTimer;
  Timer? locationTimer;
  Timer? gpsMonitorTimer;
  
  // State
  bool isMeterOn = false;
  int waitingSeconds = 0;
  
  // GPS tracking variables
  Position? lastPosition;
  Position? currentPosition;
  bool isMoving = false;
  double totalDistanceTravelled = 0.0;
  
  // Location tracking settings
  static const double movementThreshold = 3.0;
  static const int locationUpdateInterval = 2;
  
  // Location permission and service status
  bool isLocationServiceEnabled = false;
  bool hasLocationPermission = false;

  // Callbacks
  VoidCallback? onLocationUpdate;
  VoidCallback? onStatusChange;
  Function(String, bool)? onShowSnackBar;

  double get totalFare => fare + waitingCharge;

  // ENHANCED: Set fare data from database with improved parsing
  void setFareDataFromDB(Map<String, dynamic> data) {
    debugPrint('Setting fare data from database: $data');
    fareData = data;
    
    // ENHANCED: Extract base fare with better error handling
    final extractedBaseFare = _extractNumericValue(data['baseFare'], 100.0);
    baseFareFromDB = extractedBaseFare;
    fare = baseFareFromDB;
    
    // Update waiting charges from database with validation
    waitingChargesFromDB = {
      5: _extractNumericValue(data['waiting5min'], 10.0),
      10: _extractNumericValue(data['waiting10min'], 20.0),
      15: _extractNumericValue(data['waiting15min'], 30.0),
      20: _extractNumericValue(data['waiting20min'], 40.0),
      25: _extractNumericValue(data['waiting25min'], 50.0),
      30: _extractNumericValue(data['waiting30min'], 60.0),
    };
    
    debugPrint('✅ Fare data successfully set:');
    debugPrint('📊 Base Fare: ₹${baseFareFromDB}');
    debugPrint('⏱️ Waiting Charges: $waitingChargesFromDB');
    
    // Force UI update to show new fare immediately
    onStatusChange?.call();
  }

  // ENHANCED: Improved numeric value extraction with comprehensive error handling
  double _extractNumericValue(dynamic value, double defaultValue) {
    debugPrint('Extracting numeric value from: $value (type: ${value.runtimeType})');
    
    if (value == null) {
      debugPrint('❌ Value is null, using default: $defaultValue');
      return defaultValue;
    }
    
    // If it's already a number
    if (value is num) {
      debugPrint('✅ Value is already a number: ${value.toDouble()}');
      return value.toDouble();
    }
    
    // If it's a string representation of number
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) {
        debugPrint('✅ Parsed string value: $parsed');
        return parsed;
      } else {
        debugPrint('❌ Failed to parse string: $value, using default: $defaultValue');
        return defaultValue;
      }
    }
    
    // ENHANCED: Handle MongoDB Extended JSON object with detailed logging
    if (value is Map<String, dynamic>) {
      debugPrint('🔍 Processing MongoDB Extended JSON: $value');
      
      // Handle $numberInt
      if (value.containsKey('\$numberInt')) {
        final numberIntValue = value['\$numberInt'];
        debugPrint('📝 Found \$numberInt: $numberIntValue (type: ${numberIntValue.runtimeType})');
        
        if (numberIntValue is String) {
          final parsed = double.tryParse(numberIntValue);
          if (parsed != null) {
            debugPrint('✅ Successfully parsed \$numberInt string: $parsed');
            return parsed;
          }
        } else if (numberIntValue is num) {
          debugPrint('✅ \$numberInt is already a number: ${numberIntValue.toDouble()}');
          return numberIntValue.toDouble();
        }
        debugPrint('❌ Failed to parse \$numberInt, using default: $defaultValue');
        return defaultValue;
      }
      
      // Handle $numberLong
      if (value.containsKey('\$numberLong')) {
        final numberLongValue = value['\$numberLong'];
        debugPrint('📝 Found \$numberLong: $numberLongValue (type: ${numberLongValue.runtimeType})');
        
        if (numberLongValue is String) {
          final parsed = double.tryParse(numberLongValue);
          if (parsed != null) {
            debugPrint('✅ Successfully parsed \$numberLong string: $parsed');
            return parsed;
          }
        } else if (numberLongValue is num) {
          debugPrint('✅ \$numberLong is already a number: ${numberLongValue.toDouble()}');
          return numberLongValue.toDouble();
        }
        debugPrint('❌ Failed to parse \$numberLong, using default: $defaultValue');
        return defaultValue;
      }
      
      // Handle $numberDouble
      if (value.containsKey('\$numberDouble')) {
        final numberDoubleValue = value['\$numberDouble'];
        debugPrint('📝 Found \$numberDouble: $numberDoubleValue (type: ${numberDoubleValue.runtimeType})');
        
        if (numberDoubleValue is String) {
          final parsed = double.tryParse(numberDoubleValue);
          if (parsed != null) {
            debugPrint('✅ Successfully parsed \$numberDouble string: $parsed');
            return parsed;
          }
        } else if (numberDoubleValue is num) {
          debugPrint('✅ \$numberDouble is already a number: ${numberDoubleValue.toDouble()}');
          return numberDoubleValue.toDouble();
        }
        debugPrint('❌ Failed to parse \$numberDouble, using default: $defaultValue');
        return defaultValue;
      }
      
      debugPrint('❌ No recognized MongoDB numeric field found in: $value');
    }
    
    debugPrint('❌ Could not extract numeric value from: $value (type: ${value.runtimeType}), using default: $defaultValue');
    return defaultValue;
  }

  void initialize({
    VoidCallback? onLocationUpdate,
    VoidCallback? onStatusChange,
    Function(String, bool)? onShowSnackBar,
  }) {
    this.onLocationUpdate = onLocationUpdate;
    this.onStatusChange = onStatusChange;
    this.onShowSnackBar = onShowSnackBar;
    
    _checkLocationStatus();
    _startGpsMonitoring();
  }

  void dispose() {
    meterTimer?.cancel();
    locationTimer?.cancel();
    gpsMonitorTimer?.cancel();
    waitingTimer?.cancel();
  }

  // GPS Monitoring
  void _startGpsMonitoring() {
    gpsMonitorTimer = Timer.periodic(Duration(seconds: 3), (timer) async {
      await _monitorGpsStatus();
    });
  }

  Future<void> _monitorGpsStatus() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();
      bool permissionGranted = permission == LocationPermission.whileInUse || 
                              permission == LocationPermission.always;
      
      bool previousGpsStatus = isLocationServiceEnabled && hasLocationPermission;
      bool currentGpsStatus = serviceEnabled && permissionGranted;
      
      if (previousGpsStatus && !currentGpsStatus) {
        onShowSnackBar?.call('GPS disconnected! Location tracking may be affected.', false);
      } else if (!previousGpsStatus && currentGpsStatus) {
        onShowSnackBar?.call('GPS reconnected successfully!', true);
      }
      
      isLocationServiceEnabled = serviceEnabled;
      hasLocationPermission = permissionGranted;
      onStatusChange?.call();
    } catch (e) {
      bool wasConnected = isLocationServiceEnabled && hasLocationPermission;
      if (wasConnected) {
        onShowSnackBar?.call('GPS connection lost! Please check your location settings.', false);
      }
      
      isLocationServiceEnabled = false;
      hasLocationPermission = false;
      onStatusChange?.call();
    }
  }

  Future<void> _checkLocationStatus() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();
      bool permissionGranted = permission == LocationPermission.whileInUse || 
                              permission == LocationPermission.always;
      
      isLocationServiceEnabled = serviceEnabled;
      hasLocationPermission = permissionGranted;
      onStatusChange?.call();
    } catch (e) {
      isLocationServiceEnabled = false;
      hasLocationPermission = false;
      onShowSnackBar?.call('Location services error. Please check permissions.', false);
      onStatusChange?.call();
    }
  }

  Future<bool> requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        onShowSnackBar?.call('Location permission denied', false);
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    isLocationServiceEnabled = true;
    hasLocationPermission = true;
    onStatusChange?.call();
    
    return true;
  }

  // Toggle waiting timer with proper second-by-second updates
  void toggleWaitingTimer() {
    if (isWaitingTimerActive) {
      // Stop waiting timer
      isWaitingTimerActive = false;
      waitingTimer?.cancel();
      debugPrint('Waiting timer stopped at ${waitingMinutesElapsed}:${waitingSecondsElapsed.toString().padLeft(2, '0')}');
      onShowSnackBar?.call('Waiting timer stopped', true);
    } else {
      // Start waiting timer
      isWaitingTimerActive = true;
      waitingMinutesElapsed = 0;
      waitingSecondsElapsed = 0;
      waitingCharge = 0.0;
      
      // Timer runs every second
      waitingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        waitingSecondsElapsed++;
        
        // Check if a minute has passed
        if (waitingSecondsElapsed >= 60) {
          waitingSecondsElapsed = 0;
          waitingMinutesElapsed++;
          _updateWaitingChargeFromTimer();
          debugPrint('Waiting timer: ${waitingMinutesElapsed} min - Charge: ₹${waitingCharge.toStringAsFixed(0)}');
          onShowSnackBar?.call('Waiting: ${waitingMinutesElapsed} min - ₹${waitingCharge.toStringAsFixed(0)}', true);
        }
        
        onStatusChange?.call(); // Update UI every second
      });
      
      debugPrint('Waiting timer started');
      onShowSnackBar?.call('Waiting timer started', true);
    }
    onStatusChange?.call();
  }

  // Update waiting charge based on timer
  void _updateWaitingChargeFromTimer() {
    double newCharge = 0.0;
    
    for (int minutes in waitingChargesFromDB.keys.toList()..sort()) {
      if (waitingMinutesElapsed >= minutes) {
        newCharge = waitingChargesFromDB[minutes] ?? 0.0;
      }
    }
    
    waitingCharge = newCharge;
    debugPrint('Updated waiting charge: ₹${waitingCharge} for ${waitingMinutesElapsed} minutes');
  }

  // Ride Control Methods
  Future<bool> startRide() async {
    bool hasPermission = await requestLocationPermission();
    if (!hasPermission) return false;

    isMeterOn = true;
    tripStartTime = DateTime.now();
    _startMeter();
    onStatusChange?.call();
    return true;
  }

  void stopRide() {
    isMeterOn = false;
    tripEndTime = DateTime.now();
    meterTimer?.cancel();
    locationTimer?.cancel();
    
    // Stop waiting timer when ride ends
    if (isWaitingTimerActive) {
      isWaitingTimerActive = false;
      waitingTimer?.cancel();
    }
    
    onStatusChange?.call();
  }

  void cancelRide() {
    meterTimer?.cancel();
    locationTimer?.cancel();
    gpsMonitorTimer?.cancel();
    
    // Cancel waiting timer
    if (isWaitingTimerActive) {
      isWaitingTimerActive = false;
      waitingTimer?.cancel();
    }
    
    resetMeter();
    
    isMeterOn = false;
    onStatusChange?.call();
  }

  void resumeRide() {
    if (isMeterOn) {
      _startMeter();
    }
  }

  void resetMeter() {
    distance = 0.0;
    totalDistanceTravelled = 0.0;
    secondsPassed = 0;
    fare = baseFareFromDB; // Reset to database base fare
    waitingCharge = 0.0;
    waitingSeconds = 0;
    waitingMinutesElapsed = 0;
    waitingSecondsElapsed = 0;
    isWaitingTimerActive = false;
    isMoving = false;
    lastPosition = null;
    currentPosition = null;
    tripStartTime = null;
    tripEndTime = null;
    onStatusChange?.call();
  }

  void _startMeter() {
    meterTimer?.cancel();
    locationTimer?.cancel();
    
    meterTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!isMeterOn) return;
      
      secondsPassed++;
      onStatusChange?.call();
    });

    locationTimer = Timer.periodic(Duration(seconds: locationUpdateInterval), (timer) async {
      if (!isMeterOn) return;
      await _updateLocation();
    });

    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );
      
      lastPosition = position;
      currentPosition = position;
      onLocationUpdate?.call();
    } catch (e) {
      onShowSnackBar?.call('Unable to get location. Check GPS.', false);
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

        if (distanceInMeters >= movementThreshold && newPosition.accuracy <= 20) {
          isMoving = true;
          double distanceInKm = distanceInMeters / 1000;
          distance += distanceInKm;
          totalDistanceTravelled += distanceInKm;
          updateFare();
          lastPosition = newPosition;
          onStatusChange?.call();
        } else {
          isMoving = false;
          onStatusChange?.call();
        }

        if (distanceInMeters < movementThreshold) {
          lastPosition = newPosition;
        }
      } else {
        lastPosition = newPosition;
      }

      currentPosition = newPosition;
      onLocationUpdate?.call();

    } catch (e) {
      debugPrint('Location update error: $e');
    }
  }

  // ENHANCED: Fare Calculation - Use database values
  void updateFare() {
    if (distance <= 1.0) {
      fare = baseFareFromDB;
    } else {
      double extraDistance = distance - 1.0;
      fare = baseFareFromDB + (extraDistance * 18.0);
    }
    debugPrint('💰 Fare updated: Base=₹${baseFareFromDB}, Distance=${distance.toStringAsFixed(2)}km, Total=₹${fare.toStringAsFixed(2)}');
  }

  // Get formatted trip times
  String getTripStartTime() {
    if (tripStartTime == null) return '--:--';
    return '${tripStartTime!.hour.toString().padLeft(2, '0')}:${tripStartTime!.minute.toString().padLeft(2, '0')}';
  }

  String getTripEndTime() {
    if (tripEndTime == null) return '--:--';
    return '${tripEndTime!.hour.toString().padLeft(2, '0')}:${tripEndTime!.minute.toString().padLeft(2, '0')}';
  }

  // Get waiting timer display with proper MM:SS format
  String getWaitingTimerDisplay() {
    if (!isWaitingTimerActive) return '00:00';
    return '${waitingMinutesElapsed.toString().padLeft(2, '0')}:${waitingSecondsElapsed.toString().padLeft(2, '0')}';
  }

  // Utility Methods
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
    if (!isMeterOn) return Color(0xFF9CA3AF);
    return isMoving ? Color(0xFF00B562) : Color(0xFFD97706);
  }
}
