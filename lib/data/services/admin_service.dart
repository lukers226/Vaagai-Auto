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

      print('Updating admin profile at: $url'); // Debug log
      print('Request body: $body'); // Debug log

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: body,
      );

      print('Response status: ${response.statusCode}'); // Debug log
      print('Response body: ${response.body}'); // Debug log

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData['data'] ?? responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Update failed',
        };
      }
    } catch (e) {
      print('Error in updateAdminProfile: $e'); // Debug log
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

      print('Getting admin profile from: $url'); // Debug log

      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
      });

      print('Response status: ${response.statusCode}'); // Debug log
      print('Response body: ${response.body}'); // Debug log

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData['data'] ?? responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch profile',
        };
      }
    } catch (e) {
      print('Error in getAdminProfile: $e'); // Debug log
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }
}
