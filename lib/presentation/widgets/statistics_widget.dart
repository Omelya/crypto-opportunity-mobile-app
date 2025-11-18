import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/statistics_model.dart';

/// Віджет для відображення статистики
class StatisticsWidget extends StatelessWidget {
  final Statistics statistics;

  const StatisticsWidget({
    super.key,
    required this.statistics,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Основна статистика
        _buildMainStats(context),

        const SizedBox(height: 16),

        // Додаткова статистика
        _buildDetailedStats(context),
      ],
    );
  }

  Widget _buildMainStats(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue,
            AppTheme.secondaryBlue,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Net Profit (головна метрика)
          Text(
            'Net Profit',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '${statistics.netProfit >= 0 ? '+' : ''}\$${statistics.netProfit.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 24),

          // Три основні метрики
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                context,
                'Total Trades',
                '${statistics.totalTrades}',
                Icons.swap_horiz,
              ),
              _buildStatItem(
                context,
                'Win Rate',
                '${statistics.winRate.toStringAsFixed(1)}%',
                Icons.trending_up,
              ),
              _buildStatItem(
                context,
                'Avg Profit',
                '\$${statistics.averageProfit.toStringAsFixed(2)}',
                Icons.analytics,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStats(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detailed Statistics',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          // Successful / Failed Trades
          _buildDetailRow(
            context,
            'Successful Trades',
            '${statistics.successfulTrades}',
            AppTheme.successGreen,
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            context,
            'Failed Trades',
            '${statistics.failedTrades}',
            AppTheme.errorRed,
          ),
          const SizedBox(height: 8),

          const Divider(),
          const SizedBox(height: 8),

          // Total Volume
          _buildDetailRow(
            context,
            'Total Volume',
            '\$${NumberFormat.compact().format(statistics.totalVolume)}',
            AppTheme.primaryBlue,
          ),
          const SizedBox(height: 8),

          // Best Trade
          if (statistics.bestTrade != null)
            _buildDetailRow(
              context,
              'Best Trade',
              '\$${statistics.bestTrade!.toStringAsFixed(2)}',
              AppTheme.successGreen,
            ),
          if (statistics.bestTrade != null) const SizedBox(height: 8),

          // Worst Trade
          if (statistics.worstTrade != null)
            _buildDetailRow(
              context,
              'Worst Trade',
              '\$${statistics.worstTrade!.toStringAsFixed(2)}',
              statistics.worstTrade! < 0 ? AppTheme.errorRed : AppTheme.successGreen,
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white70,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white70,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    Color valueColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
        ),
      ],
    );
  }
}

/// Компактний віджет статистики для Dashboard
class CompactStatisticsWidget extends StatelessWidget {
  final Statistics statistics;

  const CompactStatisticsWidget({
    super.key,
    required this.statistics,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildCompactItem(
            context,
            'Profit',
            '\$${statistics.netProfit.toStringAsFixed(0)}',
            statistics.netProfit >= 0 ? AppTheme.successGreen : AppTheme.errorRed,
          ),
          _buildDivider(),
          _buildCompactItem(
            context,
            'Win Rate',
            '${statistics.winRate.toStringAsFixed(0)}%',
            AppTheme.primaryBlue,
          ),
          _buildDivider(),
          _buildCompactItem(
            context,
            'Trades',
            '${statistics.totalTrades}',
            AppTheme.primaryBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactItem(
    BuildContext context,
    String label,
    String value,
    Color valueColor,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.grey.withOpacity(0.3),
    );
  }
}
