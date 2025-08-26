import '../services/api_service.dart';
import '../models/user_model.dart';
import '../models/driver_model.dart';

class AuthRepository {
  final ApiService apiService;

  AuthRepository({required this.apiService});

  Future<UserModel?> login(String phoneNumber) async {
    return await apiService.login(phoneNumber);
  }

  Future<bool> addDriver(String name, String phoneNumber) async {
    return await apiService.addDriver(name, phoneNumber);
  }

  Future<List<DriverModel>> getDrivers() async {
    return await apiService.getDrivers();
  }
}
