import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../data/models/opportunity_model.dart';
import '../../data/datasources/remote/websocket_client.dart';
import '../../domain/entities/risk_settings.dart';
import '../../domain/usecases/validate_risk.dart';
import 'providers.dart';
import 'settings_provider.dart';

/// Stream provider для отримання можливостей через WebSocket
final opportunitiesStreamProvider = StreamProvider<List<ArbitrageOpportunity>>((ref) async* {
  final webSocketClient = ref.watch(webSocketClientProvider);
  final logger = Logger();

  // TODO: Підключення до WebSocket з токеном
  // final authState = ref.watch(authProvider);
  // if (authState.isAuthenticated) {
  //   await webSocketClient.connect(wsUrl, authToken);
  // }

  final opportunities = <ArbitrageOpportunity>[];

  await for (final opportunity in webSocketClient.opportunitiesStream) {
    logger.d('Received opportunity: ${opportunity.id}');

    // Додаємо нову можливість
    opportunities.insert(0, opportunity);

    // Видаляємо застарілі можливості (старші 1 хвилини або expired)
    final now = DateTime.now();
    opportunities.removeWhere((opp) {
      final isExpired = opp.expiresAt.isBefore(now);
      final isOld = opp.createdAt != null &&
          now.difference(opp.createdAt!).inMinutes > 1;
      return isExpired || isOld;
    });

    // Обмежуємо кількість (максимум 50 можливостей)
    if (opportunities.length > 50) {
      opportunities.removeRange(50, opportunities.length);
    }

    yield List.from(opportunities);
  }
});

/// Provider для фільтрованих можливостей (які відповідають налаштуванням ризиків)
final filteredOpportunitiesProvider = Provider<List<ArbitrageOpportunity>>((ref) {
  final opportunities = ref.watch(opportunitiesStreamProvider);
  final riskSettings = ref.watch(riskSettingsProvider);
  final validateRisk = ref.watch(validateRiskUseCaseProvider);

  return opportunities.when(
    data: (opps) {
      // Швидка фільтрація за базовими критеріями
      return opps.where((opp) => validateRisk.quickCheck(opp, riskSettings)).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider для кількості активних можливостей
final activeOpportunitiesCountProvider = Provider<int>((ref) {
  final opportunities = ref.watch(opportunitiesStreamProvider);

  return opportunities.when(
    data: (opps) => opps.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Provider для найкращої можливості (з найвищим прибутком)
final bestOpportunityProvider = Provider<ArbitrageOpportunity?>((ref) {
  final opportunities = ref.watch(filteredOpportunitiesProvider);

  if (opportunities.isEmpty) return null;

  return opportunities.reduce(
    (current, next) =>
        next.netProfitPercent > current.netProfitPercent ? next : current,
  );
});
