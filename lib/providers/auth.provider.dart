import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// 🔹 État d’authentification global
class AuthState {
  final String? token;
  final bool isAuthenticated;
  final bool isLoading;

  const AuthState({
    this.token,
    this.isAuthenticated = false,
    this.isLoading = false,
  });

  AuthState copyWith({
    String? token,
    bool? isAuthenticated,
    bool? isLoading,
  }) {
    return AuthState(
      token: token ?? this.token,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// 🔹 Notifier pour gérer la connexion / inscription
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  final String baseUrl = "https://pictioniary.wevox.cloud/api";

  /// 🔹 Bascule entre Login et Inscription
  void toggleMode() {
    state = state.copyWith(isAuthenticated: !state.isAuthenticated);
  }

  /// 🔹 Authentification (connexion ou inscription)
  Future<bool> handleAuth(String username, String password) async {
    state = state.copyWith(isLoading: true);

    try {
      final endpoint =
          state.isAuthenticated ? "$baseUrl/login" : "$baseUrl/register";

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": username,
          "password": password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        // ⚡ On récupère le token + infos joueur
        final token = data['token'];

        if (token != null) {
          state = state.copyWith(
            token: token,
            isAuthenticated: true,
            isLoading: false,
          );
          return true;
        }
      }

      // Si erreur serveur
      print("Erreur auth : ${response.statusCode} - ${response.body}");
      state = state.copyWith(isLoading: false);
      return false;
    } catch (e) {
      print("Erreur handleAuth : $e");
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  /// 🔹 Déconnexion
  void logout() {
    state = const AuthState();
  }
}

/// 🔹 Provider global
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
