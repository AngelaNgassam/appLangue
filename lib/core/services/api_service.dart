import 'dart:convert';
import 'package:KmerLingo/data/models/goal.dart';
import 'package:KmerLingo/data/models/language.dart';
import 'package:KmerLingo/data/models/notification.dart';
import 'package:KmerLingo/data/models/question.dart';
import 'package:KmerLingo/data/models/referral_source.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // final String baseUrl = "http://192.168.1.212:3000"; // Backend NestJS    
  final String baseUrl = "http://10.166.4.172:3000"; // Backend NestJS
  // final String baseUrl = "http://localhost:3000"; // Backend NestJS

  /// 🔹 Récupère le token JWT stocké localement
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    print('💎 Token récupéré: $token');
    return token;
  }
/*************  ✨ Windsurf Command ⭐  *************/
/*******  ca9d1f9c-a91b-4b63-a54d-bf77bf0ee462  *******/
  Future<Map<String, dynamic>> followUser(String userId) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/follow/$userId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      print('✅ Follow User Response: ${response.statusCode}');
      print('📦 Body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur lors du suivi: ${response.body}');
      }
    } catch (e) {
      print('❌ Erreur followUser: $e');
      throw Exception('Impossible de suivre cet utilisateur');
    }
  }
  /// 👥 Ne plus suivre un utilisateur
  Future<Map<String, dynamic>> unfollowUser(String userId) async {
    try {
      final token = await _getToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/follow/$userId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      print('✅ Unfollow User Response: ${response.statusCode}');
      print('📦 Body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur lors du unfollow: ${response.body}');
      }
    } catch (e) {
      print('❌ Erreur unfollowUser: $e');
      throw Exception('Impossible de ne plus suivre cet utilisateur');
    }
  }

  /// 📋 Récupérer tous les utilisateurs (avec pagination)
  Future<Map<String, dynamic>> getAllUsers({int page = 1, int limit = 20}) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/follow/users/all?page=$page&limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      print('✅ Get All Users Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur lors de la récupération des utilisateurs');
      }
    } catch (e) {
      print('❌ Erreur getAllUsers: $e');
      throw Exception('Impossible de récupérer la liste des utilisateurs');
    }
  }

  /// 🔍 Rechercher des utilisateurs par email, prénom ou nom
  Future<List<dynamic>> searchUsers(String query) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/follow/users/search?q=$query'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      print('✅ Search Users Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur lors de la recherche');
      }
    } catch (e) {
      print('❌ Erreur searchUsers: $e');
      throw Exception('Impossible de rechercher des utilisateurs');
    }
  }

  /// 👤 Récupérer mes followers (qui me suit)
  Future<List<dynamic>> getMyFollowers() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/follow/followers'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      print('✅ Get My Followers Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur lors de la récupération des followers');
      }
    } catch (e) {
      print('❌ Erreur getMyFollowers: $e');
      throw Exception('Impossible de récupérer vos followers');
    }
  }

  /// 👤 Récupérer mes abonnements (que je suis)
  Future<List<dynamic>> getMyFollowing() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/follow/following'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      print('✅ Get My Following Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur lors de la récupération des abonnements');
      }
    } catch (e) {
      print('❌ Erreur getMyFollowing: $e');
      throw Exception('Impossible de récupérer vos abonnements');
    }
  }

  /// 👤 Récupérer les followers d'un utilisateur spécifique
  Future<List<dynamic>> getUserFollowers(String userId) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/follow/$userId/followers'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      print('✅ Get User Followers Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur lors de la récupération des followers');
      }
    } catch (e) {
      print('❌ Erreur getUserFollowers: $e');
      throw Exception('Impossible de récupérer les followers');
    }
  }

  /// 👤 Récupérer les abonnements d'un utilisateur spécifique
  Future<List<dynamic>> getUserFollowing(String userId) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/follow/$userId/following'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      print('✅ Get User Following Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur lors de la récupération des abonnements');
      }
    } catch (e) {
      print('❌ Erreur getUserFollowing: $e');
      throw Exception('Impossible de récupérer les abonnements');
    }
  }

  // ============================================
  // 📊 STREAK (si tu en as besoin)
  // ============================================

  /// 🔹 Récupère la langue de l'utilisateur stockée localement
  Future<String?> _getUserLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('user_language');
    print('🌐 Langue récupérée: $lang');
    return lang;
  }
    /// 🔹 Récupère le currentStreak et maxStreak de l'utilisateur
  Future<Map<String, dynamic>> getUserStreak(String userId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception("JWT token introuvable");
    }

    final url = Uri.parse('$baseUrl/question/streak/me');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('🔥 Streak récupéré: $data');
        return {
          'currentStreak': data['current'] ?? 0,
          'maxStreak': data['max'] ?? 0,
          'lastActivityAt': data['lastActivityAt'] ?? null,
        };
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Erreur lors de la récupération du streak: $e');
      rethrow;
    }
  }


  /// 🔹 Met à jour la langue de l'utilisateur
  Future<void> setUserLanguage(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_language', langCode);
    print('✅ Langue stockée: $langCode');
  }

  /// 🔹 Construit les headers avec le token et la langue
  Future<Map<String, String>> _getHeaders({bool includeToken = true}) async {
    final headers = {"Content-Type": "application/json"};

    // Ajouter la langue
    final userLanguage = await _getUserLanguage();
    if (userLanguage != null) {
      headers['Accept-Language'] = userLanguage;
    } else {
      print("⚠️ Langue introuvable, 'Accept-Language' non ajouté.");
    }

    // Ajouter le token
    final token = includeToken ? await _getToken() : null;
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    } else if (includeToken) {
      print("⚠️ Aucun token trouvé.");
    }

    print('📤 Headers envoyés: $headers');
    return headers;
  }

// Exemple de getter pour récupérer la langue choisie par l'utilisateur

 Future<List<Question>> getQuestionsByLesson(String lessonId) async {
  final url = Uri.parse('$baseUrl/question/lesson/$lessonId');

  // Envoi du token dans les headers pour que le backend récupère la langue
  final response = await http.get(url, headers: await _getHeaders());

  if (response.statusCode == 200) {
    final List data = json.decode(response.body);
    return data.map((json) => Question.fromJson(json)).toList();
  } else if (response.statusCode == 400) {
    // Cas où la langue de l'utilisateur est introuvable
    throw Exception('La langue de l’utilisateur est introuvable');
  } else {
    throw Exception(
        'Erreur lors de la récupération des questions: ${response.body}');
  }
}


  /// 🔹 Récupérer une question par son ID
  Future<Question> getQuestionById(String questionId) async {
    final url = Uri.parse('$baseUrl/question/$questionId');
    final response = await http.get(url, headers: await _getHeaders());

    if (response.statusCode == 200) {
      return Question.fromJson(json.decode(response.body));
    } else {
      throw Exception('Erreur lors de la récupération de la question: ${response.body}');
    }
  }

  /// 🔹 Vérifier la réponse de l'utilisateur
Future<Map<String, dynamic>> checkAnswer(String questionId, String userAnswer) async {
  final url = Uri.parse('$baseUrl/question/$questionId/check');

  print('🔍 Vérification de la réponse pour la question $questionId avec la réponse: "$userAnswer"');

  final headers = await _getHeaders();

  try {
    final response = await http.post(
      url,
      headers: {
        ...headers,
        'Content-Type': 'application/json',
      },
      body: json.encode({"answer": userAnswer}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> data = json.decode(response.body);

      print('✅ Résultat du backend: $data');

      // ---------------- CORRECT ANSWERS ----------------
      if (data['correctAnswers'] != null && data['correctAnswers'] is List) {
        data['correctAnswers'] =
            List<String>.from(data['correctAnswers'].map((e) => e.toString()));
      } else {
        data['correctAnswers'] = [];
      }

      // ---------------- SAFE VALUES ----------------
      data['isCorrect'] = data['isCorrect'] ?? false;
      data['pointsAdded'] = data['pointsAdded'] ?? 0;
      data['totalLessonPoints'] = data['totalLessonPoints'] ?? 0;

      // ---------------- streak retourné par backend ----------------
      data['currentStreak'] = data['currentStreak'] ?? 0;
      data['maxStreak'] = data['maxStreak'] ?? 0;

      return data;
    } else {
      throw Exception('Erreur ${response.statusCode}: ${response.body}');
    }
  } catch (e) {
    print('❌ Erreur lors de la vérification: $e');
    rethrow;
  }
}

  Future<List<AppNotification>> fetchNotifications(String userId) async {
    final url = Uri.parse('$baseUrl/notifications/$userId');
    final response = await http.get(url, headers: await _getHeaders());

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => AppNotification.fromJson(json)).toList();
    } else {
      throw Exception('Erreur lors de la récupération des notifications: ${response.body}');
    }
  }

  /// 🔹 Marquer une notification comme lue
 Future<void> markNotificationAsRead(String notificationId) async {
  final url = Uri.parse('$baseUrl/notifications/read/$notificationId');
  final response = await http.patch(url, headers: await _getHeaders());

  if (response.statusCode != 200) {
    throw Exception('Erreur lors de la mise à jour de la notification: ${response.body}');
  }
}

Future<void> submitFeedback({
  required String userId,
  required int rating,
  String? comment,
}) async {
  final url = Uri.parse('$baseUrl/feedback'); // ✅ juste /feedback

  final response = await http.post(
    url,
    headers: await _getHeaders(),
    body: json.encode({
      'userId': userId, // ✅ userId dans le body
      'rating': rating,
      'comment': comment,
    }),
  );

  if (response.statusCode == 200 || response.statusCode == 201) {
    print("Feedback envoyé avec succès !");
  } else {
    throw Exception('Erreur lors de l’envoi du feedback: ${response.body}');
  }
}



  Future<List<dynamic>> fetchAllRankingsInDivision(String divisionId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/rankings/division/$divisionId'),
      headers: await _getHeaders(),
    );

    if (res.statusCode == 200) {
      return json.decode(res.body);
    } else {
      throw Exception('Failed to fetch division rankings: ${res.body}');
    }
  }

  /// 🔹 Change le mot de passe de l'utilisateur
  Future<String> changePassword({
    required String userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    final url = Uri.parse('$baseUrl/profile/change-password/$userId');

    final response = await http.patch(
      url,
      headers: await _getHeaders(),
      body: json.encode({
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode == 200) {
      return "Mot de passe changé avec succès"; // retourne un message String
    } else {
      throw Exception('Échec du changement : ${response.body}');
    }
  }

  /// 🔹 Récupère le profil d’un utilisateur
  Future<Map<String, dynamic>> getProfile(String userId) async {
    final url = Uri.parse('$baseUrl/profile/$userId');

    final response = await http.get(url, headers: await _getHeaders());

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to load profile: ${response.body}");
    }
  }

  // Récupère le ranking de la division pour un utilisateur spécifique
  Future<List<dynamic>> fetchDivisionRankingByUser(String userId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/rankings/division/user/$userId'),
      headers: await _getHeaders(),
    );

    if (res.statusCode == 200) {
      return json.decode(res.body);
    } else {
      throw Exception('Failed to fetch division ranking by user: ${res.body}');
    }
  }

  /// 🔹 Récupère toutes les statistiques d’un utilisateur
  Future<Map<String, dynamic>> fetchUserStats(String userId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/stats/$userId'),
      headers: await _getHeaders(),
    );

    if (res.statusCode == 200) {
      return json.decode(res.body);
    } else {
      throw Exception('Failed to fetch user stats: ${res.body}');
    }
  }

  // Récupère le ranking exact d'un utilisateur
  Future<dynamic> fetchUserRanking(String userId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/rankings/user/$userId'),
      headers: await _getHeaders(),
    );

    if (res.statusCode == 200) {
      return json.decode(res.body);
    } else {
      throw Exception('Failed to fetch user ranking: ${res.body}');
    }
  }

  Future<List<dynamic>> fetchModules() async {
    final res = await http.get(
      Uri.parse('$baseUrl/modules'),
      headers: await _getHeaders(),
    );
    if (res.statusCode == 200) {
      return json.decode(res.body); // contient chapters
    } else {
      throw Exception('Failed to fetch modules: ${res.body}');
    }
  }

  Future<List<dynamic>> fetchDivisionRanking(String userId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/rankings/division/user/$userId'),
      headers: await _getHeaders(),
    );

    if (res.statusCode == 200) {
      return json.decode(res.body);
    } else {
      throw Exception('Failed to fetch division ranking: ${res.body}');
    }
  }

  Future<List<dynamic>> fetchChapters(String moduleId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/chapters/module/$moduleId'),
      headers: await _getHeaders(),
    );
    if (res.statusCode == 200) {
      return json.decode(res.body); // contient lessons
    } else {
      throw Exception('Failed to fetch chapters: ${res.body}');
    }
  }

Future<List<dynamic>> fetchLessons(String chapterId) async {
  final token = await _getToken();

  if (token == null) {
    throw Exception("No JWT token found. User not authenticated.");
  }

  final url = Uri.parse('$baseUrl/lessons/chapter/$chapterId');

  final res = await http.get(
    url,
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
  );

  print('📡 [GET] $url');
  print('📨 Status: ${res.statusCode}');
  print('📄 Body: ${res.body}');

  if (res.statusCode == 200) {
    return json.decode(res.body);
  } else {
    throw Exception('❌ Failed to fetch lessons: ${res.body}');
  }
}


  Future<bool> submitAnswer({
    required String userId,
    required String questionId,
    required String lessonId,
    required String languageId,
    String? userText,
    String? userAudioPath, // chemin local du fichier audio
  }) async {
    Map<String, dynamic> body = {
      "userId": userId,
      "questionId": questionId,
      "lessonId": lessonId,
      "languageId": languageId,
    };
    if (userText != null) body['userText'] = userText;
    if (userAudioPath != null) {
      final bytes = await http.MultipartFile.fromPath('audio', userAudioPath);
    }

    final res = await http.post(
      Uri.parse('$baseUrl/ml/analyse'),
      headers: await _getHeaders(),
      body: json.encode(body),
    );
    return res.statusCode == 200;
  }

  Future<List<dynamic>> fetchUserProgress(
    String userId,
    String lessonId,
  ) async {
    final res = await http.get(
      Uri.parse('$baseUrl/progress/user/$userId/lesson/$lessonId'),
      headers: await _getHeaders(),
    );
    if (res.statusCode == 200) {
      return json.decode(res.body); // retourne les questions déjà répondues
    } else {
      throw Exception('Failed to fetch user progress: ${res.body}');
    }
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
      body: json.encode({"name": name, "description": description}),
    );

    return res.statusCode == 201;
  }

  /// 🔹 Mettre à jour un objectif (admin) - PROTÉGÉ
  Future<bool> updateGoal(
    String id, {
    String? name,
    String? description,
  }) async {
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

  /// 🔹 Mettre à jour une source (admin) - PROTÉGÉ
  Future<bool> updateReferralSource(String id, {String? name}) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/referralsources/$id'),
      headers: await _getHeaders(),
      body: json.encode({if (name != null) "name": name}),
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

  Future<bool> hasUserPreferences(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/user-preferences/has-preferences/$userId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['hasPreferences'] ?? false;
    } else {
      return false;
    }
  }

  // 🔹 Récupérer les points d'un utilisateur
  Future<int> fetchUserPoints(String userId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/points/user/$userId'),
      headers: await _getHeaders(),
    );

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return data['value'] as int;
    } else {
      throw Exception('Failed to fetch user points: ${res.body}');
    }
  }

  // 🔹 Ajouter ou mettre à jour les points d'un utilisateur
  Future<bool> updateUserPoints(String userId, int value) async {
    final res = await http.post(
      Uri.parse('$baseUrl/points/update'),
      headers: await _getHeaders(),
      body: json.encode({"userId": userId, "value": value}),
    );

    return res.statusCode == 200 || res.statusCode == 201;
  }

  // 🔹 Récupérer le classement d'une division sur une période
  Future<List<dynamic>> fetchRanking(
    String divisionId,
    DateTime periodStart,
    DateTime periodEnd,
  ) async {
    final res = await http.get(
      Uri.parse(
        '$baseUrl/ranking/division/$divisionId?periodStart=${periodStart.toIso8601String()}&periodEnd=${periodEnd.toIso8601String()}',
      ),
      headers: await _getHeaders(),
    );

    if (res.statusCode == 200) {
      return json.decode(res.body);
    } else {
      throw Exception('Failed to fetch ranking: ${res.body}');
    }
  }

  // 🔹 Créer ou mettre à jour un ranking
  Future<bool> updateRanking({
    required String userId,
    required String pointId,
    required String divisionId,
    required int rank,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/ranking/update'),
      headers: await _getHeaders(),
      body: json.encode({
        "userId": userId,
        "pointId": pointId,
        "divisionId": divisionId,
        "rank": rank,
        "periodStart": periodStart.toIso8601String(),
        "periodEnd": periodEnd.toIso8601String(),
      }),
    );

    return res.statusCode == 200 || res.statusCode == 201;
  }
}
