import 'package:logger/logger.dart';

import '../../core/errors/exceptions.dart';
import '../datasources/local/secure_storage.dart';
import '../datasources/remote/api_client.dart';
import '../models/auth_model.dart';

/// Репозиторій для автентифікації
class AuthRepository {
  final ApiClient _apiClient;
  final SecureStorageService _secureStorage;
  final Logger _logger = Logger();

  User? _currentUser;

  AuthRepository({
    required ApiClient apiClient,
    required SecureStorageService secureStorage,
  })  : _apiClient = apiClient,
        _secureStorage = secureStorage;

  /// Поточний користувач
  User? get currentUser => _currentUser;

  /// Перевірка чи користувач автентифікований
  Future<bool> isAuthenticated() async {
    final token = await _secureStorage.getAuthToken();
    return token != null;
  }

  /// Ініціалізація автентифікації (відправка коду в Telegram)
  Future<void> initAuth(int telegramId) async {
    try {
      _logger.i('Initializing auth for Telegram ID: $telegramId');

      final response = await _apiClient.authInit(telegramId);
      final authResponse = AuthInitResponse.fromJson(response);

      _logger.i('Auth init response: ${authResponse.message}');
    } on AppException {
      rethrow;
    } catch (e) {
      _logger.e('Failed to init auth: $e');
      throw AuthException('Failed to initialize authentication: $e');
    }
  }

  /// Верифікація коду з Telegram
  Future<AuthToken> verifyCode(int telegramId, String code) async {
    try {
      _logger.i('Verifying code for Telegram ID: $telegramId');

      final response = await _apiClient.authVerify(telegramId, code);
      final authResponse = AuthVerifyResponse.fromJson(response);

      // Зберігаємо токени
      await _secureStorage.saveAuthToken(authResponse.token);

      if (authResponse.refreshToken != null) {
        await _secureStorage.saveRefreshToken(authResponse.refreshToken!);
      }

      // Зберігаємо User ID
      if (authResponse.user != null) {
        _currentUser = authResponse.user;
        await _secureStorage.saveUserId(authResponse.user!.id.toString());
      }

      // Встановлюємо токен в API client
      _apiClient.setAuthToken(authResponse.token);

      _logger.i('Auth verification successful');

      return AuthToken(
        accessToken: authResponse.token,
        refreshToken: authResponse.refreshToken,
      );
    } on AppException {
      rethrow;
    } catch (e) {
      _logger.e('Failed to verify code: $e');
      throw AuthException('Failed to verify code: $e');
    }
  }

  /// Оновлення токену
  Future<AuthToken> refreshToken() async {
    try {
      final refreshToken = await _secureStorage.getRefreshToken();

      if (refreshToken == null) {
        throw const AuthException('No refresh token available');
      }

      _logger.i('Refreshing auth token');

      final response = await _apiClient.authRefresh(refreshToken);
      final token = response['token'] as String;
      final newRefreshToken = response['refresh_token'] as String?;

      // Зберігаємо нові токени
      await _secureStorage.saveAuthToken(token);

      if (newRefreshToken != null) {
        await _secureStorage.saveRefreshToken(newRefreshToken);
      }

      // Встановлюємо новий токен в API client
      _apiClient.setAuthToken(token);

      _logger.i('Token refreshed successfully');

      return AuthToken(
        accessToken: token,
        refreshToken: newRefreshToken,
      );
    } on AppException {
      rethrow;
    } catch (e) {
      _logger.e('Failed to refresh token: $e');
      throw AuthException('Failed to refresh token: $e');
    }
  }

  /// Відновлення сесії (при запуску додатку)
  Future<bool> restoreSession() async {
    try {
      final token = await _secureStorage.getAuthToken();

      if (token == null) {
        _logger.i('No saved token found');
        return false;
      }

      // Встановлюємо токен в API client
      _apiClient.setAuthToken(token);

      // Спробуємо оновити токен для перевірки валідності
      try {
        await refreshToken();
        _logger.i('Session restored successfully');
        return true;
      } on AuthException {
        // Токен не валідний, очищаємо
        await logout();
        return false;
      }
    } catch (e) {
      _logger.e('Failed to restore session: $e');
      return false;
    }
  }

  /// Вихід з аккаунту
  Future<void> logout() async {
    try {
      _logger.i('Logging out');

      // Очищаємо токени
      await _secureStorage.clearAuthTokens();

      // Очищаємо токен в API client
      _apiClient.clearAuthToken();

      // Очищаємо поточного користувача
      _currentUser = null;

      _logger.i('Logged out successfully');
    } catch (e) {
      _logger.e('Failed to logout: $e');
      throw AuthException('Failed to logout: $e');
    }
  }

  /// Отримання збереженого токену
  Future<String?> getStoredToken() async {
    return await _secureStorage.getAuthToken();
  }

  /// Збереження токену
  Future<void> saveToken(String token) async {
    await _secureStorage.saveAuthToken(token);
    _apiClient.setAuthToken(token);
  }
}
