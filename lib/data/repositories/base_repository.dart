import 'package:ratnesh_gold_app/domain/entities/paginated_result.dart';
import 'package:ratnesh_gold_app/services/Dependencies.dart';

class ApiException implements Exception {
  final String message;
  final String? code;
  final Map<String, dynamic>? response;

  ApiException(this.message, {this.code, this.response});

  @override
  String toString() => message;
}

class BaseRepository {
  final dio = httpClient;

  void checkApiError(Map<String, dynamic> responseData) {
    if (responseData['code'] == 'ERROR') {
      final errorData = responseData['error'];
      final errorMessage = responseData['message'] ?? 'Something went wrong';
      final errorCode = errorData is Map ? errorData['code'] : null;
      throw ApiException(errorMessage, code: errorCode, response: responseData);
    }
  }

  ({int total, int totalPages, int currentPage}) parsePagination(
    Map<String, dynamic> data,
  ) {
    final rawTotal = data['total'] ?? data['totalCount'] ?? data['totalRecords'] ?? 0;
    final total = rawTotal is int
        ? rawTotal
        : int.tryParse(rawTotal.toString()) ?? 0;
    final rawTotalPages = data['totalPages'] ?? 1;
    final totalPages = rawTotalPages is int
        ? rawTotalPages
        : int.tryParse(rawTotalPages.toString()) ?? 1;
    final rawPage = data['page'] ?? data['currentPage'] ?? 1;
    final currentPage = rawPage is int
        ? rawPage
        : int.tryParse(rawPage.toString()) ?? 1;
    return (total: total, totalPages: totalPages, currentPage: currentPage);
  }

  void requireData(Map<String, dynamic> responseData) {
    if (responseData['data'] == null) {
      throw ApiException(
        responseData['message'] ?? 'No data received',
        response: responseData,
      );
    }
  }

  PaginatedResult<T> parsePaginatedList<T>(
    Map<String, dynamic> responseData, {
    String listKey = 'data',
    required T Function(dynamic) fromJson,
  }) {
    final data = responseData['data'];

    if (data is Map<String, dynamic>) {
      final rawList = data[listKey] is List ? data[listKey] as List : [];
      final pagination = parsePagination(data);

      return PaginatedResult(
        items: rawList.map((e) => fromJson(e)).toList(),
        total: pagination.total,
        totalPages: pagination.totalPages,
        currentPage: pagination.currentPage,
      );
    }

    throw ApiException(
      'Unexpected response format',
      response: responseData,
    );
  }
}
