import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../providers/opportunities_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/opportunity_card.dart';

/// Екран зі списком арбітражних можливостей
class OpportunitiesPage extends ConsumerStatefulWidget {
  const OpportunitiesPage({super.key});

  @override
  ConsumerState<OpportunitiesPage> createState() => _OpportunitiesPageState();
}

class _OpportunitiesPageState extends ConsumerState<OpportunitiesPage> {
  String _filterType = 'all'; // all, filtered

  @override
  Widget build(BuildContext context) {
    final opportunitiesAsync = ref.watch(opportunitiesStreamProvider);
    final filteredOpportunities = ref.watch(filteredOpportunitiesProvider);
    final bestOpportunity = ref.watch(bestOpportunityProvider);
    final riskSettings = ref.watch(riskSettingsProvider);

    final displayOpportunities = _filterType == 'filtered'
        ? filteredOpportunities
        : (opportunitiesAsync.value ?? []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Opportunities'),
        actions: [
          // Filter toggle
          PopupMenuButton<String>(
            initialValue: _filterType,
            onSelected: (value) {
              setState(() {
                _filterType = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Row(
                  children: [
                    Icon(Icons.list),
                    SizedBox(width: 8),
                    Text('All Opportunities'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'filtered',
                child: Row(
                  children: [
                    Icon(Icons.filter_list),
                    SizedBox(width: 8),
                    Text('Filtered by Risk'),
                  ],
                ),
              ),
            ],
          ),

          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(opportunitiesStreamProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: riskSettings.autoTradingEnabled
                  ? AppTheme.successGreen.withOpacity(0.1)
                  : AppTheme.warningYellow.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(
                  color: riskSettings.autoTradingEnabled
                      ? AppTheme.successGreen.withOpacity(0.3)
                      : AppTheme.warningYellow.withOpacity(0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  riskSettings.autoTradingEnabled
                      ? Icons.check_circle
                      : Icons.info_outline,
                  color: riskSettings.autoTradingEnabled
                      ? AppTheme.successGreen
                      : AppTheme.warningYellow,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        riskSettings.autoTradingEnabled
                            ? 'Auto-Trading Active'
                            : 'Manual Trading Mode',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: riskSettings.autoTradingEnabled
                                  ? AppTheme.successGreen
                                  : AppTheme.warningYellow,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        riskSettings.autoTradingEnabled
                            ? 'Trades will execute automatically'
                            : 'Tap Execute to trade manually',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: riskSettings.autoTradingEnabled,
                  onChanged: (value) {
                    ref.read(riskSettingsProvider.notifier).toggleAutoTrading();
                  },
                  activeColor: AppTheme.successGreen,
                ),
              ],
            ),
          ),

          // Best opportunity banner
          if (bestOpportunity != null) ...[
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.successGreen,
                    AppTheme.successGreen.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.star,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Best Opportunity',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${bestOpportunity.pair} • +${bestOpportunity.netProfitPercent.toStringAsFixed(2)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ],

          // Statistics row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${displayOpportunities.length} opportunities',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (_filterType == 'filtered')
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.filter_list,
                          size: 16,
                          color: AppTheme.primaryBlue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Filtered',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Opportunities list
          Expanded(
            child: opportunitiesAsync.when(
              data: (_) {
                if (displayOpportunities.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _filterType == 'filtered'
                              ? Icons.filter_list_off
                              : Icons.search_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _filterType == 'filtered'
                              ? 'No opportunities match your risk settings'
                              : 'No opportunities available',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _filterType == 'filtered'
                              ? 'Try adjusting your settings'
                              : 'Waiting for arbitrage signals...',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        if (_filterType == 'filtered') ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _filterType = 'all';
                              });
                            },
                            icon: const Icon(Icons.visibility),
                            label: const Text('Show All'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(opportunitiesStreamProvider);
                  },
                  child: ListView.builder(
                    itemCount: displayOpportunities.length,
                    itemBuilder: (context, index) {
                      return OpportunityCard(
                        opportunity: displayOpportunities[index],
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Loading opportunities...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
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
                      'Error loading opportunities',
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
                        ref.invalidate(opportunitiesStreamProvider);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
