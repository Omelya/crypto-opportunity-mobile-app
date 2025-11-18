import 'package:logger/logger.dart';

import '../../core/errors/exceptions.dart';
import '../datasources/local/preferences_service.dart';
import '../datasources/local/secure_storage.dart';
import '../models/exchange_model.dart';

/// Репозиторій для роботи зі сховищем
class StorageRepository {
  final SecureStorageService _secureStorage;
  final PreferencesService _preferences;
  final Logger _logger = Logger();

  StorageRepository({
    required SecureStorageService secureStorage,
    required PreferencesService preferences,
  })  : _secureStorage = secureStorage,
        _preferences = preferences;

  // ============= Exchange API Keys =============

  /// Збереження конфігурації біржі
  Future<void> saveExchangeConfig(ExchangeConfig config) async {
    try {
      _logger.i('Saving exchange config for: ${config.name}');

      await _secureStorage.saveExchangeApiKeys(
        config.name,
        config.apiKey,
        config.apiSecret,
      );

      _logger.i('Exchange config saved: ${config.name}');
    } catch (e) {
      _logger.e('Failed to save exchange config: $e');
      throw DataException('Failed to save exchange configuration: $e');
    }
  }

  /// Отримання конфігурації біржі
  Future<ExchangeConfig?> getExchangeConfig(String exchange) async {
    try {
      final keys = await _secureStorage.getExchangeApiKeys(exchange);

      if (keys == null) {
        return null;
      }

      return ExchangeConfig(
        name: exchange,
        apiKey: keys['apiKey']!,
        apiSecret: keys['apiSecret']!,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      _logger.e('Failed to get exchange config: $e');
      return null;
    }
  }

  /// Видалення конфігурації біржі
  Future<void> deleteExchangeConfig(String exchange) async {
    try {
      _logger.i('Deleting exchange config for: $exchange');

      await _secureStorage.deleteExchangeApiKeys(exchange);

      _logger.i('Exchange config deleted: $exchange');
    } catch (e) {
      _logger.e('Failed to delete exchange config: $e');
      throw DataException('Failed to delete exchange configuration: $e');
    }
  }

  /// Отримання списку налаштованих бірж
  Future<List<String>> getConfiguredExchanges() async {
    try {
      return await _secureStorage.getConfiguredExchanges();
    } catch (e) {
      _logger.e('Failed to get configured exchanges: $e');
      return [];
    }
  }

  /// Перевірка чи налаштована біржа
  Future<bool> isExchangeConfigured(String exchange) async {
    try {
      return await _secureStorage.hasExchangeApiKeys(exchange);
    } catch (e) {
      _logger.e('Failed to check exchange configuration: $e');
      return false;
    }
  }

  // ============= Trading Settings =============

  /// Збереження налаштувань торгівлі
  Future<void> saveTradingSettings({
    bool? autoTradingEnabled,
    double? minProfitPercent,
    double? maxPositionSize,
    int? dailyTradesLimit,
    double? maxDailyLoss,
  }) async {
    try {
      if (autoTradingEnabled != null) {
        await _preferences.setAutoTradingEnabled(autoTradingEnabled);
      }

      if (minProfitPercent != null) {
        await _preferences.setMinProfitPercent(minProfitPercent);
      }

      if (maxPositionSize != null) {
        await _preferences.setMaxPositionSize(maxPositionSize);
      }

      if (dailyTradesLimit != null) {
        await _preferences.setDailyTradesLimit(dailyTradesLimit);
      }

      if (maxDailyLoss != null) {
        await _preferences.setMaxDailyLoss(maxDailyLoss);
      }

      _logger.i('Trading settings saved');
    } catch (e) {
      _logger.e('Failed to save trading settings: $e');
      throw DataException('Failed to save trading settings: $e');
    }
  }

  /// Отримання налаштувань торгівлі
  Map<String, dynamic> getTradingSettings() {
    return {
      'autoTradingEnabled': _preferences.isAutoTradingEnabled(),
      'minProfitPercent': _preferences.getMinProfitPercent(),
      'maxPositionSize': _preferences.getMaxPositionSize(),
      'dailyTradesLimit': _preferences.getDailyTradesLimit(),
      'maxDailyLoss': _preferences.getMaxDailyLoss(),
    };
  }

  // ============= App Settings =============

  /// Збереження режиму теми
  Future<void> setThemeMode(String mode) async {
    await _preferences.setThemeMode(mode);
  }

  /// Отримання режиму теми
  String getThemeMode() {
    return _preferences.getThemeMode();
  }

  /// Збереження мови
  Future<void> setLanguage(String languageCode) async {
    await _preferences.setLanguage(languageCode);
  }

  /// Отримання мови
  String getLanguage() {
    return _preferences.getLanguage();
  }

  // ============= Notification Settings =============

  /// Збереження налаштувань сповіщень
  Future<void> saveNotificationSettings({
    bool? opportunityNotifications,
    bool? tradeNotifications,
  }) async {
    try {
      if (opportunityNotifications != null) {
        await _preferences.setOpportunityNotificationsEnabled(
          opportunityNotifications,
        );
      }

      if (tradeNotifications != null) {
        await _preferences.setTradeNotificationsEnabled(
          tradeNotifications,
        );
      }

      _logger.i('Notification settings saved');
    } catch (e) {
      _logger.e('Failed to save notification settings: $e');
      throw DataException('Failed to save notification settings: $e');
    }
  }

  /// Отримання налаштувань сповіщень
  Map<String, bool> getNotificationSettings() {
    return {
      'opportunityNotifications': _preferences.isOpportunityNotificationsEnabled(),
      'tradeNotifications': _preferences.isTradeNotificationsEnabled(),
    };
  }

  // ============= Onboarding =============

  /// Встановлення статусу onboarding
  Future<void> setOnboardingCompleted(bool completed) async {
    await _preferences.setOnboardingCompleted(completed);
  }

  /// Перевірка чи пройдено onboarding
  bool isOnboardingCompleted() {
    return _preferences.isOnboardingCompleted();
  }

  /// Перевірка чи це перший запуск
  bool isFirstLaunch() {
    return _preferences.isFirstLaunch();
  }

  /// Встановлення першого запуску
  Future<void> setFirstLaunch(bool isFirst) async {
    await _preferences.setFirstLaunch(isFirst);
  }

  // ============= Last Sync =============

  /// Збереження часу останньої синхронізації
  Future<void> setLastSyncTime(DateTime time) async {
    await _preferences.setLastSyncTime(time);
  }

  /// Отримання часу останньої синхронізації
  DateTime? getLastSyncTime() {
    return _preferences.getLastSyncTime();
  }

  // ============= Cleanup =============

  /// Очищення всіх даних
  Future<void> clearAllData() async {
    try {
      _logger.w('Clearing all data');

      await _secureStorage.clearAll();
      await _preferences.clearAll();

      _logger.w('All data cleared');
    } catch (e) {
      _logger.e('Failed to clear all data: $e');
      throw DataException('Failed to clear data: $e');
    }
  }
}
