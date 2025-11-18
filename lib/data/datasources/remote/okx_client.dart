import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import 'exchange_client_interface.dart';

/// OKX API клієнт
/// Документація: https://www.okx.com/docs-v5/en/
class OkxClient implements ExchangeClientInterface {
  static const String _baseUrl = 'https://www.okx.com';

  late final Dio _dio;
  final Logger _logger = Logger();

  String? _apiKey;
  String? _apiSecret;
  String? _passphrase;

  OkxClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
  }

  @override
  void initialize(String apiKey, String apiSecret, [String? passphrase]) {
    _apiKey = apiKey;
    _apiSecret = apiSecret;
    _passphrase = passphrase ?? ''; // OKX потребує passphrase
    _logger.i('OKX client initialized');
  }

  /// Генерація підпису для запиту
  String _generateSignature(String timestamp, String method, String requestPath, String body) {
    if (_apiSecret == null) {
      throw Exception('API Secret not initialized');
    }

    final preHash = '$timestamp$method$requestPath$body';
    final key = utf8.encode(_apiSecret!);
    final bytes = utf8.encode(preHash);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);

    return base64.encode(digest.bytes);
  }

  /// Виконання підписаного запиту
  Future<Response> _signedRequest(
    String method,
    String path,
    Map<String, dynamic>? params,
  ) async {
    if (_apiKey == null || _apiSecret == null) {
      throw Exception('API credentials not initialized');
    }

    final timestamp = DateTime.now().toUtc().toIso8601String().replaceAll(RegExp(r'\.\d+'), '');
    final body = params != null && method == 'POST' ? jsonEncode(params) : '';
    final signature = _generateSignature(timestamp, method, path, body);

    _logger.d('$method $path');

    try {
      final response = await _dio.request(
        path,
        options: Options(
          method: method,
          headers: {
            'OK-ACCESS-KEY': _apiKey!,
            'OK-ACCESS-SIGN': signature,
            'OK-ACCESS-TIMESTAMP': timestamp,
            'OK-ACCESS-PASSPHRASE': _passphrase!,
            'Content-Type': 'application/json',
          },
        ),
        data: body.isNotEmpty ? body : null,
        queryParameters: method == 'GET' ? params : null,
      );

      return response;
    } on DioException catch (e) {
      _logger.e('OKX API error: ${e.response?.data}');
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

      // OKX використовує формат BTC-USDT
      final instId = symbol.toUpperCase().replaceAll('/', '-');

      final params = {
        'instId': instId,
        'tdMode': 'cash', // cash trading (spot)
        'side': 'buy',
        'ordType': 'market',
        'sz': amount.toStringAsFixed(8),
      };

      final response = await _signedRequest('POST', '/api/v5/trade/order', params);

      final data = response.data as Map<String, dynamic>;

      if (data['code'] != '0') {
        throw Exception(data['msg'] ?? 'Order failed');
      }

      final dataList = data['data'] as List<dynamic>;
      if (dataList.isEmpty) {
        throw Exception('No order data returned');
      }

      final result = dataList[0] as Map<String, dynamic>;
      final orderId = result['ordId'].toString();

      _logger.i('Buy order placed: $orderId');

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

      // OKX використовує формат BTC-USDT
      final instId = symbol.toUpperCase().replaceAll('/', '-');

      final params = {
        'instId': instId,
        'tdMode': 'cash', // cash trading (spot)
        'side': 'sell',
        'ordType': 'market',
        'sz': amount.toStringAsFixed(8),
      };

      final response = await _signedRequest('POST', '/api/v5/trade/order', params);

      final data = response.data as Map<String, dynamic>;

      if (data['code'] != '0') {
        throw Exception(data['msg'] ?? 'Order failed');
      }

      final dataList = data['data'] as List<dynamic>;
      if (dataList.isEmpty) {
        throw Exception('No order data returned');
      }

      final result = dataList[0] as Map<String, dynamic>;
      final orderId = result['ordId'].toString();

      _logger.i('Sell order placed: $orderId');

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
        'ccy': asset.toUpperCase(),
      };

      final response = await _signedRequest('GET', '/api/v5/account/balance', params);

      final data = response.data as Map<String, dynamic>;

      if (data['code'] != '0') {
        throw Exception(data['msg'] ?? 'Failed to get balance');
      }

      final dataList = data['data'] as List<dynamic>;
      if (dataList.isEmpty) return null;

      final account = dataList[0] as Map<String, dynamic>;
      final details = account['details'] as List<dynamic>;

      for (var detail in details) {
        if (detail['ccy'] == asset.toUpperCase()) {
          final availBal = double.parse(detail['availBal'].toString());
          final frozenBal = double.parse(detail['frozenBal'].toString());
          final eq = double.parse(detail['eq'].toString());

          return ExchangeBalance(
            asset: asset.toUpperCase(),
            free: availBal,
            locked: frozenBal,
            total: eq,
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
      final response = await _dio.get('/api/v5/public/time');

      final data = response.data as Map<String, dynamic>;

      if (data['code'] == '0') {
        // Якщо є API ключі, перевіряємо їх
        if (_apiKey != null && _apiSecret != null) {
          final balanceResponse = await _signedRequest(
            'GET',
            '/api/v5/account/balance',
            null,
          );

          final balanceData = balanceResponse.data as Map<String, dynamic>;
          return balanceData['code'] == '0';
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
      // OKX використовує формат BTC-USDT
      final instId = symbol.toUpperCase().replaceAll('/', '-');

      final params = {
        'instType': 'SPOT',
        'instId': instId,
      };

      final response = await _dio.get(
        '/api/v5/public/instruments',
        queryParameters: params,
      );

      final data = response.data as Map<String, dynamic>;

      if (data['code'] != '0') {
        return null;
      }

      final dataList = data['data'] as List<dynamic>;
      if (dataList.isEmpty) return null;

      return dataList[0] as Map<String, dynamic>;
    } catch (e) {
      _logger.e('Failed to get symbol info: $e');
      return null;
    }
  }
}
