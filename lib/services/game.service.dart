import 'dart:convert';
import 'package:http/http.dart' as http;

class GameService {
  final String baseUrl = "https://pictioniary.wevox.cloud/api";

  /// 🔹 Crée une nouvelle session de jeu
 Future<Map<String, dynamic>?> createGameSession(String token) async {
  final response = await http.post(
    Uri.parse("$baseUrl/game_sessions"),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
  );

  if (response.statusCode == 201 || response.statusCode == 200) {
    final data = jsonDecode(response.body);
    // Retourne id de la session et player_id
    return {
      "gameId": data['id'],
      "playerId": data['player_id'],
    };
  } else {
    print("Erreur création partie : ${response.statusCode} ${response.body}");
    return null;
  }
}

Future<Map<String, dynamic>?> fetchPlayer(int id, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/players/$id'),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  /// 🔹 Rejoint une session existante avec la couleur choisie ("blue" ou "red")
  Future<bool> joinGameSession(int gameSessionId, String color, String token) async {
    final response = await http.post(
      Uri.parse("$baseUrl/game_sessions/$gameSessionId/join"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"color": color}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      print("❌ Erreur lors de la jointure : ${response.statusCode} ${response.body}");
      return false;
    }
  }

  /// 🔹 Quitte une session de jeu
  Future<bool> leaveGameSession(int gameSessionId, String token) async {
    final response = await http.get(
      Uri.parse("$baseUrl/game_sessions/$gameSessionId/leave"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      print("❌ Erreur lors de la sortie : ${response.statusCode} ${response.body}");
      return false;
    }
  }

  /// 🔹 Récupère les infos d'une session
  Future<Map<String, dynamic>?> getGameSession(int gameId, String token) async {
    final response = await http.get(
      Uri.parse("$baseUrl/game_sessions/$gameId"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print("❌ Erreur getGameSession : ${response.statusCode} ${response.body}");
      return null;
    }
  }

  Future<Map<String, dynamic>?> getGameStatus(int gameId, String token) async {
    final response = await http.get(
      Uri.parse("$baseUrl/game_sessions/$gameId/status"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print("❌ Erreur getGameStatus : ${response.statusCode} ${response.body}");
      return null;
    }
  }

  /// 🔹 Démarre une session de jeu
  Future<bool> startGame(int gameId, String token) async {
    final response = await http.post(
      Uri.parse("$baseUrl/game_sessions/$gameId/start"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      print("❌ Erreur startGame : ${response.statusCode} ${response.body}");
      return false;
    }
  }
}
