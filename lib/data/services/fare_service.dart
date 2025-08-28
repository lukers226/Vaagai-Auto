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
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.createFareEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userId': userId,
          'baseFare': baseFare,
          'waiting5min': waiting5min,
          'waiting10min': waiting10min,
          'waiting15min': waiting15min,
          'waiting20min': waiting20min,
          'waiting25min': waiting25min,
          'waiting30min': waiting30min,
        }),
      );

      final data = jsonDecode(response.body);
      
      return {
        'success': response.statusCode == 200 || response.statusCode == 201,
        'message': data['message'] ?? 'Unknown error',
        'data': data['data']
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'data': null
      };
    }
  }

  static Future<Map<String, dynamic>> getFareByUserId(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getFareEndpoint}/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Unknown error',
        'data': data['data']
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'data': null
      };
    }
  }

  static Future<Map<String, dynamic>> getAllFares({int page = 1, int limit = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.faresEndpoint}?page=$page&limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Unknown error',
        'data': data['data'],
        'pagination': data['pagination']
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'data': null
      };
    }
  }
}
