import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/trade_model.dart';

/// Картка з угодою
class TradeCard extends StatelessWidget {
  final Trade trade;
  final VoidCallback? onTap;

  const TradeCard({
    super.key,
    required this.trade,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, HH:mm');

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
              // Заголовок з парою та статусом
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Пара
                  Text(
                    trade.pair,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),

                  // Статус
                  _buildStatusChip(context),
                ],
              ),

              const SizedBox(height: 12),

              // Біржі
              Row(
                children: [
                  Expanded(
                    child: _buildExchangeInfo(
                      context,
                      'Buy',
                      trade.buyExchange,
                      trade.buyPrice,
                      Icons.shopping_cart,
                      Colors.blue,
                    ),
                  ),
                  const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildExchangeInfo(
                      context,
                      'Sell',
                      trade.sellExchange,
                      trade.sellPrice,
                      Icons.sell,
                      Colors.green,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Сума та прибуток
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Сума
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
                        '\$${trade.amount.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),

                  // Прибуток
                  if (trade.actualProfit != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Profit',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${trade.actualProfit! >= 0 ? '+' : ''}\$${trade.actualProfit!.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: trade.actualProfit! >= 0
                                    ? AppTheme.successGreen
                                    : AppTheme.errorRed,
                              ),
                        ),
                      ],
                    ),
                ],
              ),

              // Час виконання
              if (trade.executionTimeMs != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Execution: ${trade.executionTimeMs}ms',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ],
                ),
              ],

              // Помилка
              if (trade.error != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.errorRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 16,
                        color: AppTheme.errorRed,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          trade.error!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.errorRed,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 8),

              // Дата
              Text(
                dateFormat.format(trade.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (trade.status) {
      case TradeStatus.completed:
        backgroundColor = AppTheme.successGreen.withOpacity(0.1);
        textColor = AppTheme.successGreen;
        icon = Icons.check_circle;
        break;
      case TradeStatus.failed:
        backgroundColor = AppTheme.errorRed.withOpacity(0.1);
        textColor = AppTheme.errorRed;
        icon = Icons.cancel;
        break;
      case TradeStatus.stuck:
        backgroundColor = AppTheme.warningYellow.withOpacity(0.1);
        textColor = AppTheme.warningYellow;
        icon = Icons.warning;
        break;
      case TradeStatus.executing:
        backgroundColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue;
        icon = Icons.sync;
        break;
      case TradeStatus.pending:
      default:
        backgroundColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey;
        icon = Icons.pending;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            trade.status.name.toUpperCase(),
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExchangeInfo(
    BuildContext context,
    String label,
    String exchange,
    double price,
    IconData icon,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          exchange.toUpperCase(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        Text(
          '\$${price.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color,
              ),
        ),
      ],
    );
  }
}
