import 'dart:convert';
import 'package:http/http.dart' as http;

class ChallengeService {
  /// 🔹 Simule la création de 3 challenges pour une session donnée
  Future<void> simulateChallenges(int gameSessionId, String token) async {
    final List<Map<String, dynamic>> fakeChallenges = [
      {
        "first_word": "une",
        "second_word": "poule",
        "third_word": "sur",
        "fourth_word": "un",
        "fifth_word": "mur",
        "forbidden_words": ["volaille", "brique", "poulet"],
      },
      {
        "first_word": "un",
        "second_word": "chat",
        "third_word": "dans",
        "fourth_word": "une",
        "fifth_word": "boîte",
        "forbidden_words": ["félin", "carton", "miaou"],
      },
      {
        "first_word": "un",
        "second_word": "avion",
        "third_word": "sur",
        "fourth_word": "un",
        "fifth_word": "nuage",
        "forbidden_words": ["ciel", "pilote", "voler"],
      },
    ];

    for (var i = 0; i < fakeChallenges.length; i++) {
      final success = await createChallenge(gameSessionId, fakeChallenges[i], token);
      if (success != null) {
        print("✅ Challenge simulé #${i + 1} envoyé");
      } else {
        print("❌ Erreur lors de l'envoi du challenge simulé #${i + 1}");
      }
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }
  final String baseUrl = "https://pictioniary.wevox.cloud/api";

  /// 🔹 Créer un nouveau challenge
  /// POST /game_sessions/{gameSessionId}/challenges
  Future<Map<String, dynamic>?> createChallenge(int gameSessionId, Map<String, dynamic> data, String token) async {
    final response = await http.post(
      Uri.parse("$baseUrl/game_sessions/$gameSessionId/challenges"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      print("❌ Erreur createChallenge : ${response.statusCode} ${response.body}");
      return null;
    }
  }

  
  Future<List<dynamic>?> getChallenges(int gameSessionId, String token) async {
    final response = await http.get(
      Uri.parse("$baseUrl/game_sessions/$gameSessionId/myChallenges"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      print("❌ Erreur getChallenges : ${response.statusCode} ${response.body}");
      return null;
    }
  } 
  
  Future<List<dynamic>?> getAllChallenges(int gameSessionId, String token) async {
    final response = await http.get(
      Uri.parse("$baseUrl/game_sessions/$gameSessionId/challenges"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      print("❌ Erreur getAllChallenges : ${response.statusCode} ${response.body}");
      return null;
    }
  }

  /// 🔹 Récupérer les challenges que je dois deviner
  Future<List<dynamic>?> getMyChallengesToGuess(int gameSessionId, String token) async {
    final response = await http.get(
      Uri.parse("$baseUrl/game_sessions/$gameSessionId/myChallengesToGuess"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      print("❌ Erreur getMyChallengesToGuess : ${response.statusCode} ${response.body}");
      return null;
    }
  }

  /// 🔹 Dessiner un challenge (générer une image avec Stable Diffusion)
  /// POST /game_sessions/{gameSessionId}/challenges/{challengeId}/draw
  Future<Map<String, dynamic>?> drawChallenge(
    int gameSessionId,
    int challengeId,
    String prompt,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/game_sessions/$gameSessionId/challenges/$challengeId/draw"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"prompt": prompt}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }

    if (response.statusCode == 400) {
      print("Prompt contains a forbidden word");
      return null;
    } else {
      print("Erreur drawChallenge : ${response.statusCode} ${response.body}");
      return null;
    }
  }

  /// 🔹 Répondre à un challenge
  /// POST /game_sessions/{gameSessionId}/challenges/{challengeId}/answer
  Future<Map<String, dynamic>?> answerChallenge(
    int gameSessionId,
    int challengeId,
    String answer,
    bool isResolved,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/game_sessions/$gameSessionId/challenges/$challengeId/answer"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "answer": answer,
        "is_resolved": isResolved,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      print("❌ Erreur answerChallenge : ${response.statusCode} ${response.body}");
      return null;
    }
  }
}