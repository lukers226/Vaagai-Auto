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

class _StartRidePageState extends State<StartRidePage> {
  double distance = 0.0; // kilometers
  int secondsPassed = 0;
  double fare = 59.0; // initial fare for first 1km
  double waitingCharge = 0.0;
  int selectedWaitingTime = 0;
  List<int> waitingTimes = [0, 5, 10, 15, 20, 25, 30];
  Timer? meterTimer;
  Timer? locationTimer;
  bool isMeterOn = false; // Main meter toggle
  int waitingSeconds = 0;
  
  // GPS tracking variables
  Position? lastPosition;
  Position? currentPosition;
  bool isMoving = false;
  double totalDistanceTravelled = 0.0;
  
  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  // Calculate total fare - moved to a getter method
  double get totalFare => fare + waitingCharge;

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.location_off, color: Colors.white),
              SizedBox(width: 10),
              Text('Please enable location services'),
            ],
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.location_city_rounded, color: Colors.white),
                SizedBox(width: 10),
                Text('Location permission denied'),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }
  }

  void startMeter() {
    meterTimer?.cancel();
    locationTimer?.cancel();
    
    // Start the main timer for seconds counting
    meterTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!isMeterOn) return;
      
      setState(() {
        secondsPassed++;
        
        // Update waiting charge if not moving
        if (!isMoving) {
          waitingSeconds++;
          if (waitingSeconds >= 300) { // 5 minutes = 300 seconds
            updateWaitingCharge();
          }
        } else {
          // Reset waiting time when moving
          waitingSeconds = 0;
          waitingCharge = 0.0;
        }
      });
    });

    // Start location tracking timer (every 3 seconds for better accuracy)
    locationTimer = Timer.periodic(Duration(seconds: 3), (timer) async {
      if (!isMeterOn) return;
      await _updateLocation();
    });

    // Get initial position
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        lastPosition = position;
        currentPosition = position;
      });
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _updateLocation() async {
    try {
      Position newPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (lastPosition != null) {
        // Calculate distance between last and current position
        double distanceInMeters = Geolocator.distanceBetween(
          lastPosition!.latitude,
          lastPosition!.longitude,
          newPosition.latitude,
          newPosition.longitude,
        );

        // Check if vehicle is moving (minimum 5 meters movement)
        if (distanceInMeters > 5) {
          setState(() {
            isMoving = true;
            // Convert meters to kilometers and add to total distance
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
      }

      setState(() {
        currentPosition = newPosition;
      });

    } catch (e) {
      print('Error updating location: $e');
    }
  }

  void toggleMeter(bool enable) {
    setState(() {
      isMeterOn = enable;
      if (isMeterOn) {
        startMeter();
      } else {
        // Stop everything when meter is turned off
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
      fare = 59.0; // First 1km = ₹59
    } else {
      double extraDistance = distance - 1.0;
      fare = 59.0 + (extraDistance * 18.0); // After 1km = ₹18 per km
    }
  }

  void updateWaitingCharge() {
    int minutes = waitingSeconds ~/ 60;
    if (minutes >= 10) {
      waitingCharge = 20.0; // 10+ minutes = ₹20
    } else if (minutes >= 5) {
      waitingCharge = 10.0; // 5-9 minutes = ₹10
    } else {
      waitingCharge = 0.0; // Less than 5 minutes = ₹0
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
    return distance.toStringAsFixed(2);
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

  @override
  void dispose() {
    meterTimer?.cancel();
    locationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Vaagai Auto', style: GoogleFonts.poppins(color: Colors.black,fontWeight: FontWeight.bold),),
        centerTitle: false,
        backgroundColor: Colors.yellow,
        foregroundColor: Colors.grey[800],
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey[200],
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Driver: ${widget.user.name ?? "Driver"}',
              style: GoogleFonts.lato(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            
            SizedBox(height: 10),
            
            // Toggle Switch Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auto Meter',
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        isMeterOn ? getMovementStatus() : 'Tap to start',
                        style: TextStyle(
                          fontSize: 14,
                          color: isMeterOn 
                            ? (isMoving ? Colors.green[600] : Colors.orange[600])
                            : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  Switch.adaptive(
                    value: isMeterOn,
                    onChanged: toggleMeter,
                    activeColor: Colors.green[600],
                  ),
                ],
              ),
            ),

            SizedBox(height: 12),

            // Live Meter Display (only when meter is ON)
            if (isMeterOn) ...[
              Expanded(
                child: Column(
                  children: [
                    // Distance & Time Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildSimpleCard(
                            'Distance',
                            '${formatDistance()} km',
                            Icons.straighten,
                            Colors.blue[600]!,
                          ),
                        ),
                        SizedBox(width: 15),
                        Expanded(
                          child: _buildSimpleCard(
                            'Time',
                            formatTime(),
                            Icons.access_time,
                            Colors.purple[600]!,
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 12),
                    
                    // Fare & Waiting Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildSimpleCard(
                            'Fare',
                            '₹${fare.toStringAsFixed(2)}',
                            Icons.currency_rupee,
                            Colors.green[600]!,
                          ),
                        ),
                        SizedBox(width: 15),
                        Expanded(
                          child: _buildSimpleCard(
                            'Waiting',
                            '₹${waitingCharge.toStringAsFixed(2)}',
                            Icons.hourglass_bottom,
                            Colors.orange[600]!,
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 12),
                    
                    // Total Amount Card
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(12),
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
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 12),
                    
                    // Waiting Time Dropdown
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: DropdownButton<int>(
                        isExpanded: true,
                        value: selectedWaitingTime,
                        underline: SizedBox(),
                        hint: Text('Select waiting time'),
                        items: waitingTimes.map((int time) {
                          return DropdownMenuItem<int>(
                            value: time,
                            child: Text(
                              time == 0 ? 'Auto GPS' : '$time min',
                              style: TextStyle(
                                fontSize: 16,
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
                    ),
                    
                    SizedBox(height: 12),
                    
                    // End Ride Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          stopMeter();
                          _showTripSummary();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'End Ride',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // When meter is OFF - show placeholder
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.speed,
                          size: 60,
                          color: Colors.grey[400],
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Auto Meter Ready',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Enable the meter to start tracking',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
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
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Trip Summary',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSummaryRow('Distance', '${formatDistance()} km'),
              _buildSummaryRow('Duration', formatTime()),
              _buildSummaryRow('Base Fare', '₹${fare.toStringAsFixed(2)}'),
              if (waitingCharge > 0)
                _buildSummaryRow('Waiting Charge', '₹${waitingCharge.toStringAsFixed(2)}'),
              SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Amount',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '₹${totalFare.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (isMeterOn) {
                  startMeter();
                }
              },
              child: Text('Continue'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Trip completed! ₹${totalFare.toStringAsFixed(2)}'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
              ),
              child: Text(
                'Complete',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
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
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
