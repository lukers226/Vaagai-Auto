import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
            child: Icon(Icons.person, color: Colors.black, size: 24),
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
}
