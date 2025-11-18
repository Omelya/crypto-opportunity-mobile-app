import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../data/models/auth_model.dart';
import '../../data/repositories/auth_repository.dart';
import 'providers.dart';

/// Стан автентифікації
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final User? user;
  final String? error;
  final bool awaitingCode;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.user,
    this.error,
    this.awaitingCode = false,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    User? user,
    String? error,
    bool? awaitingCode,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error,
      awaitingCode: awaitingCode ?? this.awaitingCode,
    );
  }
}

/// Auth State Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  final Logger _logger = Logger();

  AuthNotifier(this._authRepository) : super(const AuthState());

  /// Перевірка чи користувач автентифікований при старті додатку
  Future<void> checkAuthStatus() async {
    state = state.copyWith(isLoading: true);

    try {
      final isAuthenticated = await _authRepository.restoreSession();

      state = state.copyWith(
        isAuthenticated: isAuthenticated,
        isLoading: false,
        user: _authRepository.currentUser,
      );

      _logger.i('Auth status checked: $isAuthenticated');
    } catch (e) {
      _logger.e('Failed to check auth status: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Ініціалізація автентифікації через Telegram
  Future<void> loginWithTelegram(int telegramId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _authRepository.initAuth(telegramId);

      state = state.copyWith(
        isLoading: false,
        awaitingCode: true,
      );

      _logger.i('Telegram auth initialized for ID: $telegramId');
    } catch (e) {
      _logger.e('Failed to init Telegram auth: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Верифікація коду з Telegram
  Future<void> verifyCode(int telegramId, String code) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _authRepository.verifyCode(telegramId, code);

      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        awaitingCode: false,
        user: _authRepository.currentUser,
      );

      _logger.i('Code verified successfully');
    } catch (e) {
      _logger.e('Failed to verify code: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Вихід з акаунту
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);

    try {
      await _authRepository.logout();

      state = const AuthState();

      _logger.i('Logged out successfully');
    } catch (e) {
      _logger.e('Failed to logout: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Очищення помилки
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Auth State Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
