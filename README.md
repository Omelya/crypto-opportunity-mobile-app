# Premium Trading Mobile App

Мобільний додаток для автоматичного арбітражу криптовалют на iOS та Android платформах.

## Про проект

Premium Trading Client Mobile - це професійний торговий додаток, який:
- Підключається до сервера арбітражних можливостей
- Отримує real-time сигнали про різницю цін між біржами
- Автоматично виконує купівлю/продаж для отримання прибутку
- Управляє ризиками та відстежує статистику

## Технологічний стек

- **Framework:** Flutter 3.16+
- **Мова:** Dart 3.0+
- **State Management:** Riverpod 2.0+
- **Networking:** Dio, WebSocket
- **Local Storage:** SQLite, Secure Storage
- **Navigation:** GoRouter

## Структура проекту

```
lib/
├── main.dart                    # Точка входу
├── core/                        # Основні утиліти
│   ├── config/                  # Конфігурація
│   ├── theme/                   # Теми UI
│   └── constants/               # Константи
├── data/                        # Шар даних
│   ├── models/                  # DTO моделі
│   ├── repositories/            # Реалізації репозиторіїв
│   └── datasources/             # API, БД, WebSocket
├── domain/                      # Бізнес-логіка
│   ├── entities/                # Бізнес-моделі
│   ├── usecases/                # Use cases
│   └── repositories/            # Інтерфейси
├── presentation/                # UI шар
│   ├── pages/                   # Екрани
│   ├── widgets/                 # Компоненти
│   └── providers/               # Стейт
└── services/                    # Сервіси
```

## Початок роботи

### Передумови

- Flutter SDK 3.16+
- Dart SDK 3.0+
- Android Studio або VS Code
- Xcode (для iOS, тільки macOS)

### Встановлення

```bash
# Клонувати репозиторій
git clone <repository-url>
cd crypto-opportunity-mobile-app

# Встановити залежності
flutter pub get

# Запустити додаток
flutter run
```

### Генерація коду

```bash
# Генерація моделей (freezed, json_serializable)
flutter pub run build_runner build --delete-conflicting-outputs

# Або watch mode для розробки
flutter pub run build_runner watch
```

## Тестування

```bash
# Запустити всі тести
flutter test

# З coverage
flutter test --coverage

# Integration тести
flutter test integration_test/
```

## Build

### Android
```bash
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## Документація

Детальна документація знаходиться в папці `docs/`:

- [MOBILE_APP_README.md](docs/MOBILE_APP_README.md) - Загальний огляд
- [MOBILE_APP_DOCUMENTATION.md](docs/MOBILE_APP_DOCUMENTATION.md) - Повна документація
- [MOBILE_APP_ARCHITECTURE.md](docs/MOBILE_APP_ARCHITECTURE.md) - Архітектура
- [MOBILE_APP_QUICK_START.md](docs/MOBILE_APP_QUICK_START.md) - Швидкий старт

## Безпека

- API ключі зберігаються в iOS Keychain / Android Keystore
- Використання HTTPS/WSS з certificate pinning
- Обфускація коду при релізі
- Детектування root/jailbreak

## Ліцензія

Див. основний проект для інформації про ліцензію.
