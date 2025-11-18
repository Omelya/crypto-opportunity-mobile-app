import 'package:freezed_annotation/freezed_annotation.dart';

part 'opportunity_model.freezed.dart';
part 'opportunity_model.g.dart';

/// Модель арбітражної можливості
@freezed
class ArbitrageOpportunity with _$ArbitrageOpportunity {
  const factory ArbitrageOpportunity({
    required int id,
    required String pair,
    @JsonKey(name: 'base_asset') required String baseAsset,
    @JsonKey(name: 'quote_asset') required String quoteAsset,
    @JsonKey(name: 'exchange_buy') required String exchangeBuy,
    @JsonKey(name: 'exchange_sell') required String exchangeSell,
    @JsonKey(name: 'price_buy') required double priceBuy,
    @JsonKey(name: 'price_sell') required double priceSell,
    @JsonKey(name: 'net_profit_percent') required double netProfitPercent,
    @JsonKey(name: 'recommended_amount') required double recommendedAmount,
    @JsonKey(name: 'expires_at') required DateTime expiresAt,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _ArbitrageOpportunity;

  factory ArbitrageOpportunity.fromJson(Map<String, dynamic> json) =>
      _$ArbitrageOpportunityFromJson(json);
}

/// Wrapper для WebSocket повідомлення з можливістю
@freezed
class OpportunityMessage with _$OpportunityMessage {
  const factory OpportunityMessage({
    required String type,
    required ArbitrageOpportunity data,
  }) = _OpportunityMessage;

  factory OpportunityMessage.fromJson(Map<String, dynamic> json) =>
      _$OpportunityMessageFromJson(json);
}
