class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? token;

  const AuthState({
    this.isAuthenticated = true,
    this.isLoading = false,
    this.token,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? token,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      token: token ?? this.token,
    );
  }
}
