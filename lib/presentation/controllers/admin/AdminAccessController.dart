import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/domain/entities/admin/adminAccessModel.dart';
import 'package:ratnesh_gold_app/services/Dependencies.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';
import 'package:ratnesh_gold_app/utils/Logger.dart';
import 'package:ratnesh_gold_app/utils/ToastUtil.dart';

class AdminAccessController extends GetxController {
  static AdminAccessController get instance => Get.find();

  final _state = CurrentAppState.INITIAL.obs;
  CurrentAppState get state => _state.value;

  final _list = <AccessRequestModel>[].obs;
  List<AccessRequestModel> get list => _list;

  final _error = "".obs;
  String get error => _error.value;

  final _handleAccessState = CurrentAppState.INITIAL.obs;
  CurrentAppState get handleAccessState => _handleAccessState.value;

  final _handleAccessError = "".obs;
  String get handleAccessError => _handleAccessError.value;

  int currentPage = 1;
  int totalPages = 1;
  bool isPaginated = false;
  bool isLoadingMore = false;

  String? status;
  String? userId;
  List<String>? phoneNumbers;

  Future<void> getAllAccessRequests({
    int? page,
    int? limit,
    String? status,
    String? userId,
    List<String>? phoneNumbers,
    bool isLoadMore = false,
  }) async {
    try {
      if (!isLoadMore) {
        _state.value = CurrentAppState.LOADING;
        _list.clear();
        currentPage = 1;
      } else {
        if (isLoadingMore || currentPage >= totalPages) return;
        isLoadingMore = true;
      }

      final queryParams = <String, dynamic>{};

      if (page != null && limit != null) {
        queryParams['page'] = page;
        queryParams['limit'] = limit;
      }

      if (status != null) queryParams['status'] = status;
      if (userId != null) queryParams['userId'] = userId;

      if (phoneNumbers != null && phoneNumbers.isNotEmpty) {
        queryParams['phoneNumbers'] = phoneNumbers;
      }

      final response = await httpClient.get(
        "/api/v1/admin-access/get-all-access",
        queryParameters: queryParams,
        options: Options(extra: {"requiresAuth": true}),
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];

        isPaginated = data['paginated'] ?? false;

        final List resultsJson = data['results'] ?? [];

        final results = resultsJson
            .map((e) => AccessRequestModel.fromJson(e))
            .toList();

        if (isLoadMore) {
          _list.addAll(results);
        } else {
          _list.value = results;
        }

        if (isPaginated) {
          currentPage = data['page'] ?? 1;
          totalPages = data['totalPages'] ?? 1;
        }

        _state.value = CurrentAppState.SUCCESS;

        Logger.info(
          "AdminAccessController",
          "Fetched ${results.length} access requests",
        );
      } else {
        _state.value = CurrentAppState.ERROR;
        _error.value = "Failed to fetch access requests";
      }
    } catch (e, st) {
      _state.value = CurrentAppState.ERROR;
      _error.value = e.toString();

      Logger.error(
        "AdminAccessController",
        "Error fetching access requests: $e",
        stackTrace: st,
      );
    } finally {
      isLoadingMore = false;
    }
  }

  Future<void> loadMore(int limit) async {
    if (!isPaginated) return;

    await getAllAccessRequests(
      page: currentPage + 1,
      limit: limit,
      status: status,
      userId: userId,
      phoneNumbers: phoneNumbers,
      isLoadMore: true,
    );
  }

  Future<void> applyFilters({
    String? status,
    String? userId,
    List<String>? phoneNumbers,
    int? limit,
  }) async {
    this.status = status;
    this.userId = userId;
    this.phoneNumbers = phoneNumbers;

    await getAllAccessRequests(
      page: 1,
      limit: limit,
      status: status,
      userId: userId,
      phoneNumbers: phoneNumbers,
    );
  }

  Future<void> resetFilters({int? limit}) async {
    status = null;
    userId = null;
    phoneNumbers = null;

    await getAllAccessRequests(page: 1, limit: limit);
  }

  Future<void> refreshData({int? limit}) async {
    await getAllAccessRequests(
      page: 1,
      limit: limit,
      status: status,
      userId: userId,
      phoneNumbers: phoneNumbers,
    );
  }

  Future<bool> handleAccessRequest({
    required String requestId,
    required String action,
    String? approvedTillDate,
    required BuildContext context,
    VoidCallback? onSuccess,
  }) async {
    try {
      _handleAccessState.value = CurrentAppState.LOADING;
      _handleAccessError.value = "";

      if (action == "APPROVED" && approvedTillDate == null) {
        _handleAccessState.value = CurrentAppState.ERROR;
        _handleAccessError.value = "Approved date required";
        ToastUtils.showError(context, _handleAccessError.value);
        return false;
      }

      final body = {
        "requestId": requestId,
        "action": action,
        if (approvedTillDate != null) "approvedTillDate": approvedTillDate,
      };

      final response = await httpClient.post(
        "/api/v1/admin-access/handle-access",
        data: body,
        options: Options(extra: {"requiresAuth": true}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _handleAccessState.value = CurrentAppState.SUCCESS;

        ToastUtils.showSuccess(
          context,
          response.data['message'] ?? "Action completed successfully",
        );

        _list.removeWhere((e) => e.id == requestId);

        onSuccess?.call();
        return true;
      } else {
        _handleAccessState.value = CurrentAppState.ERROR;
        _handleAccessError.value =
            response.data['message'] ?? "Failed to process request";

        ToastUtils.showError(context, _handleAccessError.value);
      }
    } catch (e) {
      _handleAccessState.value = CurrentAppState.ERROR;
      _handleAccessError.value = e.toString();

      ToastUtils.showError(context, _handleAccessError.value);
    }

    return false;
  }
}
