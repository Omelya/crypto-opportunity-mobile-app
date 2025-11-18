/// Константи додатку
class AppConstants {
  // API Endpoints
  static const String authInit = '/auth/init';
  static const String authVerify = '/auth/verify';
  static const String authRefresh = '/auth/refresh';
  static const String statistics = '/statistics';
  static const String trades = '/trades';
  static const String exchanges = '/exchanges';

  // WebSocket Events
  static const String wsOpportunity = 'opportunity';
  static const String wsTradeResult = 'trade_result';
  static const String wsPing = 'ping';
  static const String wsPong = 'pong';
  static const String wsError = 'error';

  // Storage Keys
  static const String storageAuthToken = 'auth_token';
  static const String storageRefreshToken = 'refresh_token';
  static const String storageUserId = 'user_id';
  static const String storageThemeMode = 'theme_mode';
  static const String storageLanguage = 'language';

  // Secure Storage Keys (for API keys)
  static const String secureBinanceApiKey = 'binance_api_key';
  static const String secureBinanceApiSecret = 'binance_api_secret';
  static const String secureBybitApiKey = 'bybit_api_key';
  static const String secureBybitApiSecret = 'bybit_api_secret';
  static const String secureOkxApiKey = 'okx_api_key';
  static const String secureOkxApiSecret = 'okx_api_secret';

  // Exchanges
  static const String exchangeBinance = 'binance';
  static const String exchangeBybit = 'bybit';
  static const String exchangeOkx = 'okx';

  static const List<String> supportedExchanges = [
    exchangeBinance,
    exchangeBybit,
    exchangeOkx,
  ];

  // Trade Status
  static const String tradePending = 'pending';
  static const String tradeExecuting = 'executing';
  static const String tradeCompleted = 'completed';
  static const String tradeFailed = 'failed';
  static const String tradeStuck = 'stuck';

  // Error Codes
  static const String errorNetwork = 'network_error';
  static const String errorAuth = 'auth_error';
  static const String errorInvalidData = 'invalid_data';
  static const String errorServerError = 'server_error';
  static const String errorUnknown = 'unknown_error';

  // Validation
  static const int minTelegramIdLength = 5;
  static const int maxTelegramIdLength = 20;
  static const int verificationCodeLength = 6;
  static const int minApiKeyLength = 20;
  static const int maxApiKeyLength = 100;

  // UI
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 8.0;
  static const double cardElevation = 2.0;

  // Timeouts
  static const int splashDuration = 2; // seconds
  static const int retryDelay = 3; // seconds
  static const int maxRetries = 3;
}
