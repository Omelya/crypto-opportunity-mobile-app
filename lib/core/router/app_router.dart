import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/auth/verification_page.dart';
import '../../presentation/pages/splash/splash_page.dart';
import '../../presentation/pages/dashboard/dashboard_page.dart';
import '../../presentation/pages/exchanges/exchanges_page.dart';
import '../../presentation/pages/opportunities/opportunities_page.dart';
import '../../presentation/pages/settings/settings_page.dart';
import '../../presentation/pages/trades/trades_history_page.dart';
import '../../presentation/providers/auth_provider.dart';

/// Provider для GoRouter
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isLoading = authState.isLoading;

      // Поточний шлях
      final currentPath = state.matchedLocation;

      // Якщо ще перевіряємо сесію, залишаємося на splash
      if (isLoading && currentPath != '/splash') {
        return '/splash';
      }

      // Публічні сторінки (доступні без авторизації)
      final publicPaths = ['/splash', '/login', '/verification'];
      final isPublicPath = publicPaths.any((path) => currentPath.startsWith(path));

      // Якщо не авторизований і намагаємось зайти на приватну сторінку
      if (!isAuthenticated && !isPublicPath) {
        return '/login';
      }

      // Якщо авторизований і намагаємось зайти на публічну сторінку
      if (isAuthenticated && isPublicPath) {
        return '/dashboard';
      }

      // Інакше залишаємося на поточній сторінці
      return null;
    },
    routes: [
      // Splash Screen
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),

      // Auth Routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),

      GoRoute(
        path: '/verification/:telegramId',
        name: 'verification',
        builder: (context, state) {
          final telegramId = int.parse(state.pathParameters['telegramId']!);
          return VerificationPage(telegramId: telegramId);
        },
      ),

      // Dashboard (Home)
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardPage(),
      ),

      // Opportunities
      GoRoute(
        path: '/opportunities',
        name: 'opportunities',
        builder: (context, state) => const OpportunitiesPage(),
      ),

      // Trades History
      GoRoute(
        path: '/trades',
        name: 'trades',
        builder: (context, state) => const TradesHistoryPage(),
      ),

      // Settings
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),

      // Exchanges
      GoRoute(
        path: '/exchanges',
        name: 'exchanges',
        builder: (context, state) => const ExchangesPage(),
      ),
    ],

    // Error page
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.uri.toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/dashboard'),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    ),
  );
});

/// Extension для зручної навігації
extension GoRouterNavigation on BuildContext {
  /// Перейти на Dashboard
  void goToDashboard() => go('/dashboard');

  /// Перейти на Opportunities
  void goToOpportunities() => go('/opportunities');

  /// Перейти на Trades
  void goToTrades() => go('/trades');

  /// Перейти на Settings
  void goToSettings() => go('/settings');

  /// Перейти на Exchanges
  void goToExchanges() => go('/exchanges');

  /// Перейти на Login
  void goToLogin() => go('/login');

  /// Перейти на Verification
  void goToVerification(int telegramId) => go('/verification/$telegramId');
}
