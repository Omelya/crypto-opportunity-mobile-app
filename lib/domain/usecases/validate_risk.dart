import 'package:logger/logger.dart';

import '../../data/models/opportunity_model.dart';
import '../../data/repositories/trading_repository.dart';
import '../entities/risk_settings.dart';

/// Результат валідації ризику
class RiskValidationResult {
  final bool isValid;
  final String? reason;

  const RiskValidationResult({
    required this.isValid,
    this.reason,
  });

  factory RiskValidationResult.approved() {
    return const RiskValidationResult(isValid: true);
  }

  factory RiskValidationResult.rejected(String reason) {
    return RiskValidationResult(isValid: false, reason: reason);
  }
}

/// Use case для валідації ризиків перед виконанням угоди
class ValidateRiskUseCase {
  final TradingRepository _tradingRepository;
  final Logger _logger = Logger();

  ValidateRiskUseCase(this._tradingRepository);

  /// Валідація можливості згідно з налаштуваннями ризиків
  Future<RiskValidationResult> call(
    ArbitrageOpportunity opportunity,
    RiskSettings settings,
  ) async {
    try {
      _logger.d('Validating risk for opportunity ${opportunity.id}');

      // 1. Перевірка чи включена автоматична торгівля
      if (!settings.autoTradingEnabled) {
        return RiskValidationResult.rejected('Auto trading is disabled');
      }

      // 2. Перевірка розміру позиції
      final positionSize = opportunity.recommendedAmount;
      if (positionSize > settings.maxPositionSize) {
        return RiskValidationResult.rejected(
          'Position size \$${positionSize.toStringAsFixed(2)} exceeds max \$${settings.maxPositionSize.toStringAsFixed(2)}',
        );
      }

      // 3. Перевірка мінімального прибутку
      if (opportunity.netProfitPercent < settings.minProfitPercent) {
        return RiskValidationResult.rejected(
          'Profit ${opportunity.netProfitPercent.toStringAsFixed(2)}% is below min ${settings.minProfitPercent.toStringAsFixed(2)}%',
        );
      }

      // 4. Перевірка денного ліміту угод
      final todayTrades = await _tradingRepository.getTodayTrades();
      if (todayTrades.length >= settings.maxDailyTrades) {
        return RiskValidationResult.rejected(
          'Daily trades limit ${settings.maxDailyTrades} reached (${todayTrades.length} trades today)',
        );
      }

      // 5. Перевірка денних збитків
      final todayLoss = _calculateTodayLoss(todayTrades);
      if (todayLoss.abs() >= settings.maxDailyLoss) {
        return RiskValidationResult.rejected(
          'Daily loss limit \$${settings.maxDailyLoss.toStringAsFixed(2)} reached (loss: \$${todayLoss.abs().toStringAsFixed(2)})',
        );
      }

      // 6. Перевірка ліквідності (рекомендована сума не повинна бути занадто маленькою)
      const minTradeAmount = 10.0; // $10 мінімум
      if (positionSize < minTradeAmount) {
        return RiskValidationResult.rejected(
          'Position size \$${positionSize.toStringAsFixed(2)} is too small (min \$${minTradeAmount.toStringAsFixed(2)})',
        );
      }

      // 7. Перевірка чи не закінчився час дії можливості
      final now = DateTime.now();
      if (opportunity.expiresAt.isBefore(now)) {
        return RiskValidationResult.rejected('Opportunity has expired');
      }

      // 8. Перевірка чи є достатньо часу для виконання (мінімум 5 секунд)
      final timeUntilExpiry = opportunity.expiresAt.difference(now);
      if (timeUntilExpiry.inSeconds < 5) {
        return RiskValidationResult.rejected(
          'Not enough time to execute (${timeUntilExpiry.inSeconds}s remaining)',
        );
      }

      _logger.d('Risk validation passed for opportunity ${opportunity.id}');

      return RiskValidationResult.approved();
    } catch (e) {
      _logger.e('Error during risk validation: $e');
      return RiskValidationResult.rejected('Validation error: $e');
    }
  }

  /// Розрахунок сьогоднішніх збитків
  double _calculateTodayLoss(List trades) {
    double totalProfit = 0.0;

    for (final trade in trades) {
      if (trade.actualProfit != null) {
        totalProfit += trade.actualProfit!;
      }
    }

    // Якщо загальний прибуток негативний - це збиток
    return totalProfit < 0 ? totalProfit : 0.0;
  }

  /// Швидка перевірка чи можливість підходить під базові критерії
  bool quickCheck(
    ArbitrageOpportunity opportunity,
    RiskSettings settings,
  ) {
    // Базові перевірки без async операцій
    if (!settings.autoTradingEnabled) return false;
    if (opportunity.recommendedAmount > settings.maxPositionSize) return false;
    if (opportunity.netProfitPercent < settings.minProfitPercent) return false;
    if (opportunity.expiresAt.isBefore(DateTime.now())) return false;

    return true;
  }
}
