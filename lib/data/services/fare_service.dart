import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vaagaiauto/core/constants/api_constants.dart';


class FareService {
  static Future<Map<String, dynamic>> updateOrCreateFare({
    required String userId,
    required double baseFare,
    required double waiting5min,
    required double waiting10min,
    required double waiting15min,
    required double waiting20min,
    required double waiting25min,
    required double waiting30min,
  }) async {
    try {
      print('Sending fare data to server...');
      print('URL: ${ApiConstants.baseUrl}${ApiConstants.createFareEndpoint}');
      
      final requestBody = {
        'userId': userId,
        'baseFare': baseFare,
        'waiting5min': waiting5min,
        'waiting10min': waiting10min,
        'waiting15min': waiting15min,
        'waiting20min': waiting20min,
        'waiting25min': waiting25min,
        'waiting30min': waiting30min,
      };
      
      print('Request body: $requestBody');

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.createFareEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Fare saved successfully',
          'data': data['data']
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to save fare',
          'data': null
        };
      }
    } catch (e) {
      print('Network error: $e');
      return {
        'success': false,
        'message': 'Network error: Please check your internet connection',
        'data': null
      };
    }
  }

  static Future<Map<String, dynamic>> getFareByUserId(String userId) async {
    try {
      print('Fetching fare for userId: $userId');
      
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getFareEndpoint}/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Get fare response status: ${response.statusCode}');
      print('Get fare response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Fare retrieved successfully',
          'data': data['data']
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'No fare found for this user',
          'data': null
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch fare',
          'data': null
        };
      }
    } catch (e) {
      print('Network error in getFareByUserId: $e');
      return {
        'success': false,
        'message': 'Network error: Please check your internet connection',
        'data': null
      };
    }
  }

  // Test database connection
  static Future<Map<String, dynamic>> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/fares/debug/test'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Test connection response: ${response.body}');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body)
        };
      } else {
        return {
          'success': false,
          'message': 'Connection test failed'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection test error: $e'
      };
    }
  }
}
