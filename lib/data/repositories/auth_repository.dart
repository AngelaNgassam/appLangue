// lib/data/repositories/auth_repository.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_endpoints.dart';
import '../models/user_model.dart';

class AuthRepository {
  Future<String?> registerUser(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.register),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['message'];
    } else {
      throw Exception('Failed to register: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.login),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'token': data['access_token'],
        'user': UserModel.fromJson(data['user']),
      };
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  Future<String?> verifyOtp(String email, String otp) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.verifyOtp),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': otp}),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['message'];
    } else {
      throw Exception('OTP verification failed: ${response.body}');
    }
  }
}
