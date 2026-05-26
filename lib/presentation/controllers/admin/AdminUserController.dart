import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:ratnesh_gold_app/domain/entities/admin/adminAccessModel.dart';
import 'package:ratnesh_gold_app/services/Dependencies.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';
import 'package:ratnesh_gold_app/utils/Logger.dart';

class AdminUserController extends GetxController {
  static AdminUserController get instance => Get.find();

  static const int _pageLimit = 10;

  final _requests = <AccessRequestModel>[].obs;
  List<AccessRequestModel> get requests => _requests;

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

  // Search related
  final _searchMode = SearchMode.PHONE.obs;
  SearchMode get searchMode => _searchMode.value;
  
  final _searchQuery = ''.obs;
  String get searchQuery => _searchQuery.value;
  
  final _searchResults = <UserSearchModel>[].obs;
  List<UserSearchModel> get searchResults => _searchResults;
  
  final _searchState = CurrentAppState.INITIAL.obs;
  CurrentAppState get searchState => _searchState.value;
  
  final _selectedUserId = Rxn<String>();
  String? get selectedUserId => _selectedUserId.value;

  @override
  void onInit() {
    super.onInit();
    fetchRequests();
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

      // Add search params
      if (_searchQuery.value.trim().isNotEmpty && _searchMode.value == SearchMode.PHONE) {
        queryParams['phoneNumbers'] = _searchQuery.value.trim();
      } else if (_selectedUserId.value != null) {
        queryParams['userId'] = _selectedUserId.value;
      }

      final response = await httpClient.get(
        '/api/v1/admin-access/get-all-access',
        queryParameters: queryParams,
        options: Options(extra: {'requiresAuth': true}),
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final List raw = data['results'] ?? [];
        final fetched = raw.map((e) => AccessRequestModel.fromJson(e)).toList();

        if (isPagination) {
          _requests.addAll(fetched);
        } else {
          _requests.value = fetched;
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
        _error.value = response.data['message'] ?? 'Failed to fetch';
      }
    } catch (e, st) {
      _state.value = CurrentAppState.ERROR;
      _error.value = e.toString();
      Logger.error('AdminUserController', 'fetchRequests: $e\n$st');
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

  // Search Methods
  void toggleSearchMode() {
    _searchMode.value = _searchMode.value == SearchMode.PHONE 
        ? SearchMode.USER 
        : SearchMode.PHONE;
    // Clear search when toggling
    _searchQuery.value = '';
    _searchResults.clear();
    _selectedUserId.value = null;
    _searchState.value = CurrentAppState.INITIAL;
    fetchRequests();
  }

  void onSearchTextChanged(String query) {
    _searchQuery.value = query;
    
    if (_searchMode.value == SearchMode.PHONE) {
      // Direct search - just update query and fetch
      fetchRequests();
    } else {
      // User mode - search users and show dropdown
      if (query.trim().isEmpty) {
        _searchResults.clear();
        _searchState.value = CurrentAppState.INITIAL;
      } else {
        _searchUsers(query);
      }
    }
  }

  Future<void> _searchUsers(String query) async {
    _searchState.value = CurrentAppState.LOADING;

    try {
      final response = await httpClient.get(
        '/api/v1/admin-access/get-all-users',
        queryParameters: {'name': query.trim()},
        options: Options(extra: {'requiresAuth': true}),
      );

      if (response.statusCode == 200) {
        final data = response.data['data']['data'];
        final List usersRaw = data['users'] ?? [];
        final users = usersRaw.map((e) => UserSearchModel.fromJson(e)).toList();
        _searchResults.value = users;
        _searchState.value = CurrentAppState.SUCCESS;
      } else {
        _searchState.value = CurrentAppState.ERROR;
        _searchResults.clear();
      }
    } catch (e, st) {
      _searchState.value = CurrentAppState.ERROR;
      _searchResults.clear();
      Logger.error('AdminUserController', '_searchUsers: $e\n$st');
    }
  }

  void selectUser(UserSearchModel user) {
    _selectedUserId.value = user.id;
    _searchQuery.value = '';
    _searchResults.clear();
    _searchState.value = CurrentAppState.INITIAL;
    // Refresh requests with new userId filter
    _page = 1;
    _hasMore = true;
    fetchRequests();
  }

  void clearSearch() {
    _searchQuery.value = '';
    _searchResults.clear();
    _selectedUserId.value = null;
    _searchState.value = CurrentAppState.INITIAL;
    _page = 1;
    _hasMore = true;
    fetchRequests();
  }

  String getSelectedUserName() {
    return '';
  }

  Future<bool> approveRequest({
    required String requestId,
    required DateTime approvedTillDate,
  }) async {
    return _handleAction(
      requestId: requestId,
      body: {
        'requestId': requestId,
        'action': 'APPROVED',
        'approvedTillDate': approvedTillDate.toIso8601String(),
      },
      onSuccess: (req) => req.copyWith(
        status: 'APPROVED', 
        approvedTill: approvedTillDate
      ),
    );
  }

  Future<bool> rejectRequest({required String requestId}) async {
    return _handleAction(
      requestId: requestId,
      body: {'requestId': requestId, 'action': 'REJECTED'},
      onSuccess: (req) => req.copyWith(
        status: 'REJECTED',
        approvedTill: null
      ),
    );
  }

  Future<bool> _handleAction({
    required String requestId,
    required Map<String, dynamic> body,
    required AccessRequestModel Function(AccessRequestModel) onSuccess,
  }) async {
    try {
      _actionState.value = CurrentAppState.LOADING;
      _actioningId.value = requestId;
      _error.value = '';

      final response = await httpClient.post(
        '/api/v1/admin-access/handle-access',
        data: body,
        options: Options(extra: {'requiresAuth': true}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final index = _requests.indexWhere((r) => r.id == requestId);

        if (index != -1) {
          final updated = onSuccess(_requests[index]);

          if (updated.status != _activeFilter.value) {
            _requests.removeAt(index);
            _total.value = (_total.value - 1).clamp(0, 999999);
          } else {
            _requests[index] = updated;
          }
        }

        _actionState.value = CurrentAppState.SUCCESS;
        _actioningId.value = '';
        Get.snackbar("Success", response.data["message"] ?? "Action completed");
        return true;
      }

      final message = response.data?["error"]?["message"] ??
          response.data?["message"] ??
          "Action failed";

      _actionState.value = CurrentAppState.ERROR;
      _error.value = message;
      Get.snackbar("Failed", message);
      return false;
    } on DioException catch (e, st) {
      Logger.error('AdminUserController', '_handleAction Dio: $e\n$st');
      
      String message = e.response?.data?["error"]?["message"] ??
          e.response?.data?["message"] ??
          e.message ??
          "Something went wrong";

      _actionState.value = CurrentAppState.ERROR;
      _error.value = message;
      Get.snackbar("Failed", message, snackPosition: SnackPosition.BOTTOM);
      return false;
    } catch (e, st) {
      Logger.error('AdminUserController', '_handleAction: $e\n$st');
      _actionState.value = CurrentAppState.ERROR;
      _error.value = e.toString();
      Get.snackbar("Error", e.toString(), snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      _actioningId.value = '';
    }
  }
}

enum SearchMode {
  PHONE, 
  USER, 
}

// domain/entities/admin/userSearchModel.dart

class UserSearchModel {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String role;
  final String? city;
  final String? area;
  final String? companyName;
  final String accountStatus;
  final String userActivationStatus;
  final DateTime? enableAccessTill;
  final DateTime createdAt;
  final List<AccessRequestRef>? accessRequests;

  UserSearchModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.role,
    this.city,
    this.area,
    this.companyName,
    required this.accountStatus,
    required this.userActivationStatus,
    this.enableAccessTill,
    required this.createdAt,
    this.accessRequests,
  });

  factory UserSearchModel.fromJson(Map<String, dynamic> json) {
    return UserSearchModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      role: json['role'] ?? 'USER',
      city: json['city'],
      area: json['area'],
      companyName: json['companyName'],
      accountStatus: json['accountStatus'] ?? 'PENDING',
      userActivationStatus: json['userActivationStatus'] ?? 'ACTIVE',
      enableAccessTill: json['enableAccessTill'] != null
          ? DateTime.parse(json['enableAccessTill'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      accessRequests: json['accessRequests'] != null
          ? (json['accessRequests'] as List)
              .map((e) => AccessRequestRef.fromJson(e))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role,
      'city': city,
      'area': area,
      'companyName': companyName,
      'accountStatus': accountStatus,
      'userActivationStatus': userActivationStatus,
      'enableAccessTill': enableAccessTill?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'accessRequests': accessRequests?.map((e) => e.toJson()).toList(),
    };
  }

  UserSearchModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? role,
    String? city,
    String? area,
    String? companyName,
    String? accountStatus,
    String? userActivationStatus,
    DateTime? enableAccessTill,
    DateTime? createdAt,
    List<AccessRequestRef>? accessRequests,
  }) {
    return UserSearchModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      city: city ?? this.city,
      area: area ?? this.area,
      companyName: companyName ?? this.companyName,
      accountStatus: accountStatus ?? this.accountStatus,
      userActivationStatus: userActivationStatus ?? this.userActivationStatus,
      enableAccessTill: enableAccessTill ?? this.enableAccessTill,
      createdAt: createdAt ?? this.createdAt,
      accessRequests: accessRequests ?? this.accessRequests,
    );
  }
}

class AccessRequestRef {

  final String id;
  final String status;
  final DateTime requestedAt;
  final DateTime? approvedTill;
  final DateTime createdAt;

  AccessRequestRef({
    required this.id,
    required this.status,
    required this.requestedAt,
    this.approvedTill,
    required this.createdAt,
  });

  factory AccessRequestRef.fromJson(Map<String, dynamic> json) {
    return AccessRequestRef(
      id: json['id'] ?? '',
      status: json['status'] ?? 'PENDING',
      requestedAt: json['requestedAt'] != null
          ? DateTime.parse(json['requestedAt'])
          : DateTime.now(),
      approvedTill: json['approvedTill'] != null
          ? DateTime.parse(json['approvedTill'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'requestedAt': requestedAt.toIso8601String(),
      'approvedTill': approvedTill?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  AccessRequestRef copyWith({
    String? id,
    String? status,
    DateTime? requestedAt,
    DateTime? approvedTill,
    DateTime? createdAt,
  }) {
    return AccessRequestRef(
      id: id ?? this.id,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      approvedTill: approvedTill ?? this.approvedTill,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}