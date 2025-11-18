import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/exceptions.dart';

/// REST API клієнт
class ApiClient {
  late final Dio _dio;
  final Logger _logger = Logger();

  String? _authToken;

  ApiClient({String? baseUrl}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? AppConfig.apiUrl,
        connectTimeout: AppConfig.apiConnectTimeout,
        receiveTimeout: AppConfig.apiReceiveTimeout,
        sendTimeout: AppConfig.apiTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Додаємо interceptor для логування
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          _logger.d('Request: ${options.method} ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.d('Response: ${response.statusCode} ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (error, handler) {
          _logger.e('Error: ${error.message}');
          return handler.next(error);
        },
      ),
    );
  }

  /// Встановлення токену автентифікації
  void setAuthToken(String token) {
    _authToken = token;
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Видалення токену автентифікації
  void clearAuthToken() {
    _authToken = null;
    _dio.options.headers.remove('Authorization');
  }

  /// GET запит
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// POST запит
  Future<Map<String, dynamic>> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PUT запит
  Future<Map<String, dynamic>> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// DELETE запит
  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        queryParameters: queryParameters,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Обробка відповіді
  Map<String, dynamic> _handleResponse(Response response) {
    if (response.statusCode! >= 200 && response.statusCode! < 300) {
      return response.data as Map<String, dynamic>;
    } else {
      throw ServerException(
        'Server returned status code ${response.statusCode}',
        response.statusCode.toString(),
      );
    }
  }

  /// Обробка помилки
  AppException _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException('Connection timeout');

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['message'] ?? 'Server error';

        if (statusCode == 401 || statusCode == 403) {
          return AuthException(message, statusCode.toString());
        } else if (statusCode! >= 400 && statusCode < 500) {
          return ValidationException(message, statusCode.toString());
        } else {
          return ServerException(message, statusCode.toString());
        }

      case DioExceptionType.cancel:
        return const NetworkException('Request cancelled');

      case DioExceptionType.unknown:
      case DioExceptionType.badCertificate:
      case DioExceptionType.connectionError:
      default:
        return NetworkException(
          'Network error: ${error.message}',
          AppConstants.errorNetwork,
        );
    }
  }

  /// Ініціалізація автентифікації
  Future<Map<String, dynamic>> authInit(int telegramId) async {
    return await post(
      AppConstants.authInit,
      data: {'telegram_id': telegramId},
    );
  }

  /// Верифікація коду
  Future<Map<String, dynamic>> authVerify(int telegramId, String code) async {
    return await post(
      AppConstants.authVerify,
      data: {
        'telegram_id': telegramId,
        'code': code,
      },
    );
  }

  /// Оновлення токену
  Future<Map<String, dynamic>> authRefresh(String refreshToken) async {
    return await post(
      AppConstants.authRefresh,
      data: {'refresh_token': refreshToken},
    );
  }

  /// Отримання статистики
  Future<Map<String, dynamic>> getStatistics() async {
    return await get(AppConstants.statistics);
  }

  /// Отримання історії угод
  Future<List<dynamic>> getTrades({
    int? limit,
    int? offset,
    String? status,
  }) async {
    final response = await get(
      AppConstants.trades,
      queryParameters: {
        if (limit != null) 'limit': limit,
        if (offset != null) 'offset': offset,
        if (status != null) 'status': status,
      },
    );
    return response['trades'] as List<dynamic>;
  }

  /// Отримання деталей угоди
  Future<Map<String, dynamic>> getTrade(String tradeId) async {
    return await get('${AppConstants.trades}/$tradeId');
  }
}
