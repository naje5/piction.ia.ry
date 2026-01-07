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

  /// 🔹 Simule des joueurs automatiques rejoignant la session
  Future<bool> simulatePlayers(int gameSessionId) async {
    // Liste de joueurs simulés (à créer ou utiliser des comptes existants)
    final List<Map<String, String>> botPlayers = [
      {"name": "Bot_Blue_1", "password": "bot123", "color": "blue"},
      {"name": "Bot_Red_1", "password": "bot123", "color": "red"},
      {"name": "Bot_Blue_2", "password": "bot123", "color": "blue"},
    ];

    try {
      for (var bot in botPlayers) {
        // 1. Se connecter avec le compte bot
        final loginResponse = await http.post(
          Uri.parse("$baseUrl/login"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "name": bot["name"],
            "password": bot["password"],
          }),
        );

        String? botToken;
        
        if (loginResponse.statusCode == 200) {
          final data = jsonDecode(loginResponse.body);
          botToken = data["token"];
        } else {
          // Si le bot n'existe pas, on le crée
          print("🤖 Création du bot ${bot['name']}...");
          final registerResponse = await http.post(
            Uri.parse("$baseUrl/players"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "name": bot["name"],
              "password": bot["password"],
            }),
          );

          if (registerResponse.statusCode == 201) {
            // On se reconnecte après création
            final reLoginResponse = await http.post(
              Uri.parse("$baseUrl/login"),
              headers: {"Content-Type": "application/json"},
              body: jsonEncode({
                "name": bot["name"],
                "password": bot["password"],
              }),
            );

            if (reLoginResponse.statusCode == 200) {
              final data = jsonDecode(reLoginResponse.body);
              botToken = data["token"];
            }
          }
        }

        if (botToken == null) {
          print("❌ Impossible de connecter ${bot['name']}");
          continue;
        }

        // 2. Rejoindre la session avec la couleur appropriée
        final joinSuccess = await joinGameSession(
          gameSessionId,
          bot["color"]!,
          botToken,
        );

        if (joinSuccess) {
          print("✅ ${bot['name']} a rejoint l'équipe ${bot['color']}");
        } else {
          print("❌ ${bot['name']} n'a pas pu rejoindre");
        }

        // Petit délai entre chaque bot pour éviter les conflits
        await Future.delayed(const Duration(milliseconds: 500));
      }

      return true;
    } catch (e) {
      print("❌ Erreur lors de la simulation des joueurs : $e");
      return false;
    }
  }
}
