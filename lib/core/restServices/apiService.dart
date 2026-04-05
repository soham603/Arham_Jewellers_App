import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:ratnesh_gold_app/core/constants/ApiUrlConstants.dart';
import 'package:ratnesh_gold_app/services/Dependencies.dart';
import 'package:ratnesh_gold_app/utils/SessionManager.dart';

class BaseHttpService {
  late final Dio _dio;

  SessionManager sessionManager = SessionManager();

  BaseHttpService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiUrlConstants.UAT_BASE_URL,
        connectTimeout: const Duration(minutes: 2),
        sendTimeout: const Duration(minutes: 2),
        receiveTimeout: const Duration(minutes: 2),
        headers: {"Content-Type": "application/json"},
      ),
    );
    _initializeInterceptors();
  }

  void _initializeInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          debugPrint("➡️ Request: ${options.method} ${options.uri}");

          final requiresAuth = options.extra["requiresAuth"] ?? true;

          if (requiresAuth) {
            final token = await sessionManager.getAccessToken();

            if (token != null) {
              options.headers["Authorization"] = "Bearer $token";
            }
          }

          return handler.next(options);
        },

        onResponse: (response, handler) {
          debugPrint("✅ Response [${response.statusCode}]: ${response.data}");
          return handler.next(response);
        },

        onError: (DioException error, handler) async {
          debugPrint(
            "❌ Error [${error.response?.statusCode}]: ${error.message}",
          );

          if (error.response?.statusCode == 401) {
            await _handleTokenExpiration();
          }

          final errorMessage = _extractErrorMessage(error.response);

          // Re-throw error with clean message
          handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              error: errorMessage ?? "An unexpected error occurred.",
              type: error.type,
            ),
          );
        },
      ),
    );
  }

  String? _extractErrorMessage(Response? response) {
    if (response != null &&
        response.data is Map &&
        response.data.containsKey('message')) {
      return response.data['message'];
    } else if (response?.data is String) {
      return response?.data;
    }
    return null;
  }

  Future<void> _handleTokenExpiration() async {
    debugPrint("⚠️ Token expired. Redirecting to SignIn.");
    await sessionManager.clearTokens();

    final context = navigatorKey.currentContext;
    if (context != null && context.mounted) {
      // TODO: Navigate user to SignInScreen
      // Navigator.pushAndRemoveUntil(
      //   context,
      //   MaterialPageRoute(builder: (_) => SignInScreen()),
      //   (route) => false,
      // );
    }
  }

  Dio get client => _dio;
}
