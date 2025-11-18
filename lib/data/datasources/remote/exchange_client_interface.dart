/// Результат виконання ордера
class OrderResult {
  final bool success;
  final String? orderId;
  final double filledAmount;
  final double totalSpent;
  final double totalReceived;
  final String? error;

  OrderResult({
    required this.success,
    this.orderId,
    this.filledAmount = 0.0,
    this.totalSpent = 0.0,
    this.totalReceived = 0.0,
    this.error,
  });
}

/// Баланс на біржі
class ExchangeBalance {
  final String asset;
  final double free;
  final double locked;
  final double total;

  ExchangeBalance({
    required this.asset,
    required this.free,
    required this.locked,
    required this.total,
  });
}

/// Базовий інтерфейс для біржових клієнтів
abstract class ExchangeClientInterface {
  /// Ініціалізація клієнта з API ключами
  void initialize(String apiKey, String apiSecret);

  /// Розміщення ордера на купівлю (market order)
  Future<OrderResult> placeBuyOrder({
    required String symbol,
    required double amount,
    double? price,
  });

  /// Розміщення ордера на продаж (market order)
  Future<OrderResult> placeSellOrder({
    required String symbol,
    required double amount,
    double? price,
  });

  /// Отримання балансу для конкретного активу
  Future<ExchangeBalance?> getBalance(String asset);

  /// Перевірка з'єднання з API
  Future<bool> testConnection();

  /// Отримання інформації про символ/пару
  Future<Map<String, dynamic>?> getSymbolInfo(String symbol);
}
