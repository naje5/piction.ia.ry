import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/model/player.dart';
import 'package:flutter_app/services/game.service.dart';
import 'package:flutter_app/providers/auth.provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Provider pour suivre les joueurs d'une session de jeu
final gamePlayersProvider = StateNotifierProvider.family<
    GamePlayersNotifier, List<Player>, int>(
  (ref, gameId) => GamePlayersNotifier(gameId, ref),
);

class GamePlayersNotifier extends StateNotifier<List<Player>> {
  final int gameId;
  final Ref ref;
  final GameService _service = GameService();
  Timer? _timer;

  GamePlayersNotifier(this.gameId, this.ref) : super([]) {
    _init();
  }

  void _init() {
    // Rafraîchit immédiatement puis toutes les 3 secondes
    _refreshPlayers();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _refreshPlayers());
  }

  /// Rafraîchit la liste des joueurs à partir du backend
 Future<void> _refreshPlayers() async {
  try {
    final token = ref.read(authNotifierProvider).token;
    if (token == null) return;

    final session = await _service.getGameSession(gameId, token);
    if (session == null) return;

    List<Player> players = [];

    final creatorId = session['player_id'];

    // 🔹 Récupération des IDs (en filtrant les null)
    List<int> blueTeamIds = [
      session['blue_player_1'],
      session['blue_player_2'],
    ].whereType<int>().toList();

    List<int> redTeamIds = [
      session['red_player_1'],
      session['red_player_2'],
    ].whereType<int>().toList();

    // 🔹 Inclure le créateur s'il n'est pas déjà présent
    if (creatorId != null &&
        !blueTeamIds.contains(creatorId) &&
        !redTeamIds.contains(creatorId)) {
      blueTeamIds.add(creatorId);
    }

    // 🔹 Charger les joueurs de l’équipe bleue
    for (var id in blueTeamIds) {
      final playerData = await _fetchPlayer(id);
      if (playerData != null) {
        players.add(Player(playerData['name'] ?? 'Joueur $id', 'Bleu'));
      }
    }

    // 🔹 Charger les joueurs de l’équipe rouge
    for (var id in redTeamIds) {
      final playerData = await _fetchPlayer(id);
      if (playerData != null) {
        players.add(Player(playerData['name'] ?? 'Joueur $id', 'Rouge'));
      }
    }

    // 🔹 Supprimer les doublons éventuels (par ID)
    final uniquePlayers = {
      for (var p in players) p.name: p,
    }.values.toList();

    // 🔹 Mise à jour du state (notifie l’UI)
    state = uniquePlayers;

    // 🔹 Vérifie si la partie est complète (2 bleus + 2 rouges)
    if (blueTeamIds.length == 2 && redTeamIds.length == 2) {
      _timer?.cancel();
      _startGame();
    }

    print(blueTeamIds);
    print(redTeamIds);
  } catch (e) {
    print("❌ Erreur lors du rafraîchissement des joueurs : $e");
  }
}

  /// Récupère un joueur par ID
  Future<Map<String, dynamic>?> _fetchPlayer(dynamic id) async {
    try {
      final url = Uri.parse('https://pictioniary.wevox.cloud/api/players/$id');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Erreur lors de la récupération du joueur $id : $e');
    }
    return null;
  }

  /// Permet à un joueur de rejoindre une partie
  Future<void> joinGame([String color = 'Rouge']) async {
    final token = ref.read(authNotifierProvider).token;
    if (token == null) return;

    final success = await _service.joinGameSession(gameId, color, token);
    if (success) {
      await _refreshPlayers();
    }
  }

  /// Notifie que la partie peut commencer
  void _startGame() {
    print('🎮 La partie peut commencer !');
    // Tu pourras ici :
    // - notifier un autre provider
    // - ou envoyer un signal à ton écran pour naviguer vers PlayScreen
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
