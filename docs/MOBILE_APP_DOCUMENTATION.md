# Документація для мобільного додатку Premium Trading Client

## Зміст
1. [Огляд проекту](#огляд-проекту)
2. [Порівняння Desktop vs Mobile](#порівняння-desktop-vs-mobile)
3. [Технічний стек](#технічний-стек)
4. [Архітектура додатку](#архітектура-додатку)
5. [Функціонал](#функціонал)
6. [Покроковий план реалізації](#покроковий-план-реалізації)
7. [API інтеграції](#api-інтеграції)
8. [Безпека](#безпека)
9. [UI/UX дизайн](#uiux-дизайн)
10. [Тестування](#тестування)
11. [Деплой](#деплой)

---

## Огляд проекту

**Premium Trading Client Mobile** - це мобільний додаток для автоматичного арбітражу криптовалют, який дозволяє користувачам:

- 📊 Моніторити арбітражні можливості в реальному часі
- 💰 Автоматично виконувати торгові операції
- 📈 Відстежувати статистику та історію угод
- ⚙️ Керувати налаштуваннями та ризиками
- 🔐 Безпечно зберігати API ключі бірж

### Основна концепція
Мобільний додаток з'єднується з сервером арбітражних можливостей через WebSocket і автоматично виконує купівлю/продаж на різних біржах (Binance, Bybit, OKX) для отримання прибутку від різниці цін.

---

## Порівняння Desktop vs Mobile

| Функція | Desktop (GUI/CLI) | Mobile | Примітки |
|---------|------------------|--------|----------|
| **Автоматична торгівля** | ✅ Повна підтримка | ✅ Повна підтримка | Основний функціонал |
| **Push-сповіщення** | ❌ Відсутні | ✅ Важливо для mobile | Сповіщення про угоди |
| **Віджети** | ❌ Відсутні | ✅ Додаткова фіча | Швидкий огляд статистики |
| **Біометрична автентифікація** | ❌ Відсутня | ✅ Touch ID/Face ID | Додаткова безпека |
| **Режим фону** | ✅ Завжди активний | ⚠️ Обмежений ОС | Потрібна оптимізація |
| **Енергоспоживання** | Не критично | ⚠️ Критично | Оптимізація батареї |
| **Розмір екрану** | Великий | Малий | Адаптивний UI |
| **Оффлайн режим** | Частковий | ✅ Кешування даних | Перегляд історії |

---

## Технічний стек

### Рекомендований стек для кросплатформенної розробки

#### Варіант 1: Flutter (рекомендовано) ⭐
```yaml
Переваги:
  ✅ Єдина кодова база для iOS і Android
  ✅ Нативна продуктивність
  ✅ Багатий набір UI компонентів
  ✅ Відмінна підтримка WebSocket
  ✅ Велика спільнота

Мови: Dart
Фреймворк: Flutter 3.x
Стейт менеджмент: Riverpod / Bloc
Мережа: dio, web_socket_channel
Локальне сховище: sqflite, flutter_secure_storage
Графіки: fl_chart
Сповіщення: firebase_messaging, flutter_local_notifications
```

#### Варіант 2: React Native
```yaml
Переваги:
  ✅ JavaScript/TypeScript екосистема
  ✅ Велика кількість бібліотек
  ✅ Швидка розробка

Мови: TypeScript
Фреймворк: React Native 0.72+
Навігація: React Navigation
Стейт: Redux Toolkit / Zustand
Мережа: axios, react-native-websocket
Сховище: AsyncStorage, react-native-keychain
```

#### Варіант 3: Native (iOS + Android)
```yaml
Переваги:
  ✅ Максимальна продуктивність
  ✅ Повний доступ до платформи

Недоліки:
  ❌ Два окремі проекти
  ❌ Довша розробка

iOS: Swift + SwiftUI
Android: Kotlin + Jetpack Compose
```

### Рекомендація: **Flutter**
- Оптимальне співвідношення швидкості розробки та продуктивності
- Одна кодова база = менше помилок
- Відмінна підтримка реального часу та WebSocket
- Легка інтеграція з Go backend

---

## Архітектура додатку

### Структура проекту (Flutter)

```
mobile_app/
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── config/           # Конфігурація
│   │   ├── constants/        # Константи
│   │   ├── errors/           # Обробка помилок
│   │   └── theme/            # Теми UI
│   ├── data/
│   │   ├── models/           # Моделі даних
│   │   │   ├── opportunity.dart
│   │   │   ├── trade.dart
│   │   │   ├── statistics.dart
│   │   │   └── exchange_config.dart
│   │   ├── repositories/     # Репозиторії
│   │   │   ├── auth_repository.dart
│   │   │   ├── trading_repository.dart
│   │   │   └── storage_repository.dart
│   │   └── datasources/      # Джерела даних
│   │       ├── websocket_client.dart
│   │       ├── api_client.dart
│   │       └── local_database.dart
│   ├── domain/
│   │   ├── entities/         # Бізнес-сутності
│   │   ├── usecases/         # Бізнес-логіка
│   │   │   ├── execute_trade.dart
│   │   │   ├── validate_opportunity.dart
│   │   │   └── manage_risk.dart
│   │   └── repositories/     # Інтерфейси репозиторіїв
│   ├── presentation/
│   │   ├── pages/            # Екрани
│   │   │   ├── splash/
│   │   │   ├── auth/
│   │   │   │   ├── login_page.dart
│   │   │   │   └── telegram_auth_page.dart
│   │   │   ├── dashboard/
│   │   │   │   └── dashboard_page.dart
│   │   │   ├── opportunities/
│   │   │   │   ├── opportunities_list_page.dart
│   │   │   │   └── opportunity_detail_page.dart
│   │   │   ├── trades/
│   │   │   │   ├── trades_history_page.dart
│   │   │   │   └── trade_detail_page.dart
│   │   │   ├── exchanges/
│   │   │   │   ├── exchanges_page.dart
│   │   │   │   └── add_exchange_page.dart
│   │   │   └── settings/
│   │   │       ├── settings_page.dart
│   │   │       └── risk_settings_page.dart
│   │   ├── widgets/          # Компоненти UI
│   │   │   ├── opportunity_card.dart
│   │   │   ├── trade_card.dart
│   │   │   ├── statistics_widget.dart
│   │   │   └── chart_widget.dart
│   │   └── providers/        # Стейт менеджмент (Riverpod)
│   │       ├── auth_provider.dart
│   │       ├── trading_provider.dart
│   │       └── settings_provider.dart
│   └── services/
│       ├── notification_service.dart
│       ├── background_service.dart
│       ├── encryption_service.dart
│       └── logger_service.dart
├── test/
│   ├── unit/
│   ├── widget/
│   └── integration/
└── pubspec.yaml
```

### Архітектурні шари

```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│    (UI, Widgets, State Management)      │
└───────────────┬─────────────────────────┘
                │
┌───────────────▼─────────────────────────┐
│          Domain Layer                   │
│    (Business Logic, Use Cases)          │
└───────────────┬─────────────────────────┘
                │
┌───────────────▼─────────────────────────┐
│           Data Layer                    │
│  (Repositories, API, Database, WS)      │
└─────────────────────────────────────────┘
```

### Потік даних

```
WebSocket Server
      ↓
WebSocket Client (Data Layer)
      ↓
Repository (Data Layer)
      ↓
Use Case (Domain Layer)
      ↓
Provider/State (Presentation Layer)
      ↓
UI Widget (Presentation Layer)
```

---

## Функціонал

### Мінімально життєздатний продукт (MVP)

#### Фаза 1: Базовий функціонал ✅
1. **Автентифікація**
    - Вхід через Telegram
    - Зберігання JWT токена
    - Автоматичне відновлення сесії

2. **Dashboard**
    - Загальна статистика (прибуток, кількість угод, win rate)
    - Список активних можливостей
    - Швидкий доступ до налаштувань

3. **Управління біржами**
    - Додавання API ключів (Binance, Bybit)
    - Безпечне зберігання в Keychain/Keystore
    - Тестування з'єднання
    - Перегляд балансів

4. **Торгівля**
    - Отримання можливостей через WebSocket
    - Автоматичне/ручне виконання
    - Відображення статусу виконання
    - Базове управління ризиками

5. **Історія угод**
    - Список всіх угод
    - Деталі кожної угоди
    - Фільтрація (дата, біржа, статус)

#### Фаза 2: Покращений функціонал 🚀
1. **Push-сповіщення**
    - Нова можливість
    - Угода виконана
    - Помилка виконання
    - Досягнуто денний ліміт

2. **Розширена аналітика**
    - Графіки прибутку
    - Статистика по біржам
    - Статистика по парам
    - Порівняння періодів

3. **Налаштування ризиків**
    - Максимальний розмір позиції
    - Денний ліміт угод
    - Максимальний денний збиток
    - Мінімальний відсоток прибутку

4. **Віджети**
    - Загальна статистика
    - Останні угоди
    - Швидкий старт/стоп

#### Фаза 3: Розширений функціонал 🎯
1. **Режим фону**
    - Торгівля в фоновому режимі
    - Оптимізація батареї
    - Сповіщення про важливі події

2. **Біометрія**
    - Touch ID / Face ID для входу
    - Підтвердження критичних операцій

3. **Портфоліо**
    - Загальний баланс по всіх біржах
    - Розподіл активів
    - Історія балансів

4. **Налаштування сповіщень**
    - Вибіркові сповіщення
    - Розклад (тихий режим)
    - Пріоритети

---

## Покроковий план реалізації

### Етап 1: Підготовка (Тиждень 1)

#### 1.1 Налаштування проекту
```bash
# Встановити Flutter
flutter doctor

# Створити новий проект
flutter create --org com.cryptotrading premium_trading_mobile
cd premium_trading_mobile

# Додати залежності
flutter pub add riverpod
flutter pub add dio
flutter pub add web_socket_channel
flutter pub add sqflite
flutter pub add flutter_secure_storage
flutter pub add go_router
flutter pub add freezed_annotation
flutter pub add json_annotation

# Dev залежності
flutter pub add --dev build_runner
flutter pub add --dev freezed
flutter pub add --dev json_serializable
```

#### 1.2 Структура папок
```bash
mkdir -p lib/{core,data,domain,presentation,services}
mkdir -p lib/core/{config,constants,errors,theme}
mkdir -p lib/data/{models,repositories,datasources}
mkdir -p lib/domain/{entities,usecases,repositories}
mkdir -p lib/presentation/{pages,widgets,providers}
```

#### 1.3 Конфігурація
- Створити `lib/core/config/app_config.dart`
- Налаштувати теми (світла/темна)
- Додати константи

### Етап 2: Data Layer (Тиждень 2)

#### 2.1 Моделі даних
```dart
// lib/data/models/opportunity.dart
@freezed
class ArbitrageOpportunity with _$ArbitrageOpportunity {
  factory ArbitrageOpportunity({
    required int id,
    required String pair,
    required String baseAsset,
    required String quoteAsset,
    required String exchangeBuy,
    required String exchangeSell,
    required double priceBuy,
    required double priceSell,
    required double netProfitPercent,
    required double recommendedAmount,
    required DateTime expiresAt,
  }) = _ArbitrageOpportunity;

  factory ArbitrageOpportunity.fromJson(Map<String, dynamic> json) =>
      _$ArbitrageOpportunityFromJson(json);
}

// lib/data/models/trade.dart
@freezed
class Trade with _$Trade {
  factory Trade({
    required String id,
    required int opportunityId,
    required String pair,
    required double amount,
    required String buyExchange,
    required String sellExchange,
    required double buyPrice,
    required double sellPrice,
    String? buyOrderId,
    String? sellOrderId,
    required double expectedProfit,
    double? actualProfit,
    double? actualProfitPercent,
    required TradeStatus status,
    int? executionTimeMs,
    required DateTime createdAt,
    DateTime? completedAt,
  }) = _Trade;

  factory Trade.fromJson(Map<String, dynamic> json) =>
      _$TradeFromJson(json);
}

enum TradeStatus { pending, executing, completed, failed, stuck }
```

#### 2.2 WebSocket Client
```dart
// lib/data/datasources/websocket_client.dart
class WebSocketClient {
  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>> _messageController;

  Future<void> connect(String url, String token) async {
    _channel = WebSocketChannel.connect(
      Uri.parse(url),
      protocols: ['Bearer $token'],
    );

    _channel!.stream.listen(
      _handleMessage,
      onError: _handleError,
      onDone: _handleDone,
    );
  }

  void _handleMessage(dynamic message) {
    // Парсинг JSON
    final data = jsonDecode(message);
    _messageController.add(data);
  }

  Future<void> reconnect() async {
    // Експоненціальна затримка
    await Future.delayed(Duration(seconds: 2));
    await connect(_lastUrl, _lastToken);
  }
}
```

#### 2.3 Локальна база даних
```dart
// lib/data/datasources/local_database.dart
class LocalDatabase {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final path = await getDatabasesPath();
    return await openDatabase(
      '$path/trades.db',
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE trades (
        id TEXT PRIMARY KEY,
        opportunity_id INTEGER,
        pair TEXT,
        amount REAL,
        buy_exchange TEXT,
        sell_exchange TEXT,
        buy_price REAL,
        sell_price REAL,
        status TEXT,
        created_at INTEGER,
        completed_at INTEGER
      )
    ''');
  }
}
```

#### 2.4 Безпечне сховище
```dart
// lib/data/datasources/secure_storage.dart
class SecureStorage {
  final _storage = FlutterSecureStorage();

  Future<void> saveApiKey(String exchange, String apiKey, String apiSecret) async {
    await _storage.write(key: '${exchange}_api_key', value: apiKey);
    await _storage.write(key: '${exchange}_api_secret', value: apiSecret);
  }

  Future<Map<String, String>?> getApiKey(String exchange) async {
    final apiKey = await _storage.read(key: '${exchange}_api_key');
    final apiSecret = await _storage.read(key: '${exchange}_api_secret');

    if (apiKey == null || apiSecret == null) return null;

    return {'apiKey': apiKey, 'apiSecret': apiSecret};
  }
}
```

### Етап 3: Domain Layer (Тиждень 3)

#### 3.1 Use Cases
```dart
// lib/domain/usecases/execute_trade.dart
class ExecuteTrade {
  final TradingRepository repository;

  ExecuteTrade(this.repository);

  Future<TradeResult> call(ArbitrageOpportunity opportunity) async {
    // 1. Валідація
    final isValid = await _validateOpportunity(opportunity);
    if (!isValid) return TradeResult.invalid();

    // 2. Перевірка балансів
    final hasBalance = await _checkBalance(opportunity);
    if (!hasBalance) return TradeResult.insufficientBalance();

    // 3. Виконання купівлі
    final buyResult = await repository.placeBuyOrder(
      exchange: opportunity.exchangeBuy,
      pair: opportunity.pair,
      price: opportunity.priceBuy,
      amount: opportunity.recommendedAmount,
    );

    if (!buyResult.success) return TradeResult.buyFailed();

    // 4. Виконання продажу
    final sellResult = await repository.placeSellOrder(
      exchange: opportunity.exchangeSell,
      pair: opportunity.pair,
      price: opportunity.priceSell,
      amount: buyResult.filledAmount,
    );

    if (!sellResult.success) {
      // Застрягла угода!
      return TradeResult.stuck(buyOrderId: buyResult.orderId);
    }

    // 5. Розрахунок прибутку
    final actualProfit = sellResult.totalReceived - buyResult.totalSpent;

    return TradeResult.success(profit: actualProfit);
  }
}
```

#### 3.2 Risk Manager
```dart
// lib/domain/usecases/validate_risk.dart
class ValidateRisk {
  final RiskSettings settings;
  final StatisticsRepository statsRepository;

  Future<RiskValidation> validate(ArbitrageOpportunity opp) async {
    // Перевірка розміру позиції
    if (opp.recommendedAmount > settings.maxPositionSize) {
      return RiskValidation.rejected('Position size too large');
    }

    // Перевірка денного ліміту угод
    final todayTrades = await statsRepository.getTodayTradesCount();
    if (todayTrades >= settings.maxDailyTrades) {
      return RiskValidation.rejected('Daily trades limit reached');
    }

    // Перевірка денних збитків
    final todayLoss = await statsRepository.getTodayLoss();
    if (todayLoss.abs() >= settings.maxDailyLoss) {
      return RiskValidation.rejected('Daily loss limit reached');
    }

    // Перевірка мінімального прибутку
    if (opp.netProfitPercent < settings.minProfitPercent) {
      return RiskValidation.rejected('Profit too low');
    }

    return RiskValidation.approved();
  }
}
```

### Етап 4: Presentation Layer (Тиждень 4-5)

#### 4.1 Providers (Riverpod)
```dart
// lib/presentation/providers/auth_provider.dart
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(AuthState.initial());

  Future<void> loginWithTelegram(int telegramId) async {
    state = AuthState.loading();

    try {
      // 1. Ініціалізація
      await _repository.initAuth(telegramId);
      state = AuthState.awaitingCode();

      // 2. Користувач вводить код
      // Викликається з UI: verifyCode(code)
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> verifyCode(String code) async {
    try {
      final token = await _repository.verifyCode(code);
      await _repository.saveToken(token);
      state = AuthState.authenticated(token);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }
}

// lib/presentation/providers/trading_provider.dart
final opportunitiesProvider = StreamProvider<List<ArbitrageOpportunity>>((ref) {
  final websocket = ref.read(websocketClientProvider);
  return websocket.opportunitiesStream;
});

final tradesHistoryProvider = FutureProvider<List<Trade>>((ref) {
  final repository = ref.read(tradingRepositoryProvider);
  return repository.getTradesHistory();
});

final statisticsProvider = FutureProvider<Statistics>((ref) {
  final repository = ref.read(statisticsRepositoryProvider);
  return repository.getStatistics();
});
```

#### 4.2 UI Екрани

**Екран входу:**
```dart
// lib/presentation/pages/auth/login_page.dart
class LoginPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Логотип
              Icon(Icons.currency_bitcoin, size: 100),
              SizedBox(height: 24),
              Text('Premium Trading Client',
                style: Theme.of(context).textTheme.headlineMedium),
              SizedBox(height: 48),

              // Поле для Telegram ID
              TextField(
                controller: _telegramIdController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Telegram ID',
                  prefixIcon: Icon(Icons.telegram),
                ),
              ),
              SizedBox(height: 16),

              // Кнопка входу
              ElevatedButton(
                onPressed: authState.isLoading ? null : () {
                  final id = int.parse(_telegramIdController.text);
                  ref.read(authProvider.notifier).loginWithTelegram(id);
                },
                child: authState.isLoading
                  ? CircularProgressIndicator()
                  : Text('Login with Telegram'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Dashboard:**
```dart
// lib/presentation/pages/dashboard/dashboard_page.dart
class DashboardPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statistics = ref.watch(statisticsProvider);
    final opportunities = ref.watch(opportunitiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(statisticsProvider);
          ref.invalidate(opportunitiesProvider);
        },
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Статистика
            statistics.when(
              data: (stats) => StatisticsCard(stats),
              loading: () => CircularProgressIndicator(),
              error: (e, _) => ErrorWidget(e),
            ),

            SizedBox(height: 16),

            // Активні можливості
            Text('Active Opportunities',
              style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 8),

            opportunities.when(
              data: (opps) => ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: opps.length,
                itemBuilder: (ctx, i) => OpportunityCard(opps[i]),
              ),
              loading: () => CircularProgressIndicator(),
              error: (e, _) => ErrorWidget(e),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Картка можливості:**
```dart
// lib/presentation/widgets/opportunity_card.dart
class OpportunityCard extends ConsumerWidget {
  final ArbitrageOpportunity opportunity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(opportunity.pair,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  )),
                Chip(
                  label: Text('+${opportunity.netProfitPercent.toStringAsFixed(2)}%'),
                  backgroundColor: Colors.green,
                ),
              ],
            ),

            SizedBox(height: 8),

            // Біржі
            Row(
              children: [
                Icon(Icons.shopping_cart, size: 16),
                SizedBox(width: 4),
                Text('${opportunity.exchangeBuy}: \$${opportunity.priceBuy}'),
                SizedBox(width: 16),
                Icon(Icons.sell, size: 16),
                SizedBox(width: 4),
                Text('${opportunity.exchangeSell}: \$${opportunity.priceSell}'),
              ],
            ),

            SizedBox(height: 8),

            // Рекомендована сума
            Text('Amount: \$${opportunity.recommendedAmount.toStringAsFixed(2)}'),

            SizedBox(height: 12),

            // Кнопка виконання
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ref.read(tradingProvider.notifier)
                    .executeTrade(opportunity);
                },
                child: Text('Execute Trade'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Етап 5: Сервіси (Тиждень 6)

#### 5.1 Push-сповіщення
```dart
// lib/services/notification_service.dart
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Запит дозволів
    await _messaging.requestPermission();

    // Налаштування локальних сповіщень
    await _local.initialize(
      InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    // Обробка сповіщень
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
  }

  Future<void> showTradeNotification(Trade trade) async {
    await _local.show(
      trade.id.hashCode,
      'Trade ${trade.status == TradeStatus.completed ? 'Completed' : 'Failed'}',
      'Pair: ${trade.pair}, Profit: \$${trade.actualProfit?.toStringAsFixed(2)}',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'trades_channel',
          'Trades',
          importance: Importance.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
```

#### 5.2 Фоновий сервіс (Android)
```dart
// lib/services/background_service.dart
import 'package:workmanager/workmanager.dart';

class BackgroundService {
  static const String taskName = 'trading_task';

  Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
  }

  Future<void> registerPeriodicTask() async {
    await Workmanager().registerPeriodicTask(
      taskName,
      taskName,
      frequency: Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Підключення до WebSocket
    // Перевірка можливостей
    // Виконання угод
    return true;
  });
}
```

### Етап 6: Тестування (Тиждень 7)

#### 6.1 Unit тести
```dart
// test/domain/usecases/execute_trade_test.dart
void main() {
  group('ExecuteTrade', () {
    late ExecuteTrade useCase;
    late MockTradingRepository mockRepository;

    setUp(() {
      mockRepository = MockTradingRepository();
      useCase = ExecuteTrade(mockRepository);
    });

    test('should execute successful trade', () async {
      // Arrange
      final opportunity = ArbitrageOpportunity(/* ... */);
      when(mockRepository.placeBuyOrder(any))
        .thenAnswer((_) async => OrderResult.success());
      when(mockRepository.placeSellOrder(any))
        .thenAnswer((_) async => OrderResult.success());

      // Act
      final result = await useCase(opportunity);

      // Assert
      expect(result.isSuccess, true);
      verify(mockRepository.placeBuyOrder(any)).called(1);
      verify(mockRepository.placeSellOrder(any)).called(1);
    });
  });
}
```

#### 6.2 Widget тести
```dart
// test/presentation/widgets/opportunity_card_test.dart
void main() {
  testWidgets('OpportunityCard displays correct info', (tester) async {
    final opportunity = ArbitrageOpportunity(
      id: 1,
      pair: 'BTCUSDT',
      netProfitPercent: 0.5,
      // ...
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OpportunityCard(opportunity),
        ),
      ),
    );

    expect(find.text('BTCUSDT'), findsOneWidget);
    expect(find.text('+0.50%'), findsOneWidget);
    expect(find.text('Execute Trade'), findsOneWidget);
  });
}
```

### Етап 7: Деплой (Тиждень 8)

#### 7.1 Android
```bash
# 1. Підготувати ключ підпису
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload

# 2. Налаштувати android/key.properties
storePassword=<password>
keyPassword=<password>
keyAlias=upload
storeFile=<path-to-key>

# 3. Збірка
flutter build appbundle --release

# 4. Завантажити в Google Play Console
```

#### 7.2 iOS
```bash
# 1. Відкрити в Xcode
open ios/Runner.xcworkspace

# 2. Налаштувати сертифікати та профілі
# 3. Збірка
flutter build ios --release

# 4. Архівувати та завантажити через Xcode
```

---

## API інтеграції

### WebSocket протокол

#### Підключення
```dart
final url = 'wss://your-server.com/ws';
final token = 'your-jwt-token';

final channel = WebSocketChannel.connect(
  Uri.parse(url),
  protocols: ['Bearer $token'],
);
```

#### Повідомлення від сервера

**1. Арбітражна можливість:**
```json
{
  "type": "opportunity",
  "data": {
    "id": 12345,
    "pair": "BTCUSDT",
    "base_asset": "BTC",
    "quote_asset": "USDT",
    "exchange_buy": "binance",
    "exchange_sell": "bybit",
    "price_buy": 43500.00,
    "price_sell": 43650.00,
    "net_profit_percent": 0.34,
    "recommended_amount": 1000.00,
    "expires_at": "2025-01-15T10:30:00Z"
  }
}
```

**2. Heartbeat:**
```json
{
  "type": "ping"
}
```

#### Повідомлення від клієнта

**1. Результат угоди:**
```json
{
  "type": "trade_result",
  "data": {
    "opportunity_id": 12345,
    "status": "completed",
    "buy_order_id": "binance_123456",
    "sell_order_id": "bybit_789012",
    "actual_profit": 3.40,
    "actual_profit_percent": 0.34,
    "execution_time_ms": 2500
  }
}
```

**2. Pong:**
```json
{
  "type": "pong"
}
```

### REST API

#### Автентифікація

**POST /api/auth/init**
```json
Request:
{
  "telegram_id": 123456789
}

Response:
{
  "message": "Verification code sent to Telegram"
}
```

**POST /api/auth/verify**
```json
Request:
{
  "telegram_id": 123456789,
  "code": "123456"
}

Response:
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

#### Статистика

**GET /api/statistics**
```json
Headers:
  Authorization: Bearer <token>

Response:
{
  "total_trades": 150,
  "successful_trades": 142,
  "failed_trades": 8,
  "net_profit": 523.50,
  "win_rate": 94.67,
  "average_profit": 3.69,
  "total_volume": 150000.00
}
```

### Інтеграція з біржами

#### Binance
```dart
import 'package:binance/binance.dart';

class BinanceClient {
  late Binance _client;

  void initialize(String apiKey, String apiSecret) {
    _client = Binance(
      key: apiKey,
      secret: apiSecret,
    );
  }

  Future<Order> placeBuyOrder({
    required String symbol,
    required double quantity,
    double? price,
  }) async {
    return await _client.newOrder(
      symbol: symbol,
      side: Side.BUY,
      type: price == null ? OrderType.MARKET : OrderType.LIMIT,
      quantity: quantity,
      price: price,
      timeInForce: TimeInForce.GTC,
    );
  }
}
```

#### Bybit
```dart
class BybitClient {
  late BybitAPI _client;

  void initialize(String apiKey, String apiSecret) {
    _client = BybitAPI(
      apiKey: apiKey,
      apiSecret: apiSecret,
    );
  }

  Future<Order> placeSellOrder({
    required String symbol,
    required double quantity,
    double? price,
  }) async {
    return await _client.placeOrder(
      category: 'spot',
      symbol: symbol,
      side: 'Sell',
      orderType: price == null ? 'Market' : 'Limit',
      qty: quantity.toString(),
      price: price?.toString(),
    );
  }
}
```

---

## Безпека

### 1. Зберігання API ключів

**iOS (Keychain):**
```dart
final storage = FlutterSecureStorage(
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  ),
);
```

**Android (Keystore):**
```dart
final storage = FlutterSecureStorage(
  aOptions: AndroidOptions(
    encryptedSharedPreferences: true,
  ),
);
```

### 2. Мережева безпека

**Certificate Pinning:**
```dart
// lib/core/config/certificate_pinning.dart
class CertificatePinning {
  static final List<String> certificates = [
    'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
  ];

  static SecurityContext getSecurityContext() {
    final context = SecurityContext.defaultContext;
    // Додати сертифікати
    return context;
  }
}
```

### 3. Код обфускація

```yaml
# android/app/build.gradle
buildTypes {
  release {
    minifyEnabled true
    shrinkResources true
    proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
  }
}
```

### 4. Біометрична автентифікація

```dart
// lib/services/biometric_service.dart
import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> authenticate() async {
    try {
      final canAuth = await _auth.canCheckBiometrics;
      if (!canAuth) return false;

      return await _auth.authenticate(
        localizedReason: 'Authenticate to access trading',
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }
}
```

### 5. Захист від root/jailbreak

```dart
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';

Future<bool> checkDeviceSecurity() async {
  final isJailbroken = await FlutterJailbreakDetection.jailbroken;
  final isDeveloperMode = await FlutterJailbreakDetection.developerMode;

  return !isJailbroken && !isDeveloperMode;
}
```

---

## UI/UX дизайн

### Колірна схема

```dart
// lib/core/theme/app_theme.dart
class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Color(0xFF2563EB), // Синій
    scaffoldBackgroundColor: Color(0xFFF9FAFB),
    colorScheme: ColorScheme.light(
      primary: Color(0xFF2563EB),
      secondary: Color(0xFF10B981), // Зелений для прибутку
      error: Color(0xFFEF4444), // Червоний для збитків
      surface: Colors.white,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Color(0xFF3B82F6),
    scaffoldBackgroundColor: Color(0xFF111827),
    colorScheme: ColorScheme.dark(
      primary: Color(0xFF3B82F6),
      secondary: Color(0xFF10B981),
      error: Color(0xFFEF4444),
      surface: Color(0xFF1F2937),
    ),
  );
}
```

### Навігація

```dart
// lib/core/routing/app_router.dart
final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      redirect: (context, state) => '/login',
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => LoginPage(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => DashboardPage(),
    ),
    GoRoute(
      path: '/opportunities',
      builder: (context, state) => OpportunitiesPage(),
    ),
    GoRoute(
      path: '/trades',
      builder: (context, state) => TradesHistoryPage(),
    ),
    GoRoute(
      path: '/exchanges',
      builder: (context, state) => ExchangesPage(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => SettingsPage(),
    ),
  ],
);
```

### Адаптивний дизайн

```dart
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1024) {
          return desktop ?? tablet ?? mobile;
        } else if (constraints.maxWidth >= 768) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}
```

---

## Тестування

### Типи тестів

#### 1. Unit тести (60% покриття)
- Use cases
- Repositories
- Models
- Utilities

#### 2. Widget тести (30% покриття)
- UI компоненти
- Екрани
- Навігація

#### 3. Integration тести (10% покриття)
- End-to-end сценарії
- WebSocket з'єднання
- API виклики

### Приклад integration тесту

```dart
// integration_test/app_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Complete trading flow', (tester) async {
    // 1. Запуск додатку
    app.main();
    await tester.pumpAndSettle();

    // 2. Вхід
    await tester.enterText(
      find.byType(TextField),
      '123456789',
    );
    await tester.tap(find.text('Login with Telegram'));
    await tester.pumpAndSettle();

    // 3. Введення коду
    await tester.enterText(
      find.byType(TextField),
      '123456',
    );
    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();

    // 4. Dashboard
    expect(find.text('Dashboard'), findsOneWidget);

    // 5. Виконання угоди
    await tester.tap(find.text('Execute Trade').first);
    await tester.pumpAndSettle();

    // 6. Перевірка результату
    expect(find.text('Trade Completed'), findsOneWidget);
  });
}
```

---

## Деплой

### Чеклист перед релізом

#### Код
- [ ] Всі тести проходять
- [ ] Code review завершено
- [ ] Немає console.log / print statements
- [ ] Немає hardcoded секретів
- [ ] Оптимізовано розмір додатку

#### Безпека
- [ ] API ключі в secure storage
- [ ] Certificate pinning налаштовано
- [ ] Обфускація коду увімкнена
- [ ] Root/Jailbreak detection працює

#### Продуктивність
- [ ] Lazy loading для великих списків
- [ ] Кешування зображень
- [ ] Оптимізація батареї
- [ ] Мінімальний розмір APK/IPA

#### UX
- [ ] Завантаження стани
- [ ] Обробка помилок
- [ ] Оффлайн режим
- [ ] Pull-to-refresh

### CI/CD Pipeline (GitHub Actions)

```yaml
# .github/workflows/deploy.yml
name: Deploy Mobile App

on:
  push:
    branches: [main]
    tags:
      - 'v*'

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test

  build-android:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter build appbundle --release
      - uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.GOOGLE_PLAY_JSON }}
          packageName: com.cryptotrading.premium_trading_mobile
          releaseFiles: build/app/outputs/bundle/release/app-release.aab
          track: production

  build-ios:
    needs: test
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter build ios --release --no-codesign
      - uses: apple-actions/upload-testflight-build@v1
        with:
          app-path: build/ios/iphoneos/Runner.app
          issuer-id: ${{ secrets.APPSTORE_ISSUER_ID }}
          api-key-id: ${{ secrets.APPSTORE_API_KEY_ID }}
          api-private-key: ${{ secrets.APPSTORE_API_PRIVATE_KEY }}
```

---

## Оцінка часу та ресурсів

### Команда (мінімум)
- 1 Flutter розробник (Senior)
- 1 Backend розробник (для підтримки API)
- 1 UI/UX дизайнер
- 1 QA engineer

### Часові рамки

| Етап | Тривалість | Паралельно |
|------|------------|------------|
| Підготовка | 1 тиждень | - |
| Data Layer | 1 тиждень | ✅ |
| Domain Layer | 1 тиждень | ✅ |
| Presentation Layer | 2 тижні | - |
| Сервіси | 1 тиждень | ✅ |
| Тестування | 1 тиждень | - |
| Деплой | 1 тиждень | - |
| **Всього** | **6-8 тижнів** | |

### Бюджет (приблизно)

- Розробка: $25,000 - $40,000
- Дизайн: $5,000 - $10,000
- Тестування: $5,000 - $8,000
- App Store/Play Store облікові записи: $125/рік
- CI/CD: $50-100/місяць
- Firebase (push-сповіщення): $25-100/місяць

**Загальний MVP: $35,000 - $60,000**

---

## Підтримка та розвиток

### Моніторинг
- Crashlytics (Firebase)
- Analytics (Firebase/Mixpanel)
- Performance monitoring
- User feedback

### Майбутні фічі
1. Соціальні фічі (спільноти трейдерів)
2. AI прогнозування
3. Копі-трейдинг
4. Розширена аналітика з ML
5. Інтеграція з більшою кількістю бірж
6. Веб-версія (PWA)

---

## Висновок

Створення мобільного додатку для Premium Trading Client - це амбітний проект, який вимагає ретельного планування та виконання. Ця документація надає вичерпний план, який допоможе вам:

1. ✅ Зрозуміти повний обсяг роботи
2. ✅ Організувати розробку по етапах
3. ✅ Уникнути типових помилок
4. ✅ Створити безпечний та продуктивний додаток
5. ✅ Підготуватись до масштабування

### Наступні кроки

1. Зібрати команду
2. Створити дизайн-макети
3. Налаштувати середовище розробки
4. Почати з Етапу 1: Підготовка
5. Регулярні code review та тестування

**Успіхів у розробці!** 🚀