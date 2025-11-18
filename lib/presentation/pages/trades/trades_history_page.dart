import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/trade_model.dart';
import '../../providers/trading_provider.dart';
import '../../widgets/statistics_widget.dart';
import '../../widgets/trade_card.dart';

/// Екран з історією угод
class TradesHistoryPage extends ConsumerStatefulWidget {
  const TradesHistoryPage({super.key});

  @override
  ConsumerState<TradesHistoryPage> createState() => _TradesHistoryPageState();
}

class _TradesHistoryPageState extends ConsumerState<TradesHistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trades History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(tradesProvider);
              ref.invalidate(statisticsProvider);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Completed'),
            Tab(text: 'Failed'),
            Tab(text: 'Today'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Statistics section
          _buildStatisticsSection(),

          const SizedBox(height: 8),

          // Tabs content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTradesList(TradesFilter.all),
                _buildTradesList(TradesFilter.completed),
                _buildTradesList(TradesFilter.failed),
                _buildTodayTrades(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    final statisticsAsync = ref.watch(statisticsProvider);

    return statisticsAsync.when(
      data: (statistics) => Padding(
        padding: const EdgeInsets.all(16),
        child: StatisticsWidget(statistics: statistics),
      ),
      loading: () => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.errorRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: AppTheme.errorRed),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Failed to load statistics',
                  style: const TextStyle(color: AppTheme.errorRed),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTradesList(TradesFilter filter) {
    final tradesAsync = ref.watch(tradesProvider(filter));

    return tradesAsync.when(
      data: (trades) {
        if (trades.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.inbox,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  _getEmptyMessage(filter),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(tradesProvider(filter));
          },
          child: ListView.builder(
            itemCount: trades.length,
            itemBuilder: (context, index) {
              return TradeCard(
                trade: trades[index],
                onTap: () => _showTradeDetails(context, trades[index]),
              );
            },
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.errorRed,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading trades',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                error.toString(),
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(tradesProvider(filter));
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayTrades() {
    final todayTradesAsync = ref.watch(todayTradesProvider);

    return todayTradesAsync.when(
      data: (trades) {
        if (trades.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.today,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No trades today yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Start trading to see results',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        // Calculate today's statistics
        final completedTrades = trades.where((t) => t.status == TradeStatus.completed).length;
        final totalProfit = trades
            .where((t) => t.actualProfit != null)
            .fold<double>(0.0, (sum, t) => sum + t.actualProfit!);

        return Column(
          children: [
            // Today's summary
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTodayStat(
                    context,
                    'Trades',
                    '${trades.length}',
                    Icons.swap_horiz,
                  ),
                  _buildDivider(),
                  _buildTodayStat(
                    context,
                    'Success',
                    '$completedTrades',
                    Icons.check_circle,
                  ),
                  _buildDivider(),
                  _buildTodayStat(
                    context,
                    'Profit',
                    '${totalProfit >= 0 ? '+' : ''}\$${totalProfit.toStringAsFixed(2)}',
                    Icons.trending_up,
                    valueColor: totalProfit >= 0
                        ? AppTheme.successGreen
                        : AppTheme.errorRed,
                  ),
                ],
              ),
            ),

            // Trades list
            Expanded(
              child: ListView.builder(
                itemCount: trades.length,
                itemBuilder: (context, index) {
                  return TradeCard(
                    trade: trades[index],
                    onTap: () => _showTradeDetails(context, trades[index]),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error: $error'),
      ),
    );
  }

  Widget _buildTodayStat(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
        ),
        const SizedBox(height: 2),
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

  String _getEmptyMessage(TradesFilter filter) {
    if (filter == TradesFilter.completed) {
      return 'No completed trades yet';
    } else if (filter == TradesFilter.failed) {
      return 'No failed trades';
    }
    return 'No trades yet';
  }

  void _showTradeDetails(BuildContext context, Trade trade) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Trade Details',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Trade card
                  TradeCard(trade: trade),

                  const SizedBox(height: 16),

                  // Additional details
                  _buildDetailRow('Trade ID', trade.id),
                  _buildDetailRow('Opportunity ID', '${trade.opportunityId}'),
                  if (trade.buyOrderId != null)
                    _buildDetailRow('Buy Order ID', trade.buyOrderId!),
                  if (trade.sellOrderId != null)
                    _buildDetailRow('Sell Order ID', trade.sellOrderId!),
                  if (trade.executionTimeMs != null)
                    _buildDetailRow(
                      'Execution Time',
                      '${trade.executionTimeMs}ms',
                    ),
                  _buildDetailRow(
                    'Created At',
                    trade.createdAt.toString(),
                  ),
                  if (trade.completedAt != null)
                    _buildDetailRow(
                      'Completed At',
                      trade.completedAt.toString(),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
