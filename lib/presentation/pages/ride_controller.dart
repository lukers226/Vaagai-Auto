import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class RideController {
  // Ride metrics
  double distance = 0.0;
  int secondsPassed = 0;
  double currentFare = 0.0;
  double baseFareFromDB = 60.0;
  double perKmRateFromDB = 18.0;
  
  // Waiting time and charges
  int waitingSeconds = 0;
  double totalWaitingFare = 0.0;
  bool isVehicleMoving = false;
  Timer? waitingTimer;
  
  // **ENHANCED: Motion sensor movement detection**
  StreamSubscription<UserAccelerometerEvent>? accelerometerSubscription;
  bool isMotionDetected = false;
  double accelerometerThreshold = 1.8; // Lower threshold for walking detection
  List<double> accelerometerReadings = [];
  DateTime? lastMotionTime;
  
  // Database fare structure
  Map<String, dynamic>? fareData;
  double waiting60MinFromDB = 60.0;
  
  // Trip timing
  DateTime? tripStartTime;
  DateTime? tripEndTime;
  
  // Timers
  Timer? meterTimer;
  Timer? locationTimer;
  Timer? gpsMonitorTimer;
  Timer? fareUpdateTimer;
  Timer? stationaryTimer;
  int secondsSinceLastMovement = 0;
  
  // State management
  bool isMeterOn = false;
  bool isRidePaused = false;
  
  // GPS tracking variables
  Position? lastPosition;
  Position? currentPosition;
  double totalDistanceTravelled = 0.0;
  
  // **OPTIMIZED: Movement detection settings**
  static const double walkingThreshold = 1.0; // Very sensitive for walking
  static const int locationUpdateInterval = 1; // 1 second updates
  static const int stationaryDelaySeconds = 3; // Start waiting after 3 seconds (faster)

  // Location permission and service status
  bool isLocationServiceEnabled = false;
  bool hasLocationPermission = false;

  // Callbacks
  VoidCallback? onLocationUpdate;
  VoidCallback? onStatusChange;
  Function(String, bool)? onShowSnackBar;

  double get totalFare => currentFare;

  void setFareDataFromDB(Map<String, dynamic> data) {
    debugPrint('Setting fare data from database: $data');
    fareData = data;
    
    final extractedBaseFare = _extractNumericValue(data['baseFare'], 60.0);
    baseFareFromDB = extractedBaseFare;
    
    final extractedPerKmRate = _extractNumericValue(data['perKmRate'], 18.0);
    perKmRateFromDB = extractedPerKmRate;
    
    waiting60MinFromDB = _extractNumericValue(data['waiting60min'], 60.0);
    
    debugPrint('📊 Fare data loaded: Base=₹${baseFareFromDB}, PerKm=₹${perKmRateFromDB}, Waiting60Min=₹${waiting60MinFromDB}');
    
    onStatusChange?.call();
  }

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
    _setupMotionSensors();
  }

  // **ENHANCED: Motion sensor setup for walking detection**  
  void _setupMotionSensors() {
    accelerometerSubscription = userAccelerometerEvents.listen((event) {
      // Calculate motion magnitude
      double magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      
      accelerometerReadings.add(magnitude);
      if (accelerometerReadings.length > 5) {
        accelerometerReadings.removeAt(0); // Keep only last 5 readings
      }
      
      // Calculate average motion over recent readings
      double avgMotion = accelerometerReadings.reduce((a, b) => a + b) / accelerometerReadings.length;
      
      bool previousMotionState = isMotionDetected;
      isMotionDetected = avgMotion > accelerometerThreshold;
      
      if (isMotionDetected) {
        lastMotionTime = DateTime.now();
        
        if (!previousMotionState) {
          debugPrint('🚶 MOTION DETECTED via accelerometer (${avgMotion.toStringAsFixed(2)})');
          _handleMovementDetected('Motion Sensor');
        }
      }
    });
    
    debugPrint('✅ Motion sensors initialized with threshold: $accelerometerThreshold');
  }

  // **ENHANCED: Handle movement detection from any source**
  void _handleMovementDetected(String source) {
    if (!isVehicleMoving) {
      debugPrint('🚗 MOVEMENT CONFIRMED by $source → STOP waiting charges');
      isVehicleMoving = true;
      secondsSinceLastMovement = 0;
      _stopWaitingCharges();
      onStatusChange?.call();
    }
  }

  void dispose() {
    meterTimer?.cancel();
    locationTimer?.cancel();
    gpsMonitorTimer?.cancel();
    waitingTimer?.cancel();
    fareUpdateTimer?.cancel();
    stationaryTimer?.cancel();
    accelerometerSubscription?.cancel();
  }

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

  Future<bool> startRide() async {
    bool hasPermission = await requestLocationPermission();
    if (!hasPermission) return false;

    isMeterOn = true;
    isRidePaused = false;
    currentFare = 0.0;
    distance = 0.0;
    waitingSeconds = 0;
    totalWaitingFare = 0.0;
    isVehicleMoving = false;
    isMotionDetected = false;
    secondsSinceLastMovement = 0;
    accelerometerReadings.clear();
    lastMotionTime = null;
    
    tripStartTime = DateTime.now();
    _startMeter();
    _startFareUpdateTimer();
    _startStationaryTimer();
    
    onStatusChange?.call();
    return true;
  }

  void _startStationaryTimer() {
    stationaryTimer?.cancel();
    
    debugPrint('🏁 Starting enhanced stationary detection (${stationaryDelaySeconds}s delay)');
    
    stationaryTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!isMeterOn || isRidePaused) {
        timer.cancel();
        stationaryTimer = null;
        return;
      }
      
      // **Check if motion was recently detected**
      bool recentMotion = false;
      if (lastMotionTime != null) {
        int secondsSinceMotion = DateTime.now().difference(lastMotionTime!).inSeconds;
        recentMotion = secondsSinceMotion < 2; // Motion detected within last 2 seconds
      }
      
      if (!isVehicleMoving && !recentMotion) {
        secondsSinceLastMovement++;
        debugPrint('⏰ Stationary for ${secondsSinceLastMovement}s (Motion: $isMotionDetected, Recent: $recentMotion)');
        
        if (secondsSinceLastMovement >= stationaryDelaySeconds && waitingTimer == null) {
          debugPrint('✅ ${stationaryDelaySeconds} seconds stationary → STARTING waiting charges');
          _startWaitingCharges();
        }
      } else {
        if (recentMotion && !isVehicleMoving) {
          _handleMovementDetected('Recent Motion');
        }
        secondsSinceLastMovement = 0;
      }
    });
  }

  void endRide() {
    isMeterOn = false;
    isRidePaused = false;
    tripEndTime = DateTime.now();
    _stopAllTimers();
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
    isMotionDetected = false;
    isRidePaused = false;
    secondsSinceLastMovement = 0;
    accelerometerReadings.clear();
    lastMotionTime = null;
    lastPosition = null;
    currentPosition = null;
    tripStartTime = null;
    tripEndTime = null;
    _stopAllTimers();
    onStatusChange?.call();
  }

  void _stopAllTimers() {
    stationaryTimer?.cancel();
    stationaryTimer = null;
    waitingTimer?.cancel();
    waitingTimer = null;
    fareUpdateTimer?.cancel();
    debugPrint('🛑 All timers stopped');
  }

  void _startFareUpdateTimer() {
    fareUpdateTimer?.cancel();
    fareUpdateTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!isMeterOn || isRidePaused) return;
      
      _calculateCurrentFare();
      onStatusChange?.call();
    });
  }

  void _startMeter() {
    meterTimer?.cancel();
    locationTimer?.cancel();
    
    if (isRidePaused) return;
    
    meterTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!isMeterOn || isRidePaused) return;
      
      secondsPassed++;
      onStatusChange?.call();
    });

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
        timeLimit: Duration(seconds: 5),
      );

      // **Accept wider range of accuracy**
      if (newPosition.accuracy > 100) {
        debugPrint('⚠️ Very poor GPS accuracy (${newPosition.accuracy}m), ignoring');
        return;
      }

      if (lastPosition != null) {
        double distanceInMeters = Geolocator.distanceBetween(
          lastPosition!.latitude,
          lastPosition!.longitude,
          newPosition.latitude,
          newPosition.longitude,
        );

        debugPrint('📍 GPS: Distance=${distanceInMeters.toStringAsFixed(1)}m, Accuracy=${newPosition.accuracy.toStringAsFixed(1)}m, Motion=${isMotionDetected}');

        // **GPS-based movement detection**
        if (distanceInMeters >= walkingThreshold) {
          _handleMovementDetected('GPS (${distanceInMeters.toStringAsFixed(1)}m)');
          
          // Add distance
          double distanceInKm = distanceInMeters / 1000;
          distance += distanceInKm;
          totalDistanceTravelled += distanceInKm;
          debugPrint('🛣️ Added distance: ${distanceInKm.toStringAsFixed(4)}km, Total: ${distance.toStringAsFixed(3)}km');
          
        } else if (!isMotionDetected && isVehicleMoving) {
          // **STOPPED MOVING** - only if no motion sensor activity
          debugPrint('⏸️ GPS shows no movement and no motion detected → Reset stationary timer');
          isVehicleMoving = false;
          secondsSinceLastMovement = 0;
        }

        lastPosition = newPosition;
      } else {
        lastPosition = newPosition;
      }

      currentPosition = newPosition;
      onLocationUpdate?.call();

    } catch (e) {
      debugPrint('❌ Location update error: $e');
    }
  }

  void _startWaitingCharges() {
    if (waitingTimer != null) return; // Already running
    
    debugPrint('✅ STARTING waiting charges');
    
    waitingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      // **IMMEDIATELY STOP if any movement detected**
      bool recentMotion = false;
      if (lastMotionTime != null) {
        int secondsSinceMotion = DateTime.now().difference(lastMotionTime!).inSeconds;
        recentMotion = secondsSinceMotion < 1; // Very sensitive - 1 second
      }
      
      if (isVehicleMoving || recentMotion) {
        debugPrint('🛑 Movement detected → STOP waiting charges (GPS: $isVehicleMoving, Recent: $recentMotion)');
        timer.cancel();
        waitingTimer = null;
        return;
      }
      
      if (!isMeterOn || isRidePaused) {
        debugPrint('🛑 Meter stopped → STOP waiting charges');
        timer.cancel();
        waitingTimer = null;
        return;
      }
      
      waitingSeconds++;
      double perSecondRate = waiting60MinFromDB / 3600.0;
      totalWaitingFare = waitingSeconds * perSecondRate;
      
      debugPrint('⏰ WAITING: ${waitingSeconds}s → +₹${totalWaitingFare.toStringAsFixed(2)}');
      
      _calculateCurrentFare();
      onStatusChange?.call();
    });
  }

  void _stopWaitingCharges() {
    if (waitingTimer != null) {
      debugPrint('🛑 STOPPING waiting charges');
      waitingTimer!.cancel();
      waitingTimer = null;
      debugPrint('   📊 Final waiting: ${waitingSeconds}s, ₹${totalWaitingFare.toStringAsFixed(2)}');
    }
  }

  void _calculateCurrentFare() {
    double baseFareComponent = 0.0;
    double extraDistanceFare = 0.0;
    
    if (distance <= 1.0) {
      baseFareComponent = distance * baseFareFromDB;
      extraDistanceFare = 0.0;
    } else {
      baseFareComponent = baseFareFromDB;
      double extraDistance = distance - 1.0;
      extraDistanceFare = extraDistance * perKmRateFromDB;
    }
    
    currentFare = baseFareComponent + extraDistanceFare + totalWaitingFare;
    
    // **Ensure minimum fare**
    if (currentFare < 1.0) {
      currentFare = 1.0;
    }
    
    debugPrint('💰 FARE: Base=₹${baseFareComponent.toStringAsFixed(2)}, Extra=₹${extraDistanceFare.toStringAsFixed(2)}, Waiting=₹${totalWaitingFare.toStringAsFixed(2)}, Total=₹${currentFare.toStringAsFixed(2)}');
  }

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

  String formatDistance() => distance.toStringAsFixed(2);
  
  String formatTime() {
    int minutes = secondsPassed ~/ 60;
    int seconds = secondsPassed % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String getMovementStatus() {
    if (!isMeterOn) return 'Ready to Start';
    if (isRidePaused) return 'Ride Paused';
    if (isVehicleMoving) return 'Moving';
    if (waitingTimer != null) return 'Waiting';
    if (secondsSinceLastMovement < stationaryDelaySeconds) {
      return 'Stationary (${stationaryDelaySeconds - secondsSinceLastMovement}s)';
    }
    return 'Stopped';
  }

  Color getStatusColor() {
    if (!isMeterOn) return Color(0xFF9CA3AF);
    if (isRidePaused) return Color(0xFFEF4444);
    if (isVehicleMoving) return Color(0xFF00B562);
    if (waitingTimer != null) return Color(0xFFD97706);
    if (secondsSinceLastMovement < stationaryDelaySeconds) return Color(0xFFF59E0B);
    return Color(0xFF6B7280);
  }
}
