/// Базовий клас для всіх винятків додатку
abstract class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, [this.code]);

  @override
  String toString() => 'AppException: $message${code != null ? ' (code: $code)' : ''}';
}

/// Помилка мережі
class NetworkException extends AppException {
  const NetworkException([String message = 'Network error occurred', String? code])
      : super(message, code);
}

/// Помилка автентифікації
class AuthException extends AppException {
  const AuthException([String message = 'Authentication failed', String? code])
      : super(message, code);
}

/// Помилка валідації
class ValidationException extends AppException {
  const ValidationException([String message = 'Validation failed', String? code])
      : super(message, code);
}

/// Помилка сервера
class ServerException extends AppException {
  const ServerException([String message = 'Server error occurred', String? code])
      : super(message, code);
}

/// Помилка даних
class DataException extends AppException {
  const DataException([String message = 'Data error occurred', String? code])
      : super(message, code);
}

/// Помилка кешу
class CacheException extends AppException {
  const CacheException([String message = 'Cache error occurred', String? code])
      : super(message, code);
}

/// Помилка WebSocket
class WebSocketException extends AppException {
  const WebSocketException([String message = 'WebSocket error occurred', String? code])
      : super(message, code);
}

/// Помилка торгівлі
class TradingException extends AppException {
  const TradingException([String message = 'Trading error occurred', String? code])
      : super(message, code);
}

/// Невідома помилка
class UnknownException extends AppException {
  const UnknownException([String message = 'Unknown error occurred', String? code])
      : super(message, code);
}
