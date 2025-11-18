import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_model.freezed.dart';
part 'auth_model.g.dart';

/// Модель користувача
@freezed
class User with _$User {
  const factory User({
    required int id,
    @JsonKey(name: 'telegram_id') required int telegramId,
    String? username,
    String? firstName,
    String? lastName,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

/// Запит на ініціалізацію автентифікації
@freezed
class AuthInitRequest with _$AuthInitRequest {
  const factory AuthInitRequest({
    @JsonKey(name: 'telegram_id') required int telegramId,
  }) = _AuthInitRequest;

  factory AuthInitRequest.fromJson(Map<String, dynamic> json) =>
      _$AuthInitRequestFromJson(json);

  Map<String, dynamic> toJson() => {
        'telegram_id': telegramId,
      };
}

/// Відповідь на ініціалізацію автентифікації
@freezed
class AuthInitResponse with _$AuthInitResponse {
  const factory AuthInitResponse({
    required String message,
  }) = _AuthInitResponse;

  factory AuthInitResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthInitResponseFromJson(json);
}

/// Запит на верифікацію коду
@freezed
class AuthVerifyRequest with _$AuthVerifyRequest {
  const factory AuthVerifyRequest({
    @JsonKey(name: 'telegram_id') required int telegramId,
    required String code,
  }) = _AuthVerifyRequest;

  factory AuthVerifyRequest.fromJson(Map<String, dynamic> json) =>
      _$AuthVerifyRequestFromJson(json);

  Map<String, dynamic> toJson() => {
        'telegram_id': telegramId,
        'code': code,
      };
}

/// Відповідь на верифікацію коду
@freezed
class AuthVerifyResponse with _$AuthVerifyResponse {
  const factory AuthVerifyResponse({
    required String token,
    @JsonKey(name: 'refresh_token') String? refreshToken,
    User? user,
  }) = _AuthVerifyResponse;

  factory AuthVerifyResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthVerifyResponseFromJson(json);
}

/// Токен автентифікації
@freezed
class AuthToken with _$AuthToken {
  const factory AuthToken({
    @JsonKey(name: 'access_token') required String accessToken,
    @JsonKey(name: 'refresh_token') String? refreshToken,
    @JsonKey(name: 'expires_at') DateTime? expiresAt,
  }) = _AuthToken;

  factory AuthToken.fromJson(Map<String, dynamic> json) =>
      _$AuthTokenFromJson(json);
}
