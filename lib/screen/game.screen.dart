import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game.provider.dart';
import '../providers/auth.provider.dart';
import '../model/player.dart';
import '../services/game.service.dart';
import '../theme/app_colors.dart';

class GameLobbyScreen extends ConsumerWidget {
  final int gameId;
  const GameLobbyScreen({Key? key, required this.gameId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider);
    final players = ref.watch(gamePlayersProvider(gameId));
    final creatorAsync = ref.watch(_gameSessionCreatorProvider(gameId));

    return creatorAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Lobby de la partie'),
          backgroundColor: AppColors.primary,
          centerTitle: true,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (err, stack) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Lobby de la partie'),
          backgroundColor: AppColors.primary,
          centerTitle: true,
          elevation: 0,
        ),
        body: const Center(child: Text('Erreur lors du chargement du créateur')),
      ),
      data: (creatorId) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Lobby de la partie'),
          backgroundColor: AppColors.primary,
          centerTitle: true,
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: players.isEmpty
              ? const Center(
                  child: Text(
                    "En attente de joueurs...",
                    style: TextStyle(color: AppColors.muted, fontSize: 16),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTeamSection(
                      title: "Équipe Bleue",
                      color: AppColors.primary,
                      players: players.where((p) => p.team.toLowerCase() == 'bleu').toList(),
                      creatorId: creatorId,
                    ),
                    const SizedBox(height: 20),
                    _buildTeamSection(
                      title: "Équipe Rose",
                      color: AppColors.secondary,
                      players: players.where((p) => p.team.toLowerCase() == 'rouge').toList(),
                      creatorId: creatorId,
                    ),
                    const Spacer(),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await GameService().startGame(gameId, auth.token!);
                          // TODO: Naviguer vers l'écran principal du jeu
                        },
                        icon: const Icon(Icons.play_arrow, size: 22),
                        label: const Text(
                          'Démarrer la partie',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 4,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  /// Section d’équipe moderne
  Widget _buildTeamSection({
    required String title,
    required Color color,
    required List<Player> players,
    required String? creatorId,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.1), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.group, color: color, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (players.isEmpty)
            Text(
              "Aucun joueur pour le moment...",
              style: TextStyle(color: AppColors.muted.withValues(alpha: 0.8)),
            )
          else
            Column(
              children: players
                  .map((p) => _playerTile(p, creatorId, color))
                  .toList(),
            ),
        ],
      ),
    );
  }

  /// Carte joueur stylisée
  Widget _playerTile(Player player, String? creatorId, Color color) {
    final bool isCreator = creatorId != null && player.name == creatorId;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.2),
            child: Icon(Icons.person, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              player.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.text,
              ),
            ),
          ),
          if (isCreator)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Créateur',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

final _gameSessionCreatorProvider = FutureProvider.family<String?, int>((ref, gameId) async {
  final auth = ref.read(authNotifierProvider);
  final session = await GameService().getGameSession(gameId, auth.token ?? '');
  if (session == null) return null;
  return session['creator_id']?.toString();
});
