import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vaagaiauto/core/constants/api_constants.dart';

class AdminService {
  static Future<Map<String, dynamic>> updateAdminProfile({
    required String name,
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final url = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.updateAdminProfileEndpoint}'
      );
      
      final body = jsonEncode({
        'name': name,
        'phoneNumber': phoneNumber,
        'password': password,
      });

      print('🔵 Updating admin profile at: $url');
      print('🔵 Request body: $body');

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: body,
      );

      print('🟢 Response status: ${response.statusCode}');
      print('🟢 Response headers: ${response.headers}');
      print('🟢 Response body: "${response.body}"');

      // Handle empty response body (like from 301 redirects)
      if (response.body.isEmpty) {
        return {
          'success': false,
          'message': 'Server returned empty response. Status: ${response.statusCode}',
        };
      }

      // Handle non-JSON responses
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        print('🔴 JSON decode error: $e');
        return {
          'success': false,
          'message': 'Invalid response format from server',
        };
      }

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData['data'] ?? responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Update failed (Status: ${response.statusCode})',
        };
      }
    } catch (e) {
      print('🔴 Error in updateAdminProfile: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> getAdminProfile() async {
    try {
      final url = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.getAdminProfileEndpoint}'
      );

      print('🔵 Getting admin profile from: $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('🟢 Response status: ${response.statusCode}');
      print('🟢 Response headers: ${response.headers}');
      print('🟢 Response body: "${response.body}"');

      // Handle empty response body
      if (response.body.isEmpty) {
        return {
          'success': false,
          'message': 'Server returned empty response. Status: ${response.statusCode}',
        };
      }

      // Handle non-JSON responses
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        print('🔴 JSON decode error: $e');
        return {
          'success': false,
          'message': 'Invalid response format from server',
        };
      }

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData['data'] ?? responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch profile (Status: ${response.statusCode})',
        };
      }
    } catch (e) {
      print('🔴 Error in getAdminProfile: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }
}
