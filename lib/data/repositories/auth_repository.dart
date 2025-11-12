// lib/data/repositories/auth_repository.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_endpoints.dart';
import '../models/user_model.dart';

/// Modèle de réponse pour la connexion
class AuthResponse {
  final String token;
  final UserModel user;

  AuthResponse({required this.token, required this.user});
}

class AuthRepository {
  /// Enregistrement utilisateur
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

  /// Connexion utilisateur
  Future<AuthResponse> loginUser(String email, String password) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.login),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final token = data['access_token'];
      final user = UserModel.fromJson(data['user']);
      return AuthResponse(token: token, user: user);
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  /// Vérification OTP
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
