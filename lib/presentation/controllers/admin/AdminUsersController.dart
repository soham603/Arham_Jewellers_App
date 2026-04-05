import 'package:dio/dio.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:ratnesh_gold_app/domain/entities/user_model.dart';
import 'package:ratnesh_gold_app/services/Dependencies.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';
import 'package:ratnesh_gold_app/utils/Logger.dart';

class AdminUsersController extends GetxController {
  static AdminUsersController get instance => Get.find();

  final _listState = CurrentAppState.INITIAL.obs;
  CurrentAppState get listState => _listState.value;

  final _actionState = CurrentAppState.INITIAL.obs;
  CurrentAppState get actionState => _actionState.value;

  final _migrateUserState = CurrentAppState.INITIAL.obs;
  CurrentAppState get migrateUserState => _migrateUserState.value;

  final _error = "".obs;
  String get error => _error.value;

  final RxList<UserModel> _users = <UserModel>[].obs;
  List<UserModel> get users => _users;

  int page = 1;
  int limit = 10;
  int totalPages = 1;
  bool isLoadingMore = false;
  bool hasMore = true;

  String? name;
  String? email;
  String? phoneNumber;

  Future<void> getAllUsers({bool isLoadMore = false}) async {
    try {
      if (!isLoadMore) {
        _listState.value = CurrentAppState.LOADING;
        page = 1;
        hasMore = true;
        _users.clear();
      } else {
        if (isLoadingMore || !hasMore) return;
        isLoadingMore = true;
      }

      final queryParams = {
        "page": page,
        "limit": limit,
        if (name != null && name!.isNotEmpty) "name": name,
        if (email != null && email!.isNotEmpty) "email": email,
        if (phoneNumber != null && phoneNumber!.isNotEmpty)
          "phoneNumber": phoneNumber,
      };

      final response = await httpClient.get(
        "/api/v1/user/get-all-users",
        queryParameters: queryParams,
        options: Options(extra: {"requiresAuth": true}),
      );

      if (response.statusCode == 200) {
        /// 🔥 CORRECT PARSING
        final root = response.data;
        final data = root['data']?['data'];

        final List usersJson = data['users'] ?? [];
        totalPages = data['totalPages'] ?? 1;

        final List<UserModel> fetchedUsers = usersJson
            .map((e) => UserModel.fromJson(e))
            .toList();

        /// 🔥 HANDLE PAGINATION
        if (isLoadMore) {
          _users.addAll(fetchedUsers);
        } else {
          _users.value = fetchedUsers;
        }

        /// 🔥 PAGE LOGIC
        if (page >= totalPages) {
          hasMore = false;
        } else {
          page++;
        }

        _listState.value = CurrentAppState.SUCCESS;

        Logger.info("AdminUsers", "Fetched ${fetchedUsers.length} users");
      } else {
        _listState.value = CurrentAppState.ERROR;
        _error.value = "Failed to fetch users";
      }
    } catch (e, st) {
      _listState.value = CurrentAppState.ERROR;
      _error.value = e.toString();

      Logger.error("AdminUsers", "Error: $e", stackTrace: st);
    } finally {
      isLoadingMore = false;
    }
  }

  Future<void> loadMore() async {
    await getAllUsers(isLoadMore: true);
  }

  Future<void> applyFilters({
    String? name,
    String? email,
    String? phoneNumber,
  }) async {
    this.name = name;
    this.email = email;
    this.phoneNumber = phoneNumber;

    await getAllUsers(isLoadMore: false);
  }

  Future<void> resetFilters() async {
    name = null;
    email = null;
    phoneNumber = null;

    await getAllUsers(isLoadMore: false);
  }

  Future<void> refreshData() async {
    await getAllUsers(isLoadMore: false);
  }

  Future<bool> updateUserActivation({
    required String userId,
    required String action,
  }) async {
    try {
      _actionState.value = CurrentAppState.LOADING;

      final response = await httpClient.patch(
        "/api/v1/user/update-user-activation",
        data: {"userId": userId, "action": action},
        options: Options(extra: {"requiresAuth": true}),
      );

      if (response.statusCode == 200) {
        final updatedUserJson = response.data['data'];
        final updatedUser = UserModel.fromJson(updatedUserJson);

        /// 🔥 UPDATE LOCAL LIST CORRECTLY
        final index = _users.indexWhere((e) => e.id == userId);

        if (index != -1) {
          _users[index] = updatedUser;
          _users.refresh(); // important for UI
        }

        _actionState.value = CurrentAppState.SUCCESS;

        Logger.info("AdminUsers", "User $action success");

        return true;
      } else {
        _actionState.value = CurrentAppState.ERROR;
        _error.value = response.data['message'] ?? "Something went wrong";
      }
    } catch (e, st) {
      _actionState.value = CurrentAppState.ERROR;
      _error.value = e.toString();

      Logger.error("AdminUsers", "Activation error: $e", stackTrace: st);
    }

    return false;
  }

  Future<bool> importUsersFromExcel({required String filePath}) async {
    try {
      _migrateUserState.value = CurrentAppState.LOADING;

      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(
          filePath,
          filename: filePath.split("/").last,
        ),
      });

      final response = await httpClient.post(
        "/api/v1/admin-access/import-allUsers",
        data: formData,
        options: Options(
          headers: {"Content-Type": "multipart/form-data"},
          extra: {"requiresAuth": true},
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _actionState.value = CurrentAppState.SUCCESS;

        Logger.info("AdminUsers", "Excel import successful");

        /// OPTIONAL: Refresh list after import
        await getAllUsers();

        return true;
      } else {
        _migrateUserState.value = CurrentAppState.ERROR;
        _error.value = response.data['message'] ?? "Import failed";

        Logger.error("AdminUsers", "Import failed: ${_error.value}");
      }
    } catch (e, st) {
      _migrateUserState.value = CurrentAppState.ERROR;
      _error.value = e.toString();

      Logger.error("AdminUsers", "Import error: $e", stackTrace: st);
    }

    return false;
  }
}
