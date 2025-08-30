import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:vaagaiauto/core/constants/api_constants.dart';

class AdminService {
  // Helper method for debug logging that only works in debug mode
  static void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint('AdminService: $message');
    }
  }

  // Cache busting helper
  static String _addCacheBuster(String url) {
    final random = Random().nextInt(999999);
    final separator = url.contains('?') ? '&' : '?';
    return '$url${separator}_cb=$random';
  }

  static Future<Map<String, dynamic>> updateAdminProfile({
    required String name,
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final baseUrl = '${ApiConstants.baseUrl}${ApiConstants.updateAdminProfileEndpoint}';
      final urlWithCacheBuster = _addCacheBuster(baseUrl);
      final url = Uri.parse(urlWithCacheBuster);
      
      final body = jsonEncode({
        'name': name,
        'phoneNumber': phoneNumber,
        'password': password,
      });

      _debugLog('🔵 Updating admin profile at: $url');
      _debugLog('🔵 Request body: $body');

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0',
        },
        body: body,
      );

      _debugLog('🟢 Response status: ${response.statusCode}');
      _debugLog('🟢 Response headers: ${response.headers}');
      _debugLog('🟢 Response body: "${response.body}"');

      if (response.body.isEmpty) {
        _debugLog('🔴 Empty response body received');
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
        _debugLog('🔴 JSON decode error: $e');
        return {
          'success': false,
          'message': 'Invalid response format from server',
        };
      }

      if (response.statusCode == 200) {
        _debugLog('✅ Admin profile updated successfully');
        return {
          'success': true,
          'data': responseData['data'] ?? responseData,
        };
      } else {
        _debugLog('❌ Update failed with status: ${response.statusCode}');
        return {
          'success': false,
          'message': responseData['message'] ?? 'Update failed (Status: ${response.statusCode})',
        };
      }
    } catch (e) {
      _debugLog('🔴 Error in updateAdminProfile: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> getAdminProfile() async {
    try {
      final baseUrl = '${ApiConstants.baseUrl}${ApiConstants.getAdminProfileEndpoint}';
      final urlWithCacheBuster = _addCacheBuster(baseUrl);
      final url = Uri.parse(urlWithCacheBuster);

      _debugLog('🔵 Getting admin profile from: $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0',
        },
      );

      _debugLog('🟢 Response status: ${response.statusCode}');
      _debugLog('🟢 Response headers: ${response.headers}');
      _debugLog('🟢 Response body: "${response.body}"');

      // Handle empty response body
      if (response.body.isEmpty) {
        _debugLog('🔴 Empty response body received');
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
        _debugLog('🔴 JSON decode error: $e');
        return {
          'success': false,
          'message': 'Invalid response format from server',
        };
      }

      if (response.statusCode == 200) {
        _debugLog('✅ Admin profile fetched successfully');
        return {
          'success': true,
          'data': responseData['data'] ?? responseData,
        };
      } else {
        _debugLog('❌ Failed to fetch profile with status: ${response.statusCode}');
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch profile (Status: ${response.statusCode})',
        };
      }
    } catch (e) {
      _debugLog('🔴 Error in getAdminProfile: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Test method to verify backend deployment
  static Future<Map<String, dynamic>> testBackend() async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/test');
      _debugLog('🔵 Testing backend at: $url');

      final response = await http.get(url);
      _debugLog('🟢 Test response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        _debugLog('✅ Backend test successful');
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        _debugLog('❌ Backend test failed with status: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Test failed with status: ${response.statusCode}',
        };
      }
    } catch (e) {
      _debugLog('🔴 Backend test error: $e');
      return {
        'success': false,
        'message': 'Test error: $e',
      };
    }
  }
}
