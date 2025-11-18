/// Конфігурація додатку
class AppConfig {
  // API URLs
  static const String wsUrl = 'wss://your-server.com/ws';
  static const String apiUrl = 'https://your-server.com/api';

  // App Info
  static const String appName = 'Premium Trading';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // WebSocket
  static const Duration wsReconnectDelay = Duration(seconds: 2);
  static const int wsMaxReconnectAttempts = 5;
  static const Duration wsHeartbeatInterval = Duration(seconds: 30);

  // API
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration apiConnectTimeout = Duration(seconds: 15);
  static const Duration apiReceiveTimeout = Duration(seconds: 30);

  // Database
  static const String dbName = 'premium_trading.db';
  static const int dbVersion = 1;

  // Cache
  static const Duration cacheDuration = Duration(hours: 1);
  static const int maxCacheSize = 100; // MB

  // UI
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration snackbarDuration = Duration(seconds: 3);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Trading
  static const Duration opportunityExpiration = Duration(seconds: 30);
  static const double minProfitPercent = 0.1;
  static const double maxPositionSize = 10000.0;

  // Security
  static const Duration tokenRefreshThreshold = Duration(minutes: 5);
  static const int maxLoginAttempts = 3;
  static const Duration lockoutDuration = Duration(minutes: 15);
}
