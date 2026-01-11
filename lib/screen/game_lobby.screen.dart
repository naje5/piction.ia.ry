import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_app/screen/challenge.screen.dart';
import 'package:flutter_app/screen/game_round.screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth.provider.dart';
import '../services/game.service.dart';
import '../services/challenge.service.dart';
import '../theme/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class GameLobbyScreen extends ConsumerStatefulWidget {
  final int gameId;
  final int creatorId;

  const GameLobbyScreen({
    super.key,
    required this.gameId,
    required this.creatorId,
  });

  @override
  ConsumerState<GameLobbyScreen> createState() => _GameLobbyScreenState();
}

class _GameLobbyScreenState extends ConsumerState<GameLobbyScreen> {
  Timer? _timer;
  Map<String, dynamic>? _session;
  bool _isLoading = true;
  int? _currentUserId;

  final GameService _service = GameService();
  final ChallengeService _challengeService = ChallengeService();

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserId();
    _fetchGameData();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchGameData());
  }

  Future<void> _fetchCurrentUserId() async {
    final token = ref.read(authNotifierProvider).token;
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('https://pictioniary.wevox.cloud/api/me'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _currentUserId = data['id'] ?? data['_id'] ?? data['player_id'];
          });
        }
      }
    } catch (e) {
      print('Erreur lors de la récupération de l\'ID utilisateur: $e');
    }
  }

  Future<void> _fetchGameData() async {
    final token = ref.read(authNotifierProvider).token;
    if (token == null) return;

    final session = await _service.getGameSession(widget.gameId, token);
    if (session == null) return;

    if (mounted) {
      setState(() {
        _session = session;
        _isLoading = false;
      });
    }

    await _checkGameStatusAndRedirect(token);
  }

  Future<void> _checkGameStatusAndRedirect(String token) async {
    if (!mounted) return;

    try {
      final gameStatus = await _service.getGameStatus(widget.gameId, token);
      if (gameStatus == null) return;

      final status = gameStatus['status'] as String?;

      // Si le jeu est en phase drawing ou guessing, rediriger vers GameRoundScreen
      if (status == 'drawing' || status == 'guessing') {
        if (mounted) {
          _timer?.cancel();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => GameRoundScreen(gameId: widget.gameId, token: token),
            ),
          );
        }
        return;
      }

      // Si le jeu est terminé, rester dans le lobby
      if (status == 'finished') {
        return;
      }

      // Si le statut est "challenge", vérifier si l'utilisateur a créé ses challenges
      if (status == 'challenge') {
        final myChallenges = await _challengeService.getChallenges(widget.gameId, token);
        final hasCreatedChallenges = myChallenges != null && myChallenges.length >= 3;

        // Rediriger vers ChallengeScreen seulement si l'utilisateur n'a pas encore créé ses challenges
        if (!hasCreatedChallenges && mounted) {
          _timer?.cancel();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ChallengeScreen(gameId: widget.gameId),
            ),
          );
        }
      }
      // Si le statut est "lobby" ou autre, rester dans le lobby (ne rien faire)
    } catch (e) {
      debugPrint('Erreur lors de la vérification du statut du jeu: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startGame() async {
    final token = ref.read(authNotifierProvider).token;
    if (token == null) return;

    final success = await _service.startGame(widget.gameId, token);
    if (mounted) {
      if (success) {
        _timer?.cancel();
        Navigator.push(
          context,
          MaterialPageRoute(
            
            builder: (_) => ChallengeScreen(gameId: widget.gameId),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ Impossible de démarrer la partie"),
            backgroundColor: AppColors.secondary,
          ),
        );
      }
    }
  }

  void _showChangeTeamDialog() {
    String selectedColor = 'red';
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white.withAlpha(230),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                "Changer d'équipe",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Choisissez votre nouvelle équipe :",
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              selectedColor = 'blue';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: selectedColor == 'blue'
                                  ? AppColors.primaryDark
                                  : AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primaryDark,
                                width: selectedColor == 'blue' ? 3 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.shield,
                                  color: Colors.white,
                                  size: selectedColor == 'blue' ? 32 : 24,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "BLEUE 💙",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: selectedColor == 'blue' ? 14 : 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              selectedColor = 'red';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: selectedColor == 'red'
                                  ? AppColors.secondary
                                  : AppColors.secondaryLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.secondary,
                                width: selectedColor == 'red' ? 3 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.shield,
                                  color: Colors.white,
                                  size: selectedColor == 'red' ? 32 : 24,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "ROUGE ❤️",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: selectedColor == 'red' ? 14 : 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Annuler"),
                ),
                TextButton(
                  onPressed: () async {
                    final token = ref.read(authNotifierProvider).token;
                    if (token == null) return;

                    // Quitter d'abord l'équipe actuelle
                    await _service.leaveGameSession(widget.gameId, token);

                    // Rejoindre la nouvelle équipe
                    final success = await _service.joinGameSession(
                      widget.gameId,
                      selectedColor,
                      token,
                    );

                    if (mounted) {
                      Navigator.pop(ctx);
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "✅ Vous avez rejoint l'équipe ${selectedColor == 'blue' ? 'BLEUE 💙' : 'ROUGE ❤️'}",
                            ),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                        _fetchGameData();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                "❌ Impossible de changer d'équipe (équipe pleine ?)"),
                            backgroundColor: AppColors.secondary,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text(
                    "Confirmer",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameId = widget.gameId;
    final gameService = GameService();
    final token = ref.read(authNotifierProvider).token;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_session == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            "Impossible de charger la session ❌",
            style: TextStyle(color: AppColors.secondary),
          ),
        ),
      );
    }

    final session = _session!;
    final sessionCreatorId = session['player_id'] ?? session['creator_id'];
    final playersCount = [
      session['blue_player_1'],
      session['blue_player_2'],
      session['red_player_1'],
      session['red_player_2'],
    ].whereType<int>().length;

    final isCreator = _currentUserId != null
        ? _currentUserId == sessionCreatorId
        : (sessionCreatorId == widget.creatorId);
    // Le bouton s'affiche seulement si l'utilisateur est le créateur
    // Mais il ne sera cliquable que si 4 joueurs sont présents

    final List<int> blueTeamIds = [
      session['blue_player_1'],
      session['blue_player_2'],
    ].whereType<int>().toList();

    final List<int> redTeamIds = [
      session['red_player_1'],
      session['red_player_2'],
    ].whereType<int>().toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Lobby de la partie"),
        elevation: 0,
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      body: Container(
        // 🎨 même fond que ChallengeScreen
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryLight, AppColors.secondaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'ID de la partie : $gameId',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20, color: AppColors.primaryDark),
                      tooltip: 'Copier',
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: gameId.toString()));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('ID copié dans le presse-papier !'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Partage cet ID pour que d’autres joueurs puissent rejoindre la partie.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.text.withAlpha(220)),
                ),
                const SizedBox(height: 30),

                // 🟦 Équipe Bleue
                Text(
                  "ÉQUIPE BLEUE 💙",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 10),
                ...blueTeamIds.map((id) => FutureBuilder<Map<String, dynamic>?>(
                      future: gameService.fetchPlayer(id, token!),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const ListTile(
                            leading: CircularProgressIndicator(),
                            title: Text("Chargement..."),
                          );
                        }
                        final player = snapshot.data!;
                        return Card(
                          color: Colors.white.withAlpha(230),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ListTile(
                            leading: Icon(Icons.person,
                                color: AppColors.primaryDark),
                            title: Text(
                              player['name'] ?? 'Joueur $id',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            trailing: id == sessionCreatorId
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      "Créateur ⭐",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  )
                                : null,
                          ),
                        );
                      },
                    )),

                const SizedBox(height: 30),

                // 🔴 Équipe Rouge
                Text(
                  "ÉQUIPE ROUGE ❤️",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 10),
                ...redTeamIds.map((id) => FutureBuilder<Map<String, dynamic>?>(
                      future: gameService.fetchPlayer(id, token!),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const ListTile(
                            leading: CircularProgressIndicator(),
                            title: Text("Chargement..."),
                          );
                        }
                        final player = snapshot.data!;
                        return Card(
                          color: Colors.white.withAlpha(230),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ListTile(
                            leading:
                                Icon(Icons.person, color: AppColors.secondary),
                            title: Text(
                              player['name'] ?? 'Joueur $id',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        );
                      },
                    )),

                const Spacer(),
                const SizedBox(height: 20),

                // Bouton "Démarrer la partie" - visible seulement pour le créateur
                if (isCreator)
                  ElevatedButton.icon(
                    onPressed: playersCount >= 4 ? _startGame : null,
                    icon: const Icon(Icons.play_arrow, size: 22),
                    label: Text(
                      playersCount >= 4
                          ? "Démarrer la partie"
                          : "En attente de joueurs (${playersCount}/4)",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: playersCount >= 4
                          ? AppColors.primary
                          : AppColors.muted,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: playersCount >= 4 ? 4 : 0,
                    ),
                  ),
                if (isCreator) const SizedBox(height: 12),

                // Bouton pour changer d'équipe
                ElevatedButton.icon(
                  onPressed: () {
                    _showChangeTeamDialog();
                  },
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text(
                    "Changer d'équipe",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
