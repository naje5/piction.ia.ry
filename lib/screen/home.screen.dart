import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/game.service.dart';
import '../providers/auth.provider.dart';
import '../providers/user_info.provider.dart';
import 'game_lobby.screen.dart';
import '../theme/app_colors.dart'; // Couleurs du thème

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameService = GameService();
    final userInfoAsync = ref.watch(userInfoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Accueil"),
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  userInfoAsync.when(
                    data: (user) => user != null && user['name'] != null
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Text(
                              'Bonjour ${user['name']} 👋',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                    loading: () => const Padding(
                      padding: EdgeInsets.only(bottom: 24),
                      child: SizedBox(height: 24),
                    ),
                    error: (e, _) => const SizedBox.shrink(),
                  ),
                  // Bouton créer une partie
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text(
                        "Créer une partie",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      onPressed: () async {
                        String selectedColor = 'red';
                        showDialog(
                          context: context,
                          builder: (ctx) {
                            return StatefulBuilder(
                              builder: (context, setDialogState) {
                                return AlertDialog(
                                  backgroundColor: Colors.white.withAlpha(230),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  title: const Text(
                                    "Créer une partie",
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        "Choisissez votre équipe :",
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
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 16),
                                                decoration: BoxDecoration(
                                                  color: selectedColor == 'blue'
                                                      ? AppColors.primaryDark
                                                      : AppColors.primaryLight,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: AppColors.primaryDark,
                                                    width: selectedColor == 'blue'
                                                        ? 3
                                                        : 1,
                                                  ),
                                                ),
                                                child: Column(
                                                  children: [
                                                    Icon(
                                                      Icons.shield,
                                                      color: Colors.white,
                                                      size: selectedColor == 'blue'
                                                          ? 32
                                                          : 24,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      "BLEUE 💙",
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize:
                                                            selectedColor == 'blue'
                                                                ? 14
                                                                : 12,
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
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 16),
                                                decoration: BoxDecoration(
                                                  color: selectedColor == 'red'
                                                      ? AppColors.secondary
                                                      : AppColors.secondaryLight,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: AppColors.secondary,
                                                    width: selectedColor == 'red'
                                                        ? 3
                                                        : 1,
                                                  ),
                                                ),
                                                child: Column(
                                                  children: [
                                                    Icon(
                                                      Icons.shield,
                                                      color: Colors.white,
                                                      size: selectedColor == 'red'
                                                          ? 32
                                                          : 24,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      "ROUGE ❤️",
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize:
                                                            selectedColor == 'red'
                                                                ? 14
                                                                : 12,
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
                                        final token =
                                            ref.read(authNotifierProvider).token!;
                                        final result = await gameService
                                            .createGameSession(token);
                                        if (result != null) {
                                          final gameId = result['gameId'];
                                          final playerId = result['playerId'];
                                          await gameService.joinGameSession(
                                              gameId, selectedColor, token);

                                          Navigator.pop(ctx);
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => GameLobbyScreen(
                                                  gameId: gameId,
                                                  creatorId: playerId),
                                            ),
                                          );
                                        }
                                      },
                                      child: const Text(
                                        "Créer",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Bouton rejoindre une partie
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.group_add),
                      label: const Text(
                        "Rejoindre une partie",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      onPressed: () {
                        final idController = TextEditingController();
                        String selectedColor = 'red';
                        showDialog(
                          context: context,
                          builder: (ctx) {
                            return StatefulBuilder(
                              builder: (context, setDialogState) {
                                return AlertDialog(
                                  backgroundColor: Colors.white.withAlpha(230),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  title: const Text("Rejoindre une partie"),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextField(
                                        controller: idController,
                                        decoration: const InputDecoration(
                                          labelText: "ID de la partie",
                                          border: OutlineInputBorder(),
                                        ),
                                        keyboardType: TextInputType.number,
                                      ),
                                      const SizedBox(height: 20),
                                      const Text(
                                        "Choisir votre équipe :",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
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
                                                padding: const EdgeInsets.symmetric(
                                                    vertical: 16),
                                                decoration: BoxDecoration(
                                                  color: selectedColor == 'blue'
                                                      ? AppColors.primaryDark
                                                      : AppColors.primaryLight,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: AppColors.primaryDark,
                                                    width: selectedColor == 'blue'
                                                        ? 3
                                                        : 1,
                                                  ),
                                                ),
                                                child: Column(
                                                  children: [
                                                    Icon(
                                                      Icons.shield,
                                                      color: Colors.white,
                                                      size: selectedColor == 'blue'
                                                          ? 32
                                                          : 24,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      "BLEUE 💙",
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize:
                                                            selectedColor == 'blue'
                                                                ? 14
                                                                : 12,
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
                                                padding: const EdgeInsets.symmetric(
                                                    vertical: 16),
                                                decoration: BoxDecoration(
                                                  color: selectedColor == 'red'
                                                      ? AppColors.secondary
                                                      : AppColors.secondaryLight,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: AppColors.secondary,
                                                    width: selectedColor == 'red'
                                                        ? 3
                                                        : 1,
                                                  ),
                                                ),
                                                child: Column(
                                                  children: [
                                                    Icon(
                                                      Icons.shield,
                                                      color: Colors.white,
                                                      size: selectedColor == 'red'
                                                          ? 32
                                                          : 24,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      "ROUGE ❤️",
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize:
                                                            selectedColor == 'red'
                                                                ? 14
                                                                : 12,
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
                                        if (idController.text.trim().isEmpty) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  "Veuillez entrer un ID de partie"),
                                            ),
                                          );
                                          return;
                                        }
                                        final token =
                                            ref.read(authNotifierProvider).token!;
                                        final gameId =
                                            int.parse(idController.text);
                                        await gameService.joinGameSession(
                                          gameId,
                                          selectedColor,
                                          token,
                                        );
                                        Navigator.pop(ctx);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => GameLobbyScreen(
                                                gameId: gameId, creatorId: 0),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        "Rejoindre",
                                        style:
                                            TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
