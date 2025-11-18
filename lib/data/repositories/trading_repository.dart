import 'package:logger/logger.dart';

import '../../core/errors/exceptions.dart';
import '../datasources/local/local_database.dart';
import '../datasources/remote/api_client.dart';
import '../models/opportunity_model.dart';
import '../models/statistics_model.dart';
import '../models/trade_model.dart';

/// Репозиторій для торгівлі
class TradingRepository {
  final ApiClient _apiClient;
  final LocalDatabase _localDatabase;
  final Logger _logger = Logger();

  TradingRepository({
    required ApiClient apiClient,
    required LocalDatabase localDatabase,
  })  : _apiClient = apiClient,
        _localDatabase = localDatabase;

  // ============= Trades =============

  /// Отримання історії угод з сервера
  Future<List<Trade>> getTradesFromServer({
    int? limit,
    int? offset,
    String? status,
  }) async {
    try {
      _logger.i('Fetching trades from server');

      final response = await _apiClient.getTrades(
        limit: limit,
        offset: offset,
        status: status,
      );

      final trades = response.map((json) => Trade.fromJson(json as Map<String, dynamic>)).toList();

      // Зберігаємо в локальну БД
      for (final trade in trades) {
        await _localDatabase.insertTrade(trade);
      }

      _logger.i('Fetched ${trades.length} trades from server');

      return trades;
    } on AppException {
      rethrow;
    } catch (e) {
      _logger.e('Failed to fetch trades from server: $e');
      throw TradingException('Failed to fetch trades: $e');
    }
  }

  /// Отримання історії угод з локальної БД
  Future<List<Trade>> getTradesFromLocal({
    int? limit,
    int? offset,
    String? status,
    String? pair,
  }) async {
    try {
      _logger.d('Fetching trades from local database');

      final trades = await _localDatabase.getAllTrades(
        limit: limit,
        offset: offset,
        status: status,
        pair: pair,
      );

      _logger.d('Fetched ${trades.length} trades from local database');

      return trades;
    } catch (e) {
      _logger.e('Failed to fetch trades from local database: $e');
      throw DataException('Failed to fetch trades: $e');
    }
  }

  /// Отримання угоди за ID
  Future<Trade?> getTrade(String tradeId) async {
    try {
      // Спочатку перевіряємо локальну БД
      final localTrade = await _localDatabase.getTrade(tradeId);

      if (localTrade != null) {
        return localTrade;
      }

      // Якщо немає локально, отримуємо з сервера
      _logger.i('Fetching trade $tradeId from server');

      final response = await _apiClient.getTrade(tradeId);
      final trade = Trade.fromJson(response);

      // Зберігаємо в локальну БД
      await _localDatabase.insertTrade(trade);

      return trade;
    } on AppException {
      rethrow;
    } catch (e) {
      _logger.e('Failed to get trade $tradeId: $e');
      return null;
    }
  }

  /// Збереження угоди
  Future<void> saveTrade(Trade trade) async {
    try {
      await _localDatabase.insertTrade(trade);
      _logger.d('Trade ${trade.id} saved');
    } catch (e) {
      _logger.e('Failed to save trade: $e');
      throw DataException('Failed to save trade: $e');
    }
  }

  /// Оновлення угоди
  Future<void> updateTrade(Trade trade) async {
    try {
      await _localDatabase.updateTrade(trade);
      _logger.d('Trade ${trade.id} updated');
    } catch (e) {
      _logger.e('Failed to update trade: $e');
      throw DataException('Failed to update trade: $e');
    }
  }

  /// Отримання сьогоднішніх угод
  Future<List<Trade>> getTodayTrades() async {
    try {
      return await _localDatabase.getTodayTrades();
    } catch (e) {
      _logger.e('Failed to get today trades: $e');
      throw DataException('Failed to get today trades: $e');
    }
  }

  /// Підрахунок угод
  Future<int> getTradesCount({String? status}) async {
    try {
      return await _localDatabase.getTradesCount(status: status);
    } catch (e) {
      _logger.e('Failed to count trades: $e');
      return 0;
    }
  }

  // ============= Statistics =============

  /// Отримання статистики з сервера
  Future<Statistics> getStatistics() async {
    try {
      _logger.i('Fetching statistics from server');

      final response = await _apiClient.getStatistics();
      final statistics = Statistics.fromJson(response);

      _logger.i('Statistics fetched: ${statistics.totalTrades} total trades');

      return statistics;
    } on AppException {
      rethrow;
    } catch (e) {
      _logger.e('Failed to fetch statistics: $e');
      throw TradingException('Failed to fetch statistics: $e');
    }
  }

  /// Розрахунок локальної статистики
  Future<Statistics> calculateLocalStatistics() async {
    try {
      final trades = await _localDatabase.getAllTrades();

      if (trades.isEmpty) {
        return const Statistics();
      }

      final totalTrades = trades.length;
      final successfulTrades = trades.where((t) => t.status == TradeStatus.completed).length;
      final failedTrades = trades.where((t) => t.status == TradeStatus.failed).length;

      final completedTrades = trades.where((t) => t.actualProfit != null);
      final netProfit = completedTrades.fold<double>(
        0.0,
        (sum, trade) => sum + (trade.actualProfit ?? 0.0),
      );

      final winRate = totalTrades > 0 ? (successfulTrades / totalTrades) * 100 : 0.0;

      final averageProfit = successfulTrades > 0 ? netProfit / successfulTrades : 0.0;

      final totalVolume = trades.fold<double>(
        0.0,
        (sum, trade) => sum + (trade.amount * trade.buyPrice),
      );

      final profits = completedTrades.map((t) => t.actualProfit ?? 0.0).toList();
      profits.sort();

      return Statistics(
        totalTrades: totalTrades,
        successfulTrades: successfulTrades,
        failedTrades: failedTrades,
        netProfit: netProfit,
        winRate: winRate,
        averageProfit: averageProfit,
        totalVolume: totalVolume,
        bestTrade: profits.isNotEmpty ? profits.last : null,
        worstTrade: profits.isNotEmpty ? profits.first : null,
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      _logger.e('Failed to calculate local statistics: $e');
      throw DataException('Failed to calculate statistics: $e');
    }
  }

  // ============= Sync =============

  /// Синхронізація даних з сервером
  Future<void> syncWithServer() async {
    try {
      _logger.i('Syncing data with server');

      // Отримуємо останні угоди з сервера
      await getTradesFromServer(limit: 100);

      _logger.i('Sync completed');
    } catch (e) {
      _logger.e('Failed to sync with server: $e');
      // Не кидаємо помилку, оскільки це фонова операція
    }
  }

  // ============= Cleanup =============

  /// Очищення старих даних
  Future<void> cleanupOldData({Duration age = const Duration(days: 30)}) async {
    try {
      _logger.i('Cleaning up old data');
      await _localDatabase.deleteOldTrades(age);
      _logger.i('Cleanup completed');
    } catch (e) {
      _logger.e('Failed to cleanup old data: $e');
    }
  }
}
