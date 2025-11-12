import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/language.dart';
import '../../data/models/goal.dart';
import '../../data/models/referral_source.dart';

class ApiService {
  final String baseUrl = "http://localhost:3000"; // Ton backend NestJS

  /// 🔹 Récupère le token JWT stocké localement
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  /// 🔹 Construit les headers avec le token si disponible
  Future<Map<String, String>> _getHeaders({bool includeToken = true}) async {
    final headers = {"Content-Type": "application/json"};
    print('📤 Headers envoyés : $headers'); // ✅ AJOUTEZ CETTE LIGNE

    
    if (includeToken) {
      final token = await _getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    
    return headers;
  }

  /// 🔹 Récupère toutes les langues disponibles (PUBLIC - pas besoin de token)
  Future<List<Language>> fetchLanguages() async {
    final res = await http.get(
      Uri.parse('$baseUrl/languages/search'),
      headers: await _getHeaders(includeToken: true), // Public route
    );

    if (res.statusCode == 200) {
      final data = json.decode(res.body) as List;
      return data.map((e) => Language.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch languages: ${res.body}');
    }
  }

  /// 🔹 Récupère tous les objectifs (goals) - PUBLIC
  Future<List<Goal>> fetchGoals() async {
    final res = await http.get(
      Uri.parse('$baseUrl/goals'),
      headers: await _getHeaders(includeToken: true),
    );

    if (res.statusCode == 200) {
      final data = json.decode(res.body) as List;
      return data.map((e) => Goal.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch goals: ${res.body}');
    }
  }

  /// 🔹 Ajouter un objectif (admin) - PROTÉGÉ
  Future<bool> createGoal(String name, String description) async {
    final res = await http.post(
      Uri.parse('$baseUrl/goals/create'),
      headers: await _getHeaders(),
      body: json.encode({
        "name": name,
        "description": description,
      }),
    );

    return res.statusCode == 201;
  }

  /// 🔹 Mettre à jour un objectif (admin) - PROTÉGÉ
  Future<bool> updateGoal(String id, {String? name, String? description}) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/goals/$id'),
      headers: await _getHeaders(),
      body: json.encode({
        if (name != null) "name": name,
        if (description != null) "description": description,
      }),
    );

    return res.statusCode == 200;
  }

  /// 🔹 Supprimer un objectif (admin) - PROTÉGÉ
  Future<bool> deleteGoal(String id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/goals/delete/$id'),
      headers: await _getHeaders(),
    );
    return res.statusCode == 200;
  }

  /// 🔹 Récupère toutes les sources (referral sources) - PUBLIC
  Future<List<ReferralSource>> fetchReferralSources() async {
    final res = await http.get(
      Uri.parse('$baseUrl/referralsources'),
      headers: await _getHeaders(includeToken: true),
    );

    if (res.statusCode == 200) {
      final data = json.decode(res.body) as List;
      return data.map((e) => ReferralSource.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch referral sources: ${res.body}');
    }
  }

  /// 🔹 Ajouter une source (admin) - PROTÉGÉ
  Future<bool> createReferralSource(String name) async {
    final res = await http.post(
      Uri.parse('$baseUrl/referralsources/create'),
      headers: await _getHeaders(),
      body: json.encode({"name": name}),
    );

    return res.statusCode == 201;
  }

  /// 🔹 Mettre à jour une source (admin) - PROTÉGÉ
  Future<bool> updateReferralSource(String id, {String? name}) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/referralsources/$id'),
      headers: await _getHeaders(),
      body: json.encode({
        if (name != null) "name": name,
      }),
    );

    return res.statusCode == 200;
  }

  /// 🔹 Supprimer une source (admin) - PROTÉGÉ
  Future<bool> deleteReferralSource(String id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/referralsources/delete/$id'),
      headers: await _getHeaders(),
    );
    return res.statusCode == 200;
  }

  /// 🔹 Crée une préférence utilisateur - PROTÉGÉ
  Future<bool> createUserPreference(
  String userId,
  String languageId, {
  String? goalId,
  String? referralSourceId,
}) async {
  final res = await http.post(
    Uri.parse('$baseUrl/user-preferences/create'),
    headers: await _getHeaders(),
    body: json.encode({
      "userId": userId,
      "targetLanguageId": languageId,
      if (goalId != null) "goalId": goalId,
      if (referralSourceId != null) "referralSourceId": referralSourceId,
    }),
  );

  return res.statusCode == 201 || res.statusCode == 200;
}

  /// 🔹 Met à jour une préférence utilisateur - PROTÉGÉ
  Future<bool> updateUserPreference(
    String userId, {
    String? languageId,
    String? goalId,
    String? sourceId,
  }) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/user-preferences/update/$userId'),
      headers: await _getHeaders(),
      body: json.encode({
        if (languageId != null) "targetLanguageId": languageId,
        if (goalId != null) "goalId": goalId,
        if (sourceId != null) "referralSourceId": sourceId,
      }),
    );

    return res.statusCode == 200;
  }

  /// 🔹 Récupère la préférence d'un utilisateur - PROTÉGÉ
  Future<Map<String, dynamic>> getUserPreference(String userId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/user-preferences/$userId'),
      headers: await _getHeaders(),
    );

    if (res.statusCode == 200) {
      return json.decode(res.body);
    } else {
      throw Exception('Failed to fetch user preference: ${res.body}');
    }
  }
}