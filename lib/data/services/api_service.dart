import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/driver_model.dart';
import '../../core/constants/api_constants.dart';

class ApiService {
  static const Duration _timeout = Duration(seconds: 90); // Increased for Render cold starts
  static const int _maxRetries = 3;

  Future<UserModel?> login(String phoneNumber) async {
    debugPrint('Attempting to connect to: ${ApiConstants.baseUrl}${ApiConstants.loginEndpoint}');
    
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        debugPrint('Login attempt $attempt of $_maxRetries...');
        
        if (attempt > 1) {
          debugPrint('Retrying... (Server might be waking up)');
          await Future.delayed(Duration(seconds: 5));
        }
        
        final response = await http.post(
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.loginEndpoint}'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({'phoneNumber': phoneNumber}),
        ).timeout(_timeout);

        debugPrint('Response status: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return UserModel.fromJson(data['user']);
        } else {
          throw Exception('Server returned ${response.statusCode}');
        }
        
      } on TimeoutException {
        debugPrint('TimeoutException on attempt $attempt');
        if (attempt == _maxRetries) {
          throw Exception('Connection timeout. Server might be starting up, please try again in a moment.');
        }
        continue;
        
      } on SocketException {
        debugPrint('SocketException on attempt $attempt');
        if (attempt == _maxRetries) {
          throw Exception('Cannot connect to server. Please check your network connection.');
        }
        continue;
        
      } on HttpException {
        debugPrint('HttpException on attempt $attempt');
        if (attempt == _maxRetries) {
          throw Exception('HTTP Error occurred');
        }
        continue;
        
      } on FormatException {
        debugPrint('FormatException on attempt $attempt');
        throw Exception('Invalid response format');
        
      } catch (e) {
        debugPrint('General Exception on attempt $attempt: $e');
        if (attempt == _maxRetries) {
          throw Exception('Login failed: Unable to connect to server');
        }
        continue;
      }
    }
    
    throw Exception('Login failed after $_maxRetries attempts');
  }

  Future<bool> addDriver(String name, String phoneNumber) async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        if (attempt > 1) {
          await Future.delayed(Duration(seconds: 3));
        }
        
        final response = await http.post(
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.addDriverEndpoint}'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'name': name,
            'phoneNumber': phoneNumber,
          }),
        ).timeout(_timeout);

        return response.statusCode == 201;
        
      } on TimeoutException {
        if (attempt == _maxRetries) {
          throw Exception('Connection timeout. Please try again.');
        }
        continue;
      } catch (e) {
        if (attempt == _maxRetries) {
          throw Exception('Add driver failed: $e');
        }
        continue;
      }
    }
    return false;
  }

  Future<List<DriverModel>> getDrivers() async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        if (attempt > 1) {
          await Future.delayed(Duration(seconds: 3));
        }
        
        final response = await http.get(
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getDriversEndpoint}'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ).timeout(_timeout);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return (data['drivers'] as List)
              .map((driver) => DriverModel.fromJson(driver))
              .toList();
        }
        return [];
        
      } on TimeoutException {
        if (attempt == _maxRetries) {
          throw Exception('Connection timeout. Please try again.');
        }
        continue;
      } catch (e) {
        if (attempt == _maxRetries) {
          throw Exception('Get drivers failed: $e');
        }
        continue;
      }
    }
    return [];
  }

  // FIXED: Update cancelled rides count with correct route
  Future<bool> updateCancelledRides(String userId) async {
    debugPrint('Updating cancelled rides for user: $userId');
    
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        if (attempt > 1) {
          debugPrint('Retrying cancelled rides update... attempt $attempt');
          await Future.delayed(Duration(seconds: attempt * 2)); // Progressive delay
        }
        
        // FIXED: Use the correct API route that matches your backend
        final response = await http.patch(
          Uri.parse('${ApiConstants.baseUrl}/rides/$userId/cancel-ride'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'action': 'cancel',
            'timestamp': DateTime.now().toIso8601String(),
          }),
        ).timeout(_timeout);

        debugPrint('Cancel ride response status: ${response.statusCode}');
        debugPrint('Cancel ride response body: ${response.body}');

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          if (responseData['success'] == true) {
            debugPrint('Cancelled rides updated successfully');
            return true;
          } else {
            throw Exception('API returned success: false - ${responseData['error'] ?? 'Unknown error'}');
          }
        } else if (response.statusCode == 404) {
          // Handle 404 specifically - driver not found
          final errorData = jsonDecode(response.body);
          debugPrint('Driver not found: ${errorData['error']}');
          return false; // Return false instead of throwing exception
        } else {
          throw Exception('Server returned ${response.statusCode}');
        }
        
      } on TimeoutException {
        debugPrint('TimeoutException on cancelled rides update attempt $attempt');
        if (attempt == _maxRetries) {
          return false;
        }
        continue;
        
      } on SocketException {
        debugPrint('SocketException on cancelled rides update attempt $attempt');
        if (attempt == _maxRetries) {
          return false;
        }
        continue;
        
      } on FormatException {
        debugPrint('FormatException on cancelled rides update attempt $attempt');
        if (attempt == _maxRetries) {
          return false;
        }
        continue;
        
      } catch (e) {
        debugPrint('Error updating cancelled rides on attempt $attempt: $e');
        if (attempt == _maxRetries) {
          return false;
        }
        continue;
      }
    }
    
    return false;
  }

  // FIXED: Update completed rides and total earnings with correct route
  Future<bool> updateCompletedRide({
    required String userId,
    required double rideEarnings,
    required Map<String, dynamic> tripData,
  }) async {
    debugPrint('Updating completed ride for user: $userId with earnings: $rideEarnings');
    
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        if (attempt > 1) {
          debugPrint('Retrying completed ride update... attempt $attempt');
          await Future.delayed(Duration(seconds: attempt * 2)); // Progressive delay
        }
        
        // FIXED: Use the correct API route that matches your backend
        final response = await http.patch(
          Uri.parse('${ApiConstants.baseUrl}/rides/$userId/complete-ride'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'rideEarnings': rideEarnings,
            'tripData': tripData,
          }),
        ).timeout(_timeout);

        debugPrint('Complete ride response status: ${response.statusCode}');
        debugPrint('Complete ride response body: ${response.body}');

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          if (responseData['success'] == true) {
            debugPrint('Completed ride updated successfully');
            return true;
          } else {
            throw Exception('API returned success: false - ${responseData['error'] ?? 'Unknown error'}');
          }
        } else if (response.statusCode == 404) {
          // Handle 404 specifically - driver not found
          final errorData = jsonDecode(response.body);
          debugPrint('Driver not found: ${errorData['error']}');
          return false;
        } else {
          throw Exception('Server returned ${response.statusCode}');
        }
        
      } on TimeoutException {
        debugPrint('TimeoutException on completed ride update attempt $attempt');
        if (attempt == _maxRetries) {
          return false;
        }
        continue;
        
      } on SocketException {
        debugPrint('SocketException on completed ride update attempt $attempt');
        if (attempt == _maxRetries) {
          return false;
        }
        continue;
        
      } on FormatException {
        debugPrint('FormatException on completed ride update attempt $attempt');
        if (attempt == _maxRetries) {
          return false;
        }
        continue;
        
      } catch (e) {
        debugPrint('Error updating completed ride on attempt $attempt: $e');
        if (attempt == _maxRetries) {
          return false;
        }
        continue;
      }
    }
    
    return false;
  }

  // NEW: Get user statistics for profile page
  Future<Map<String, dynamic>?> getUserStats(String userId) async {
    debugPrint('Getting user stats for user: $userId');
    
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        if (attempt > 1) {
          debugPrint('Retrying get user stats... attempt $attempt');
          await Future.delayed(Duration(seconds: attempt * 2));
        }
        
        // Use the same endpoint as getDriverStats but with a different method name for clarity
        final response = await http.get(
          Uri.parse('${ApiConstants.baseUrl}/rides/$userId/stats'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ).timeout(_timeout);

        debugPrint('User stats response status: ${response.statusCode}');
        debugPrint('User stats response body: ${response.body}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            debugPrint('User stats loaded successfully: ${data['data']}');
            return data['data'];
          } else {
            throw Exception('API returned success: false - ${data['error'] ?? 'Unknown error'}');
          }
        } else if (response.statusCode == 404) {
          debugPrint('User not found');
          return null;
        } else {
          throw Exception('Server returned ${response.statusCode}');
        }
        
      } on TimeoutException {
        debugPrint('TimeoutException on get user stats attempt $attempt');
        if (attempt == _maxRetries) {
          return null;
        }
        continue;
        
      } on SocketException {
        debugPrint('SocketException on get user stats attempt $attempt');
        if (attempt == _maxRetries) {
          return null;
        }
        continue;
        
      } on FormatException {
        debugPrint('FormatException on get user stats attempt $attempt');
        if (attempt == _maxRetries) {
          return null;
        }
        continue;
        
      } catch (e) {
        debugPrint('Error getting user stats on attempt $attempt: $e');
        if (attempt == _maxRetries) {
          return null;
        }
        continue;
      }
    }
    
    return null;
  }

  // FIXED: Get updated driver stats with correct route
  Future<Map<String, dynamic>?> getDriverStats(String userId) async {
    debugPrint('Getting driver stats for user: $userId');
    
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        if (attempt > 1) {
          debugPrint('Retrying get driver stats... attempt $attempt');
          await Future.delayed(Duration(seconds: attempt * 2));
        }
        
        // FIXED: Use the correct API route that matches your backend
        final response = await http.get(
          Uri.parse('${ApiConstants.baseUrl}/rides/$userId/stats'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ).timeout(_timeout);

        debugPrint('Driver stats response status: ${response.statusCode}');
        debugPrint('Driver stats response body: ${response.body}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            return data['data'];
          } else {
            throw Exception('API returned success: false - ${data['error'] ?? 'Unknown error'}');
          }
        } else if (response.statusCode == 404) {
          debugPrint('Driver not found');
          return null;
        } else {
          throw Exception('Server returned ${response.statusCode}');
        }
        
      } on TimeoutException {
        debugPrint('TimeoutException on get driver stats attempt $attempt');
        if (attempt == _maxRetries) {
          return null;
        }
        continue;
        
      } on SocketException {
        debugPrint('SocketException on get driver stats attempt $attempt');
        if (attempt == _maxRetries) {
          return null;
        }
        continue;
        
      } on FormatException {
        debugPrint('FormatException on get driver stats attempt $attempt');
        if (attempt == _maxRetries) {
          return null;
        }
        continue;
        
      } catch (e) {
        debugPrint('Error getting driver stats on attempt $attempt: $e');
        if (attempt == _maxRetries) {
          return null;
        }
        continue;
      }
    }
    
    return null;
  }

  // Health check to wake up server
  Future<bool> healthCheck() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl.replaceAll('/api', '')}/'),
        headers: {'Accept': 'application/json'},
      ).timeout(Duration(seconds: 30));
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Health check failed: $e');
      return false;
    }
  }
}
