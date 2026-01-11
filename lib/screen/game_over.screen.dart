import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_app/services/challenge.service.dart';
import 'package:flutter_app/services/game.service.dart';
import 'package:flutter_app/theme/app_colors.dart';

class GameOverScreen extends StatefulWidget {
  final int gameId;
  final String token;
  final int finalScore;

  const GameOverScreen({
    super.key,
    required this.gameId,
    required this.token,
    required this.finalScore,
  });

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen> {
  bool _isLoading = true;
  bool _isError = false;

  List<dynamic> _challenges = [];
  Map<String, Map<String, int>> _playerStats = {};
  Map<String, String> _playerNames = {};

  final ChallengeService _challengeService = ChallengeService();
  final GameService _gameService = GameService();

  @override
  void initState() {
    super.initState();
    _loadAllChallenges();
  }

  // ==============================
  // DATA LOADING
  // ==============================
  Future<void> _loadAllChallenges() async {
    try {
      final challenges =
          await _challengeService.getAllChallenges(widget.gameId, widget.token);

      if (challenges == null) {
        setState(() => _isError = true);
        return;
      }

      // ---- Collect unique challenger ids
      final Set<String> challengerIds = {};
      for (final c in challenges) {
        if (c['challenger_id'] != null) {
          challengerIds.add(c['challenger_id'].toString());
        }
      }

      // ---- Fetch player names
      final Map<String, String> playerNames = {};
      for (final idStr in challengerIds) {
        try {
          final player =
              await _gameService.fetchPlayer(int.parse(idStr), widget.token);
          playerNames[idStr] =
              player?['name'] ?? player?['username'] ?? 'Joueur#$idStr';
        } catch (_) {
          playerNames[idStr] = 'Joueur#$idStr';
        }
      }

      // ---- Stats per player
      final Map<String, Map<String, int>> stats = {};
      for (final c in challenges) {
        final id = c['challenger_id']?.toString();
        final playerName = playerNames[id] ?? 'Joueur#$id';

        final bool resolved = c['is_resolved'] == 1 || c['is_resolved'] == true;

        stats.putIfAbsent(playerName, () => {
              'resolved': 0,
              'unresolved': 0,
            });

        if (resolved) {
          stats[playerName]!['resolved'] =
              stats[playerName]!['resolved']! + 1;
        } else {
          stats[playerName]!['unresolved'] =
              stats[playerName]!['unresolved']! + 1;
        }
      }

      setState(() {
        _challenges = challenges;
        _playerStats = stats;
        _playerNames = playerNames;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erreur GameOverScreen: $e');
      setState(() => _isError = true);
    }
  }

  // ==============================
  // HELPERS
  // ==============================
  String _getChallengeResult(Map<String, dynamic> challenge) {
    if (challenge['proposals'] != null &&
        challenge['proposals'].toString().isNotEmpty) {
      try {
        final List proposals = jsonDecode(challenge['proposals']);
        if (proposals.isNotEmpty) {
          return proposals.first.toString();
        }
      } catch (_) {}
    }

    final words = [
      challenge['first_word'],
      challenge['second_word'],
      challenge['third_word'],
      challenge['fourth_word'],
      challenge['fifth_word'],
    ].where((w) => w != null && w.toString().isNotEmpty);

    return words.join(' ');
  }

  // ==============================
  // UI
  // ==============================
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_isError) {
      return const Scaffold(
        body: Center(child: Text("Erreur de chargement")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("🎉 Fin de la partie"),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          // ==============================
          // HEADER
          // ==============================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                const Icon(Icons.emoji_events,
                    size: 64, color: Colors.white),
                const SizedBox(height: 12),
                const Text(
                  "Score final",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "${widget.finalScore} pts",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),

                // ==============================
                // STATS TABLE
                // ==============================
                const Text(
                  "Statistiques par joueur",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Table(
                  border: TableBorder.all(color: Colors.white24),
                  children: [
                    const TableRow(
                      decoration: BoxDecoration(color: Colors.white12),
                      children: [
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text("Joueur",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text("Résolus",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text("Non résolus",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    ..._playerStats.entries.map(
                      (e) => TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(e.key,
                                style:
                                    const TextStyle(color: Colors.white)),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text("${e.value['resolved']}",
                                style:
                                    const TextStyle(color: Colors.white)),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text("${e.value['unresolved']}",
                                style:
                                    const TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ==============================
          // CHALLENGES RESULTS
          // ==============================
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _challenges.length,
              itemBuilder: (context, index) {
                final challenge = _challenges[index];
                final bool resolved =
                    challenge['is_resolved'] == 1 ||
                        challenge['is_resolved'] == true;

                return Card(
                  color: Colors.grey.shade900,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: Icon(
                      resolved
                          ? Icons.check_circle
                          : Icons.cancel,
                      color: resolved
                          ? Colors.greenAccent
                          : Colors.redAccent,
                    ),
                    title: Text(
                      _getChallengeResult(challenge),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Challenge #${challenge['id']}",
                      style:
                          const TextStyle(color: Colors.white70),
                    ),
                    trailing: Text(
                      resolved ? "+100 pts" : "0 pt",
                      style: TextStyle(
                        color: resolved
                            ? Colors.greenAccent
                            : Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ==============================
          // HOME BUTTON
          // ==============================
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () =>
                    Navigator.of(context)
                        .popUntil((r) => r.isFirst),
                icon: const Icon(Icons.home),
                label: const Text("Retour à l'accueil"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
