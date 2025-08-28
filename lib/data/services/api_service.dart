import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/driver_model.dart';
import '../../core/constants/api_constants.dart';

class ApiService {
  static const Duration _timeout = Duration(seconds: 90);
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

  // FIXED: Get fare data with proper MongoDB Extended JSON parsing
  Future<Map<String, dynamic>> getFareData() async {
    debugPrint('Getting fare data from database...');
    
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        if (attempt > 1) {
          debugPrint('Retrying get fare data... attempt $attempt');
          await Future.delayed(Duration(seconds: attempt * 2));
        }
        
        // FIXED: Use the correct endpoint from your backend
        final response = await http.get(
          Uri.parse('${ApiConstants.baseUrl}/fares'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ).timeout(_timeout);

        debugPrint('Fare data response status: ${response.statusCode}');
        debugPrint('Fare data response body: ${response.body}');

        if (response.statusCode == 200) {
          final rawData = jsonDecode(response.body);
          debugPrint('Raw fare data received: $rawData');
          
          // Extract the actual fare data from response
          Map<String, dynamic> fareDataFromDB;
          
          if (rawData is Map<String, dynamic>) {
            // Handle your backend response format {"success": true, "data": {...}}
            if (rawData.containsKey('data') && rawData['data'] is Map<String, dynamic>) {
              fareDataFromDB = rawData['data'];
            } else if (rawData.containsKey('success')) {
              // Remove success field and use the rest
              fareDataFromDB = Map.from(rawData);
              fareDataFromDB.remove('success');
              fareDataFromDB.remove('message');
            } else {
              // Use the data as-is
              fareDataFromDB = rawData;
            }
          } else {
            throw Exception('Invalid fare data structure received');
          }
          
          // FIXED: Parse MongoDB Extended JSON format correctly
          Map<String, dynamic> parsedFareData = _parseMongoExtendedJson(fareDataFromDB);
          
          debugPrint('Parsed fare data: $parsedFareData');
          return parsedFareData;
          
        } else if (response.statusCode == 404) {
          debugPrint('Fare settings not found in database');
          throw Exception('Fare settings not configured in database');
        } else {
          throw Exception('Server returned ${response.statusCode}');
        }
        
      } on TimeoutException {
        debugPrint('TimeoutException on get fare data attempt $attempt');
        if (attempt == _maxRetries) {
          throw Exception('Connection timeout while loading fare data');
        }
        continue;
        
      } on SocketException {
        debugPrint('SocketException on get fare data attempt $attempt');
        if (attempt == _maxRetries) {
          throw Exception('Network error while loading fare data');
        }
        continue;
        
      } on FormatException {
        debugPrint('FormatException on get fare data attempt $attempt');
        if (attempt == _maxRetries) {
          throw Exception('Invalid fare data format received from server');
        }
        continue;
        
      } catch (e) {
        debugPrint('Error getting fare data on attempt $attempt: $e');
        if (attempt == _maxRetries) {
          throw Exception('Failed to load fare data: $e');
        }
        continue;
      }
    }
    
    throw Exception('Failed to load fare data after $_maxRetries attempts');
  }

  // ENHANCED: Parse MongoDB Extended JSON format with better error handling
  Map<String, dynamic> _parseMongoExtendedJson(Map<String, dynamic> rawData) {
    Map<String, dynamic> parsedData = {};
    
    rawData.forEach((key, value) {
      try {
        parsedData[key] = _extractValue(value);
      } catch (e) {
        debugPrint('Error parsing field $key: $e');
        // Keep original value if parsing fails
        parsedData[key] = value;
      }
    });
    
    return parsedData;
  }

  // ENHANCED: Helper method to extract values from MongoDB Extended JSON
  dynamic _extractValue(dynamic value) {
    if (value is Map<String, dynamic>) {
      // Handle MongoDB Extended JSON types
      if (value.containsKey('\$numberInt')) {
        final stringValue = value['\$numberInt'].toString();
        return int.tryParse(stringValue) ?? 0;
      }
      if (value.containsKey('\$numberLong')) {
        final stringValue = value['\$numberLong'].toString();
        return int.tryParse(stringValue) ?? 0;
      }
      if (value.containsKey('\$numberDouble')) {
        final stringValue = value['\$numberDouble'].toString();
        return double.tryParse(stringValue) ?? 0.0;
      }
      if (value.containsKey('\$oid')) {
        return value['\$oid'].toString();
      }
      if (value.containsKey('\$date')) {
        if (value['\$date'] is Map && value['\$date'].containsKey('\$numberLong')) {
          final timestamp = int.tryParse(value['\$date']['\$numberLong'].toString()) ?? 0;
          return DateTime.fromMillisecondsSinceEpoch(timestamp);
        }
        return value['\$date'];
      }
      
      // If it's a nested object, parse recursively
      Map<String, dynamic> nestedParsed = {};
      value.forEach((nestedKey, nestedValue) {
        nestedParsed[nestedKey] = _extractValue(nestedValue);
      });
      return nestedParsed;
    }
    
    // Return as-is for other types
    return value;
  }

  // Rest of your methods remain the same...
  
  Future<bool> updateCancelledRides(String userId) async {
    debugPrint('Updating cancelled rides for user: $userId');
    
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        if (attempt > 1) {
          debugPrint('Retrying cancelled rides update... attempt $attempt');
          await Future.delayed(Duration(seconds: attempt * 2));
        }
        
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
          final errorData = jsonDecode(response.body);
          debugPrint('Driver not found: ${errorData['error']}');
          return false;
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
          await Future.delayed(Duration(seconds: attempt * 2));
        }
        
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

  Future<Map<String, dynamic>?> getUserStats(String userId) async {
    debugPrint('Getting user stats for user: $userId');
    
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        if (attempt > 1) {
          debugPrint('Retrying get user stats... attempt $attempt');
          await Future.delayed(Duration(seconds: attempt * 2));
        }
        
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

  Future<Map<String, dynamic>?> getDriverStats(String userId) async {
    debugPrint('Getting driver stats for user: $userId');
    
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        if (attempt > 1) {
          debugPrint('Retrying get driver stats... attempt $attempt');
          await Future.delayed(Duration(seconds: attempt * 2));
        }
        
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
