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

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: body,
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Update failed',
        };
      }
    } catch (e) {
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

      final response = await http.get(url);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch profile',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }
}
