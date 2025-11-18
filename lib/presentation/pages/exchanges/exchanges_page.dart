import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../providers/providers.dart';

/// Екран для управління біржами та їх API ключами
class ExchangesPage extends ConsumerStatefulWidget {
  const ExchangesPage({super.key});

  @override
  ConsumerState<ExchangesPage> createState() => _ExchangesPageState();
}

class _ExchangesPageState extends ConsumerState<ExchangesPage> {
  final Map<String, bool> _testingConnections = {};
  final Map<String, String> _connectionStatus = {};

  @override
  Widget build(BuildContext context) {
    final storageRepository = ref.watch(storageRepositoryProvider);
    final configuredExchanges = storageRepository.getConfiguredExchanges();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exchanges'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelp(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppTheme.primaryBlue,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manage Exchange Connections',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add API keys for automated trading across exchanges',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Configured exchanges count
          Text(
            '${configuredExchanges.length} Exchange${configuredExchanges.length != 1 ? 's' : ''} Configured',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 16),

          // Supported exchanges
          _buildExchangeCard(
            context,
            'Binance',
            'binance',
            Icons.currency_bitcoin,
            configuredExchanges.contains('binance'),
          ),

          const SizedBox(height: 12),

          _buildExchangeCard(
            context,
            'Bybit',
            'bybit',
            Icons.trending_up,
            configuredExchanges.contains('bybit'),
          ),

          const SizedBox(height: 12),

          _buildExchangeCard(
            context,
            'OKX',
            'okx',
            Icons.account_balance,
            configuredExchanges.contains('okx'),
          ),

          const SizedBox(height: 24),

          // Security notice
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.warningYellow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.warningYellow.withOpacity(0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.security,
                  color: AppTheme.warningYellow,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Security Notice',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.warningYellow,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'API keys are stored securely in device keychain/keystore. '
                        'Only use API keys with trading permissions. '
                        'Never share your secret keys.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[700],
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExchangeCard(
    BuildContext context,
    String name,
    String exchangeId,
    IconData icon,
    bool isConfigured,
  ) {
    final isTesting = _testingConnections[exchangeId] ?? false;
    final status = _connectionStatus[exchangeId];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConfigured
              ? AppTheme.successGreen.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
          width: isConfigured ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isConfigured
                    ? AppTheme.successGreen.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isConfigured ? AppTheme.successGreen : Colors.grey,
                size: 28,
              ),
            ),
            title: Row(
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(width: 8),
                if (isConfigured)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Active',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.successGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  isConfigured
                      ? 'API keys configured'
                      : 'Not configured',
                  style: TextStyle(
                    color: isConfigured ? AppTheme.successGreen : Colors.grey,
                    fontSize: 13,
                  ),
                ),
                if (status != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        status.startsWith('Error') || status.startsWith('Failed')
                            ? Icons.error_outline
                            : Icons.check_circle_outline,
                        size: 14,
                        color: status.startsWith('Error') ||
                                status.startsWith('Failed')
                            ? AppTheme.errorRed
                            : AppTheme.successGreen,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 12,
                            color: status.startsWith('Error') ||
                                    status.startsWith('Failed')
                                ? AppTheme.errorRed
                                : AppTheme.successGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            trailing: isConfigured
                ? PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'test') {
                        _testConnection(exchangeId);
                      } else if (value == 'edit') {
                        _showAddEditDialog(context, exchangeId, name);
                      } else if (value == 'delete') {
                        _confirmDelete(context, exchangeId, name);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'test',
                        child: Row(
                          children: [
                            Icon(Icons.wifi_tethering, size: 20),
                            SizedBox(width: 8),
                            Text('Test Connection'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit Keys'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: AppTheme.errorRed),
                            SizedBox(width: 8),
                            Text('Remove', style: TextStyle(color: AppTheme.errorRed)),
                          ],
                        ),
                      ),
                    ],
                  )
                : null,
          ),

          // Actions
          if (!isConfigured) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showAddEditDialog(context, exchangeId, name),
                  icon: const Icon(Icons.add),
                  label: const Text('Add API Keys'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ),
          ] else if (isTesting) ...[
            const Divider(height: 1),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Testing connection...'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _testConnection(String exchangeId) async {
    setState(() {
      _testingConnections[exchangeId] = true;
      _connectionStatus[exchangeId] = null;
    });

    try {
      final storageRepository = ref.read(storageRepositoryProvider);
      final keys = await storageRepository.getExchangeApiKeys(exchangeId);

      if (keys == null || keys['apiKey'] == null || keys['apiSecret'] == null) {
        throw Exception('API keys not found');
      }

      final apiKey = keys['apiKey']!;
      final apiSecret = keys['apiSecret']!;

      // Базова валідація формату ключів
      if (apiKey.isEmpty || apiSecret.isEmpty) {
        throw Exception('API keys cannot be empty');
      }

      if (apiKey.length < 20 || apiSecret.length < 20) {
        throw Exception('API keys seem too short');
      }

      // Симуляція API виклику
      // В реальному додатку тут буде виклик до API біржі
      await Future.delayed(const Duration(seconds: 2));

      // Для демонстрації: успіх якщо ключі валідні за форматом
      // В production тут має бути реальний API виклик:
      // - Binance: GET /api/v3/account
      // - Bybit: GET /v5/user/query-api
      // - OKX: GET /api/v5/account/balance

      final success = _validateKeyFormat(exchangeId, apiKey, apiSecret);

      setState(() {
        _testingConnections[exchangeId] = false;
        _connectionStatus[exchangeId] = success
            ? 'Keys format valid. Configure real API endpoint to test connection.'
            : 'Invalid key format';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                ? 'Keys format validated. Real API test requires backend configuration.'
                : 'Connection test failed: Invalid key format',
            ),
            backgroundColor: success ? AppTheme.successGreen : AppTheme.errorRed,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _testingConnections[exchangeId] = false;
        _connectionStatus[exchangeId] = 'Error: ${e.toString()}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test failed: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  /// Базова валідація формату API ключів
  bool _validateKeyFormat(String exchangeId, String apiKey, String apiSecret) {
    switch (exchangeId) {
      case 'binance':
        // Binance API keys зазвичай 64 символи
        return apiKey.length >= 32 && apiSecret.length >= 32;
      case 'bybit':
        // Bybit API keys можуть варіюватися
        return apiKey.length >= 20 && apiSecret.length >= 20;
      case 'okx':
        // OKX API keys також можуть варіюватися
        return apiKey.length >= 20 && apiSecret.length >= 20;
      default:
        return true;
    }
  }

  Future<void> _showAddEditDialog(
    BuildContext context,
    String exchangeId,
    String exchangeName,
  ) async {
    final apiKeyController = TextEditingController();
    final apiSecretController = TextEditingController();
    bool obscureSecret = true;

    // Load existing keys if editing
    final storageRepository = ref.read(storageRepositoryProvider);
    try {
      final existingKeys = await storageRepository.getExchangeApiKeys(exchangeId);
      if (existingKeys != null) {
        apiKeyController.text = existingKeys['apiKey'] ?? '';
        apiSecretController.text = existingKeys['apiSecret'] ?? '';
      }
    } catch (e) {
      // Keys don't exist yet
    }

    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Configure $exchangeName'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter your API credentials for $exchangeName',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: apiKeyController,
                  decoration: const InputDecoration(
                    labelText: 'API Key',
                    hintText: 'Enter your API key',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.key),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: apiSecretController,
                  obscureText: obscureSecret,
                  decoration: InputDecoration(
                    labelText: 'API Secret',
                    hintText: 'Enter your API secret',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureSecret ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          obscureSecret = !obscureSecret;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.warningYellow.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warning_amber,
                        size: 20,
                        color: AppTheme.warningYellow,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Make sure your API key has trading permissions enabled',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (apiKeyController.text.isEmpty ||
                    apiSecretController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all fields'),
                      backgroundColor: AppTheme.errorRed,
                    ),
                  );
                  return;
                }
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      try {
        await storageRepository.saveExchangeApiKeys(
          exchangeId,
          apiKeyController.text,
          apiSecretController.text,
        );

        setState(() {
          _connectionStatus.remove(exchangeId);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$exchangeName API keys saved successfully'),
              backgroundColor: AppTheme.successGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving keys: ${e.toString()}'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      }
    }

    apiKeyController.dispose();
    apiSecretController.dispose();
  }

  Future<void> _confirmDelete(
    BuildContext context,
    String exchangeId,
    String exchangeName,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove $exchangeName?'),
        content: Text(
          'This will delete your API keys for $exchangeName. '
          'You can add them again later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final storageRepository = ref.read(storageRepositoryProvider);
        await storageRepository.deleteExchangeApiKeys(exchangeId);

        setState(() {
          _connectionStatus.remove(exchangeId);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$exchangeName removed successfully'),
              backgroundColor: AppTheme.successGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error removing exchange: ${e.toString()}'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      }
    }
  }

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exchange Setup Help'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHelpSection(
                context,
                'How to get API keys',
                '1. Log in to your exchange account\n'
                    '2. Go to API Management section\n'
                    '3. Create new API key\n'
                    '4. Enable trading permissions\n'
                    '5. Copy API key and secret',
              ),
              const SizedBox(height: 16),
              _buildHelpSection(
                context,
                'Security Tips',
                '• Never share your API secret\n'
                    '• Use IP whitelist if available\n'
                    '• Don\'t enable withdrawal permissions\n'
                    '• Regularly rotate API keys',
              ),
              const SizedBox(height: 16),
              _buildHelpSection(
                context,
                'Testing Connection',
                'Use the "Test Connection" option to verify '
                    'that your API keys are configured correctly '
                    'and have proper permissions.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection(BuildContext context, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[700],
              ),
        ),
      ],
    );
  }
}
