import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import 'exchange_client_interface.dart';

/// Binance API клієнт
/// Документація: https://binance-docs.github.io/apidocs/spot/en/
class BinanceClient implements ExchangeClientInterface {
  static const String _baseUrl = 'https://api.binance.com';

  late final Dio _dio;
  final Logger _logger = Logger();

  String? _apiKey;
  String? _apiSecret;

  BinanceClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
  }

  @override
  void initialize(String apiKey, String apiSecret) {
    _apiKey = apiKey;
    _apiSecret = apiSecret;
    _logger.i('Binance client initialized');
  }

  /// Генерація підпису для запиту
  String _generateSignature(String queryString) {
    if (_apiSecret == null) {
      throw Exception('API Secret not initialized');
    }

    final key = utf8.encode(_apiSecret!);
    final bytes = utf8.encode(queryString);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);

    return digest.toString();
  }

  /// Виконання підписаного запиту
  Future<Response> _signedRequest(
    String method,
    String path,
    Map<String, dynamic> params,
  ) async {
    if (_apiKey == null || _apiSecret == null) {
      throw Exception('API credentials not initialized');
    }

    // Додаємо timestamp
    params['timestamp'] = DateTime.now().millisecondsSinceEpoch;

    // Створюємо query string
    final queryString = params.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');

    // Генеруємо підпис
    final signature = _generateSignature(queryString);

    // Додаємо підпис до параметрів
    final signedParams = '$queryString&signature=$signature';

    _logger.d('$method $path');

    try {
      final response = await _dio.request(
        '$path?$signedParams',
        options: Options(
          method: method,
          headers: {
            'X-MBX-APIKEY': _apiKey!,
          },
        ),
      );

      return response;
    } on DioException catch (e) {
      _logger.e('Binance API error: ${e.response?.data}');
      rethrow;
    }
  }

  @override
  Future<OrderResult> placeBuyOrder({
    required String symbol,
    required double amount,
    double? price,
  }) async {
    try {
      _logger.i('Placing BUY order: $symbol, amount: $amount');

      // Використовуємо MARKET order для швидкості
      final params = {
        'symbol': symbol.toUpperCase(),
        'side': 'BUY',
        'type': 'MARKET',
        'quantity': amount.toStringAsFixed(8),
      };

      final response = await _signedRequest('POST', '/api/v3/order', params);

      final data = response.data as Map<String, dynamic>;
      final orderId = data['orderId'].toString();
      final executedQty = double.parse(data['executedQty'].toString());

      // Розрахунок загальної вартості
      double totalSpent = 0.0;
      if (data['fills'] != null) {
        for (var fill in data['fills']) {
          final qty = double.parse(fill['qty'].toString());
          final price = double.parse(fill['price'].toString());
          totalSpent += qty * price;
        }
      }

      _logger.i('Buy order executed: $orderId');

      return OrderResult(
        success: true,
        orderId: orderId,
        filledAmount: executedQty,
        totalSpent: totalSpent,
      );
    } catch (e) {
      _logger.e('Buy order failed: $e');
      return OrderResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  @override
  Future<OrderResult> placeSellOrder({
    required String symbol,
    required double amount,
    double? price,
  }) async {
    try {
      _logger.i('Placing SELL order: $symbol, amount: $amount');

      // Використовуємо MARKET order для швидкості
      final params = {
        'symbol': symbol.toUpperCase(),
        'side': 'SELL',
        'type': 'MARKET',
        'quantity': amount.toStringAsFixed(8),
      };

      final response = await _signedRequest('POST', '/api/v3/order', params);

      final data = response.data as Map<String, dynamic>;
      final orderId = data['orderId'].toString();
      final executedQty = double.parse(data['executedQty'].toString());

      // Розрахунок загальної отриманої суми
      double totalReceived = 0.0;
      if (data['fills'] != null) {
        for (var fill in data['fills']) {
          final qty = double.parse(fill['qty'].toString());
          final price = double.parse(fill['price'].toString());
          totalReceived += qty * price;
        }
      }

      _logger.i('Sell order executed: $orderId');

      return OrderResult(
        success: true,
        orderId: orderId,
        filledAmount: executedQty,
        totalReceived: totalReceived,
      );
    } catch (e) {
      _logger.e('Sell order failed: $e');
      return OrderResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  @override
  Future<ExchangeBalance?> getBalance(String asset) async {
    try {
      final response = await _signedRequest('GET', '/api/v3/account', {});

      final data = response.data as Map<String, dynamic>;
      final balances = data['balances'] as List<dynamic>;

      for (var balance in balances) {
        if (balance['asset'] == asset.toUpperCase()) {
          final free = double.parse(balance['free'].toString());
          final locked = double.parse(balance['locked'].toString());

          return ExchangeBalance(
            asset: asset.toUpperCase(),
            free: free,
            locked: locked,
            total: free + locked,
          );
        }
      }

      return null;
    } catch (e) {
      _logger.e('Failed to get balance: $e');
      return null;
    }
  }

  @override
  Future<bool> testConnection() async {
    try {
      // Перевіряємо підключення через публічний endpoint
      final response = await _dio.get('/api/v3/ping');

      if (response.statusCode == 200) {
        // Якщо є API ключі, перевіряємо їх
        if (_apiKey != null && _apiSecret != null) {
          final accountResponse = await _signedRequest('GET', '/api/v3/account', {});
          return accountResponse.statusCode == 200;
        }
        return true;
      }

      return false;
    } catch (e) {
      _logger.e('Connection test failed: $e');
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>?> getSymbolInfo(String symbol) async {
    try {
      final response = await _dio.get('/api/v3/exchangeInfo');

      final data = response.data as Map<String, dynamic>;
      final symbols = data['symbols'] as List<dynamic>;

      for (var symbolData in symbols) {
        if (symbolData['symbol'] == symbol.toUpperCase()) {
          return symbolData as Map<String, dynamic>;
        }
      }

      return null;
    } catch (e) {
      _logger.e('Failed to get symbol info: $e');
      return null;
    }
  }
}
