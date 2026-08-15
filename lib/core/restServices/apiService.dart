import 'dart:async';
import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/app/routes/app_routes.dart';
import 'package:ratnesh_gold_app/core/constants/ApiUrlConstants.dart';
import 'package:ratnesh_gold_app/core/constants/timeout_constants.dart';
import 'package:ratnesh_gold_app/services/deviceIdService.dart';
import 'package:ratnesh_gold_app/utils/SessionManager.dart';

enum _RefreshResult { success, authFailure, otherFailure }

class BaseHttpService {
  late final dio.Dio _dio;
  late final dio.Dio _refreshDio;

  SessionManager sessionManager = SessionManager();

  Completer<_RefreshResult>? _refreshCompleter;

  BaseHttpService() {
    _dio = dio.Dio(
      dio.BaseOptions(
        baseUrl: ApiUrlConstants.BASE_URL,
        connectTimeout: AppTimeouts.normalSend,
        sendTimeout: AppTimeouts.normalSend,
        receiveTimeout: AppTimeouts.normalReceive,
        headers: {"Content-Type": "application/json"},
      ),
    );

    _refreshDio = dio.Dio(
      dio.BaseOptions(
        baseUrl: ApiUrlConstants.BASE_URL,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {"Content-Type": "application/json"},
      ),
    );

    _initializeInterceptors();
  }

  void _initializeInterceptors() {
    _dio.interceptors.add(
      dio.InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final requiresAuth = options.extra["requiresAuth"] ?? true;

            if (requiresAuth) {
              final token = await sessionManager.getAccessToken();

              if (token != null) {
                options.headers["Authorization"] = "Bearer $token";
              }
            }
          } catch (e) {
          }

          return handler.next(options);
        },

        onResponse: (response, handler) {
          return handler.next(response);
        },

        onError: (dio.DioException error, handler) async {
          final statusCode = error.response?.statusCode;

          if (statusCode == 502 || statusCode == 503 || statusCode == 504) {
            if (error.requestOptions.extra["retried"] != true) {
              error.requestOptions.extra["retried"] = true;
              await Future.delayed(const Duration(seconds: 2));
              try {
                final retryResponse = await _dio.fetch(error.requestOptions);
                return handler.resolve(retryResponse);
              } on dio.DioException catch (retryError) {
                final errorMessage = _extractErrorMessage(retryError.response);
                return handler.reject(
                  dio.DioException(
                    requestOptions: retryError.requestOptions,
                    response: retryError.response,
                    error: errorMessage ?? _getServerErrorMessage(statusCode),
                    type: retryError.type,
                  ),
                );
              }
            }
          }

          if (statusCode == 401) {
            final requiresAuth =
                error.requestOptions.extra["requiresAuth"] ?? true;

            if (requiresAuth &&
                error.requestOptions.extra["retried"] != true) {
              final refreshResult = await _handleTokenRefresh();

              if (refreshResult == _RefreshResult.success) {
                final newToken = await sessionManager.getAccessToken();
                if (newToken != null) {
                  error.requestOptions.headers["Authorization"] =
                      "Bearer $newToken";
                }

                error.requestOptions.extra["retried"] = true;

                try {
                  final retryResponse =
                      await _dio.fetch(error.requestOptions);
                  return handler.resolve(retryResponse);
                } on dio.DioException catch (retryError) {
                  if (retryError.response?.statusCode == 401) {
                    await _handleTokenExpiration();
                  }
                  final errorMessage = _extractErrorMessage(
                    retryError.response,
                  );
                  return handler.reject(
                    dio.DioException(
                      requestOptions: retryError.requestOptions,
                      response: retryError.response,
                      error:
                          errorMessage ?? "An unexpected error occurred.",
                      type: retryError.type,
                    ),
                  );
                }
              } else if (refreshResult == _RefreshResult.authFailure) {
                await _handleTokenExpiration();
              }
            }
          }

          final errorMessage = _extractErrorMessage(error.response);
          final isServerError = statusCode == 502 || statusCode == 503 || statusCode == 504;

          handler.reject(
            dio.DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              error: errorMessage ?? (isServerError ? _getServerErrorMessage(statusCode) : "An unexpected error occurred."),
              type: error.type,
            ),
          );
        },
      ),
    );
  }

  Future<_RefreshResult> _handleTokenRefresh() async {
    if (_refreshCompleter != null && !_refreshCompleter!.isCompleted) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<_RefreshResult>();

    try {
      final refreshToken = await sessionManager.getRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        _refreshCompleter!.complete(_RefreshResult.authFailure);
        return _RefreshResult.authFailure;
      }

      final isRefreshExpired = await sessionManager.isRefreshTokenExpired();
      if (isRefreshExpired) {
        _refreshCompleter!.complete(_RefreshResult.authFailure);
        return _RefreshResult.authFailure;
      }


      final deviceId = await getDeviceId();

      final response = await _refreshDio.post(
        ApiUrlConstants.REFRESH_TOKEN,
        data: {
          "refreshToken": refreshToken,
          "deviceId": deviceId,
        },
      );

      final extracted = _extractTokenSet(response.data);
      if (extracted != null) {
        await sessionManager.saveTokens(
          accessToken: extracted.access,
          refreshToken: extracted.refresh,
          accessTokenExpiry: extracted.accessExpiry,
          refreshTokenExpiry: extracted.refreshExpiry,
        );

        _refreshCompleter!.complete(_RefreshResult.success);
        return _RefreshResult.success;
      }

      _refreshCompleter!.complete(_RefreshResult.otherFailure);
      return _RefreshResult.otherFailure;
    } on dio.DioException catch (e) {
      final status = e.response?.statusCode;
      final result = (status == 401 || status == 403)
          ? _RefreshResult.authFailure
          : _RefreshResult.otherFailure;
      _refreshCompleter!.complete(result);
      return result;
    } catch (e) {
      _refreshCompleter!.complete(_RefreshResult.otherFailure);
      return _RefreshResult.otherFailure;
    } finally {
      _refreshCompleter = null;
    }
  }

  ({String access, String refresh, String accessExpiry, String refreshExpiry})?
      _extractTokenSet(dynamic body) {
    if (body is! Map) return null;

    final candidates = <Map>[];
    final nested = body['data'];
    if (nested is Map) {
      candidates.add(nested);
      final nested2 = nested['data'];
      if (nested2 is Map) candidates.add(nested2);
    }
    candidates.add(body);

    for (final m in candidates) {
      final access = m['accessToken'];
      final refresh = m['refreshToken'];
      final accessExpiry = m['accessTokenValidTill'];
      final refreshExpiry = m['refreshTokenValidTill'] ?? m['enableAccessTill'];
      if (access is String && access.isNotEmpty &&
          refresh is String && refresh.isNotEmpty &&
          accessExpiry is String && accessExpiry.isNotEmpty &&
          refreshExpiry is String && refreshExpiry.isNotEmpty) {
        return (
          access: access,
          refresh: refresh,
          accessExpiry: accessExpiry,
          refreshExpiry: refreshExpiry,
        );
      }
    }
    return null;
  }

  String _getServerErrorMessage(int? statusCode) {
    switch (statusCode) {
      case 502:
        return "Server is temporarily unavailable. Please try again.";
      case 503:
        return "Service is currently unavailable. Please try again later.";
      case 504:
        return "Server took too long to respond. Please try again.";
      default:
        return "Server error. Please try again.";
    }
  }

  String? _extractErrorMessage(dio.Response? response) {
    if (response != null && response.data is Map) {
      if (response.data.containsKey('message')) {
        return response.data['message'];
      }
      if (response.data['error'] is Map &&
          response.data['error'].containsKey('message')) {
        return response.data['error']['message'];
      }
    } else if (response?.data is String) {
      return response?.data;
    }
    return null;
  }

  DateTime? _lastExpirationRedirect;

  Future<void> _handleTokenExpiration() async {
    final lastSave = sessionManager.lastTokenSaveAt;
    if (lastSave != null &&
        DateTime.now().difference(lastSave) < const Duration(seconds: 20)) {
      return;
    }

    final now = DateTime.now();
    if (_lastExpirationRedirect != null &&
        now.difference(_lastExpirationRedirect!) < const Duration(seconds: 3)) {
      return;
    }
    _lastExpirationRedirect = now;

    await sessionManager.clearTokens();

    Get.offAllNamed(AppRoutes.login);
  }

  Future<bool> proactiveTokenRefresh() async {
    final isAccessExpired = await sessionManager.isAccessTokenExpired();
    if (!isAccessExpired) return true;

    return await _handleTokenRefresh() == _RefreshResult.success;
  }

  dio.Dio get client => _dio;
}
