import 'package:flutter/material.dart';
import 'package:flutter_app/services/challenge.service.dart';
import 'package:flutter_app/services/game.service.dart';
import 'package:flutter_app/screen/home.screen.dart';
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

  List<Map<String, dynamic>> _playerScores = [];

  final ChallengeService _challengeService = ChallengeService();
  final GameService _gameService = GameService();

  @override
  void initState() {
    super.initState();
    _loadPlayerScores();
  }

  Future<void> _loadPlayerScores() async {
    try {
      final challenges =
          await _challengeService.getAllChallenges(widget.gameId, widget.token);

      if (challenges == null) {
        if (mounted) {
          setState(() {
            _isError = true;
            _isLoading = false;
          });
        }
        return;
      }

      // ---- Collect unique challenger ids
      final Set<String> challengerIds = {};
      for (final c in challenges) {
        if (c['challenger_id'] != null) {
          challengerIds.add(c['challenger_id'].toString());
        }
      }

      // ---- Fetch player names and calculate scores
      final Map<String, Map<String, dynamic>> playerData = {};
      
      for (final idStr in challengerIds) {
        try {
          final player =
              await _gameService.fetchPlayer(int.parse(idStr), widget.token);
          final playerName = player?['name'] ?? player?['username'] ?? 'Joueur#$idStr';
          
          playerData[idStr] = {
            'name': playerName,
            'resolved': 0,
            'score': 0,
          };
        } catch (_) {
          playerData[idStr] = {
            'name': 'Joueur#$idStr',
            'resolved': 0,
            'score': 0,
          };
        }
      }

      // ---- Calculate scores (100 pts per resolved challenge)
      for (final c in challenges) {
        final id = c['challenger_id']?.toString();
        if (id != null && playerData.containsKey(id)) {
          final bool resolved = c['is_resolved'] == 1 || c['is_resolved'] == true;
          if (resolved) {
            playerData[id]!['resolved'] = (playerData[id]!['resolved'] as int) + 1;
            playerData[id]!['score'] = (playerData[id]!['score'] as int) + 100;
          }
        }
      }

      // ---- Convert to list and sort by score (descending)
      final List<Map<String, dynamic>> scores = playerData.values.toList();
      scores.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

      setState(() {
        _playerScores = scores;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erreur GameOverScreen: $e');
      if (mounted) {
        setState(() {
          _isError = true;
          _isLoading = false;
        });
      }
    }
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
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryLight, AppColors.secondaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
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
                child: const Column(
                  children: [
                    Icon(Icons.emoji_events, size: 64, color: Colors.white),
                    SizedBox(height: 12),
                    Text(
                      "Classement final",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // ==============================
              // PLAYER SCORES LIST
              // ==============================
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _playerScores.length,
                  itemBuilder: (context, index) {
                    final player = _playerScores[index];
                    final name = player['name'] as String;
                    final score = player['score'] as int;
                    final resolved = player['resolved'] as int;
                    final isWinner = index == 0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: isWinner ? 8 : 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: isWinner
                            ? BorderSide(color: AppColors.secondary, width: 2)
                            : BorderSide.none,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: isWinner
                                ? AppColors.secondary
                                : AppColors.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: isWinner ? Colors.white : AppColors.primaryDark,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: isWinner ? AppColors.secondary : AppColors.text,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '$resolved challenge${resolved > 1 ? 's' : ''} résolu${resolved > 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$score pts',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            if (isWinner)
                              const Text(
                                '🏆',
                                style: TextStyle(fontSize: 16),
                              ),
                          ],
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
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.home),
                    label: const Text(
                      "Retour à l'accueil",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
