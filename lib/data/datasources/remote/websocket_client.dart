import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:logger/logger.dart';

import '../../../core/config/app_config.dart';
import '../../../core/errors/exceptions.dart';
import '../../models/opportunity_model.dart';

/// WebSocket клієнт для підключення до сервера арбітражних можливостей
class WebSocketClient {
  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _messageController;
  StreamController<ArbitrageOpportunity>? _opportunitiesController;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  bool _isConnected = false;
  bool _isDisposed = false;

  String? _url;
  String? _token;

  final Logger _logger = Logger();

  /// Stream для отримання всіх повідомлень
  Stream<Map<String, dynamic>> get messageStream =>
      _messageController?.stream ?? const Stream.empty();

  /// Stream для отримання можливостей
  Stream<ArbitrageOpportunity> get opportunitiesStream =>
      _opportunitiesController?.stream ?? const Stream.empty();

  /// Чи підключений клієнт
  bool get isConnected => _isConnected;

  /// Підключення до WebSocket сервера
  Future<void> connect(String url, String token) async {
    if (_isDisposed) {
      throw const WebSocketException('WebSocket client is disposed');
    }

    _url = url;
    _token = token;

    try {
      _logger.i('Connecting to WebSocket: $url');

      // Створюємо контролери, якщо їх ще немає
      _messageController ??= StreamController<Map<String, dynamic>>.broadcast();
      _opportunitiesController ??= StreamController<ArbitrageOpportunity>.broadcast();

      // Підключаємось до WebSocket з токеном в заголовку
      _channel = WebSocketChannel.connect(
        Uri.parse(url),
      );

      // Слухаємо повідомлення
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDone,
        cancelOnError: false,
      );

      _isConnected = true;
      _reconnectAttempts = 0;

      // Запускаємо heartbeat
      _startHeartbeat();

      _logger.i('WebSocket connected successfully');
    } catch (e) {
      _logger.e('Failed to connect to WebSocket: $e');
      _isConnected = false;
      throw WebSocketException('Failed to connect: $e');
    }
  }

  /// Відключення від WebSocket
  Future<void> disconnect() async {
    _logger.i('Disconnecting from WebSocket');

    _isConnected = false;
    _stopHeartbeat();
    _stopReconnectTimer();

    await _channel?.sink.close();
    _channel = null;
  }

  /// Обробка вхідного повідомлення
  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      _logger.d('Received WebSocket message: ${data['type']}');

      // Відправляємо в загальний stream
      _messageController?.add(data);

      // Обробляємо різні типи повідомлень
      final type = data['type'] as String?;

      switch (type) {
        case 'opportunity':
          _handleOpportunity(data);
          break;
        case 'ping':
          _handlePing();
          break;
        case 'error':
          _handleServerError(data);
          break;
        default:
          _logger.w('Unknown message type: $type');
      }
    } catch (e) {
      _logger.e('Failed to parse WebSocket message: $e');
    }
  }

  /// Обробка можливості
  void _handleOpportunity(Map<String, dynamic> data) {
    try {
      final opportunityData = data['data'] as Map<String, dynamic>;
      final opportunity = ArbitrageOpportunity.fromJson(opportunityData);
      _opportunitiesController?.add(opportunity);
    } catch (e) {
      _logger.e('Failed to parse opportunity: $e');
    }
  }

  /// Обробка ping від сервера
  void _handlePing() {
    _logger.d('Received ping, sending pong');
    sendMessage({'type': 'pong'});
  }

  /// Обробка помилки від сервера
  void _handleServerError(Map<String, dynamic> data) {
    final error = data['error'] as String?;
    _logger.e('Server error: $error');
  }

  /// Обробка помилки з'єднання
  void _handleError(dynamic error) {
    _logger.e('WebSocket error: $error');
    _isConnected = false;
    _attemptReconnect();
  }

  /// Обробка закриття з'єднання
  void _handleDone() {
    _logger.w('WebSocket connection closed');
    _isConnected = false;
    _stopHeartbeat();
    _attemptReconnect();
  }

  /// Спроба перепідключення
  void _attemptReconnect() {
    if (_isDisposed) return;

    if (_reconnectAttempts >= AppConfig.wsMaxReconnectAttempts) {
      _logger.e('Max reconnect attempts reached');
      return;
    }

    _reconnectAttempts++;
    final delay = AppConfig.wsReconnectDelay * _reconnectAttempts;

    _logger.i('Attempting to reconnect in ${delay.inSeconds}s (attempt $_reconnectAttempts)');

    _reconnectTimer = Timer(delay, () {
      if (_url != null && _token != null && !_isDisposed) {
        connect(_url!, _token!).catchError((e) {
          _logger.e('Reconnect failed: $e');
        });
      }
    });
  }

  /// Запуск heartbeat таймера
  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(
      AppConfig.wsHeartbeatInterval,
      (_) {
        if (_isConnected) {
          _logger.d('Sending heartbeat ping');
          sendMessage({'type': 'ping'});
        }
      },
    );
  }

  /// Зупинка heartbeat таймера
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Зупинка таймера перепідключення
  void _stopReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  /// Відправка повідомлення на сервер
  void sendMessage(Map<String, dynamic> message) {
    if (!_isConnected) {
      _logger.w('Cannot send message: not connected');
      return;
    }

    try {
      final json = jsonEncode(message);
      _channel?.sink.add(json);
      _logger.d('Sent message: ${message['type']}');
    } catch (e) {
      _logger.e('Failed to send message: $e');
    }
  }

  /// Відправка результату угоди
  void sendTradeResult({
    required int opportunityId,
    required String status,
    String? buyOrderId,
    String? sellOrderId,
    double? actualProfit,
    double? actualProfitPercent,
    int? executionTimeMs,
    String? error,
  }) {
    sendMessage({
      'type': 'trade_result',
      'data': {
        'opportunity_id': opportunityId,
        'status': status,
        if (buyOrderId != null) 'buy_order_id': buyOrderId,
        if (sellOrderId != null) 'sell_order_id': sellOrderId,
        if (actualProfit != null) 'actual_profit': actualProfit,
        if (actualProfitPercent != null) 'actual_profit_percent': actualProfitPercent,
        if (executionTimeMs != null) 'execution_time_ms': executionTimeMs,
        if (error != null) 'error': error,
      },
    });
  }

  /// Очищення ресурсів
  void dispose() {
    _logger.i('Disposing WebSocket client');
    _isDisposed = true;

    disconnect();
    _messageController?.close();
    _opportunitiesController?.close();

    _messageController = null;
    _opportunitiesController = null;
  }
}
