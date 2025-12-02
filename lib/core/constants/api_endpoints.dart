// lib/core/constants/api_endpoints.dart

const String baseUrl = "http://10.166.4.172:3000";
// const String baseUrl = "http://localhost:3000";

class ApiEndpoints {
  static const String register = "$baseUrl/auth/register";
  static const String login = "$baseUrl/auth/login";
  static const String verifyOtp = "$baseUrl/auth/verify-otp";
}
