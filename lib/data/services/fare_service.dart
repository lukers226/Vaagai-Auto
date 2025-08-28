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

  static Future<Map<String, dynamic>> updateOrCreateSystemFare({
    required double baseFare,
    required double waiting5min,
    required double waiting10min,
    required double waiting15min,
    required double waiting20min,
    required double waiting25min,
    required double waiting30min,
  }) async {
    try {
      _logInfo('Sending system fare data to server...');
      _logDebug('URL: ${ApiConstants.baseUrl}${ApiConstants.createFareEndpoint}');
      
      final requestBody = {
        'baseFare': baseFare,
        'waiting5min': waiting5min,
        'waiting10min': waiting10min,
        'waiting15min': waiting15min,
        'waiting20min': waiting20min,
        'waiting25min': waiting25min,
        'waiting30min': waiting30min,
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
        final data = jsonDecode(response.body);
        _logInfo('System fare retrieved successfully');
        return {
          'success': true,
          'message': data['message'] ?? 'System fare retrieved successfully',
          'data': data['data']
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
        _logInfo('Connection test successful');
        return {
          'success': true,
          'data': jsonDecode(response.body)
        };
      } else {
        _logError('Connection test failed - Status: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Connection test failed'
        };
      }
    } catch (e) {
      _logError('Connection test error', e);
      return {
        'success': false,
        'message': 'Connection test error: $e'
      };
    }
  }
}
