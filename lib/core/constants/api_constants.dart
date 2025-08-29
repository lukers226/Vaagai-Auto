class ApiConstants {
  // Replace "192.168.1.100" with YOUR computer's actual IP address
  static const String baseUrl = "https://vaagai-auto.onrender.com/api";
  static const String loginEndpoint = "/auth/login";
  static const String addDriverEndpoint = "/admin/add-driver";
  static const String getDriversEndpoint = "/admin/drivers";
  static const String healthEndpoint = "/";

  // NEW: Fare management endpoints
  static const String faresEndpoint = "/fares";
  static const String createFareEndpoint = "/fares";
  static const String getFareEndpoint = "/fares"; // GET /fares/:userId
  static const String updateFareEndpoint = "/fares"; // PUT /fares/:userId
  static const String deleteFareEndpoint = "/fares"; // DELETE /fares/:userId
  

  static const String getAdminProfileEndpoint = "/auth/admin";
  static const String updateAdminProfileEndpoint = "/auth/admin";
}
