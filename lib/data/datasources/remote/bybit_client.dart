import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import 'exchange_client_interface.dart';

/// Bybit API клієнт (V5 API)
/// Документація: https://bybit-exchange.github.io/docs/v5/intro
class BybitClient implements ExchangeClientInterface {
  static const String _baseUrl = 'https://api.bybit.com';

  late final Dio _dio;
  final Logger _logger = Logger();

  String? _apiKey;
  String? _apiSecret;

  BybitClient() {
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
    _logger.i('Bybit client initialized');
  }

  /// Генерація підпису для запиту (V5 API)
  String _generateSignature(String timestamp, String payload) {
    if (_apiSecret == null) {
      throw Exception('API Secret not initialized');
    }

    final preHash = '$timestamp$_apiKey$payload';
    final key = utf8.encode(_apiSecret!);
    final bytes = utf8.encode(preHash);
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

    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final payload = method == 'GET'
        ? params.entries.map((e) => '${e.key}=${e.value}').join('&')
        : jsonEncode(params);

    final signature = _generateSignature(timestamp, payload);

    _logger.d('$method $path');

    try {
      final response = await _dio.request(
        path,
        options: Options(
          method: method,
          headers: {
            'X-BAPI-API-KEY': _apiKey!,
            'X-BAPI-SIGN': signature,
            'X-BAPI-TIMESTAMP': timestamp,
            'X-BAPI-SIGN-TYPE': '2',
            'Content-Type': 'application/json',
          },
        ),
        data: method == 'POST' ? params : null,
        queryParameters: method == 'GET' ? params : null,
      );

      return response;
    } on DioException catch (e) {
      _logger.e('Bybit API error: ${e.response?.data}');
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

      final params = {
        'category': 'spot',
        'symbol': symbol.toUpperCase(),
        'side': 'Buy',
        'orderType': 'Market',
        'qty': amount.toStringAsFixed(8),
      };

      final response = await _signedRequest('POST', '/v5/order/create', params);

      final data = response.data as Map<String, dynamic>;

      if (data['retCode'] != 0) {
        throw Exception(data['retMsg'] ?? 'Order failed');
      }

      final result = data['result'] as Map<String, dynamic>;
      final orderId = result['orderId'].toString();

      _logger.i('Buy order placed: $orderId');

      // Bybit повертає лише order ID, потрібен окремий запит для деталей
      // Для простоти використовуємо апроксимацію
      return OrderResult(
        success: true,
        orderId: orderId,
        filledAmount: amount,
        totalSpent: price != null ? amount * price : 0.0,
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

      final params = {
        'category': 'spot',
        'symbol': symbol.toUpperCase(),
        'side': 'Sell',
        'orderType': 'Market',
        'qty': amount.toStringAsFixed(8),
      };

      final response = await _signedRequest('POST', '/v5/order/create', params);

      final data = response.data as Map<String, dynamic>;

      if (data['retCode'] != 0) {
        throw Exception(data['retMsg'] ?? 'Order failed');
      }

      final result = data['result'] as Map<String, dynamic>;
      final orderId = result['orderId'].toString();

      _logger.i('Sell order placed: $orderId');

      // Для простоти використовуємо апроксимацію
      return OrderResult(
        success: true,
        orderId: orderId,
        filledAmount: amount,
        totalReceived: price != null ? amount * price : 0.0,
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
      final params = {
        'accountType': 'SPOT',
        'coin': asset.toUpperCase(),
      };

      final response = await _signedRequest('GET', '/v5/account/wallet-balance', params);

      final data = response.data as Map<String, dynamic>;

      if (data['retCode'] != 0) {
        throw Exception(data['retMsg'] ?? 'Failed to get balance');
      }

      final result = data['result'] as Map<String, dynamic>;
      final list = result['list'] as List<dynamic>;

      if (list.isEmpty) return null;

      final account = list[0] as Map<String, dynamic>;
      final coins = account['coin'] as List<dynamic>;

      for (var coin in coins) {
        if (coin['coin'] == asset.toUpperCase()) {
          final free = double.parse(coin['walletBalance'].toString());
          final locked = double.parse(coin['locked'].toString());

          return ExchangeBalance(
            asset: asset.toUpperCase(),
            free: free - locked,
            locked: locked,
            total: free,
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
      final response = await _dio.get('/v5/market/time');

      if (response.statusCode == 200) {
        // Якщо є API ключі, перевіряємо їх
        if (_apiKey != null && _apiSecret != null) {
          final balanceResponse = await _signedRequest(
            'GET',
            '/v5/account/wallet-balance',
            {'accountType': 'SPOT'},
          );

          final data = balanceResponse.data as Map<String, dynamic>;
          return data['retCode'] == 0;
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
      final params = {
        'category': 'spot',
        'symbol': symbol.toUpperCase(),
      };

      final response = await _dio.get(
        '/v5/market/instruments-info',
        queryParameters: params,
      );

      final data = response.data as Map<String, dynamic>;

      if (data['retCode'] != 0) {
        return null;
      }

      final result = data['result'] as Map<String, dynamic>;
      final list = result['list'] as List<dynamic>;

      if (list.isEmpty) return null;

      return list[0] as Map<String, dynamic>;
    } catch (e) {
      _logger.e('Failed to get symbol info: $e');
      return null;
    }
  }
}
