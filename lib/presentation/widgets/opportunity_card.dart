import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/opportunity_model.dart';
import '../providers/trading_provider.dart';
import '../providers/settings_provider.dart';

/// Картка з арбітражною можливістю
class OpportunityCard extends ConsumerWidget {
  final ArbitrageOpportunity opportunity;
  final VoidCallback? onTap;

  const OpportunityCard({
    super.key,
    required this.opportunity,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tradeExecution = ref.watch(tradeExecutionProvider);
    final riskSettings = ref.watch(riskSettingsProvider);
    final isExecuting = tradeExecution.isExecuting;

    // Перевірка чи можливість закінчується
    final now = DateTime.now();
    final timeRemaining = opportunity.expiresAt.difference(now);
    final isExpiring = timeRemaining.inSeconds < 10;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок з парою та прибутком
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Пара
                  Text(
                    opportunity.pair,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),

                  // Прибуток
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '+${opportunity.netProfitPercent.toStringAsFixed(2)}%',
                      style: const TextStyle(
                        color: AppTheme.successGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Інформація про біржі
              _buildExchangeRow(context),

              const SizedBox(height: 12),

              // Рекомендована сума та очікуваний прибуток
              _buildAmountRow(context),

              const SizedBox(height: 12),

              // Час до закінчення
              _buildExpiryTimer(context, timeRemaining, isExpiring),

              const SizedBox(height: 16),

              // Кнопка виконання
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isExecuting
                      ? null
                      : () => _executeTrade(context, ref),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: isExecuting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Execute Trade',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExchangeRow(BuildContext context) {
    return Row(
      children: [
        // Купівля
        Expanded(
          child: Row(
            children: [
              const Icon(
                Icons.shopping_cart,
                size: 18,
                color: Colors.blue,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      opportunity.exchangeBuy.toUpperCase(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      '\$${opportunity.priceBuy.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.blue,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Стрілка
        const Icon(
          Icons.arrow_forward,
          size: 20,
          color: Colors.grey,
        ),

        // Продаж
        Expanded(
          child: Row(
            children: [
              const SizedBox(width: 12),
              const Icon(
                Icons.sell,
                size: 18,
                color: Colors.green,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      opportunity.exchangeSell.toUpperCase(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      '\$${opportunity.priceSell.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.green,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmountRow(BuildContext context) {
    final expectedProfit = opportunity.recommendedAmount *
        (opportunity.priceSell - opportunity.priceBuy);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Рекомендована сума
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Amount',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              '\$${opportunity.recommendedAmount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),

        // Очікуваний прибуток
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Expected Profit',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              '\$${expectedProfit.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.successGreen,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpiryTimer(
    BuildContext context,
    Duration timeRemaining,
    bool isExpiring,
  ) {
    return Row(
      children: [
        Icon(
          Icons.access_time,
          size: 16,
          color: isExpiring ? AppTheme.errorRed : Colors.grey,
        ),
        const SizedBox(width: 6),
        Text(
          'Expires in ${timeRemaining.inSeconds}s',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isExpiring ? AppTheme.errorRed : Colors.grey,
                fontWeight: isExpiring ? FontWeight.bold : FontWeight.normal,
              ),
        ),
      ],
    );
  }

  Future<void> _executeTrade(BuildContext context, WidgetRef ref) async {
    try {
      final riskSettings = ref.read(riskSettingsProvider);

      final trade = await ref
          .read(tradeExecutionProvider.notifier)
          .executeTrade(opportunity, riskSettings);

      if (!context.mounted) return;

      // Показуємо результат
      final isSuccess = trade.status == TradeStatus.completed;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isSuccess
                ? 'Trade completed! Profit: \$${trade.actualProfit?.toStringAsFixed(2)}'
                : 'Trade failed: ${trade.error}',
          ),
          backgroundColor: isSuccess ? AppTheme.successGreen : AppTheme.errorRed,
          duration: const Duration(seconds: 3),
        ),
      );

      // Оновлюємо список угод
      ref.invalidate(tradesProvider);
      ref.invalidate(statisticsProvider);
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }
}
