/// Налаштування ризик-менеджменту
class RiskSettings {
  /// Максимальний розмір позиції в USD
  final double maxPositionSize;

  /// Денний ліміт угод
  final int maxDailyTrades;

  /// Максимальний денний збиток в USD
  final double maxDailyLoss;

  /// Мінімальний відсоток прибутку для виконання угоди
  final double minProfitPercent;

  /// Чи включено автоматичну торгівлю
  final bool autoTradingEnabled;

  const RiskSettings({
    required this.maxPositionSize,
    required this.maxDailyTrades,
    required this.maxDailyLoss,
    required this.minProfitPercent,
    this.autoTradingEnabled = false,
  });

  /// Дефолтні налаштування
  factory RiskSettings.defaultSettings() {
    return const RiskSettings(
      maxPositionSize: 1000.0,
      maxDailyTrades: 50,
      maxDailyLoss: 500.0,
      minProfitPercent: 0.5,
      autoTradingEnabled: false,
    );
  }

  /// Створення з Map
  factory RiskSettings.fromMap(Map<String, dynamic> map) {
    return RiskSettings(
      maxPositionSize: map['maxPositionSize'] as double? ?? 1000.0,
      maxDailyTrades: map['dailyTradesLimit'] as int? ?? 50,
      maxDailyLoss: map['maxDailyLoss'] as double? ?? 500.0,
      minProfitPercent: map['minProfitPercent'] as double? ?? 0.5,
      autoTradingEnabled: map['autoTradingEnabled'] as bool? ?? false,
    );
  }

  /// Конвертація в Map
  Map<String, dynamic> toMap() {
    return {
      'maxPositionSize': maxPositionSize,
      'dailyTradesLimit': maxDailyTrades,
      'maxDailyLoss': maxDailyLoss,
      'minProfitPercent': minProfitPercent,
      'autoTradingEnabled': autoTradingEnabled,
    };
  }

  /// Копіювання з зміною полів
  RiskSettings copyWith({
    double? maxPositionSize,
    int? maxDailyTrades,
    double? maxDailyLoss,
    double? minProfitPercent,
    bool? autoTradingEnabled,
  }) {
    return RiskSettings(
      maxPositionSize: maxPositionSize ?? this.maxPositionSize,
      maxDailyTrades: maxDailyTrades ?? this.maxDailyTrades,
      maxDailyLoss: maxDailyLoss ?? this.maxDailyLoss,
      minProfitPercent: minProfitPercent ?? this.minProfitPercent,
      autoTradingEnabled: autoTradingEnabled ?? this.autoTradingEnabled,
    );
  }
}
