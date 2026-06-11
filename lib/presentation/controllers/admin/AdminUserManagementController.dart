import 'package:ratnesh_gold_app/utils/ToastUtil.dart';
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:ratnesh_gold_app/data/repositories/admin_access_repository.dart';
import 'package:ratnesh_gold_app/domain/entities/admin/userSearchModel.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';
import 'package:ratnesh_gold_app/utils/Logger.dart';

class AdminUserManagementController extends GetxController {
  static AdminUserManagementController get instance => Get.find();

  final _adminAccessRepo = AdminAccessRepository();

  static const int _pageLimit = 20;

  final _users = <UserSearchModel>[].obs;
  List<UserSearchModel> get users => _users;

  final _state = CurrentAppState.INITIAL.obs;
  CurrentAppState get state => _state.value;

  final _total = 0.obs;
  int get total => _total.value;

  int _page = 1;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  final _searchQuery = ''.obs;
  String get searchQuery => _searchQuery.value;

  final _searchMode = UserSearchMode.NAME.obs;
  UserSearchMode get searchMode => _searchMode.value;

  final _activeFilter = 'ALL'.obs;
  String get activeFilter => _activeFilter.value;

  final _error = ''.obs;
  String get error => _error.value;

  final _actionState = CurrentAppState.INITIAL.obs;
  CurrentAppState get actionState => _actionState.value;

  final _actioningId = ''.obs;
  String get actioningId => _actioningId.value;

  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    fetchUsers();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }

  // ── Fetch users ──────────────────────────────────────────────────────────
  Future<void> fetchUsers({bool isPagination = false}) async {
    if (!_hasMore && isPagination) return;
    if (_state.value == CurrentAppState.LOADING && !isPagination) return;

    _state.value = CurrentAppState.LOADING;
    if (!isPagination) {
      _page = 1;
      _hasMore = true;
    }

    try {
      final queryParams = <String, dynamic>{
        'page': _page,
        'limit': _pageLimit,
      };

      if (_searchQuery.value.trim().isNotEmpty) {
        switch (_searchMode.value) {
          case UserSearchMode.NAME:
            queryParams['name'] = _searchQuery.value.trim();
            break;
          case UserSearchMode.EMAIL:
            queryParams['email'] = _searchQuery.value.trim();
            break;
          case UserSearchMode.PHONE:
            queryParams['phoneNumber'] = _searchQuery.value.trim();
            break;
        }
      }

      final response = await _adminAccessRepo.fetchUsers(
        queryParams: queryParams,
      );

      if (response['data'] != null) {
        final data = response['data']['data'];
        final List raw = data['users'] ?? [];
        final fetched = raw.map((e) => UserSearchModel.fromJson(e)).toList();

        if (isPagination) {
          _users.addAll(fetched);
        } else {
          _users.value = fetched;
        }

        _total.value = data['total'] ?? fetched.length;

        if (fetched.length < _pageLimit) {
          _hasMore = false;
        } else {
          _page++;
        }

        _state.value = CurrentAppState.SUCCESS;
      } else {
        _state.value = CurrentAppState.ERROR;
        _error.value = response['message'] ?? 'Failed to fetch users';
      }
    } catch (e, st) {
      _state.value = CurrentAppState.ERROR;
      _error.value = e.toString();
      Logger.error('AdminUserManagementController', 'fetchUsers: $e\n$st');
    }
  }

  // ── Search ───────────────────────────────────────────────────────────────
  void onSearchChanged(String query) {
    _searchQuery.value = query;
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      fetchUsers();
    } else {
      _debounce = Timer(const Duration(milliseconds: 400), () {
        fetchUsers();
      });
    }
  }

  void toggleSearchMode() {
    final modes = UserSearchMode.values;
    final nextIndex = (modes.indexOf(_searchMode.value) + 1) % modes.length;
    _searchMode.value = modes[nextIndex];
    _searchQuery.value = '';
    fetchUsers();
  }

  void clearSearch() {
    _searchQuery.value = '';
    fetchUsers();
  }

  void setFilter(String filter) {
    if (_activeFilter.value == filter) return;
    _activeFilter.value = filter;
    fetchUsers();
  }

  List<UserSearchModel> get filteredUsers {
    if (_activeFilter.value == 'ALL') return _users;
    return _users.where((u) => u.role == _activeFilter.value).toList();
  }

  // ── Pagination ───────────────────────────────────────────────────────────
  Future<void> loadMore() async {
    if (!_hasMore || _state.value == CurrentAppState.LOADING) return;
    await fetchUsers(isPagination: true);
  }

  @override
  Future<void> refresh() async {
    _page = 1;
    _hasMore = true;
    await fetchUsers();
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  /// Toggle user activation status (ACTIVE / DEACTIVATED)
  Future<bool> toggleUserActivation({
    required String userId,
    required String action,
  }) async {
    return _handleAction(
      userId: userId,
      actionType: AdminAction.toggleActivation,
      body: {'userId': userId, 'action': action},
      actionLabel: action == 'ACTIVE' ? 'activated' : 'deactivated',
    );
  }

  /// Toggle staff status for a user
  Future<bool> toggleStaff({
    required String userId,
    required bool isStaff,
  }) async {
    return _handleAction(
      userId: userId,
      actionType: AdminAction.toggleStaff,
      body: {'userId': userId, 'isStaff': isStaff},
      actionLabel: isStaff ? 'granted staff' : 'removed staff',
    );
  }

  /// Toggle retailer status for a user
  Future<bool> toggleRetailer({
    required String userId,
    required bool isRetailer,
  }) async {
    return _handleAction(
      userId: userId,
      actionType: AdminAction.toggleRetailer,
      body: {'userId': userId, 'retailUser': isRetailer},
      actionLabel: isRetailer ? 'granted retailer' : 'removed retailer',
    );
  }

  /// Admin reset password for a user with pending forgot password status
  Future<bool> adminResetPassword({
    required String userId,
    required String newPassword,
  }) async {
    return _handleAction(
      userId: userId,
      actionType: AdminAction.resetPassword,
      body: {'userId': userId, 'newPassword': newPassword},
      actionLabel: 'password reset',
    );
  }

  // ── Generic action handler ───────────────────────────────────────────────
  Future<bool> _handleAction({
    required String userId,
    required AdminAction actionType,
    required Map<String, dynamic> body,
    required String actionLabel,
  }) async {
    try {
      _actionState.value = CurrentAppState.LOADING;
      _actioningId.value = userId;

      final Map<String, dynamic> response;
      switch (actionType) {
        case AdminAction.toggleStaff:
          response = await _adminAccessRepo.toggleStaff(data: body);
          break;
        case AdminAction.toggleRetailer:
          response = await _adminAccessRepo.toggleRetailer(data: body);
          break;
        case AdminAction.resetPassword:
          response = await _adminAccessRepo.adminResetPassword(data: body);
          break;
        case AdminAction.toggleActivation:
          response = await _adminAccessRepo.toggleUserActivation(data: body);
          break;
      }

      if (response['success'] != false) {
        _actionState.value = CurrentAppState.SUCCESS;
        ToastUtils.showSuccess(response['message'] ?? 'User $actionLabel');
        await refresh();
        return true;
      }

      final message = response['error']?['message'] ??
          response['message'] ??
          'Action failed';

      _actionState.value = CurrentAppState.ERROR;
      _error.value = message;
      ToastUtils.showError(message);
      return false;
    } on DioException catch (e, st) {
      Logger.error('AdminUserManagementController', 'action Dio: $e\n$st');

      String message = 'Something went wrong';
      if (e.response?.data is Map) {
        final data = e.response!.data;
        message = data['error']?['message'] ?? data['message'] ?? e.message ?? 'Something went wrong';
      } else {
        message = e.message ?? 'Something went wrong';
      }

      _actionState.value = CurrentAppState.ERROR;
      _error.value = message;
      ToastUtils.showError(message);
      return false;
    } catch (e, st) {
      Logger.error('AdminUserManagementController', 'action: $e\n$st');
      _actionState.value = CurrentAppState.ERROR;
      _error.value = e.toString();
      ToastUtils.showError(e.toString());
      return false;
    } finally {
      _actioningId.value = '';
    }
  }
}

enum UserSearchMode {
  NAME,
  EMAIL,
  PHONE,
}

enum AdminAction {
  toggleActivation,
  toggleStaff,
  toggleRetailer,
  resetPassword,
}
