import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vaagaiauto/presentation/pages/ride_controller.dart';
import '../../data/models/user_model.dart';

class RideWidgets {
  final BuildContext context;

  RideWidgets(this.context);

  Widget buildHeader({
    required String title,
    required VoidCallback onBackPressed,
    bool showCancelRide = false,
    VoidCallback? onCancelRide,
  }) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.yellow,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              onPressed: onBackPressed,
              icon: Icon(Icons.arrow_back, color: Colors.black87, size: 24),
            ),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            if (showCancelRide && onCancelRide != null)
              InkWell(
                onTap: onCancelRide,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.close,
                        color: Colors.red[600],
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Cancel Ride',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.red[600],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(0xFF00B562).withValues(alpha: 0.1),
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

  Widget buildDriverCard({
    required UserModel user,
    required bool isOnline,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.04),
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
                colors: [Colors.yellow, Colors.yellow],
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
                  "${user.name ?? 'Driver'} Driver",
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.yellow.withValues(alpha: 0.1),
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
                  isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
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

  Widget buildLocationStatus({
    required bool isLocationServiceEnabled,
    required bool hasLocationPermission,
    Position? currentPosition,
  }) {
    bool isGpsReady = isLocationServiceEnabled && hasLocationPermission;
    
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isGpsReady ? Color(0xFFECFDF3) : Color(0xFFFEF2F2),
        border: Border.all(
          color: isGpsReady ? Color(0xFF00B562).withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isGpsReady ? Color(0xFF00B562).withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
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
                AnimatedDefaultTextStyle(
                  duration: Duration(milliseconds: 300),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isGpsReady ? Color(0xFF00B562) : Colors.red[600]!,
                  ),
                  child: Text(isGpsReady ? 'GPS Connected' : 'GPS Disconnected'),
                ),
                AnimatedDefaultTextStyle(
                  duration: Duration(milliseconds: 300),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600]!,
                  ),
                  child: Text(
                    isGpsReady ? 'Location tracking is active' : 'Location tracking unavailable',
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
                '±${currentPosition.accuracy.toStringAsFixed(0)}m',
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

  Widget buildStartRideUI({required VoidCallback onStartRide}) {
    return Column(
      children: [
        SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: onStartRide,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.yellow,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'START RIDE',
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
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

  Widget buildActiveRideUI({
    required RideController rideController,
    required Animation<double> pulseAnimation,
    required VoidCallback onEndRide,
    required Function(int) onWaitingTimeChanged,
  }) {
    return Column(
      children: [
        _buildStatusCard(rideController),
        SizedBox(height: 16),
        _buildFareDisplay(rideController, pulseAnimation),
        SizedBox(height: 16),
        _buildMetricsGrid(rideController),
        SizedBox(height: 16),
        _buildWaitingTimeSelector(rideController, onWaitingTimeChanged),
        SizedBox(height: 24),
        _buildEndRideButton(onEndRide),
      ],
    );
  }

  Widget _buildStatusCard(RideController controller) {
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
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: controller.getStatusColor(),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: controller.getStatusColor().withValues(alpha: 0.4),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          Text(
            controller.getMovementStatus(),
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: controller.getStatusColor(),
            ),
          ),
          Spacer(),
          Text(
            controller.formatTime(),
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFareDisplay(RideController controller, Animation<double> pulseAnimation) {
    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: controller.isMoving ? pulseAnimation.value : 1.0,
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
                  '₹${controller.totalFare.toStringAsFixed(2)}',
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

  Widget _buildMetricsGrid(RideController controller) {
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
              Expanded(child: _buildMetric('Distance', '${controller.formatDistance()} km', Icons.straighten)),
              SizedBox(width: 1, height: 40),
              Expanded(child: _buildMetric('Base Fare', '₹${controller.fare.toStringAsFixed(2)}', Icons.currency_rupee)),
            ],
          ),
          if (controller.waitingCharge > 0) ...[
            Divider(height: 24, color: Colors.grey[200]),
            Row(
              children: [
                Expanded(child: _buildMetric('Waiting', '₹${controller.waitingCharge.toStringAsFixed(2)}', Icons.access_time)),
                SizedBox(width: 1, height: 40),
                Expanded(child: _buildMetric('Total Time', controller.formatTime(), Icons.timer)),
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

  Widget _buildWaitingTimeSelector(RideController controller, Function(int) onChanged) {
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
            value: controller.selectedWaitingTime,
            underline: SizedBox(),
            icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
            items: controller.waitingTimes.map((int time) {
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
                onChanged(newValue);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEndRideButton(VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
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
    );
  }

  // FIXED: Scrollable trip summary dialog
  void showTripSummary({
    required BuildContext context,
    required String distance,
    required String duration,
    required double baseFare,
    required double waitingCharge,
    required double totalFare,
    required String driverName,
    required String tripStartTime,
    required String tripEndTime,
    required VoidCallback onContinue,
    required VoidCallback onComplete,
    required VoidCallback onShareCustomer,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: 400,
            ),
            child: SingleChildScrollView( // FIXED: Added scroll view
              child: Container(
                padding: EdgeInsets.all(20), // FIXED: Reduced padding
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
                    Text(
                      'Thank you for riding with us',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
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
                          _buildSummaryRow('Driver', driverName),
                          _buildSummaryRow('Start Time', tripStartTime),
                          _buildSummaryRow('End Time', tripEndTime),
                          _buildSummaryRow('Distance Travelled', '$distance km'),
                          _buildSummaryRow('Trip Duration', duration),
                          _buildSummaryRow('Base Fare', '₹${baseFare.toStringAsFixed(2)}'),
                          if (waitingCharge > 0)
                            _buildSummaryRow('Waiting Charges', '₹${waitingCharge.toStringAsFixed(2)}'),
                          Divider(height: 20),
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
                    SizedBox(height: 20),
                    // Share Customer Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: onShareCustomer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Share Bill Image',
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
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onContinue,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey[300]!),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: EdgeInsets.symmetric(vertical: 10), // FIXED: Reduced padding
                            ),
                            child: Text('Continue', style: TextStyle(color: Colors.grey[600])),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: onComplete,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF00B562),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: EdgeInsets.symmetric(vertical: 10), // FIXED: Reduced padding
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3), // FIXED: Reduced spacing
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]), // FIXED: Smaller font
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13, // FIXED: Smaller font
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
