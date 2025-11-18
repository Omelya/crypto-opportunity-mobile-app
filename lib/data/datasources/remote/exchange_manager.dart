import 'package:logger/logger.dart';

import '../local/secure_storage.dart';
import 'binance_client.dart';
import 'bybit_client.dart';
import 'okx_client.dart';
import 'exchange_client_interface.dart';

/// Менеджер для керування біржовими клієнтами
class ExchangeManager {
  final SecureStorageService _secureStorage;
  final Logger _logger = Logger();

  late final BinanceClient _binanceClient;
  late final BybitClient _bybitClient;
  late final OkxClient _okxClient;

  final Map<String, ExchangeClientInterface> _clients = {};

  ExchangeManager(this._secureStorage) {
    _binanceClient = BinanceClient();
    _bybitClient = BybitClient();
    _okxClient = OkxClient();

    _clients['binance'] = _binanceClient;
    _clients['bybit'] = _bybitClient;
    _clients['okx'] = _okxClient;

    _logger.i('ExchangeManager initialized');
  }

  /// Ініціалізація всіх налаштованих бірж з їх API ключами
  Future<void> initializeConfiguredExchanges() async {
    try {
      final exchanges = await _secureStorage.getConfiguredExchanges();

      for (var exchange in exchanges) {
        await initializeExchange(exchange);
      }

      _logger.i('Initialized ${exchanges.length} exchanges');
    } catch (e) {
      _logger.e('Failed to initialize exchanges: $e');
    }
  }

  /// Ініціалізація конкретної біржі
  Future<bool> initializeExchange(String exchange) async {
    try {
      final keys = await _secureStorage.getExchangeApiKeys(exchange);

      if (keys == null || keys['apiKey'] == null || keys['apiSecret'] == null) {
        _logger.w('No API keys found for $exchange');
        return false;
      }

      final client = _clients[exchange.toLowerCase()];

      if (client == null) {
        _logger.w('Unknown exchange: $exchange');
        return false;
      }

      client.initialize(keys['apiKey']!, keys['apiSecret']!);
      _logger.i('Initialized $exchange client');

      return true;
    } catch (e) {
      _logger.e('Failed to initialize $exchange: $e');
      return false;
    }
  }

  /// Отримання клієнта для конкретної біржі
  ExchangeClientInterface? getClient(String exchange) {
    final client = _clients[exchange.toLowerCase()];

    if (client == null) {
      _logger.w('Exchange client not found: $exchange');
    }

    return client;
  }

  /// Розміщення ордера на купівлю
  Future<OrderResult> placeBuyOrder({
    required String exchange,
    required String symbol,
    required double amount,
    double? price,
  }) async {
    final client = getClient(exchange);

    if (client == null) {
      return OrderResult(
        success: false,
        error: 'Exchange client not found: $exchange',
      );
    }

    try {
      return await client.placeBuyOrder(
        symbol: symbol,
        amount: amount,
        price: price,
      );
    } catch (e) {
      _logger.e('Buy order failed on $exchange: $e');
      return OrderResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Розміщення ордера на продаж
  Future<OrderResult> placeSellOrder({
    required String exchange,
    required String symbol,
    required double amount,
    double? price,
  }) async {
    final client = getClient(exchange);

    if (client == null) {
      return OrderResult(
        success: false,
        error: 'Exchange client not found: $exchange',
      );
    }

    try {
      return await client.placeSellOrder(
        symbol: symbol,
        amount: amount,
        price: price,
      );
    } catch (e) {
      _logger.e('Sell order failed on $exchange: $e');
      return OrderResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Перевірка балансу на біржі
  Future<ExchangeBalance?> getBalance(String exchange, String asset) async {
    final client = getClient(exchange);

    if (client == null) {
      _logger.w('Exchange client not found: $exchange');
      return null;
    }

    try {
      return await client.getBalance(asset);
    } catch (e) {
      _logger.e('Failed to get balance from $exchange: $e');
      return null;
    }
  }

  /// Тестування підключення до біржі
  Future<bool> testConnection(String exchange) async {
    final client = getClient(exchange);

    if (client == null) {
      return false;
    }

    try {
      return await client.testConnection();
    } catch (e) {
      _logger.e('Connection test failed for $exchange: $e');
      return false;
    }
  }

  /// Отримання інформації про символ
  Future<Map<String, dynamic>?> getSymbolInfo(
    String exchange,
    String symbol,
  ) async {
    final client = getClient(exchange);

    if (client == null) {
      return null;
    }

    try {
      return await client.getSymbolInfo(symbol);
    } catch (e) {
      _logger.e('Failed to get symbol info from $exchange: $e');
      return null;
    }
  }

  /// Перевірка чи налаштована біржа
  bool isExchangeConfigured(String exchange) {
    return _clients.containsKey(exchange.toLowerCase());
  }

  /// Список всіх підтримуваних бірж
  List<String> get supportedExchanges => _clients.keys.toList();
}
