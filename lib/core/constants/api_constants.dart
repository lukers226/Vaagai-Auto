class ApiConstants {
  static const String baseUrl = "https://vaagai-auto.onrender.com/api";
  static const String loginEndpoint = "/auth/login";
  static const String addDriverEndpoint = "/admin/add-driver";
  static const String getDriversEndpoint = "/admin/drivers";
  static const String healthEndpoint = "/";

  // Fare management endpoints
  static const String faresEndpoint = "/fares";
  static const String createFareEndpoint = "/fares";
  static const String getFareEndpoint = "/fares";
  static const String updateFareEndpoint = "/fares";
  static const String deleteFareEndpoint = "/fares";

  // Admin profile endpoints
  static const String getAdminProfileEndpoint = "/auth/admin";
  static const String updateAdminProfileEndpoint = "/auth/admin";
}
