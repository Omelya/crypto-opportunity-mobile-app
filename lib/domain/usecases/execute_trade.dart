import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/opportunity_model.dart';
import '../../data/models/trade_model.dart';
import '../../data/repositories/trading_repository.dart';
import '../entities/risk_settings.dart';
import 'validate_risk.dart';

/// Use case для виконання арбітражної угоди
class ExecuteTradeUseCase {
  final TradingRepository _tradingRepository;
  final ValidateRiskUseCase _validateRisk;
  final Logger _logger = Logger();
  final _uuid = const Uuid();

  ExecuteTradeUseCase(
    this._tradingRepository,
    this._validateRisk,
  );

  /// Виконання угоди
  ///
  /// Повертає Trade об'єкт з результатом виконання
  Future<Trade> call(
    ArbitrageOpportunity opportunity,
    RiskSettings settings,
  ) async {
    final startTime = DateTime.now();
    final tradeId = _uuid.v4();

    _logger.i('Executing trade for opportunity ${opportunity.id}');

    // Створюємо початковий trade
    Trade trade = Trade(
      id: tradeId,
      opportunityId: opportunity.id,
      pair: opportunity.pair,
      amount: opportunity.recommendedAmount,
      buyExchange: opportunity.exchangeBuy,
      sellExchange: opportunity.exchangeSell,
      buyPrice: opportunity.priceBuy,
      sellPrice: opportunity.priceSell,
      expectedProfit: _calculateExpectedProfit(opportunity),
      status: TradeStatus.pending,
      createdAt: startTime,
    );

    try {
      // 1. Валідація ризиків
      final validation = await _validateRisk(opportunity, settings);

      if (!validation.isValid) {
        _logger.w('Trade validation failed: ${validation.reason}');

        trade = trade.copyWith(
          status: TradeStatus.failed,
          error: validation.reason ?? 'Validation failed',
          completedAt: DateTime.now(),
        );

        await _tradingRepository.saveTrade(trade);

        return trade;
      }

      // 2. Оновлюємо статус на executing
      trade = trade.copyWith(status: TradeStatus.executing);
      await _tradingRepository.saveTrade(trade);

      _logger.d('Trade ${trade.id}: Starting execution');

      // 3. Виконуємо купівлю
      final buyResult = await _executeBuyOrder(
        exchange: opportunity.exchangeBuy,
        pair: opportunity.pair,
        price: opportunity.priceBuy,
        amount: opportunity.recommendedAmount,
      );

      if (!buyResult.success) {
        _logger.e('Buy order failed: ${buyResult.error}');

        trade = trade.copyWith(
          status: TradeStatus.failed,
          error: 'Buy order failed: ${buyResult.error}',
          completedAt: DateTime.now(),
          executionTimeMs: DateTime.now().difference(startTime).inMilliseconds,
        );

        await _tradingRepository.updateTrade(trade);

        return trade;
      }

      trade = trade.copyWith(buyOrderId: buyResult.orderId);
      await _tradingRepository.updateTrade(trade);

      _logger.d('Trade ${trade.id}: Buy order completed ${buyResult.orderId}');

      // 4. Виконуємо продаж
      final sellResult = await _executeSellOrder(
        exchange: opportunity.exchangeSell,
        pair: opportunity.pair,
        price: opportunity.priceSell,
        amount: buyResult.filledAmount,
      );

      if (!sellResult.success) {
        _logger.e('Sell order failed: ${sellResult.error}');

        trade = trade.copyWith(
          status: TradeStatus.stuck,
          error: 'Sell order failed: ${sellResult.error}. Buy order: ${buyResult.orderId}',
          sellOrderId: sellResult.orderId,
          completedAt: DateTime.now(),
          executionTimeMs: DateTime.now().difference(startTime).inMilliseconds,
        );

        await _tradingRepository.updateTrade(trade);

        _logger.w('Trade ${trade.id}: STUCK! Buy succeeded but sell failed');

        return trade;
      }

      trade = trade.copyWith(sellOrderId: sellResult.orderId);

      _logger.d('Trade ${trade.id}: Sell order completed ${sellResult.orderId}');

      // 5. Розрахунок фактичного прибутку
      final actualProfit = sellResult.totalReceived - buyResult.totalSpent;
      final actualProfitPercent = (actualProfit / buyResult.totalSpent) * 100;

      final executionTime = DateTime.now().difference(startTime).inMilliseconds;

      trade = trade.copyWith(
        status: TradeStatus.completed,
        actualProfit: actualProfit,
        actualProfitPercent: actualProfitPercent,
        executionTimeMs: executionTime,
        completedAt: DateTime.now(),
      );

      await _tradingRepository.updateTrade(trade);

      _logger.i(
        'Trade ${trade.id}: COMPLETED! Profit: \$${actualProfit.toStringAsFixed(2)} (${actualProfitPercent.toStringAsFixed(2)}%) in ${executionTime}ms',
      );

      return trade;
    } catch (e) {
      _logger.e('Trade execution error: $e');

      trade = trade.copyWith(
        status: TradeStatus.failed,
        error: 'Execution error: $e',
        completedAt: DateTime.now(),
        executionTimeMs: DateTime.now().difference(startTime).inMilliseconds,
      );

      await _tradingRepository.updateTrade(trade);

      return trade;
    }
  }

  /// Симуляція виконання ордера на купівлю
  ///
  /// В реальному додатку тут буде інтеграція з біржами через їх API
  Future<_OrderResult> _executeBuyOrder({
    required String exchange,
    required String pair,
    required double price,
    required double amount,
  }) async {
    try {
      _logger.d('Executing BUY order: $exchange $pair $amount @ $price');

      // Симуляція затримки мережі (100-500ms)
      await Future.delayed(Duration(milliseconds: 100 + (DateTime.now().millisecond % 400)));

      // TODO: Реальна інтеграція з біржами
      // Binance: await _binanceClient.placeBuyOrder(...)
      // Bybit: await _bybitClient.placeBuyOrder(...)
      // OKX: await _okxClient.placeBuyOrder(...)

      // Симуляція успішного ордера
      final orderId = '${exchange.toUpperCase()}_BUY_${_uuid.v4().substring(0, 8)}';
      final filledAmount = amount;
      final totalSpent = amount * price;

      return _OrderResult(
        success: true,
        orderId: orderId,
        filledAmount: filledAmount,
        totalSpent: totalSpent,
      );
    } catch (e) {
      _logger.e('Buy order error: $e');
      return _OrderResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Симуляція виконання ордера на продаж
  ///
  /// В реальному додатку тут буде інтеграція з біржами через їх API
  Future<_OrderResult> _executeSellOrder({
    required String exchange,
    required String pair,
    required double price,
    required double amount,
  }) async {
    try {
      _logger.d('Executing SELL order: $exchange $pair $amount @ $price');

      // Симуляція затримки мережі (100-500ms)
      await Future.delayed(Duration(milliseconds: 100 + (DateTime.now().millisecond % 400)));

      // TODO: Реальна інтеграція з біржами
      // Binance: await _binanceClient.placeSellOrder(...)
      // Bybit: await _bybitClient.placeSellOrder(...)
      // OKX: await _okxClient.placeSellOrder(...)

      // Симуляція успішного ордера
      final orderId = '${exchange.toUpperCase()}_SELL_${_uuid.v4().substring(0, 8)}';
      final filledAmount = amount;
      final totalReceived = amount * price;

      return _OrderResult(
        success: true,
        orderId: orderId,
        filledAmount: filledAmount,
        totalReceived: totalReceived,
      );
    } catch (e) {
      _logger.e('Sell order error: $e');
      return _OrderResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Розрахунок очікуваного прибутку
  double _calculateExpectedProfit(ArbitrageOpportunity opportunity) {
    final buyAmount = opportunity.recommendedAmount;
    final buyTotal = buyAmount * opportunity.priceBuy;
    final sellTotal = buyAmount * opportunity.priceSell;

    return sellTotal - buyTotal;
  }
}

/// Внутрішній клас для результату ордера
class _OrderResult {
  final bool success;
  final String? orderId;
  final double filledAmount;
  final double totalSpent;
  final double totalReceived;
  final String? error;

  _OrderResult({
    required this.success,
    this.orderId,
    this.filledAmount = 0.0,
    this.totalSpent = 0.0,
    this.totalReceived = 0.0,
    this.error,
  });
}
