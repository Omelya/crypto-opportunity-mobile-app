import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:logger/logger.dart';

import '../../../core/config/app_config.dart';
import '../../models/trade_model.dart';

/// Локальна база даних SQLite
class LocalDatabase {
  static Database? _database;
  static final LocalDatabase instance = LocalDatabase._internal();
  final Logger _logger = Logger();

  LocalDatabase._internal();

  /// Отримання інстансу бази даних
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Ініціалізація бази даних
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, AppConfig.dbName);

    _logger.i('Initializing database at: $path');

    return await openDatabase(
      path,
      version: AppConfig.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Створення таблиць при першому запуску
  Future<void> _onCreate(Database db, int version) async {
    _logger.i('Creating database tables');

    // Таблиця угод
    await db.execute('''
      CREATE TABLE trades (
        id TEXT PRIMARY KEY,
        opportunity_id INTEGER NOT NULL,
        pair TEXT NOT NULL,
        amount REAL NOT NULL,
        buy_exchange TEXT NOT NULL,
        sell_exchange TEXT NOT NULL,
        buy_price REAL NOT NULL,
        sell_price REAL NOT NULL,
        buy_order_id TEXT,
        sell_order_id TEXT,
        expected_profit REAL NOT NULL,
        actual_profit REAL,
        actual_profit_percent REAL,
        status TEXT NOT NULL,
        execution_time_ms INTEGER,
        error TEXT,
        created_at INTEGER NOT NULL,
        completed_at INTEGER
      )
    ''');

    // Індекси для швидкого пошуку
    await db.execute('''
      CREATE INDEX idx_trades_status ON trades(status)
    ''');

    await db.execute('''
      CREATE INDEX idx_trades_created_at ON trades(created_at DESC)
    ''');

    await db.execute('''
      CREATE INDEX idx_trades_pair ON trades(pair)
    ''');

    // Таблиця кешу можливостей
    await db.execute('''
      CREATE TABLE opportunities_cache (
        id INTEGER PRIMARY KEY,
        pair TEXT NOT NULL,
        base_asset TEXT NOT NULL,
        quote_asset TEXT NOT NULL,
        exchange_buy TEXT NOT NULL,
        exchange_sell TEXT NOT NULL,
        price_buy REAL NOT NULL,
        price_sell REAL NOT NULL,
        net_profit_percent REAL NOT NULL,
        recommended_amount REAL NOT NULL,
        expires_at INTEGER NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    _logger.i('Database tables created successfully');
  }

  /// Оновлення бази даних при зміні версії
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    _logger.i('Upgrading database from v$oldVersion to v$newVersion');

    // Застосовуємо міграції послідовно
    for (var version = oldVersion + 1; version <= newVersion; version++) {
      await _runMigration(db, version);
    }

    _logger.i('Database upgrade completed');
  }

  /// Виконання міграції для конкретної версії
  Future<void> _runMigration(Database db, int version) async {
    _logger.i('Running migration for version $version');

    switch (version) {
      case 2:
        await _migrateToV2(db);
        break;
      case 3:
        await _migrateToV3(db);
        break;
      // Додавайте нові міграції тут
      default:
        _logger.w('No migration defined for version $version');
    }
  }

  /// Приклад міграції до версії 2
  /// Додає нову колонку для комісій
  Future<void> _migrateToV2(Database db) async {
    _logger.i('Migrating to v2: Adding fees columns');

    await db.execute('''
      ALTER TABLE trades ADD COLUMN buy_fee REAL DEFAULT 0.0
    ''');

    await db.execute('''
      ALTER TABLE trades ADD COLUMN sell_fee REAL DEFAULT 0.0
    ''');

    _logger.i('Migration to v2 completed');
  }

  /// Приклад міграції до версії 3
  /// Додає таблицю для статистики
  Future<void> _migrateToV3(Database db) async {
    _logger.i('Migrating to v3: Adding statistics table');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS daily_statistics (
        date TEXT PRIMARY KEY,
        total_trades INTEGER DEFAULT 0,
        successful_trades INTEGER DEFAULT 0,
        failed_trades INTEGER DEFAULT 0,
        total_profit REAL DEFAULT 0.0,
        total_loss REAL DEFAULT 0.0,
        created_at INTEGER NOT NULL
      )
    ''');

    _logger.i('Migration to v3 completed');
  }

  // ============= CRUD операції для угод =============

  /// Збереження угоди
  Future<void> insertTrade(Trade trade) async {
    final db = await database;

    await db.insert(
      'trades',
      {
        'id': trade.id,
        'opportunity_id': trade.opportunityId,
        'pair': trade.pair,
        'amount': trade.amount,
        'buy_exchange': trade.buyExchange,
        'sell_exchange': trade.sellExchange,
        'buy_price': trade.buyPrice,
        'sell_price': trade.sellPrice,
        'buy_order_id': trade.buyOrderId,
        'sell_order_id': trade.sellOrderId,
        'expected_profit': trade.expectedProfit,
        'actual_profit': trade.actualProfit,
        'actual_profit_percent': trade.actualProfitPercent,
        'status': trade.status.name,
        'execution_time_ms': trade.executionTimeMs,
        'error': trade.error,
        'created_at': trade.createdAt.millisecondsSinceEpoch,
        'completed_at': trade.completedAt?.millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    _logger.d('Trade ${trade.id} saved to database');
  }

  /// Оновлення угоди
  Future<void> updateTrade(Trade trade) async {
    final db = await database;

    await db.update(
      'trades',
      {
        'status': trade.status.name,
        'buy_order_id': trade.buyOrderId,
        'sell_order_id': trade.sellOrderId,
        'actual_profit': trade.actualProfit,
        'actual_profit_percent': trade.actualProfitPercent,
        'execution_time_ms': trade.executionTimeMs,
        'error': trade.error,
        'completed_at': trade.completedAt?.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [trade.id],
    );

    _logger.d('Trade ${trade.id} updated in database');
  }

  /// Отримання угоди за ID
  Future<Trade?> getTrade(String id) async {
    final db = await database;

    final maps = await db.query(
      'trades',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    return _tradeFromMap(maps.first);
  }

  /// Отримання всіх угод
  Future<List<Trade>> getAllTrades({
    int? limit,
    int? offset,
    String? status,
    String? pair,
  }) async {
    final db = await database;

    String? where;
    List<dynamic>? whereArgs;

    if (status != null || pair != null) {
      final conditions = <String>[];
      whereArgs = [];

      if (status != null) {
        conditions.add('status = ?');
        whereArgs.add(status);
      }

      if (pair != null) {
        conditions.add('pair = ?');
        whereArgs.add(pair);
      }

      where = conditions.join(' AND ');
    }

    final maps = await db.query(
      'trades',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => _tradeFromMap(map)).toList();
  }

  /// Отримання угод за період
  Future<List<Trade>> getTradesByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;

    final maps = await db.query(
      'trades',
      where: 'created_at BETWEEN ? AND ?',
      whereArgs: [
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      ],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => _tradeFromMap(map)).toList();
  }

  /// Підрахунок угод
  Future<int> getTradesCount({String? status}) async {
    final db = await database;

    final result = await db.query(
      'trades',
      columns: ['COUNT(*) as count'],
      where: status != null ? 'status = ?' : null,
      whereArgs: status != null ? [status] : null,
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Отримання сьогоднішніх угод
  Future<List<Trade>> getTodayTrades() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    return await getTradesByDateRange(todayStart, todayEnd);
  }

  /// Видалення старих угод
  Future<void> deleteOldTrades(Duration age) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(age);

    final count = await db.delete(
      'trades',
      where: 'created_at < ?',
      whereArgs: [cutoffDate.millisecondsSinceEpoch],
    );

    _logger.i('Deleted $count old trades');
  }

  /// Очищення всієї бази даних
  Future<void> clearAllData() async {
    final db = await database;

    await db.delete('trades');
    await db.delete('opportunities_cache');

    _logger.w('All data cleared from database');
  }

  /// Псевдонім для clearAllData
  Future<void> clearAllTables() async {
    await clearAllData();
  }

  /// Перетворення Map в Trade
  Trade _tradeFromMap(Map<String, dynamic> map) {
    return Trade(
      id: map['id'] as String,
      opportunityId: map['opportunity_id'] as int,
      pair: map['pair'] as String,
      amount: map['amount'] as double,
      buyExchange: map['buy_exchange'] as String,
      sellExchange: map['sell_exchange'] as String,
      buyPrice: map['buy_price'] as double,
      sellPrice: map['sell_price'] as double,
      buyOrderId: map['buy_order_id'] as String?,
      sellOrderId: map['sell_order_id'] as String?,
      expectedProfit: map['expected_profit'] as double,
      actualProfit: map['actual_profit'] as double?,
      actualProfitPercent: map['actual_profit_percent'] as double?,
      status: TradeStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TradeStatus.pending,
      ),
      executionTimeMs: map['execution_time_ms'] as int?,
      error: map['error'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['created_at'] as int,
      ),
      completedAt: map['completed_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              map['completed_at'] as int,
            )
          : null,
    );
  }

  /// Закриття бази даних
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
    _logger.i('Database closed');
  }
}
