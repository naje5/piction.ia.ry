import 'package:flutter/material.dart';
import 'package:flutter_app/services/challenge.service.dart';
import 'package:flutter_app/theme/app_colors.dart';

class GameOverScreen extends StatefulWidget {
  final int gameId;
  final String token;
  final int finalScore;

  const GameOverScreen({super.key, required this.gameId, required this.token, required this.finalScore});

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen> {
  bool _isLoading = true;
  bool _isError = false;
  List<dynamic> _challenges = [];

  @override
  void initState() {
    super.initState();
    _loadAllChallenges();
  }

  Future<void> _loadAllChallenges() async {
    try {
      final challenges = await ChallengeService().getAllChallenges(widget.gameId, widget.token);
      if (challenges == null) {
        setState(() => _isError = true);
      } else {
        setState(() {
          _challenges = challenges;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isError = true);
    }
  }

  int _calculateChallengeScore(Map<String, dynamic> challenge) {
    // Si le challenge est résolu, on donne des points
    if (challenge["is_resolved"] == true) {
      return 100; // Points de base pour un challenge résolu
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Fin de partie")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_isError) {
      return Scaffold(
        appBar: AppBar(title: const Text("Erreur")),
        body: const Center(child: Text("Impossible de charger les résultats.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("🎉 Fin de la partie !"),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          // En-tête avec le score final
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
                const Icon(Icons.emoji_events, size: 60, color: Colors.white),
                const SizedBox(height: 12),
                const Text(
                  "Score Final",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "${widget.finalScore} points",
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "${_challenges.length} challenge(s) joué(s)",
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          
          // Liste des challenges
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _challenges.length,
              itemBuilder: (context, index) {
                final challenge = _challenges[index];
                final words = [
                  challenge["first_word"],
                  challenge["second_word"],
                  challenge["third_word"],
                  challenge["fourth_word"],
                  challenge["fifth_word"]
                ].whereType<String>().toList();
                
                final String wordsText = words.join(" ");
                final bool isResolved = challenge["is_resolved"] == true;
                final int challengeScore = _calculateChallengeScore(challenge);

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isResolved ? Colors.green : Colors.red,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // En-tête du challenge
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isResolved 
                            ? Colors.green.withOpacity(0.1) 
                            : Colors.red.withOpacity(0.1),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isResolved ? Icons.check_circle : Icons.cancel,
                                  color: isResolved ? Colors.green : Colors.red,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Challenge #${index + 1}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isResolved ? Colors.green : Colors.grey,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "+$challengeScore pts",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image du challenge
                            if (challenge["image_path"] != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  challenge["image_path"],
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 200,
                                      color: Colors.grey[300],
                                      child: const Center(
                                        child: Icon(Icons.image_not_supported, size: 50),
                                      ),
                                    );
                                  },
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      height: 200,
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  },
                                ),
                              )
                            else
                              Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Text("Aucune image"),
                                ),
                              ),
                            
                            const SizedBox(height: 16),
                            
                            // Mots à deviner
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.lightbulb, color: Colors.blue),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Mots à deviner :",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          wordsText,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Réponse donnée
                            if (challenge["answer"] != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isResolved 
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isResolved 
                                      ? Colors.green.withOpacity(0.3)
                                      : Colors.orange.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isResolved ? Icons.check : Icons.clear,
                                      color: isResolved ? Colors.green : Colors.orange,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isResolved ? "Réponse correcte :" : "Réponse donnée :",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: isResolved ? Colors.green : Colors.orange,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            challenge["answer"],
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.help_outline, color: Colors.grey),
                                    SizedBox(width: 8),
                                    Text(
                                      "Aucune réponse donnée",
                                      style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            
                            const SizedBox(height: 12),
                            
                            // Créateur du challenge
                            if (challenge["player_name"] != null)
                              Row(
                                children: [
                                  const Icon(Icons.person, size: 20, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Créé par ${challenge["player_name"]}",
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // Bouton de retour
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                icon: const Icon(Icons.home),
                label: const Text("Retour à l'accueil"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
