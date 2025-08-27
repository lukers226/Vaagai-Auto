import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';

class RideController {
  // Ride metrics
  double distance = 0.0;
  int secondsPassed = 0;
  double fare = 59.0;
  double waitingCharge = 0.0;
  int selectedWaitingTime = 0;
  List<int> waitingTimes = [0, 5, 10, 15, 20, 25, 30];
  
  // NEW: Trip timing
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
  static const double MOVEMENT_THRESHOLD = 3.0;
  static const int LOCATION_UPDATE_INTERVAL = 2;
  
  // Location permission and service status
  bool isLocationServiceEnabled = false;
  bool hasLocationPermission = false;

  // Callbacks
  VoidCallback? onLocationUpdate;
  VoidCallback? onStatusChange;
  Function(String, bool)? onShowSnackBar;

  double get totalFare => fare + waitingCharge;

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

  // Ride Control Methods
  Future<bool> startRide() async {
    bool hasPermission = await requestLocationPermission();
    if (!hasPermission) return false;

    isMeterOn = true;
    tripStartTime = DateTime.now(); // NEW: Record start time
    _startMeter();
    onStatusChange?.call();
    return true;
  }

  void stopRide() {
    isMeterOn = false;
    tripEndTime = DateTime.now(); // NEW: Record end time
    meterTimer?.cancel();
    locationTimer?.cancel();
    onStatusChange?.call();
  }

  void cancelRide() {
    meterTimer?.cancel();
    locationTimer?.cancel();
    gpsMonitorTimer?.cancel();
    
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
    fare = 59.0;
    waitingCharge = 0.0;
    waitingSeconds = 0;
    selectedWaitingTime = 0;
    isMoving = false;
    lastPosition = null;
    currentPosition = null;
    tripStartTime = null; // NEW: Reset start time
    tripEndTime = null; // NEW: Reset end time
    onStatusChange?.call();
  }

  void _startMeter() {
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
      
      onStatusChange?.call();
    });

    locationTimer = Timer.periodic(Duration(seconds: LOCATION_UPDATE_INTERVAL), (timer) async {
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

        if (distanceInMeters >= MOVEMENT_THRESHOLD && newPosition.accuracy <= 20) {
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

        if (distanceInMeters < MOVEMENT_THRESHOLD) {
          lastPosition = newPosition;
        }
      } else {
        lastPosition = newPosition;
      }

      currentPosition = newPosition;
      onLocationUpdate?.call();

    } catch (e) {
      print('Location update error: $e');
    }
  }

  // Fare Calculation
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

  void updateSelectedWaitingTime(int newValue) {
    selectedWaitingTime = newValue;
    if (newValue == 0) {
      waitingCharge = 0.0;
    } else {
      updateWaitingChargeFromDropdown();
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

  // NEW: Get formatted trip times
  String getTripStartTime() {
    if (tripStartTime == null) return '--:--';
    return '${tripStartTime!.hour.toString().padLeft(2, '0')}:${tripStartTime!.minute.toString().padLeft(2, '0')}';
  }

  String getTripEndTime() {
    if (tripEndTime == null) return '--:--';
    return '${tripEndTime!.hour.toString().padLeft(2, '0')}:${tripEndTime!.minute.toString().padLeft(2, '0')}';
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
