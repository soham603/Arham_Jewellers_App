import 'dart:async';

import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:ratnesh_gold_app/data/repositories/auth_repository.dart';
import 'package:ratnesh_gold_app/core/utils/dio_error_helper.dart';
import 'package:ratnesh_gold_app/domain/entities/admin/handsetChangeModel.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';
import 'package:ratnesh_gold_app/utils/ToastUtil.dart';
import 'package:flutter/material.dart';

class HandsetChangeController extends GetxController {
  static HandsetChangeController get instance => Get.find();

  final _authRepo = AuthRepository();

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
  void onInit() {
    super.onInit();
    fetchRequests();
  }

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

      final result = await _authRepo.fetchHandsetRequests(queryParams: queryParams);

      if (isPagination) {
        _requests.addAll(result.items);
      } else {
        _requests.value = result.items;
      }

      _total.value = result.total;

      if (result.items.length < _pageLimit) {
          _hasMore = false;
        } else {
          _page++;
        }

        _state.value = CurrentAppState.SUCCESS;
    } catch (e, st) {
      _state.value = CurrentAppState.ERROR;
      _error.value = e.toString();
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

  @override
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
      action: 'APPROVE',
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
      action: 'REJECT',
      rejectionReason: rejectionReason,
      context: context,
    );
  }

  Future<bool> _handleAction({
    required String requestId,
    required String action,
    String? rejectionReason,
    required BuildContext context,
  }) async {
    try {
      _actionState.value = CurrentAppState.LOADING;
      _actioningId.value = requestId;
      _error.value = '';

      final response = await _authRepo.handleHandsetRequest(
        requestId: requestId,
        action: action,
        rejectionReason: rejectionReason,
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data['success'] != false) {
        _actionState.value = CurrentAppState.SUCCESS;
        _actioningId.value = '';
        ToastUtils.showSuccess(
          
          response.data['message'] ?? 'Action completed successfully',
        );
        await refresh();
        return true;
      }

      final resData = response.data;
      final message = resData['error']?['message'] ?? resData['message'] ?? 'Action failed';

      _actionState.value = CurrentAppState.ERROR;
      _error.value = message;
      ToastUtils.showError(message);
      return false;
    } on DioException catch (e, st) {
      final message = DioErrorHelper.getMessage(e);
      _actionState.value = CurrentAppState.ERROR;
      _error.value = message;
      ToastUtils.showError(message);
      return false;
    } catch (e, st) {
      _actionState.value = CurrentAppState.ERROR;
      _error.value = e.toString();
      ToastUtils.showError(e.toString());
      return false;
    } finally {
      _actioningId.value = '';
    }
  }
}
