import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth.provider.dart';
import '../services/game.service.dart';
import '../theme/app_colors.dart';
import 'challenge.screen.dart';

class PlayScreen extends ConsumerStatefulWidget {
  final int gameId;
  const PlayScreen({super.key, required this.gameId});

  @override
  ConsumerState<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends ConsumerState<PlayScreen> {
  Map<String, dynamic>? _session;
  bool _isLoading = true;
  bool _isError = false;
  final service = GameService();

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    try {
      final token = ref.read(authNotifierProvider).token;
      if (token == null) return;

      final session = await service.getGameSession(widget.gameId, token);
      setState(() {
        _session = session;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isError = true;
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>?> _fetchGameStatus() async {
    try {
      final token = ref.read(authNotifierProvider).token;
      if (token == null) return null;
      final response = await service.getGameStatus(widget.gameId, token);
      if (response != null) {
        return response;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _refreshGame() async {
    await _loadSession();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_isError || _session == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Erreur'),
          backgroundColor: AppColors.secondary,
        ),
        body: const Center(
          child: Text(
            "Impossible de charger la session de jeu.",
            style: TextStyle(color: AppColors.secondary),
          ),
        ),
      );
    }

    final session = _session!;
    final blueTeam = session['blue_team'] ?? [];
    final redTeam = session['red_team'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Partie en cours'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshGame,
          ),
        ],
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
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🧭 Infos générales
                Center(
                  child: Text(
                    'Partie #${widget.gameId}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Divider(
                  color: Colors.white.withAlpha(200),
                  thickness: 1,
                ),
                const SizedBox(height: 20),

                // 🔵 Équipe Bleue
                Text(
                  'ÉQUIPE BLEUE 💙 (${blueTeam.length}/2)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 8),
                ...blueTeam.map((p) => Card(
                      color: Colors.white.withAlpha(230),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        leading: Icon(Icons.person, color: AppColors.primaryDark),
                        title: Text(
                          'Joueur ID: $p',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    )),

                const SizedBox(height: 24),

                // 🔴 Équipe Rouge
                Text(
                  'ÉQUIPE ROUGE ❤️ (${redTeam.length}/2)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 8),
                ...redTeam.map((p) => Card(
                      color: Colors.white.withAlpha(230),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        leading: Icon(Icons.person, color: AppColors.secondary),
                        title: Text(
                          'Joueur ID: $p',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    )),

                const SizedBox(height: 30),

                // 🧩 Statut du jeu
                FutureBuilder<Map<String, dynamic>?>(
                  future: _fetchGameStatus(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary));
                    }
                    final status = snapshot.data!;
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(240),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 6,
                            color: Colors.black.withOpacity(0.1),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '📊 Statut de la partie : ${status['status'] ?? 'inconnu'}',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (status['round'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Tour actuel : ${status['round']}',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: AppColors.text.withAlpha(220),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),

                const Spacer(),

                // 🕹️ Bouton d’action
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text(
                      "Créer les challenges",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 3,
                    ),
                    onPressed: () {
                      GameService()
                        .startGame(widget.gameId, ref.read(authNotifierProvider).token!);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          
                          builder: (_) => ChallengeScreen(gameId: widget.gameId),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
