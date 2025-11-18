import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

import '../../../core/constants/app_constants.dart';

/// Безпечне сховище для API ключів та токенів
class SecureStorageService {
  static final SecureStorageService instance = SecureStorageService._internal();
  final Logger _logger = Logger();

  late final FlutterSecureStorage _storage;

  SecureStorageService._internal() {
    _storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock,
      ),
    );
  }

  // ============= Auth Tokens =============

  /// Збереження auth токену
  Future<void> saveAuthToken(String token) async {
    await _storage.write(
      key: AppConstants.storageAuthToken,
      value: token,
    );
    _logger.d('Auth token saved');
  }

  /// Отримання auth токену
  Future<String?> getAuthToken() async {
    return await _storage.read(key: AppConstants.storageAuthToken);
  }

  /// Збереження refresh токену
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(
      key: AppConstants.storageRefreshToken,
      value: token,
    );
    _logger.d('Refresh token saved');
  }

  /// Отримання refresh токену
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: AppConstants.storageRefreshToken);
  }

  /// Видалення auth токенів
  Future<void> clearAuthTokens() async {
    await _storage.delete(key: AppConstants.storageAuthToken);
    await _storage.delete(key: AppConstants.storageRefreshToken);
    _logger.i('Auth tokens cleared');
  }

  // ============= Exchange API Keys =============

  /// Збереження API ключів біржі
  Future<void> saveExchangeApiKeys(
    String exchange,
    String apiKey,
    String apiSecret,
  ) async {
    final keyPrefix = _getExchangeKeyPrefix(exchange);

    await _storage.write(
      key: '${keyPrefix}_api_key',
      value: apiKey,
    );

    await _storage.write(
      key: '${keyPrefix}_api_secret',
      value: apiSecret,
    );

    _logger.i('API keys saved for exchange: $exchange');
  }

  /// Отримання API ключів біржі
  Future<Map<String, String>?> getExchangeApiKeys(String exchange) async {
    final keyPrefix = _getExchangeKeyPrefix(exchange);

    final apiKey = await _storage.read(key: '${keyPrefix}_api_key');
    final apiSecret = await _storage.read(key: '${keyPrefix}_api_secret');

    if (apiKey == null || apiSecret == null) {
      return null;
    }

    return {
      'apiKey': apiKey,
      'apiSecret': apiSecret,
    };
  }

  /// Перевірка чи є API ключі для біржі
  Future<bool> hasExchangeApiKeys(String exchange) async {
    final keys = await getExchangeApiKeys(exchange);
    return keys != null;
  }

  /// Видалення API ключів біржі
  Future<void> deleteExchangeApiKeys(String exchange) async {
    final keyPrefix = _getExchangeKeyPrefix(exchange);

    await _storage.delete(key: '${keyPrefix}_api_key');
    await _storage.delete(key: '${keyPrefix}_api_secret');

    _logger.i('API keys deleted for exchange: $exchange');
  }

  /// Отримання списку бірж з збереженими ключами
  Future<List<String>> getConfiguredExchanges() async {
    final exchanges = <String>[];

    for (final exchange in AppConstants.supportedExchanges) {
      if (await hasExchangeApiKeys(exchange)) {
        exchanges.add(exchange);
      }
    }

    return exchanges;
  }

  /// Отримання префіксу ключа для біржі
  String _getExchangeKeyPrefix(String exchange) {
    switch (exchange.toLowerCase()) {
      case AppConstants.exchangeBinance:
        return 'binance';
      case AppConstants.exchangeBybit:
        return 'bybit';
      case AppConstants.exchangeOkx:
        return 'okx';
      default:
        return exchange.toLowerCase();
    }
  }

  // ============= User Data =============

  /// Збереження User ID
  Future<void> saveUserId(String userId) async {
    await _storage.write(
      key: AppConstants.storageUserId,
      value: userId,
    );
  }

  /// Отримання User ID
  Future<String?> getUserId() async {
    return await _storage.read(key: AppConstants.storageUserId);
  }

  // ============= Generic Operations =============

  /// Збереження значення
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  /// Читання значення
  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  /// Видалення значення
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  /// Перевірка чи існує ключ
  Future<bool> containsKey(String key) async {
    return await _storage.containsKey(key: key);
  }

  /// Отримання всіх ключів
  Future<Map<String, String>> readAll() async {
    return await _storage.readAll();
  }

  /// Очищення всього сховища
  Future<void> clearAll() async {
    await _storage.deleteAll();
    _logger.w('All secure storage cleared');
  }
}
