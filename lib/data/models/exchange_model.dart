import 'package:freezed_annotation/freezed_annotation.dart';

part 'exchange_model.freezed.dart';
part 'exchange_model.g.dart';

/// Модель конфігурації біржі
@freezed
class ExchangeConfig with _$ExchangeConfig {
  const factory ExchangeConfig({
    required String name,
    @JsonKey(name: 'api_key') required String apiKey,
    @JsonKey(name: 'api_secret') required String apiSecret,
    @Default(true) bool enabled,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _ExchangeConfig;

  factory ExchangeConfig.fromJson(Map<String, dynamic> json) =>
      _$ExchangeConfigFromJson(json);
}

/// Баланс на біржі
@freezed
class ExchangeBalance with _$ExchangeBalance {
  const factory ExchangeBalance({
    required String exchange,
    required String asset,
    @Default(0.0) double free,
    @Default(0.0) double locked,
    @Default(0.0) double total,
  }) = _ExchangeBalance;

  factory ExchangeBalance.fromJson(Map<String, dynamic> json) =>
      _$ExchangeBalanceFromJson(json);
}

/// Статус підключення до біржі
@freezed
class ExchangeStatus with _$ExchangeStatus {
  const factory ExchangeStatus({
    required String exchange,
    required bool connected,
    String? error,
    @JsonKey(name: 'last_check') DateTime? lastCheck,
  }) = _ExchangeStatus;

  factory ExchangeStatus.fromJson(Map<String, dynamic> json) =>
      _$ExchangeStatusFromJson(json);
}
