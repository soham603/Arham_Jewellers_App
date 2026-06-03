import 'dart:async';

import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:ratnesh_gold_app/domain/entities/admin/handsetChangeModel.dart';
import 'package:ratnesh_gold_app/services/Dependencies.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';
import 'package:ratnesh_gold_app/utils/Logger.dart';
import 'package:ratnesh_gold_app/utils/ToastUtil.dart';
import 'package:flutter/material.dart';

class HandsetChangeController extends GetxController {
  static HandsetChangeController get instance => Get.find();

  static const int _pageLimit = 10;

  final _requests = <HandsetChangeRequestModel>[].obs;
  List<HandsetChangeRequestModel> get requests => _requests;

  final _state = CurrentAppState.INITIAL.obs;
  CurrentAppState get state => _state.value;

  final _total = 0.obs;
  int get total => _total.value;

  int _page = 1;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  final _activeFilter = 'PENDING'.obs;
  String get activeFilter => _activeFilter.value;

  final _actionState = CurrentAppState.INITIAL.obs;
  CurrentAppState get actionState => _actionState.value;

  final _actioningId = ''.obs;
  String get actioningId => _actioningId.value;

  final _error = ''.obs;
  String get error => _error.value;

  final _searchQuery = ''.obs;
  String get searchQuery => _searchQuery.value;

  Timer? _debounce;

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }

  Future<void> fetchRequests({bool isPagination = false}) async {
    if (!_hasMore && isPagination) return;
    if (_state.value == CurrentAppState.LOADING) return;

    if (!isPagination) {
      _state.value = CurrentAppState.LOADING;
      _page = 1;
      _hasMore = true;
    }

    try {
      final queryParams = <String, dynamic>{
        'page': _page,
        'limit': _pageLimit,
        'status': _activeFilter.value,
      };

      if (_searchQuery.value.trim().isNotEmpty) {
        queryParams['search'] = _searchQuery.value.trim();
      }

      final response = await httpClient.get(
        '/api/v1/auth/device-change-request',
        queryParameters: queryParams,
        options: Options(extra: {'requiresAuth': true}),
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final List raw = (data['requests'] ?? data['data'] ?? data['results'] ?? data) is List
            ? (data['requests'] ?? data['data'] ?? data['results'] ?? data) as List
            : [];
        final fetched =
            raw.map((e) => HandsetChangeRequestModel.fromJson(e)).toList();

        if (isPagination) {
          _requests.addAll(fetched);
        } else {
          _requests.value = fetched;
        }

        final pagination = data['pagination'];
        _total.value = pagination?['totalRecords'] ?? data['total'] ?? data['totalItems'] ?? fetched.length;

        if (fetched.length < _pageLimit) {
          _hasMore = false;
        } else {
          _page++;
        }

        _state.value = CurrentAppState.SUCCESS;
      } else {
        _state.value = CurrentAppState.ERROR;
        _error.value = response.data['message'] ?? 'Failed to fetch';
      }
    } catch (e, st) {
      _state.value = CurrentAppState.ERROR;
      _error.value = e.toString();
      Logger.error('HandsetChangeController', 'fetchRequests: $e\n$st');
    }
  }

  void setFilter(String status) {
    if (_activeFilter.value == status) return;
    _activeFilter.value = status;
    fetchRequests();
  }

  Future<void> loadMore() async {
    if (!_hasMore || _state.value == CurrentAppState.LOADING) return;
    await fetchRequests(isPagination: true);
  }

  Future<void> refresh() async {
    _page = 1;
    _hasMore = true;
    await fetchRequests();
  }

  void onSearchChanged(String query) {
    _searchQuery.value = query;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      fetchRequests();
    });
  }

  void clearSearch() {
    _searchQuery.value = '';
    _debounce?.cancel();
    fetchRequests();
  }

  Future<bool> approveRequest({
    required String requestId,
    required BuildContext context,
  }) async {
    return _handleAction(
      requestId: requestId,
      body: {
        'requestId': requestId,
        'action': 'APPROVE',
      },
      context: context,
    );
  }

  Future<bool> rejectRequest({
    required String requestId,
    required String rejectionReason,
    required BuildContext context,
  }) async {
    return _handleAction(
      requestId: requestId,
      body: {
        'requestId': requestId,
        'action': 'REJECT',
        'rejectionReason': rejectionReason,
      },
      context: context,
    );
  }

  Future<bool> _handleAction({
    required String requestId,
    required Map<String, dynamic> body,
    required BuildContext context,
  }) async {
    try {
      _actionState.value = CurrentAppState.LOADING;
      _actioningId.value = requestId;
      _error.value = '';

      final response = await httpClient.patch(
        '/api/v1/auth/device-change-request/action',
        data: body,
        options: Options(extra: {'requiresAuth': true}),
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data['success'] != false) {
        _actionState.value = CurrentAppState.SUCCESS;
        _actioningId.value = '';
        ToastUtils.showSuccess(
          context,
          response.data['message'] ?? 'Action completed successfully',
        );
        await refresh();
        return true;
      }

      final message = response.data?['error']?['message'] ??
          response.data?['message'] ??
          'Action failed';

      _actionState.value = CurrentAppState.ERROR;
      _error.value = message;
      ToastUtils.showError(context, message);
      return false;
    } on DioException catch (e, st) {
      Logger.error('HandsetChangeController', '_handleAction Dio: $e\n$st');

      String message = e.response?.data?['error']?['message'] ??
          e.response?.data?['message'] ??
          e.message ??
          'Something went wrong';

      _actionState.value = CurrentAppState.ERROR;
      _error.value = message;
      ToastUtils.showError(context, message);
      return false;
    } catch (e, st) {
      Logger.error('HandsetChangeController', '_handleAction: $e\n$st');
      _actionState.value = CurrentAppState.ERROR;
      _error.value = e.toString();
      ToastUtils.showError(context, e.toString());
      return false;
    } finally {
      _actioningId.value = '';
    }
  }
}
