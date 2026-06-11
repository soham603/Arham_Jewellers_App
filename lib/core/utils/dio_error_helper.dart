import 'package:dio/dio.dart';

class DioErrorHelper {
  static String getMessage(dynamic error) {
    if (error is DioException) {
      if (error.response?.data is Map) {
        final data = error.response!.data as Map;
        final msg = data['error']?['message'] ??
            data['message'] ??
            data['detail'] ??
            data['error'];
        if (msg is String && msg.isNotEmpty) return msg;
      }
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          return 'Connection timed out. Please try again.';
        case DioExceptionType.sendTimeout:
          return 'Request timed out. Please try again.';
        case DioExceptionType.receiveTimeout:
          return 'Response timed out. Please try again.';
        case DioExceptionType.connectionError:
          return 'No internet connection.';
        case DioExceptionType.badResponse:
          return _handleBadResponse(error.response?.statusCode);
        default:
          return 'An unexpected error occurred.';
      }
    }
    return error?.toString() ?? 'An unexpected error occurred.';
  }

  static String _handleBadResponse(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request.';
      case 401:
        return 'Session expired. Please login again.';
      case 403:
        return 'Access denied.';
      case 404:
        return 'Resource not found.';
      case 500:
        return 'Server error. Please try again later.';
      default:
        return 'Server error ($statusCode).';
    }
  }
}
