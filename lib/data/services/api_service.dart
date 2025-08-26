import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/driver_model.dart';
import '../../core/constants/api_constants.dart';

class ApiService {
  Future<UserModel?> login(String phoneNumber) async {
    try {
      print('Attempting to connect to: ${ApiConstants.baseUrl}${ApiConstants.loginEndpoint}');
      
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.loginEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'phoneNumber': phoneNumber}),
      ).timeout(Duration(seconds: 10));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserModel.fromJson(data['user']);
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } on SocketException catch (e) {
      print('SocketException: $e');
      throw Exception('Cannot connect to server. Please check your network connection.');
    } on HttpException catch (e) {
      print('HttpException: $e');
      throw Exception('HTTP Error occurred');
    } on FormatException catch (e) {
      print('FormatException: $e');
      throw Exception('Invalid response format');
    } catch (e) {
      print('General Exception: $e');
      throw Exception('Login failed: Unable to connect to server');
    }
  }

  Future<bool> addDriver(String name, String phoneNumber) async {
    try {
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
      ).timeout(Duration(seconds: 10));

      return response.statusCode == 201;
    } catch (e) {
      throw Exception('Add driver failed: $e');
    }
  }

  Future<List<DriverModel>> getDrivers() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getDriversEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['drivers'] as List)
            .map((driver) => DriverModel.fromJson(driver))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Get drivers failed: $e');
    }
  }
}
