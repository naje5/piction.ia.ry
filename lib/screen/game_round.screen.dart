import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_app/screen/game_over.screen.dart';
import 'package:flutter_app/services/challenge.service.dart';
import 'package:flutter_app/services/game.service.dart';
import 'package:flutter_app/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class GameRoundScreen extends ConsumerStatefulWidget {
  final int gameId;
  final String token;

  const GameRoundScreen({super.key, required this.gameId, required this.token});

  @override
  ConsumerState<GameRoundScreen> createState() => _GameRoundScreenState();
}

class _GameRoundScreenState extends ConsumerState<GameRoundScreen> {
  bool _isLoading = true;
  bool _isError = false;
  bool _isDrawer = true; // true = drawer, false = guesser
  Map<String, dynamic>? _roundData;
  String? _generatedImageUrl;
  String? _guessInput;
  int _score = 100;
  int _regenerationCount = 0;
  int _timeLeft = 300; // 5 minutes en secondes
  Timer? _timer;
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _guessController = TextEditingController();
  Set<String> _foundWords = {};

  final GameService _gameService = GameService();
  
  @override
  void initState() {
    super.initState();
    _loadRoundData();
  }

  @override
  void dispose() {
    _promptController.dispose();
    _guessController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  /// 🔹 Start the timer
  void _startTimer() {
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
    }
    _timeLeft = 300;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        timer.cancel();
        if (mounted) {
          _showDialog("⏰ Temps écoulé !", "La partie est terminée car le temps est écoulé.");
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) _goToGameOverScreen();
          });
        }
      }
    });
  }

  Future<void> _checkIfGameFinished() async {
    final status = await _gameService.getGameStatus(widget.gameId, widget.token);
    if (status?["status"] == "finished") {
      if (mounted) {
        _showDialog("🎉 Partie terminée !", "Tous les joueurs ont fini !");
        _goToGameOverScreen();
      }
    }
  }

  Future<void> _loadRoundData() async {
    try {
      setState(() {
        _isLoading = true;
        _isError = false;
      });

      bool isDrawing = false;
      int retryCount = 0;
      const int maxRetries = 60; // 3 minutes waiting
      const Duration retryDelay = Duration(seconds: 3);

      Map<String, dynamic>? statusGame;

      // 🔁 Loop waiting for "drawing" status
      while (!isDrawing && retryCount < maxRetries) {
        statusGame = await _gameService.getGameStatus(widget.gameId, widget.token);

        if (statusGame?["status"] == "drawing") {
          isDrawing = true;
          break;
        }

        if (statusGame?["status"] == "finished") {
          // The game is already finished
          _goToGameOverScreen();
          return;
        }

        await Future.delayed(retryDelay);
        retryCount++;
      }

      if (!isDrawing) {
        setState(() {
          _isError = true;
          _isLoading = false;
        });
        return;
      }

      // 🔹 Once in drawing mode, fetch the challenges
      final challenges = await ChallengeService().getChallenges(widget.gameId, widget.token);

      if (challenges == null || challenges.isEmpty) {
        setState(() {
          _isError = true;
          _isLoading = false;
        });
        return;
      }

      // 🔹 Update the round state
      setState(() {
        _roundData = {
          "challenges": challenges,
          "currentIndex": 0,
          "role": "drawer",
        };
        _isDrawer = true;
        _isLoading = false;
      });

      _startTimer();
    } catch (e) {
      setState(() {
        _isError = true;
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> get _currentChallenge {
    if (_roundData == null) return {};
    final index = _roundData!["currentIndex"] as int;
    final challenges = _roundData!["challenges"] as List<dynamic>;
    if (index >= challenges.length) return {};
    return challenges[index] as Map<String, dynamic>;
  }

  bool _validatePrompt(String prompt) {
    final challenge = _currentChallenge;

    List<String> forbidden = [];
    try {
      forbidden = List<String>.from(jsonDecode(challenge["forbidden_words"] ?? "[]"));
    } catch (_) {}

    final invalidWords = [...forbidden];
    for (final word in invalidWords) {
      if (prompt.toLowerCase().contains(word.toLowerCase())) {
        _showDialog("Erreur ❌",
            "The prompt must not contain the forbidden word: \"$word\"");
        return false;
      }
    }
    return true;
  }

  Future<void> _generateImage(String prompt) async {
    if (prompt.trim().isEmpty) {
      _showDialog("Erreur", "Veuillez écrire un prompt !");
      return;
    }

    if (!_validatePrompt(prompt)) return;

    if (_regenerationCount >= 2) {
      _showDialog("Limite atteinte", "Tu ne peux régénérer l'image que 2 fois !");
      return;
    }

    setState(() {
      _generatedImageUrl = null;
    });

    final challengeId = _currentChallenge["id"];
    final result = await ChallengeService()
        .drawChallenge(widget.gameId, challengeId, prompt, widget.token);

    if (result != null) {
      setState(() {
        _generatedImageUrl = result["image_path"];
        if (_regenerationCount > 0) {
          _score -= 10;
        }
        _regenerationCount++;
      });
    } else {
      _showDialog("Erreur", "Impossible de générer l'image.");
    }
  }

  /// 🔹 Guesser tries an answer
  Future<void> _checkGuess(String input) async {
    final challenge = _currentChallenge;
    if (challenge.isEmpty) return;

    if (input.trim().isEmpty) {
      _showDialog("Erreur", "Veuillez entrer une réponse !");
      return;
    }

    final validWords = [
      challenge["first_word"],
      challenge["second_word"],
      challenge["third_word"],
      challenge["fourth_word"],
      challenge["fifth_word"]
    ].whereType<String>().map((w) => w.toLowerCase()).toList();

    final inputLower = input.trim().toLowerCase();
    
    // Check if the word has already been found
    if (_foundWords.contains(inputLower)) {
      _showDialog("Already found!", "You have already found this word. Look for the others!");
      _guessController.clear();
      return;
    }
    
    if (validWords.contains(inputLower)) {
      setState(() {
        _score += 25;
        _foundWords.add(inputLower);
      });
      
      // Send the answer to the API
      final challengeId = challenge["id"];
      if (challengeId != null) {
        await ChallengeService().answerChallenge(
          widget.gameId,
          challengeId,
          input.trim(),
          true, // is_resolved = true car mot trouvé
          widget.token,
        );
      }
      
      // Check if all words are found
      if (_foundWords.length >= validWords.length) {
        _showDialog("🎉 Challenge terminé !", "Vous avez trouvé tous les mots ! Passage au suivant...");
        await Future.delayed(const Duration(seconds: 2));
        _nextRound();
      } else {
        _showDialog("Bravo 🎉", "Tu as trouvé un mot ! (${_foundWords.length}/${validWords.length})");
      }
    } else {
      setState(() => _score = (_score - 1).clamp(0, 999999));
      _showDialog("Raté 😅", "Ce mot n'est pas dans la liste.");
      
      // Send the answer anyway (incorrect)
      final challengeId = challenge["id"];
      if (challengeId != null) {
        await ChallengeService().answerChallenge(
          widget.gameId,
          challengeId,
          input.trim(),
          false, // is_resolved = false car mot incorrect
          widget.token,
        );
      }
    }
    
    // Clear the input field
    _guessController.clear();
  }

  Future<void> _nextRound() async {
    final currentIndex = _roundData!["currentIndex"] as int;
    final challenges = _roundData!["challenges"] as List;

    if (currentIndex + 1 < challenges.length) {
      // Passer au challenge suivant
      setState(() {
        _roundData!["currentIndex"] = currentIndex + 1;
        _generatedImageUrl = null;
        _promptController.clear();
        _guessController.clear();
        _regenerationCount = 0;
        _foundWords.clear(); // Reset found words
        
        // In guessing mode, load the next challenge image
        if (!_isDrawer && _roundData!["challenges"][currentIndex + 1]["image_path"] != null) {
          _generatedImageUrl = _roundData!["challenges"][currentIndex + 1]["image_path"];
        }
      });
    } else {
      // All challenges of this phase are finished
      _timer?.cancel();

      if (!_isDrawer) {
        // If we were in guessing mode → game finished
        await _checkIfGameFinished();
      } else {
        // If we were in drawing mode → switch to guessing mode
        setState(() {
          _isLoading = true;
          _isDrawer = false;
        });
        await _loadGuesserChallenges();
      }
    }
  }

  Future<void> _loadGuesserChallenges() async {
    try {
      setState(() {
        _isLoading = true;
        _isError = false;
      });

      bool isGuessing = false;
      int retryCount = 0;
      const int maxRetries = 60; // 3 minutes
      const Duration retryDelay = Duration(seconds: 3);

      Map<String, dynamic>? statusGame;

      // 🔁 Wait for "guessing" status
      while (!isGuessing && retryCount < maxRetries) {
        statusGame = await _gameService.getGameStatus(widget.gameId, widget.token);
        
        if (statusGame?["status"] == "guessing") {
          isGuessing = true;
          break;
        }

        if (statusGame?["status"] == "finished") {
          _goToGameOverScreen();
          return;
        }

        await Future.delayed(retryDelay);
        retryCount++;
      }

      if (!isGuessing) {
        setState(() {
          _isError = true;
          _isLoading = false;
        });
        return;
      }

      // 🔹 Once in guessing mode, fetch the challenges to guess
      final challenges = await ChallengeService().getMyChallengesToGuess(widget.gameId, widget.token);

      if (challenges == null || challenges.isEmpty) {
        // No challenges to guess, maybe the game is finished
        await _checkIfGameFinished();
        return;
      }

      setState(() {
        _roundData = {
          "challenges": challenges,
          "currentIndex": 0,
          "role": "guesser",
        };
        _isDrawer = false;
        _isLoading = false;
        _generatedImageUrl = challenges[0]["image_path"];
      });

      _startTimer();
    } catch (e) {
      setState(() {
        _isError = true;
        _isLoading = false;
      });
    }
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text("OK"),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  void _goToGameOverScreen() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => GameOverScreen(
            gameId: widget.gameId,
            token: widget.token,
            finalScore: _score,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_isDrawer ? "Phase Dessin 🎨" : "Phase Devinette 🧩"),
          centerTitle: true,
          elevation: 0,
          backgroundColor: AppColors.primary,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 20),
              Text(
                "En attente que tous les joueurs soient prêts…",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (_isError) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Erreur'),
          backgroundColor: AppColors.secondary,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.secondary),
              const SizedBox(height: 20),
              const Text(
                'Impossible de charger la partie.',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text("Retour"),
              ),
            ],
          ),
        ),
      );
    }

    final currentIndex = _roundData!["currentIndex"] as int;
    final totalChallenges = (_roundData!["challenges"] as List).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isDrawer ? "Mode Dessinateur 🎨" : "Mode Devineur 🧩"),
        backgroundColor: AppColors.primary,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                "⏱ ${_formatTime(_timeLeft)}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primaryLight.withOpacity(0.3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Challenge ${currentIndex + 1}/$totalChallenges",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  "Score: $_score pts",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _isDrawer ? _buildDrawerView() : _buildGuesserView(),
            ),
          ),
        ],
      ),
    );
  }

  // === 🧠 Mode DESSINATEUR ===
  Widget _buildDrawerView() {
  final challenge = _currentChallenge;

  List<String> forbiddenWords = [];
  if (challenge["forbidden_words"] != null) {
    try {
      forbiddenWords =
          List<String>.from(jsonDecode(challenge["forbidden_words"]));
    } catch (_) {}
  }

  final promptWords = [
    challenge["first_word"],
    challenge["second_word"],
    challenge["third_word"],
    challenge["fourth_word"],
    challenge["fifth_word"]
  ].whereType<String>().join(" ");

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary, width: 2),
          boxShadow: [
            BoxShadow(
              blurRadius: 8,
              color: Colors.black.withOpacity(0.05),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "🎨 À dessiner",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Text(
              promptWords,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),

            const SizedBox(height: 16),

            if (forbiddenWords.isNotEmpty) ...[
              const Text(
                "🚫 Forbidden words",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 10),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: forbiddenWords.map((word) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red, width: 2),
                      color: Colors.red.withOpacity(0.08),
                    ),
                    child: Text(
                      word,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),

      const SizedBox(height: 20),
Container(
  padding: const EdgeInsets.all(14),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.grey.shade300),
    boxShadow: [
      BoxShadow(
        blurRadius: 8,
        color: Colors.black.withOpacity(0.05),
      ),
    ],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "📝 Décrivez votre image",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),

      const SizedBox(height: 10),

      TextField(
        controller: _promptController,
        maxLines: 1,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey.shade50,
          hintText: "Ex: Un lapin pirate sur un bateau en lego…",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      const SizedBox(height: 12),

      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.auto_awesome),
          label: const Text("Générer l'image"),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => _generateImage(_promptController.text),
        ),
      ),
const SizedBox(height: 12),
  if (_generatedImageUrl != null) ...[
  Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          blurRadius: 8,
          color: Colors.black.withOpacity(0.05),
        ),
      ],
    ),
    child: Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            _generatedImageUrl!,
            height: 260,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 260,
              color: Colors.grey[300],
              child: const Center(
                child: Icon(Icons.error, size: 40, color: Colors.red),
              ),
            ),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 260,
                child: const Center(child: CircularProgressIndicator()),
              );
            },
          ),
        ),

        const SizedBox(height: 14),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.check_circle),
            label: const Text("Valider et passer au suivant"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _nextRound,
          ),
        ),
      ],
    ),
  ),
]
  ],
  ),
),

const SizedBox(height: 20),
    ],
  );
}

  // === 🧩 Mode DEVINEUR ===
  Widget _buildGuesserView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Image to guess
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _generatedImageUrl != null
                ? Image.network(
                    _generatedImageUrl!,
                    height: 300,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 300,
                        color: Colors.grey[300],
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error, size: 50, color: Colors.red),
                              SizedBox(height: 8),
                              Text("Erreur de chargement"),
                            ],
                          ),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 300,
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    },
                  )
                : Container(
                    height: 300,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Text("En attente de l'image..."),
                    ),
                  ),
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Found words
        if (_foundWords.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "Mots trouvés (${_foundWords.length}/5) :",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _foundWords.map((word) {
                    return Chip(
                      label: Text(word),
                      backgroundColor: Colors.green[100],
                      avatar: const Icon(Icons.check, size: 18, color: Colors.green),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        
        if (_foundWords.isNotEmpty) const SizedBox(height: 20),
        
        // Partner info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 1),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.primaryDark, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Cette image a été créée par votre coéquipier ! Devinez les 5 mots qu'il a utilisés 🎨",
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primaryDark,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Answer field
        TextField(
          controller: _guessController,
          onChanged: (val) => _guessInput = val,
          onSubmitted: (val) {
            if (val.isNotEmpty) _checkGuess(val);
          },
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: "Ex: poule, mur, camion...",
            labelText: "Votre réponse (un mot à la fois)",
            prefixIcon: Icon(Icons.edit),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Validate button
        ElevatedButton.icon(
          icon: const Icon(Icons.send),
          label: const Text("Valider ma réponse"),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: () {
            if (_guessInput?.isNotEmpty ?? false) {
              _checkGuess(_guessInput!);
            }
          },
        ),
        
        const SizedBox(height: 24),
        
        // Scoring info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Text("Mot trouvé : +25 points"),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.cancel, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Text("Mauvaise réponse : -1 point"),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Button to skip to next
        OutlinedButton.icon(
          icon: const Icon(Icons.skip_next),
          label: Text(_foundWords.length >= 3 
            ? "Passer au challenge suivant" 
            : "Je passe ce challenge (trouvez au moins 3 mots pour gagner des points)"
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: BorderSide(
              color: _foundWords.length >= 3 ? AppColors.primary : Colors.orange, 
              width: 2
            ),
          ),
          onPressed: () {
            if (_foundWords.length < 3) {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("⚠️ Attention"),
                  content: Text(
                    "Vous n'avez trouvé que ${_foundWords.length}/5 mots.\n\n"
                    "Voulez-vous vraiment passer au challenge suivant ?"
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Non, continuer"),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _nextRound();
                      },
                      child: const Text("Oui, passer"),
                    ),
                  ],
                ),
              );
            } else {
              _nextRound();
            }
          },
        ),
      ],
    );
  }
}
