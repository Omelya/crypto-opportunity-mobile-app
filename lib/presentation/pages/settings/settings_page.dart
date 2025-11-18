import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/theme_provider.dart';

/// Екран налаштувань
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final riskSettings = ref.watch(riskSettingsProvider);
    final authState = ref.watch(authProvider);
    final themeState = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: () => _showResetDialog(context, ref),
            tooltip: 'Reset to defaults',
          ),
        ],
      ),
      body: ListView(
        children: [
          // User section
          _buildUserSection(context, authState.user?.username),

          const Divider(),

          // Risk Management section
          _buildSectionHeader(context, 'Risk Management'),

          _buildSwitchTile(
            context,
            'Auto Trading',
            'Automatically execute trades',
            riskSettings.autoTradingEnabled,
            Icons.auto_mode,
            (value) => ref.read(riskSettingsProvider.notifier).toggleAutoTrading(),
          ),

          _buildSliderTile(
            context,
            'Min Profit Percent',
            '${riskSettings.minProfitPercent.toStringAsFixed(2)}%',
            'Minimum profit required to execute trade',
            Icons.trending_up,
            riskSettings.minProfitPercent,
            0.1,
            5.0,
            (value) => ref.read(riskSettingsProvider.notifier).setMinProfitPercent(value),
          ),

          _buildSliderTile(
            context,
            'Max Position Size',
            '\$${riskSettings.maxPositionSize.toStringAsFixed(0)}',
            'Maximum amount per single trade',
            Icons.account_balance_wallet,
            riskSettings.maxPositionSize,
            100.0,
            10000.0,
            (value) => ref.read(riskSettingsProvider.notifier).setMaxPositionSize(value),
          ),

          _buildSliderTile(
            context,
            'Daily Trades Limit',
            '${riskSettings.maxDailyTrades} trades',
            'Maximum number of trades per day',
            Icons.format_list_numbered,
            riskSettings.maxDailyTrades.toDouble(),
            10.0,
            200.0,
            (value) => ref.read(riskSettingsProvider.notifier).setDailyTradesLimit(value.toInt()),
            divisions: 19,
          ),

          _buildSliderTile(
            context,
            'Max Daily Loss',
            '\$${riskSettings.maxDailyLoss.toStringAsFixed(0)}',
            'Maximum loss allowed per day',
            Icons.warning,
            riskSettings.maxDailyLoss,
            100.0,
            5000.0,
            (value) => ref.read(riskSettingsProvider.notifier).setMaxDailyLoss(value),
          ),

          const Divider(),

          // App Settings section
          _buildSectionHeader(context, 'App Settings'),

          _buildListTile(
            context,
            'Theme',
            _getThemeModeLabel(themeState.themeMode),
            Icons.palette,
            () => _showThemeDialog(context, ref),
          ),

          _buildListTile(
            context,
            'Notifications',
            'Configure push notifications',
            Icons.notifications,
            () {
              // TODO: Notification settings
            },
          ),

          const Divider(),

          // About section
          _buildSectionHeader(context, 'About'),

          _buildListTile(
            context,
            'Version',
            '1.0.0',
            Icons.info,
            null,
          ),

          _buildListTile(
            context,
            'Privacy Policy',
            'View privacy policy',
            Icons.privacy_tip,
            () {
              // TODO: Open privacy policy
            },
          ),

          const Divider(),

          // Danger Zone
          _buildSectionHeader(context, 'Danger Zone', color: AppTheme.errorRed),

          _buildListTile(
            context,
            'Clear Data',
            'Remove all local data',
            Icons.delete_forever,
            () => _showClearDataDialog(context, ref),
            textColor: AppTheme.errorRed,
          ),

          _buildListTile(
            context,
            'Logout',
            'Sign out of your account',
            Icons.logout,
            () => _showLogoutDialog(context, ref),
            textColor: AppTheme.errorRed,
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildUserSection(BuildContext context, String? username) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
            child: const Icon(
              Icons.person,
              size: 32,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username ?? 'Trader',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Premium Account',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color ?? AppTheme.primaryBlue,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context,
    String title,
    String subtitle,
    bool value,
    IconData icon,
    Function(bool) onChanged,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryBlue),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.successGreen,
      ),
    );
  }

  Widget _buildSliderTile(
    BuildContext context,
    String title,
    String currentValue,
    String subtitle,
    IconData icon,
    double value,
    double min,
    double max,
    Function(double) onChanged, {
    int? divisions,
  }) {
    return ExpansionTile(
      leading: Icon(icon, color: AppTheme.primaryBlue),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          currentValue,
          style: const TextStyle(
            color: AppTheme.primaryBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Slider(
                value: value,
                min: min,
                max: max,
                divisions: divisions ?? ((max - min) ~/ 10),
                label: currentValue,
                onChanged: onChanged,
                activeColor: AppTheme.primaryBlue,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      min.toString(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                    Text(
                      max.toString(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback? onTap, {
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? AppTheme.primaryBlue),
      title: Text(
        title,
        style: textColor != null ? TextStyle(color: textColor) : null,
      ),
      subtitle: Text(subtitle),
      trailing: onTap != null
          ? const Icon(Icons.arrow_forward_ios, size: 16)
          : null,
      onTap: onTap,
    );
  }

  String _getThemeModeLabel(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'Light mode';
      case ThemeMode.dark:
        return 'Dark mode';
      case ThemeMode.system:
        return 'System default';
    }
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    final currentThemeMode = ref.read(themeProvider).themeMode;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Light'),
              subtitle: const Text('Always use light theme'),
              value: ThemeMode.light,
              groupValue: currentThemeMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeProvider.notifier).setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              subtitle: const Text('Always use dark theme'),
              value: ThemeMode.dark,
              groupValue: currentThemeMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeProvider.notifier).setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('System'),
              subtitle: const Text('Follow system settings'),
              value: ThemeMode.system,
              groupValue: currentThemeMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeProvider.notifier).setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'Are you sure you want to reset all settings to default values?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(riskSettingsProvider.notifier).resetToDefaults();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings reset to defaults'),
                  backgroundColor: AppTheme.successGreen,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will remove all local data including trades history, settings, and exchange configurations. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Очищення всіх даних
                final storageRepository = ref.read(storageRepositoryProvider);
                final localDatabase = ref.read(localDatabaseProvider);

                await storageRepository.clearAllData();
                await localDatabase.clearAllTables();

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All data cleared successfully'),
                      backgroundColor: AppTheme.successGreen,
                    ),
                  );

                  // Виходимо з аккаунту після очищення
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) {
                    context.goToLogin();
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error clearing data: $e'),
                      backgroundColor: AppTheme.errorRed,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
            ),
            child: const Text('Clear Data'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.pop(context);
                context.goToLogin();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
