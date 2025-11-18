import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/risk_settings.dart';
import 'providers.dart';

/// Provider для налаштувань ризик-менеджменту
final riskSettingsProvider = StateNotifierProvider<RiskSettingsNotifier, RiskSettings>((ref) {
  return RiskSettingsNotifier(ref.watch(storageRepositoryProvider));
});

/// Notifier для управління налаштуваннями ризиків
class RiskSettingsNotifier extends StateNotifier<RiskSettings> {
  final dynamic _storageRepository;

  RiskSettingsNotifier(this._storageRepository) : super(RiskSettings.defaultSettings()) {
    _loadSettings();
  }

  /// Завантаження налаштувань
  Future<void> _loadSettings() async {
    try {
      final settingsMap = _storageRepository.getTradingSettings() as Map<String, dynamic>;
      state = RiskSettings.fromMap(settingsMap);
    } catch (e) {
      // Використовуємо дефолтні налаштування
      state = RiskSettings.defaultSettings();
    }
  }

  /// Оновлення налаштувань
  Future<void> updateSettings(RiskSettings newSettings) async {
    try {
      await _storageRepository.saveTradingSettings(
        autoTradingEnabled: newSettings.autoTradingEnabled,
        minProfitPercent: newSettings.minProfitPercent,
        maxPositionSize: newSettings.maxPositionSize,
        dailyTradesLimit: newSettings.maxDailyTrades,
        maxDailyLoss: newSettings.maxDailyLoss,
      );
      state = newSettings;
    } catch (e) {
      // Помилка при збереженні
      rethrow;
    }
  }

  /// Включення/вимкнення автоторгівлі
  Future<void> toggleAutoTrading() async {
    final newSettings = state.copyWith(
      autoTradingEnabled: !state.autoTradingEnabled,
    );
    await updateSettings(newSettings);
  }

  /// Встановлення мінімального відсотка прибутку
  Future<void> setMinProfitPercent(double percent) async {
    final newSettings = state.copyWith(minProfitPercent: percent);
    await updateSettings(newSettings);
  }

  /// Встановлення максимального розміру позиції
  Future<void> setMaxPositionSize(double size) async {
    final newSettings = state.copyWith(maxPositionSize: size);
    await updateSettings(newSettings);
  }

  /// Встановлення денного ліміту угод
  Future<void> setDailyTradesLimit(int limit) async {
    final newSettings = state.copyWith(maxDailyTrades: limit);
    await updateSettings(newSettings);
  }

  /// Встановлення максимального денного збитку
  Future<void> setMaxDailyLoss(double loss) async {
    final newSettings = state.copyWith(maxDailyLoss: loss);
    await updateSettings(newSettings);
  }

  /// Скидання до дефолтних налаштувань
  Future<void> resetToDefaults() async {
    await updateSettings(RiskSettings.defaultSettings());
  }
}

/// Provider для режиму теми
final themeModeProvider = StateProvider<String>((ref) {
  final storageRepository = ref.watch(storageRepositoryProvider);
  return storageRepository.getThemeMode();
});

/// Provider для налаштувань сповіщень
final notificationSettingsProvider = Provider<Map<String, bool>>((ref) {
  final storageRepository = ref.watch(storageRepositoryProvider);
  return storageRepository.getNotificationSettings();
});
