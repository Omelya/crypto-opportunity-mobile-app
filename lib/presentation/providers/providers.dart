import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/local/local_database.dart';
import '../../data/datasources/local/preferences_service.dart';
import '../../data/datasources/local/secure_storage.dart';
import '../../data/datasources/remote/api_client.dart';
import '../../data/datasources/remote/websocket_client.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/storage_repository.dart';
import '../../data/repositories/trading_repository.dart';
import '../../domain/usecases/execute_trade.dart';
import '../../domain/usecases/validate_risk.dart';

// ============= Data Sources =============

/// API Client Provider
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

/// WebSocket Client Provider
final webSocketClientProvider = Provider<WebSocketClient>((ref) {
  return WebSocketClient();
});

/// Local Database Provider
final localDatabaseProvider = Provider<LocalDatabase>((ref) {
  return LocalDatabase.instance;
});

/// Secure Storage Provider
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService.instance;
});

/// Preferences Service Provider
final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  return PreferencesService.instance;
});

// ============= Repositories =============

/// Auth Repository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    apiClient: ref.watch(apiClientProvider),
    secureStorage: ref.watch(secureStorageProvider),
  );
});

/// Trading Repository Provider
final tradingRepositoryProvider = Provider<TradingRepository>((ref) {
  return TradingRepository(
    apiClient: ref.watch(apiClientProvider),
    localDatabase: ref.watch(localDatabaseProvider),
  );
});

/// Storage Repository Provider
final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  return StorageRepository(
    secureStorage: ref.watch(secureStorageProvider),
    preferences: ref.watch(preferencesServiceProvider),
  );
});

// ============= Use Cases =============

/// Validate Risk Use Case Provider
final validateRiskUseCaseProvider = Provider<ValidateRiskUseCase>((ref) {
  return ValidateRiskUseCase(
    ref.watch(tradingRepositoryProvider),
  );
});

/// Execute Trade Use Case Provider
final executeTradeUseCaseProvider = Provider<ExecuteTradeUseCase>((ref) {
  return ExecuteTradeUseCase(
    ref.watch(tradingRepositoryProvider),
    ref.watch(validateRiskUseCaseProvider),
  );
});
