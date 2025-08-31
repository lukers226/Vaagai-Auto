import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:vaagaiauto/core/constants/api_constants.dart';

class FareService {
  // Logging methods
  static void _logInfo(String message) {
    developer.log(message, name: 'FareService', level: 800);
  }

  static void _logError(String message, [Object? error]) {
    developer.log(message, name: 'FareService', level: 1000, error: error);
  }

  static void _logDebug(String message) {
    developer.log(message, name: 'FareService', level: 700);
  }

  /// Parse MongoDB Extended JSON format
  static dynamic _parseExtendedJson(dynamic value) {
    if (value is Map<String, dynamic>) {
      if (value.containsKey('\$numberInt')) {
        return int.parse(value['\$numberInt'].toString());
      } else if (value.containsKey('\$numberDouble')) {
        return double.parse(value['\$numberDouble'].toString());
      } else if (value.containsKey('\$oid')) {
        return value['\$oid'];
      } else if (value.containsKey('\$date')) {
        return value['\$date'];
      }
    }
    return value;
  }

  /// Create or update system-wide fare configuration
  static Future<Map<String, dynamic>> updateOrCreateSystemFare({
    required double baseFare,
    required double perKmRate,
    required double waiting60min,
  }) async {
    try {
      _logInfo('Sending system fare data to server...');
      _logDebug('URL: ${ApiConstants.baseUrl}${ApiConstants.createFareEndpoint}');
      
      final requestBody = {
        'baseFare': baseFare,
        'perKmRate': perKmRate,
        'waiting60min': waiting60min,
      };
      
      _logDebug('Request body: $requestBody');

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.createFareEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      _logInfo('Response status: ${response.statusCode}');
      _logDebug('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _logInfo('System fare saved successfully');
        return {
          'success': true,
          'message': data['message'] ?? 'System fare saved successfully',
          'data': data['data']
        };
      } else {
        final errorData = jsonDecode(response.body);
        _logError('Failed to save system fare - Status: ${response.statusCode}');
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to save system fare',
          'data': null
        };
      }
    } catch (e) {
      _logError('Network error in updateOrCreateSystemFare', e);
      return {
        'success': false,
        'message': 'Network error: Please check your internet connection',
        'data': null
      };
    }
  }

  /// Get current system fare configuration
  static Future<Map<String, dynamic>> getSystemFare() async {
    try {
      _logInfo('Fetching system fare...');
      
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getFareEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      _logInfo('Get system fare response status: ${response.statusCode}');
      _logDebug('Get system fare response body: ${response.body}');

      if (response.statusCode == 200) {
        final rawData = jsonDecode(response.body);
        final fareData = rawData['data'] as Map<String, dynamic>;
        
        // Parse Extended JSON values
        final parsedData = <String, dynamic>{};
        fareData.forEach((key, value) {
          parsedData[key] = _parseExtendedJson(value);
        });
        
        _logInfo('System fare retrieved successfully');
        return {
          'success': true,
          'message': rawData['message'] ?? 'System fare retrieved successfully',
          'data': parsedData
        };
      } else if (response.statusCode == 404) {
        _logInfo('No system fare configuration found');
        return {
          'success': false,
          'message': 'No system fare configuration found',
          'data': null
        };
      } else {
        final errorData = jsonDecode(response.body);
        _logError('Failed to fetch system fare - Status: ${response.statusCode}');
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch system fare',
          'data': null
        };
      }
    } catch (e) {
      _logError('Network error in getSystemFare', e);
      return {
        'success': false,
        'message': 'Network error: Please check your internet connection',
        'data': null
      };
    }
  }

  /// Calculate fare based on distance and waiting time
  static Future<Map<String, dynamic>> calculateFare({
    required double distance,
    int waitingMinutes = 0,
  }) async {
    try {
      _logInfo('Calculating fare for distance: ${distance}km, waiting: ${waitingMinutes} minutes');
      
      final requestBody = {
        'distance': distance,
        'waitingMinutes': waitingMinutes,
      };
      
      _logDebug('Calculate fare request body: $requestBody');

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/fares/calculate'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      _logInfo('Calculate fare response status: ${response.statusCode}');
      _logDebug('Calculate fare response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logInfo('Fare calculated successfully');
        return {
          'success': true,
          'message': data['message'] ?? 'Fare calculated successfully',
          'data': data['data']
        };
      } else {
        final errorData = jsonDecode(response.body);
        _logError('Failed to calculate fare - Status: ${response.statusCode}');
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to calculate fare',
          'data': null
        };
      }
    } catch (e) {
      _logError('Network error in calculateFare', e);
      return {
        'success': false,
        'message': 'Network error: Please check your internet connection',
        'data': null
      };
    }
  }

  /// Initialize fare collection with default values (one-time setup)
  static Future<Map<String, dynamic>> initializeFareCollection() async {
    try {
      _logInfo('Initializing fare collection...');
      
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/fares/initialize'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      _logInfo('Initialize collection response status: ${response.statusCode}');
      _logDebug('Initialize collection response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _logInfo('Fare collection initialized successfully');
        return {
          'success': true,
          'message': data['message'] ?? 'Fare collection initialized successfully',
          'data': data['data']
        };
      } else {
        final errorData = jsonDecode(response.body);
        _logError('Failed to initialize fare collection - Status: ${response.statusCode}');
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to initialize fare collection',
          'data': null
        };
      }
    } catch (e) {
      _logError('Network error in initializeFareCollection', e);
      return {
        'success': false,
        'message': 'Network error: Please check your internet connection',
        'data': null
      };
    }
  }

  /// Test API connection and database status
  static Future<Map<String, dynamic>> testConnection() async {
    try {
      _logInfo('Testing API connection...');
      
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/fares/debug/test'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      _logDebug('Test connection response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logInfo('Connection test successful');
        return {
          'success': true,
          'message': 'Connection test successful',
          'data': data
        };
      } else {
        _logError('Connection test failed - Status: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Connection test failed',
          'data': null
        };
      }
    } catch (e) {
      _logError('Connection test error', e);
      return {
        'success': false,
        'message': 'Connection test error: $e',
        'data': null
      };
    }
  }

  /// Validate fare data before sending to server
  static Map<String, dynamic> validateFareData({
    required double baseFare,
    required double perKmRate,
    required double waiting60min,
  }) {
    try {
      // Validate base fare
      if (baseFare <= 0) {
        return {
          'valid': false,
          'message': 'Base fare must be greater than 0'
        };
      }
      
      if (baseFare > 5000) {
        return {
          'valid': false,
          'message': 'Base fare cannot exceed ₹5000'
        };
      }

      // Validate per km rate
      if (perKmRate <= 0) {
        return {
          'valid': false,
          'message': 'Per kilometer rate must be greater than 0'
        };
      }
      
      if (perKmRate > 1000) {
        return {
          'valid': false,
          'message': 'Per kilometer rate cannot exceed ₹1000'
        };
      }

      // Validate waiting charge
      if (waiting60min < 0) {
        return {
          'valid': false,
          'message': '60 minute waiting charge cannot be negative'
        };
      }
      
      if (waiting60min > 1000) {
        return {
          'valid': false,
          'message': '60 minute waiting charge cannot exceed ₹1000'
        };
      }

      return {
        'valid': true,
        'message': 'All fare data is valid'
      };
      
    } catch (e) {
      return {
        'valid': false,
        'message': 'Error validating fare data: $e'
      };
    }
  }

  /// Get fare breakdown for display purposes
  static Map<String, dynamic> getFareBreakdown({
    required double baseFare,
    required double perKmRate,
    required double distance,
    required int waitingMinutes,
    required double waiting60min,
  }) {
    try {
      // Calculate distance fare
      final distanceFare = distance * perKmRate;
      
      // Calculate waiting charge - apply waiting60min rate for any waiting time
      double waitingCharge = 0.0;
      if (waitingMinutes > 0) {
        // Apply proportional waiting charge based on 60-minute rate
        waitingCharge = (waitingMinutes / 60.0) * waiting60min;
      }

      final totalFare = baseFare + distanceFare + waitingCharge;

      return {
        'baseFare': baseFare,
        'distance': distance,
        'perKmRate': perKmRate,
        'distanceFare': double.parse(distanceFare.toStringAsFixed(2)),
        'waitingMinutes': waitingMinutes,
        'waitingCharge': double.parse(waitingCharge.toStringAsFixed(2)),
        'totalFare': double.parse(totalFare.toStringAsFixed(2)),
        'breakdown': {
          'baseFare': '₹${baseFare.toStringAsFixed(0)}',
          'distanceFare': '₹${distanceFare.toStringAsFixed(2)} (${distance}km × ₹${perKmRate}/km)',
          'waitingCharge': '₹${waitingCharge.toStringAsFixed(2)} ($waitingMinutes minutes)',
          'total': '₹${totalFare.toStringAsFixed(2)}'
        }
      };
    } catch (e) {
      _logError('Error calculating fare breakdown', e);
      return {
        'error': 'Error calculating fare breakdown: $e'
      };
    }
  }
}
