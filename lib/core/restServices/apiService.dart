import 'dart:async';
import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/app/routes/app_routes.dart';
import 'package:ratnesh_gold_app/core/constants/ApiUrlConstants.dart';
import 'package:ratnesh_gold_app/services/deviceIdService.dart';
import 'package:ratnesh_gold_app/utils/Logger.dart';
import 'package:ratnesh_gold_app/utils/SessionManager.dart';

class BaseHttpService {
  late final dio.Dio _dio;
  late final dio.Dio _refreshDio;

  SessionManager sessionManager = SessionManager();

  Completer<bool>? _refreshCompleter;

  BaseHttpService() {
    _dio = dio.Dio(
      dio.BaseOptions(
        baseUrl: ApiUrlConstants.BASE_URL,
        connectTimeout: const Duration(minutes: 2),
        sendTimeout: const Duration(minutes: 2),
        receiveTimeout: const Duration(minutes: 2),
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
            Logger.error(
              "BaseHttpService",
              "onRequest interceptor error: $e",
            );
          }

          return handler.next(options);
        },

        onResponse: (response, handler) {
          return handler.next(response);
        },

        onError: (dio.DioException error, handler) async {
          final statusCode = error.response?.statusCode;
          Logger.error(
            "BaseHttpService",
            "Error [$statusCode]: ${error.message}",
          );

          // Retry on 502/503/504 (server temporarily unavailable)
          if (statusCode == 502 || statusCode == 503 || statusCode == 504) {
            if (error.requestOptions.extra["retried"] != true) {
              Logger.info("BaseHttpService", "Retrying request due to server error $statusCode...");
              error.requestOptions.extra["retried"] = true;
              await Future.delayed(const Duration(seconds: 2));
              try {
                final retryResponse = await _dio.fetch(error.requestOptions);
                return handler.resolve(retryResponse);
              } on dio.DioException catch (retryError) {
                // Fall through to normal error handling
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
              final refreshed = await _handleTokenRefresh();

              if (refreshed) {
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
              }

              await _handleTokenExpiration();
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

  Future<bool> _handleTokenRefresh() async {
    if (_refreshCompleter != null && !_refreshCompleter!.isCompleted) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<bool>();

    try {
      final refreshToken = await sessionManager.getRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        Logger.warning("BaseHttpService", "No refresh token available.");
        _refreshCompleter!.complete(false);
        return false;
      }

      final isRefreshExpired = await sessionManager.isRefreshTokenExpired();
      if (isRefreshExpired) {
        Logger.warning("BaseHttpService", "Refresh token is expired.");
        _refreshCompleter!.complete(false);
        return false;
      }

      Logger.info("BaseHttpService", "Attempting token refresh...");

      final deviceId = await getDeviceId();

      final response = await _refreshDio.post(
        ApiUrlConstants.REFRESH_TOKEN,
        data: {
          "refreshToken": refreshToken,
          "deviceId": deviceId,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];

        final newAccessToken = data['accessToken'] as String?;
        final newRefreshToken = data['refreshToken'] as String?;
        final accessExpiry = data['accessTokenValidTill'] as String?;
        final refreshExpiry =
            data['refreshTokenValidTill'] as String? ??
            data['enableAccessTill'] as String?;

        if (newAccessToken != null &&
            newRefreshToken != null &&
            accessExpiry != null &&
            refreshExpiry != null) {
          await sessionManager.saveTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
            accessTokenExpiry: accessExpiry,
            refreshTokenExpiry: refreshExpiry,
          );

          Logger.info("BaseHttpService", "Token refresh successful.");
          _refreshCompleter!.complete(true);
          return true;
        }
      }

      Logger.warning(
        "BaseHttpService",
        "Token refresh failed: unexpected response.",
      );
      _refreshCompleter!.complete(false);
      return false;
    } catch (e) {
      Logger.error("BaseHttpService", "Token refresh error: $e");
      _refreshCompleter!.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
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

  Future<void> _handleTokenExpiration() async {
    Logger.warning("BaseHttpService", "Token expired. Redirecting to SignIn.");
    await sessionManager.clearTokens();

    Get.offAllNamed(AppRoutes.login);
  }

  /// Proactively refresh the access token before it expires.
  /// Returns true if refresh succeeded, false otherwise.
  Future<bool> proactiveTokenRefresh() async {
    final isAccessExpired = await sessionManager.isAccessTokenExpired();
    if (!isAccessExpired) return true;

    return _handleTokenRefresh();
  }

  dio.Dio get client => _dio;
}
