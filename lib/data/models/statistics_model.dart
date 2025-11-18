import 'package:freezed_annotation/freezed_annotation.dart';

part 'statistics_model.freezed.dart';
part 'statistics_model.g.dart';

/// Модель статистики
@freezed
class Statistics with _$Statistics {
  const factory Statistics({
    @JsonKey(name: 'total_trades') @Default(0) int totalTrades,
    @JsonKey(name: 'successful_trades') @Default(0) int successfulTrades,
    @JsonKey(name: 'failed_trades') @Default(0) int failedTrades,
    @JsonKey(name: 'net_profit') @Default(0.0) double netProfit,
    @JsonKey(name: 'win_rate') @Default(0.0) double winRate,
    @JsonKey(name: 'average_profit') @Default(0.0) double averageProfit,
    @JsonKey(name: 'total_volume') @Default(0.0) double totalVolume,
    @JsonKey(name: 'best_trade') double? bestTrade,
    @JsonKey(name: 'worst_trade') double? worstTrade,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _Statistics;

  factory Statistics.fromJson(Map<String, dynamic> json) =>
      _$StatisticsFromJson(json);
}

/// Статистика по біржі
@freezed
class ExchangeStatistics with _$ExchangeStatistics {
  const factory ExchangeStatistics({
    required String exchange,
    @JsonKey(name: 'total_trades') @Default(0) int totalTrades,
    @JsonKey(name: 'total_profit') @Default(0.0) double totalProfit,
    @JsonKey(name: 'win_rate') @Default(0.0) double winRate,
  }) = _ExchangeStatistics;

  factory ExchangeStatistics.fromJson(Map<String, dynamic> json) =>
      _$ExchangeStatisticsFromJson(json);
}

/// Статистика по парі
@freezed
class PairStatistics with _$PairStatistics {
  const factory PairStatistics({
    required String pair,
    @JsonKey(name: 'total_trades') @Default(0) int totalTrades,
    @JsonKey(name: 'total_profit') @Default(0.0) double totalProfit,
    @JsonKey(name: 'average_profit_percent') @Default(0.0) double averageProfitPercent,
  }) = _PairStatistics;

  factory PairStatistics.fromJson(Map<String, dynamic> json) =>
      _$PairStatisticsFromJson(json);
}
