class ApiConstants {
  // Replace "192.168.1.100" with YOUR computer's actual IP address
  static const String baseUrl = "https://vaagai-auto.onrender.com/api";
  static const String loginEndpoint = "/auth/login";
  static const String addDriverEndpoint = "/admin/add-driver";
  static const String getDriversEndpoint = "/admin/drivers";
  static const String healthEndpoint = "/";
  
  // NEW: Ride management endpoints (Note: these are appended directly to baseUrl)
  // Full endpoints will be: baseUrl + "/drivers/:userId/cancel-ride"
  // and baseUrl + "/drivers/:userId/complete-ride"
}
