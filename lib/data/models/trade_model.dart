import 'package:freezed_annotation/freezed_annotation.dart';

part 'trade_model.freezed.dart';
part 'trade_model.g.dart';

/// Статус угоди
enum TradeStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('executing')
  executing,
  @JsonValue('completed')
  completed,
  @JsonValue('failed')
  failed,
  @JsonValue('stuck')
  stuck,
}

/// Модель угоди
@freezed
class Trade with _$Trade {
  const factory Trade({
    required String id,
    @JsonKey(name: 'opportunity_id') required int opportunityId,
    required String pair,
    required double amount,
    @JsonKey(name: 'buy_exchange') required String buyExchange,
    @JsonKey(name: 'sell_exchange') required String sellExchange,
    @JsonKey(name: 'buy_price') required double buyPrice,
    @JsonKey(name: 'sell_price') required double sellPrice,
    @JsonKey(name: 'buy_order_id') String? buyOrderId,
    @JsonKey(name: 'sell_order_id') String? sellOrderId,
    @JsonKey(name: 'expected_profit') required double expectedProfit,
    @JsonKey(name: 'actual_profit') double? actualProfit,
    @JsonKey(name: 'actual_profit_percent') double? actualProfitPercent,
    required TradeStatus status,
    @JsonKey(name: 'execution_time_ms') int? executionTimeMs,
    String? error,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'completed_at') DateTime? completedAt,
  }) = _Trade;

  factory Trade.fromJson(Map<String, dynamic> json) => _$TradeFromJson(json);
}

/// Результат виконання угоди
@freezed
class TradeResult with _$TradeResult {
  const factory TradeResult({
    required bool success,
    Trade? trade,
    String? error,
    String? errorCode,
  }) = _TradeResult;

  factory TradeResult.fromJson(Map<String, dynamic> json) =>
      _$TradeResultFromJson(json);
}

/// Wrapper для WebSocket повідомлення з результатом угоди
@freezed
class TradeResultMessage with _$TradeResultMessage {
  const factory TradeResultMessage({
    required String type,
    required Map<String, dynamic> data,
  }) = _TradeResultMessage;

  factory TradeResultMessage.fromJson(Map<String, dynamic> json) =>
      _$TradeResultMessageFromJson(json);
}
