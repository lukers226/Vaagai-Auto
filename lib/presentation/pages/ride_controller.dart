import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';

class RideController {
  // Ride metrics
  double distance = 0.0;
  int secondsPassed = 0;
  double currentFare = 0.0;
  double baseFareFromDB = 100.0;
  double perKmRateFromDB = 18.0;
  
  // Waiting time and charges
  int waitingSeconds = 0;
  double totalWaitingFare = 0.0;
  bool isVehicleMoving = false;
  Timer? waitingTimer;
  
  // Database fare structure
  Map<String, dynamic>? fareData;
  Map<int, double> waitingChargesFromDB = {
    5: 50.0,   // 5 minutes = 50 rupees
    10: 60.0,  // 10 minutes = 60 rupees
    15: 70.0,  // 15 minutes = 70 rupees
    20: 80.0,  // 20 minutes = 80 rupees
    25: 90.0,  // 25 minutes = 90 rupees
    30: 100.0, // 30 minutes = 100 rupees
  };
  
  // Trip timing
  DateTime? tripStartTime;
  DateTime? tripEndTime;
  
  // Timers
  Timer? meterTimer;
  Timer? locationTimer;
  Timer? gpsMonitorTimer;
  
  // State management
  bool isMeterOn = false;
  bool isRidePaused = false;
  
  // GPS tracking variables
  Position? lastPosition;
  Position? currentPosition;
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

  double get totalFare => currentFare;

  // Set fare data from database
  void setFareDataFromDB(Map<String, dynamic> data) {
    debugPrint('Setting fare data from database: $data');
    fareData = data;
    
    // Extract base fare
    final extractedBaseFare = _extractNumericValue(data['baseFare'], 100.0);
    baseFareFromDB = extractedBaseFare;
    
    // Extract per km rate
    final extractedPerKmRate = _extractNumericValue(data['perKmRate'], 18.0);
    perKmRateFromDB = extractedPerKmRate;
    
    // Update waiting charges from database - EXACT VALUES
    waitingChargesFromDB = {
      5: _extractNumericValue(data['waiting5min'], 50.0),   // 5min = 50
      10: _extractNumericValue(data['waiting10min'], 60.0), // 10min = 60
      15: _extractNumericValue(data['waiting15min'], 70.0), // 15min = 70
      20: _extractNumericValue(data['waiting20min'], 80.0), // 20min = 80
      25: _extractNumericValue(data['waiting25min'], 90.0), // 25min = 90
      30: _extractNumericValue(data['waiting30min'], 100.0), // 30min = 100
    };
    
 
    
    onStatusChange?.call();
  }

  // Extract numeric value from MongoDB Extended JSON
  double _extractNumericValue(dynamic value, double defaultValue) {
    debugPrint('Extracting numeric value from: $value (type: ${value.runtimeType})');
    
    if (value == null) {
      debugPrint('❌ Value is null, using default: $defaultValue');
      return defaultValue;
    }
    
    if (value is num) {
      debugPrint('✅ Value is already a number: ${value.toDouble()}');
      return value.toDouble();
    }
    
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
    
    // Handle MongoDB Extended JSON
    if (value is Map<String, dynamic>) {
      debugPrint('🔍 Processing MongoDB Extended JSON: $value');
      
      if (value.containsKey('\$numberInt')) {
        final numberIntValue = value['\$numberInt'];
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
      }
      
      if (value.containsKey('\$numberLong')) {
        final numberLongValue = value['\$numberLong'];
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
      }
      
      if (value.containsKey('\$numberDouble')) {
        final numberDoubleValue = value['\$numberDouble'];
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
      }
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

  // Start ride
  Future<bool> startRide() async {
    bool hasPermission = await requestLocationPermission();
    if (!hasPermission) return false;

    isMeterOn = true;
    isRidePaused = false;
    currentFare = 0.0; // Start with 0
    distance = 0.0;
    waitingSeconds = 0;
    totalWaitingFare = 0.0;
    isVehicleMoving = true; // Start assuming vehicle is moving
    tripStartTime = DateTime.now();
    _startMeter();
    onStatusChange?.call();
    return true;
  }

  // End ride (complete directly)
  void endRide() {
    isMeterOn = false;
    isRidePaused = false;
    tripEndTime = DateTime.now();
    meterTimer?.cancel();
    locationTimer?.cancel();
    waitingTimer?.cancel();
    onStatusChange?.call();
  }

  void resetMeter() {
    distance = 0.0;
    totalDistanceTravelled = 0.0;
    secondsPassed = 0;
    currentFare = 0.0;
    waitingSeconds = 0;
    totalWaitingFare = 0.0;
    isVehicleMoving = false;
    isRidePaused = false;
    lastPosition = null;
    currentPosition = null;
    tripStartTime = null;
    tripEndTime = null;
    onStatusChange?.call();
  }

  void _startMeter() {
    meterTimer?.cancel();
    locationTimer?.cancel();
    
    if (isRidePaused) return;
    
    // Timer for seconds counting
    meterTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!isMeterOn || isRidePaused) return;
      
      secondsPassed++;
      onStatusChange?.call();
    });

    // Timer for location updates
    locationTimer = Timer.periodic(Duration(seconds: locationUpdateInterval), (timer) async {
      if (!isMeterOn || isRidePaused) return;
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
          // Vehicle is moving
          if (!isVehicleMoving) {
            isVehicleMoving = true;
            _stopWaitingTimer();
            debugPrint('🚗 Vehicle started moving');
          }
          
          double distanceInKm = distanceInMeters / 1000;
          distance += distanceInKm;
          totalDistanceTravelled += distanceInKm;
          _updateFareForDistance();
          lastPosition = newPosition;
          onStatusChange?.call();
        } else {
          // Vehicle is not moving
          if (isVehicleMoving) {
            isVehicleMoving = false;
            _startWaitingTimer();
            debugPrint('⏸️ Vehicle stopped moving');
          }
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

  // Start waiting timer when vehicle stops
  void _startWaitingTimer() {
    waitingTimer?.cancel();
    waitingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!isMeterOn || isVehicleMoving) {
        timer.cancel();
        return;
      }
      
      waitingSeconds++;
      
      // **PROGRESSIVE WAITING CALCULATION**: Calculate based on time brackets
      totalWaitingFare = _calculateProgressiveWaitingFare();
      
      // Update current fare with new waiting charges
      _updateCurrentFareWithWaiting();
      
      debugPrint('⏱️ Waiting: ${waitingSeconds}s (${getWaitingTimeDisplay()}), Waiting Fare: ₹${totalWaitingFare.toStringAsFixed(2)}, Current Fare: ₹${currentFare.toStringAsFixed(2)}');
      onStatusChange?.call();
    });
  }

  // **NEW PROGRESSIVE WAITING FARE CALCULATION**
  double _calculateProgressiveWaitingFare() {
    if (waitingSeconds <= 0) return 0.0;
    
    // Convert seconds to minutes
    double totalMinutes = waitingSeconds / 60.0;
    
    // Get sorted time brackets
    List<int> sortedBrackets = waitingChargesFromDB.keys.toList()..sort();
    
    // Progressive calculation based on time brackets
    double calculatedFare = 0.0;
    
    for (int i = 0; i < sortedBrackets.length; i++) {
      int currentBracket = sortedBrackets[i]; // Current bracket in minutes
      double currentBracketFare = waitingChargesFromDB[currentBracket]!;
      
      if (totalMinutes <= currentBracket) {
        // We're within this bracket
        if (i == 0) {
          // First bracket (0 to currentBracket minutes)
          double ratePerMinute = currentBracketFare / currentBracket;
          calculatedFare = totalMinutes * ratePerMinute;
        } else {
          // Subsequent brackets
          int previousBracket = sortedBrackets[i - 1];
          double previousBracketFare = waitingChargesFromDB[previousBracket]!;
          
          // Calculate rate for this bracket segment
          double bracketDuration = (currentBracket - previousBracket).toDouble();
          double bracketFareDifference = currentBracketFare - previousBracketFare;
          double ratePerMinute = bracketFareDifference / bracketDuration;
          
          // Add previous bracket fare + proportional fare for current bracket
          double minutesInCurrentBracket = totalMinutes - previousBracket;
          calculatedFare = previousBracketFare + (minutesInCurrentBracket * ratePerMinute);
        }
        break;
      } else if (i == sortedBrackets.length - 1) {
        // Beyond the last bracket - use the last bracket rate
        int previousBracket = i > 0 ? sortedBrackets[i - 1] : 0;
        double previousBracketFare = i > 0 ? waitingChargesFromDB[previousBracket]! : 0.0;
        
        double bracketDuration = (currentBracket - previousBracket).toDouble();
        double bracketFareDifference = currentBracketFare - previousBracketFare;
        double ratePerMinute = bracketFareDifference / bracketDuration;
        
        // Calculate fare beyond last bracket
        double extraMinutes = totalMinutes - currentBracket;
        calculatedFare = currentBracketFare + (extraMinutes * ratePerMinute);
        break;
      }
    }
    
    debugPrint('📊 Progressive Waiting Calculation: ${totalMinutes.toStringAsFixed(2)} minutes = ₹${calculatedFare.toStringAsFixed(2)}');
    return calculatedFare;
  }

  // Stop waiting timer when vehicle moves
  void _stopWaitingTimer() {
    waitingTimer?.cancel();
  }

  // Update current fare with waiting charges included
  void _updateCurrentFareWithWaiting() {
    double baseFare = 0.0;
    double distanceFare = 0.0;
    
    if (distance >= 1.0) {
      // After 1km, add base fare + extra distance charges
      baseFare = baseFareFromDB;
      double extraDistance = distance - 1.0;
      distanceFare = extraDistance * perKmRateFromDB;
    }
    
    // Current fare = base fare + distance fare + waiting fare
    currentFare = baseFare + distanceFare + totalWaitingFare;
    
    debugPrint('💰 Current Fare Updated: Base=₹${baseFare.toStringAsFixed(2)}, Distance=₹${distanceFare.toStringAsFixed(2)}, Waiting=₹${totalWaitingFare.toStringAsFixed(2)}, Total=₹${currentFare.toStringAsFixed(2)}');
  }

  // Update fare based on distance only
  void _updateFareForDistance() {
    double baseFare = 0.0;
    double distanceFare = 0.0;
    
    if (distance >= 1.0) {
      // After 1km, add base fare + extra distance charges
      baseFare = baseFareFromDB;
      double extraDistance = distance - 1.0;
      distanceFare = extraDistance * perKmRateFromDB;
    }
    
    // Current fare = base fare + distance fare + accumulated waiting fare
    currentFare = baseFare + distanceFare + totalWaitingFare;
    
    debugPrint('💰 Distance Fare Updated: Distance=${distance.toStringAsFixed(3)}km, Base=₹${baseFare.toStringAsFixed(2)}, Distance=₹${distanceFare.toStringAsFixed(2)}, Current Fare=₹${currentFare.toStringAsFixed(2)}');
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

  String getWaitingTimeDisplay() {
    int minutes = waitingSeconds ~/ 60;
    int seconds = waitingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
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
    if (isRidePaused) return 'Ride Paused';
    return isVehicleMoving ? 'Moving' : 'Waiting';
  }

  Color getStatusColor() {
    if (!isMeterOn) return Color(0xFF9CA3AF);
    if (isRidePaused) return Color(0xFFEF4444);
    return isVehicleMoving ? Color(0xFF00B562) : Color(0xFFD97706);
  }
}
