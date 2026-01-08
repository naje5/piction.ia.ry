import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/providers/auth.provider.dart';
import 'package:flutter_app/services/challenge.service.dart';
import 'package:flutter_app/theme/app_colors.dart';
import 'game_round.screen.dart';

class ChallengeScreen extends ConsumerStatefulWidget {
  final int gameId;
  const ChallengeScreen({super.key, required this.gameId});

  @override
  ConsumerState<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends ConsumerState<ChallengeScreen>
    with SingleTickerProviderStateMixin {
  final ChallengeService _challengeService = ChallengeService();
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, TextEditingController>> _challengesControllers = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 3; i++) {
      _challengesControllers.add({
        "first_word": TextEditingController(),
        "second_word": TextEditingController(),
        "third_word": TextEditingController(),
        "fourth_word": TextEditingController(),
        "fifth_word": TextEditingController(),
        "forbidden_1": TextEditingController(),
        "forbidden_2": TextEditingController(),
        "forbidden_3": TextEditingController(),
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var map in _challengesControllers) {
      for (var controller in map.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _submitChallenges() async {
    FocusScope.of(context).unfocus();
    final token = ref.read(authNotifierProvider).token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vous êtes déconnecté")),
      );
      return;
    }

    for (int i = 0; i < _challengesControllers.length; i++) {
      final c = _challengesControllers[i];
      final fields = [
        c["first_word"],
        c["second_word"],
        c["third_word"],
        c["fourth_word"],
        c["fifth_word"],
        c["forbidden_1"],
        c["forbidden_2"],
        c["forbidden_3"],
      ];
      if (fields.any((ctrl) => ctrl == null || ctrl.text.trim().isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Veuillez remplir tous les champs du challenge ${i + 1}"),
            backgroundColor: AppColors.secondary,
          ),
        );
        _pageController.animateToPage(
          i,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
        );
        return;
      }
    }

    for (int i = 0; i < _challengesControllers.length; i++) {
      final c = _challengesControllers[i];
      final data = {
        "first_word": c["first_word"]!.text.trim(),
        "second_word": c["second_word"]!.text.trim(),
        "third_word": c["third_word"]!.text.trim(),
        "fourth_word": c["fourth_word"]!.text.trim(),
        "fifth_word": c["fifth_word"]!.text.trim(),
        "forbidden_words": [
          c["forbidden_1"]!.text.trim(),
          c["forbidden_2"]!.text.trim(),
          c["forbidden_3"]!.text.trim(),
        ],
      };

      final success = await _challengeService.createChallenge(widget.gameId, data, token);
      if (success == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors de l'envoi du challenge ${i + 1}")),
        );
        return;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("✅ Challenges envoyés avec succès"),
        backgroundColor: AppColors.primary,
      ),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => GameRoundScreen(gameId: widget.gameId, token: token)),
    );
  }

  void _nextPage() => _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );

  void _previousPage() => _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );

  Widget _modernCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            Colors.white.withAlpha(179),
            Colors.white.withAlpha(77),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(38),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white.withAlpha(102)),
      ),
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData? icon, {
    bool isError = false,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, color: isError ? AppColors.secondary : AppColors.primaryDark) : null,
        filled: true,
        fillColor: Colors.white.withAlpha(204),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isError ? AppColors.secondary : AppColors.primary,
            width: 2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
            width: 1.2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      ),
    );
  }

  Widget _buildChallengeForm(int index) {
    final c = _challengesControllers[index];
    return _modernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              "Challenge ${index + 1}",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 22,
                foreground: Paint()
                  ..shader = LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.secondary],
                  ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text("🧩 Construis ta phrase :",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(flex: 2, child: _buildTextField(c["first_word"]!, "Un/Une", null)),
              const SizedBox(width: 8),
              Expanded(flex: 4, child: _buildTextField(c["second_word"]!, "Premier mot", Icons.text_fields)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(flex: 2, child: _buildTextField(c["third_word"]!, "Sur/Dans", null)),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: _buildTextField(c["fourth_word"]!, "Un/Une", null)),
              
            ],
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _buildTextField(c["fifth_word"]!, "Deuxième mot", Icons.text_fields)),
            const SizedBox(width: 8),
          ],
          ),
          const SizedBox(height: 24),
          Divider(color: AppColors.primaryLight.withAlpha(204)), // ~0.8
          const SizedBox(height: 12),
          const Text("🚫 Mots interdits",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _buildTextField(c["forbidden_1"]!, "1er mot interdit", Icons.block, isError: true),
          const SizedBox(height: 12),
          _buildTextField(c["forbidden_2"]!, "2e mot interdit", Icons.block, isError: true),
          const SizedBox(height: 12),
          _buildTextField(c["forbidden_3"]!, "3e mot interdit", Icons.block, isError: true),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Créer vos challenges"),
        elevation: 0,
        backgroundColor: AppColors.primary,
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: "Simuler 3 challenges",
            icon: const Icon(Icons.auto_awesome, color: Colors.orange),
            onPressed: () async {
              final token = ref.read(authNotifierProvider).token;
              if (token == null) return;
              final challengeId = await _challengeService.simulateChallenges(widget.gameId, token);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("3 challenges simulés et envoyés !")),
              );
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => GameRoundScreen(gameId: widget.gameId, token: token),
                ),
              );
            },
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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Challenge ${_currentPage + 1}/3",
                        style: TextStyle(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    Row(
                      children: List.generate(3, (index) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: index == _currentPage ? 22 : 10,
                          height: 10,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: index == _currentPage
                                ? AppColors.primaryDark
                                : AppColors.primaryLight.withAlpha(102), // ~0.4
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemCount: 3,
                  itemBuilder: (context, index) =>
                      SingleChildScrollView(padding: const EdgeInsets.all(16), child: _buildChallengeForm(index)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (_currentPage > 0)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _previousPage,
                          icon: const Icon(Icons.arrow_back),
                          label: const Text("Précédent"),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.primaryDark.withAlpha(230), width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    if (_currentPage > 0) const SizedBox(width: 12),
                    Expanded(
                      flex: _currentPage == 0 ? 1 : 2,
                      child: ElevatedButton.icon(
                        onPressed: _currentPage < 2 ? _nextPage : _submitChallenges,
                        icon: Icon(_currentPage < 2 ? Icons.arrow_forward : Icons.check_circle_outline),
                        label: Text(_currentPage < 2 ? "Suivant" : "Commencer le jeu"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _currentPage < 2 ? AppColors.primary : AppColors.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
