# Архітектура мобільного додатку

## Загальна архітектура

```
┌─────────────────────────────────────────────────────────────┐
│                     PRESENTATION LAYER                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Flutter    │  │   Riverpod   │  │     UI       │      │
│  │   Widgets    │◄─┤   Providers  │◄─┤  Components  │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└────────────────────────┬────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────┐
│                      DOMAIN LAYER                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Use Cases  │  │   Entities   │  │  Repository  │      │
│  │  (Business)  │  │  (Models)    │  │  Interfaces  │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└────────────────────────┬────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────┐
│                       DATA LAYER                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ Repositories │  │  WebSocket   │  │   SQLite     │      │
│  │     Impl     │  │    Client    │  │   Database   │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  REST API    │  │    Secure    │  │   Exchange   │      │
│  │   Client     │  │   Storage    │  │   Clients    │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└────────────────────────┬────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────┐
│                   EXTERNAL SERVICES                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Arbitrage   │  │   Binance    │  │    Bybit     │      │
│  │    Server    │  │     API      │  │     API      │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
```

## Потік даних: Виконання угоди

```
┌──────────────────────────────────────────────────────────────┐
│ 1. ОТРИМАННЯ МОЖЛИВОСТІ                                      │
└──────────────────────────────────────────────────────────────┘
                            │
                            ▼
    Server ──WebSocket──► WebSocket Client
                            │
                            ▼
                      Repository.onOpportunity()
                            │
                            ▼
                   OpportunityProvider (Riverpod)
                            │
                            ▼
                  OpportunityListWidget (UI)
                            │
                            ▼
                    Користувач бачить можливість

┌──────────────────────────────────────────────────────────────┐
│ 2. КОРИСТУВАЧ НАТИСКАЄ "EXECUTE"                             │
└──────────────────────────────────────────────────────────────┘
                            │
                            ▼
                  TradingProvider.executeTrade()
                            │
                            ▼
                  ExecuteTradeUseCase.call()
                            │
                ┌───────────┴──────────┐
                ▼                      ▼
      ValidateRiskUseCase     CheckBalanceUseCase
                │                      │
                └───────────┬──────────┘
                            ▼
                      Валідація OK?
                            │
                 ┌──────────┴──────────┐
                 │                     │
                ✅ Так               ❌ Ні
                 │                     │
                 ▼                     ▼
                                  Return Error
┌──────────────────────────────────────────────────────────────┐
│ 3. ВИКОНАННЯ КУПІВЛІ                                         │
└──────────────────────────────────────────────────────────────┘
                │
                ▼
    ExchangeRepository.placeBuyOrder()
                │
                ▼
    BinanceClient.createOrder(BUY)
                │
                ▼
          Binance API
                │
                ▼
         Order Filled?
                │
     ┌──────────┴──────────┐
     │                     │
    ✅ Так               ❌ Ні
     │                     │
     ▼                     ▼
                      Return Error

┌──────────────────────────────────────────────────────────────┐
│ 4. ВИКОНАННЯ ПРОДАЖУ                                         │
└──────────────────────────────────────────────────────────────┘
                │
                ▼
    ExchangeRepository.placeSellOrder()
                │
                ▼
    BybitClient.createOrder(SELL)
                │
                ▼
           Bybit API
                │
                ▼
         Order Filled?
                │
     ┌──────────┴──────────┐
     │                     │
    ✅ Так               ❌ Ні
     │                     │
     ▼                     ▼
                   Застрягла угода!
                   Notify користувача

┌──────────────────────────────────────────────────────────────┐
│ 5. ЗБЕРЕЖЕННЯ РЕЗУЛЬТАТУ                                     │
└──────────────────────────────────────────────────────────────┘
                │
                ▼
    StorageRepository.saveTrade()
                │
                ▼
         SQLite Database
                │
                ▼
    StatisticsRepository.updateStats()
                │
                ▼
         UI оновлюється
                │
                ▼
    NotificationService.showSuccess()
```

## Детальна архітектура шарів

### 1. Presentation Layer (UI)

```
presentation/
├── pages/                    # Екрани додатку
│   ├── auth/
│   │   ├── login_page.dart
│   │   └── telegram_verify_page.dart
│   ├── dashboard/
│   │   └── dashboard_page.dart
│   ├── opportunities/
│   │   ├── opportunities_list_page.dart
│   │   └── opportunity_detail_page.dart
│   ├── trades/
│   │   ├── trades_history_page.dart
│   │   └── trade_detail_page.dart
│   └── settings/
│       └── settings_page.dart
│
├── widgets/                  # Переспроживані компоненти
│   ├── opportunity_card.dart
│   ├── trade_card.dart
│   ├── statistics_widget.dart
│   ├── balance_widget.dart
│   └── chart_widget.dart
│
└── providers/                # State Management (Riverpod)
    ├── auth_provider.dart
    ├── trading_provider.dart
    ├── opportunities_provider.dart
    ├── statistics_provider.dart
    └── settings_provider.dart
```

**Відповідальність:**
- Відображення UI
- Обробка користувацьких дій
- Управління локальним станом
- Навігація

### 2. Domain Layer (Бізнес-логіка)

```
domain/
├── entities/                 # Бізнес-моделі (чисті)
│   ├── opportunity.dart
│   ├── trade.dart
│   ├── exchange_config.dart
│   └── user.dart
│
├── usecases/                 # Бізнес-логіка
│   ├── auth/
│   │   ├── login_with_telegram.dart
│   │   └── verify_code.dart
│   ├── trading/
│   │   ├── execute_trade.dart
│   │   ├── validate_opportunity.dart
│   │   └── calculate_profit.dart
│   ├── risk/
│   │   ├── validate_risk.dart
│   │   └── check_limits.dart
│   └── exchange/
│       ├── add_exchange.dart
│       └── test_connection.dart
│
└── repositories/             # Інтерфейси
    ├── auth_repository.dart
    ├── trading_repository.dart
    ├── storage_repository.dart
    └── exchange_repository.dart
```

**Відповідальність:**
- Бізнес-правила
- Валідація
- Координація між репозиторіями
- Незалежність від framework

### 3. Data Layer (Дані)

```
data/
├── models/                   # DTO (Data Transfer Objects)
│   ├── opportunity_dto.dart
│   ├── trade_dto.dart
│   └── auth_dto.dart
│
├── repositories/             # Реалізація репозиторіїв
│   ├── auth_repository_impl.dart
│   ├── trading_repository_impl.dart
│   ├── storage_repository_impl.dart
│   └── exchange_repository_impl.dart
│
└── datasources/              # Джерела даних
    ├── remote/
    │   ├── websocket_client.dart
    │   ├── api_client.dart
    │   └── exchange_clients/
    │       ├── binance_client.dart
    │       └── bybit_client.dart
    ├── local/
    │   ├── database.dart
    │   ├── secure_storage.dart
    │   └── shared_preferences.dart
    └── cache/
        └── cache_manager.dart
```

**Відповідальність:**
- Отримання даних з різних джерел
- Кешування
- Синхронізація
- Трансформація DTO ↔ Entities

## Стейт менеджмент (Riverpod)

### Провайдери

```dart
// Simple Provider - для незмінних даних
final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig();
});

// State Provider - для простого стану
final selectedExchangeProvider = StateProvider<String?>((ref) => null);

// Future Provider - для асинхронних даних
final statisticsProvider = FutureProvider<Statistics>((ref) async {
  final repository = ref.read(statisticsRepositoryProvider);
  return await repository.getStatistics();
});

// Stream Provider - для real-time даних
final opportunitiesProvider = StreamProvider<List<Opportunity>>((ref) {
  final websocket = ref.read(websocketClientProvider);
  return websocket.opportunitiesStream;
});

// StateNotifier Provider - для складної логіки
final tradingProvider = StateNotifierProvider<TradingNotifier, TradingState>((ref) {
  return TradingNotifier(ref.read(tradingRepositoryProvider));
});
```

### Потік стану

```
User Action (UI)
      │
      ▼
Provider.notifier.method()
      │
      ▼
Use Case Execution
      │
      ▼
State Update
      │
      ▼
UI Rebuild (автоматично)
```

## Безпека: Багаторівнева

```
┌─────────────────────────────────────────────────────────────┐
│ РІВЕНЬ 1: Транспортна безпека                               │
├─────────────────────────────────────────────────────────────┤
│ • HTTPS/WSS тільки                                          │
│ • Certificate Pinning                                       │
│ • TLS 1.3+                                                  │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ РІВЕНЬ 2: Автентифікація                                    │
├─────────────────────────────────────────────────────────────┤
│ • JWT токени                                                │
│ • Token refresh mechanism                                   │
│ • Біометрична автентифікація (опціонально)                 │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ РІВЕНЬ 3: Зберігання даних                                  │
├─────────────────────────────────────────────────────────────┤
│ • Keychain (iOS) / Keystore (Android) для API ключів       │
│ • Шифрування SQLite бази                                   │
│ • Secure memory для чутливих даних                          │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ РІВЕНЬ 4: Захист коду                                       │
├─────────────────────────────────────────────────────────────┤
│ • Code obfuscation                                          │
│ • Root/Jailbreak detection                                  │
│ • Anti-tampering                                            │
└─────────────────────────────────────────────────────────────┘
```

## Оффлайн режим

```
┌─────────────────────────────────────────────────────────────┐
│                    Онлайн режим                             │
├─────────────────────────────────────────────────────────────┤
│ Server ──► WebSocket ──► App ──► SQLite (кеш)               │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                   Оффлайн режим                             │
├─────────────────────────────────────────────────────────────┤
│ App ──► SQLite (читання) ──► UI                             │
│                                                             │
│ Доступно:                                                   │
│ ✅ Історія угод                                             │
│ ✅ Статистика                                               │
│ ✅ Налаштування (локальні)                                  │
│                                                             │
│ Недоступно:                                                 │
│ ❌ Нові можливості                                          │
│ ❌ Виконання угод                                           │
│ ❌ Баланси бірж                                             │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│              Повернення онлайн                              │
├─────────────────────────────────────────────────────────────┤
│ 1. Reconnect WebSocket                                      │
│ 2. Sync local changes (якщо є)                              │
│ 3. Refresh cache                                            │
│ 4. Update UI                                                │
└─────────────────────────────────────────────────────────────┘
```

## Оптимізація продуктивності

### 1. Lazy Loading списків

```dart
ListView.builder(
  itemCount: trades.length,
  itemBuilder: (context, index) {
    if (index >= trades.length - 5) {
      // Підвантажити наступну сторінку
      ref.read(tradesProvider.notifier).loadMore();
    }
    return TradeCard(trades[index]);
  },
)
```

### 2. Кешування зображень/даних

```
┌─────────────────────────────────────────────────────────────┐
│                   Cache Strategy                            │
├─────────────────────────────────────────────────────────────┤
│ • Network First: Можливості (real-time)                     │
│ • Cache First: Статичні дані (логотипи бірж)                │
│ • Stale-While-Revalidate: Статистика                        │
│ • Cache Only: Історія (локальна БД)                         │
└─────────────────────────────────────────────────────────────┘
```

### 3. Оптимізація батареї

```
┌─────────────────────────────────────────────────────────────┐
│              Battery Optimization                           │
├─────────────────────────────────────────────────────────────┤
│ • WebSocket reconnect з експоненціальною затримкою          │
│ • Throttle UI updates (max 1 раз/секунду)                   │
│ • Background mode: мінімальна активність                    │
│ • Adaptive sync: менше запитів коли батарея низька          │
└─────────────────────────────────────────────────────────────┘
```

## Помилки та відновлення

```
┌─────────────────────────────────────────────────────────────┐
│                 Error Handling Strategy                     │
└─────────────────────────────────────────────────────────────┘
                         │
        ┌────────────────┼────────────────┐
        │                │                │
        ▼                ▼                ▼
  Network Error    Business Error    System Error
        │                │                │
        ▼                ▼                ▼
  Retry Logic      Show to User    Log & Report
  (Auto/Manual)    (Dialog/Snack)  (Crashlytics)
        │                │                │
        └────────────────┴────────────────┘
                         │
                         ▼
                  Update UI State
                  (Error/Loading/Success)
```

## Тестування: Піраміда тестів

```
                    ┌──────┐
                    │  E2E │  5-10%
                    │Tests │
                ┌───┴──────┴───┐
                │ Integration  │  20-30%
                │    Tests     │
            ┌───┴──────────────┴───┐
            │   Widget Tests       │  30-40%
        ┌───┴──────────────────────┴───┐
        │       Unit Tests             │  50-60%
        └──────────────────────────────┘

Unit Tests:
  • Use Cases
  • Repositories
  • Utilities
  • Validators

Widget Tests:
  • UI Components
  • Providers
  • Navigation

Integration Tests:
  • User flows
  • API calls
  • Database operations

E2E Tests:
  • Critical paths
  • Login → Trade → View History
```

## CI/CD Pipeline

```
┌─────────────────────────────────────────────────────────────┐
│                   Git Push (main/develop)                   │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ Stage 1: Validation                                         │
├─────────────────────────────────────────────────────────────┤
│ • Code linting (dart analyze)                               │
│ • Format check (dart format)                                │
│ • Dependencies check                                        │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ Stage 2: Testing                                            │
├─────────────────────────────────────────────────────────────┤
│ • Unit tests (flutter test)                                 │
│ • Widget tests                                              │
│ • Integration tests                                         │
│ • Coverage report (>80%)                                    │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ Stage 3: Build                                              │
├─────────────────────────────────────────────────────────────┤
│ • Android: flutter build appbundle                          │
│ • iOS: flutter build ios                                    │
│ • Sign artifacts                                            │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ Stage 4: Deploy                                             │
├─────────────────────────────────────────────────────────────┤
│ • Upload to Play Store (internal track)                     │
│ • Upload to TestFlight                                      │
│ • Notify team                                               │
└─────────────────────────────────────────────────────────────┘
```

## Моніторинг та аналітика

```
┌─────────────────────────────────────────────────────────────┐
│                   App Runtime                               │
└────────────────────────┬────────────────────────────────────┘
                         │
        ┌────────────────┼────────────────┐
        │                │                │
        ▼                ▼                ▼
  Crashlytics      Analytics        Performance
  (Firebase)       (Firebase)        (Firebase)
        │                │                │
        ▼                ▼                ▼
  • Crash reports  • User events    • Screen load
  • ANR reports    • User flows     • API latency
  • Custom logs    • Conversions    • FPS metrics
        │                │                │
        └────────────────┴────────────────┘
                         │
                         ▼
              Dashboard & Alerts
```

---

## Підсумок

Ця архітектура забезпечує:

✅ **Масштабованість** - легко додавати нові фічі
✅ **Тестованість** - кожен шар можна тестувати окремо
✅ **Підтримуваність** - чіткий поділ відповідальності
✅ **Безпека** - багаторівневий захист
✅ **Продуктивність** - оптимізація на всіх рівнях
✅ **Надійність** - graceful error handling

**Наступний крок:** Почніть з [Quick Start Guide](MOBILE_APP_QUICK_START.md)