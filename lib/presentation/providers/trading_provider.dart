import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../data/models/opportunity_model.dart';
import '../../data/models/statistics_model.dart';
import '../../data/models/trade_model.dart';
import '../../data/repositories/trading_repository.dart';
import '../../domain/usecases/execute_trade.dart';
import 'providers.dart';
import 'settings_provider.dart';

/// Provider для історії угод
final tradesProvider = FutureProvider.family<List<Trade>, TradesFilter>((ref, filter) async {
  final repository = ref.watch(tradingRepositoryProvider);

  return await repository.getTradesFromLocal(
    limit: filter.limit,
    offset: filter.offset,
    status: filter.status,
    pair: filter.pair,
  );
});

/// Фільтр для угод
class TradesFilter {
  final int? limit;
  final int? offset;
  final String? status;
  final String? pair;

  const TradesFilter({
    this.limit,
    this.offset,
    this.status,
    this.pair,
  });

  static const all = TradesFilter(limit: 100);
  static const recent = TradesFilter(limit: 20);
  static const completed = TradesFilter(status: 'completed', limit: 50);
  static const failed = TradesFilter(status: 'failed', limit: 50);
}

/// Provider для статистики
final statisticsProvider = FutureProvider<Statistics>((ref) async {
  final repository = ref.watch(tradingRepositoryProvider);

  try {
    // Спочатку пробуємо отримати з сервера
    return await repository.getStatistics();
  } catch (e) {
    // Якщо не вдалося - рахуємо локально
    return await repository.calculateLocalStatistics();
  }
});

/// Provider для сьогоднішніх угод
final todayTradesProvider = FutureProvider<List<Trade>>((ref) async {
  final repository = ref.watch(tradingRepositoryProvider);
  return await repository.getTodayTrades();
});

/// Provider для кількості угод
final tradesCountProvider = FutureProvider<Map<String, int>>((ref) async {
  final repository = ref.watch(tradingRepositoryProvider);

  final total = await repository.getTradesCount();
  final completed = await repository.getTradesCount(status: 'completed');
  final failed = await repository.getTradesCount(status: 'failed');
  final pending = await repository.getTradesCount(status: 'pending');

  return {
    'total': total,
    'completed': completed,
    'failed': failed,
    'pending': pending,
  };
});

/// State для виконання угоди
class TradeExecutionState {
  final bool isExecuting;
  final Trade? currentTrade;
  final String? error;

  const TradeExecutionState({
    this.isExecuting = false,
    this.currentTrade,
    this.error,
  });

  TradeExecutionState copyWith({
    bool? isExecuting,
    Trade? currentTrade,
    String? error,
  }) {
    return TradeExecutionState(
      isExecuting: isExecuting ?? this.isExecuting,
      currentTrade: currentTrade ?? this.currentTrade,
      error: error,
    );
  }
}

/// Notifier для виконання угод
class TradeExecutionNotifier extends StateNotifier<TradeExecutionState> {
  final ExecuteTradeUseCase _executeTradeUseCase;
  final TradingRepository _tradingRepository;
  final Logger _logger = Logger();

  TradeExecutionNotifier(
    this._executeTradeUseCase,
    this._tradingRepository,
  ) : super(const TradeExecutionState());

  /// Виконання угоди
  Future<Trade> executeTrade(
    ArbitrageOpportunity opportunity,
    dynamic riskSettings,
  ) async {
    if (state.isExecuting) {
      throw Exception('Trade already in progress');
    }

    state = state.copyWith(isExecuting: true, error: null);

    try {
      _logger.i('Executing trade for opportunity ${opportunity.id}');

      final trade = await _executeTradeUseCase(opportunity, riskSettings);

      state = state.copyWith(
        isExecuting: false,
        currentTrade: trade,
      );

      _logger.i('Trade executed: ${trade.status.name}');

      return trade;
    } catch (e) {
      _logger.e('Trade execution error: $e');

      state = state.copyWith(
        isExecuting: false,
        error: e.toString(),
      );

      rethrow;
    }
  }

  /// Очищення помилки
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Скидання стану
  void reset() {
    state = const TradeExecutionState();
  }
}

/// Provider для виконання угод
final tradeExecutionProvider = StateNotifierProvider<TradeExecutionNotifier, TradeExecutionState>((ref) {
  return TradeExecutionNotifier(
    ref.watch(executeTradeUseCaseProvider),
    ref.watch(tradingRepositoryProvider),
  );
});

/// Provider для автоматичного виконання угод
final autoTradingServiceProvider = Provider<AutoTradingService>((ref) {
  return AutoTradingService(
    ref.watch(tradeExecutionProvider.notifier),
    ref.watch(riskSettingsProvider),
  );
});

/// Сервіс для автоматичного виконання угод
class AutoTradingService {
  final TradeExecutionNotifier _tradeExecutor;
  final dynamic _riskSettings;
  final Logger _logger = Logger();

  AutoTradingService(this._tradeExecutor, this._riskSettings);

  /// Обробка нової можливості
  Future<void> handleOpportunity(ArbitrageOpportunity opportunity) async {
    if (!_riskSettings.autoTradingEnabled) {
      _logger.d('Auto trading disabled, skipping opportunity ${opportunity.id}');
      return;
    }

    try {
      _logger.i('Auto trading: Processing opportunity ${opportunity.id}');

      await _tradeExecutor.executeTrade(opportunity, _riskSettings);
    } catch (e) {
      _logger.e('Auto trading error: $e');
    }
  }
}
