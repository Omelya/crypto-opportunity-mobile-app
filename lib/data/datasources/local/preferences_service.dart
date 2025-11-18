import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/app_constants.dart';

/// Сервіс для роботи з налаштуваннями додатку
class PreferencesService {
  static final PreferencesService instance = PreferencesService._internal();
  final Logger _logger = Logger();

  SharedPreferences? _prefs;

  PreferencesService._internal();

  /// Ініціалізація SharedPreferences
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _logger.i('Preferences service initialized');
  }

  /// Отримання інстансу SharedPreferences
  SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('PreferencesService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // ============= Theme Settings =============

  /// Збереження режиму теми
  Future<void> setThemeMode(String mode) async {
    await prefs.setString(AppConstants.storageThemeMode, mode);
    _logger.d('Theme mode set to: $mode');
  }

  /// Отримання режиму теми
  String getThemeMode() {
    return prefs.getString(AppConstants.storageThemeMode) ?? 'system';
  }

  // ============= Language Settings =============

  /// Збереження мови
  Future<void> setLanguage(String languageCode) async {
    await prefs.setString(AppConstants.storageLanguage, languageCode);
    _logger.d('Language set to: $languageCode');
  }

  /// Отримання мови
  String getLanguage() {
    return prefs.getString(AppConstants.storageLanguage) ?? 'en';
  }

  // ============= Trading Settings =============

  /// Збереження автоматичного режиму торгівлі
  Future<void> setAutoTradingEnabled(bool enabled) async {
    await prefs.setBool('auto_trading_enabled', enabled);
    _logger.d('Auto trading ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Отримання статусу автоматичного режиму
  bool isAutoTradingEnabled() {
    return prefs.getBool('auto_trading_enabled') ?? false;
  }

  /// Збереження мінімального відсотка прибутку
  Future<void> setMinProfitPercent(double percent) async {
    await prefs.setDouble('min_profit_percent', percent);
    _logger.d('Min profit percent set to: $percent%');
  }

  /// Отримання мінімального відсотка прибутку
  double getMinProfitPercent() {
    return prefs.getDouble('min_profit_percent') ?? AppConfig.minProfitPercent;
  }

  /// Збереження максимального розміру позиції
  Future<void> setMaxPositionSize(double size) async {
    await prefs.setDouble('max_position_size', size);
    _logger.d('Max position size set to: \$$size');
  }

  /// Отримання максимального розміру позиції
  double getMaxPositionSize() {
    return prefs.getDouble('max_position_size') ?? AppConfig.maxPositionSize;
  }

  /// Збереження денного ліміту угод
  Future<void> setDailyTradesLimit(int limit) async {
    await prefs.setInt('daily_trades_limit', limit);
    _logger.d('Daily trades limit set to: $limit');
  }

  /// Отримання денного ліміту угод
  int getDailyTradesLimit() {
    return prefs.getInt('daily_trades_limit') ?? 100;
  }

  /// Збереження максимального денного збитку
  Future<void> setMaxDailyLoss(double amount) async {
    await prefs.setDouble('max_daily_loss', amount);
    _logger.d('Max daily loss set to: \$$amount');
  }

  /// Отримання максимального денного збитку
  double getMaxDailyLoss() {
    return prefs.getDouble('max_daily_loss') ?? 1000.0;
  }

  // ============= Notification Settings =============

  /// Збереження статусу сповіщень про можливості
  Future<void> setOpportunityNotificationsEnabled(bool enabled) async {
    await prefs.setBool('opportunity_notifications', enabled);
  }

  /// Отримання статусу сповіщень про можливості
  bool isOpportunityNotificationsEnabled() {
    return prefs.getBool('opportunity_notifications') ?? true;
  }

  /// Збереження статусу сповіщень про угоди
  Future<void> setTradeNotificationsEnabled(bool enabled) async {
    await prefs.setBool('trade_notifications', enabled);
  }

  /// Отримання статусу сповіщень про угоди
  bool isTradeNotificationsEnabled() {
    return prefs.getBool('trade_notifications') ?? true;
  }

  // ============= Onboarding =============

  /// Збереження статусу завершення onboarding
  Future<void> setOnboardingCompleted(bool completed) async {
    await prefs.setBool('onboarding_completed', completed);
  }

  /// Перевірка чи пройдено onboarding
  bool isOnboardingCompleted() {
    return prefs.getBool('onboarding_completed') ?? false;
  }

  // ============= First Launch =============

  /// Збереження першого запуску
  Future<void> setFirstLaunch(bool isFirst) async {
    await prefs.setBool('is_first_launch', isFirst);
  }

  /// Перевірка чи це перший запуск
  bool isFirstLaunch() {
    return prefs.getBool('is_first_launch') ?? true;
  }

  // ============= Last Sync =============

  /// Збереження часу останньої синхронізації
  Future<void> setLastSyncTime(DateTime time) async {
    await prefs.setInt('last_sync_time', time.millisecondsSinceEpoch);
  }

  /// Отримання часу останньої синхронізації
  DateTime? getLastSyncTime() {
    final timestamp = prefs.getInt('last_sync_time');
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  // ============= Generic Operations =============

  /// Збереження String
  Future<void> setString(String key, String value) async {
    await prefs.setString(key, value);
  }

  /// Отримання String
  String? getString(String key) {
    return prefs.getString(key);
  }

  /// Збереження int
  Future<void> setInt(String key, int value) async {
    await prefs.setInt(key, value);
  }

  /// Отримання int
  int? getInt(String key) {
    return prefs.getInt(key);
  }

  /// Збереження double
  Future<void> setDouble(String key, double value) async {
    await prefs.setDouble(key, value);
  }

  /// Отримання double
  double? getDouble(String key) {
    return prefs.getDouble(key);
  }

  /// Збереження bool
  Future<void> setBool(String key, bool value) async {
    await prefs.setBool(key, value);
  }

  /// Отримання bool
  bool? getBool(String key) {
    return prefs.getBool(key);
  }

  /// Видалення ключа
  Future<void> remove(String key) async {
    await prefs.remove(key);
  }

  /// Перевірка наявності ключа
  bool containsKey(String key) {
    return prefs.containsKey(key);
  }

  /// Очищення всіх налаштувань
  Future<void> clearAll() async {
    await prefs.clear();
    _logger.w('All preferences cleared');
  }
}
