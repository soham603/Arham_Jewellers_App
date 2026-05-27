import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/domain/entities/user_model.dart';
import 'package:ratnesh_gold_app/services/Dependencies.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';
import 'package:ratnesh_gold_app/utils/SessionManager.dart';
import 'package:ratnesh_gold_app/utils/ToastUtil.dart';

class AuthController extends GetxController {
  final _userLoginState = CurrentAppState.INITIAL.obs;
  CurrentAppState get userLoginState => _userLoginState.value;

  final _adminLoginState = CurrentAppState.INITIAL.obs;
  CurrentAppState get adminLoginState => _adminLoginState.value;

  final RxString _userLoginErrorMsg = "".obs;
  String get userLoginErrorMsg => _userLoginErrorMsg.value;

  final RxString _adminLoginErrorMsg = "".obs;
  String get adminLoginErrorMsg => _adminLoginErrorMsg.value;

  final Rxn<UserModel> _user = Rxn<UserModel>();
  UserModel? get user => _user.value;

  Future<bool> loginUserWithPhone({
    required String phoneNumber,
    required String password,
    required String deviceId,
    required BuildContext context,
    VoidCallback? onSuccess,
  }) async {
    if (_userLoginState.value == CurrentAppState.LOADING) return false;

    try {
      _userLoginState.value = CurrentAppState.LOADING;
      _userLoginErrorMsg.value = "";

      final response = await httpClient.post(
        "/api/v1/auth/user-login",
        options: Options(extra: {"requiresAuth": false}),
        data: {
          "phoneNumber": phoneNumber,
          "password": password,
          "deviceId": "AP3A.240905.015.A2",
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];

        final user = UserModel.fromJson(data['user']);
        _user.value = user;
        await SessionManager().saveUserData(user);

        final bool tokensSaved = await SessionManager().saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
          accessTokenExpiry: data['accessTokenValidTill'],
          refreshTokenExpiry: data['enableAccessTill'],
        );

        if (tokensSaved) {
          _userLoginState.value = CurrentAppState.SUCCESS;
          ToastUtils.showSuccess(
            context,
            response.data['message'] ?? "Login successful!",
          );
          onSuccess?.call();
          return true;
        }
      } else {
        _userLoginErrorMsg.value = response.data['message'] ?? "Login failed";
        _userLoginState.value = CurrentAppState.ERROR;
        ToastUtils.showError(context, _userLoginErrorMsg.value);
      }
    } on DioException catch (e) {
      _handleLoginError(e, isUserLogin: true);
    } catch (e) {
      _userLoginErrorMsg.value = "An unexpected error occurred";
      _userLoginState.value = CurrentAppState.ERROR;
      ToastUtils.showError(context, _userLoginErrorMsg.value);
    }
    return false;
  }

  Future<bool> loginAdminWithPhone({
    required String phoneNumber,
    required String password,
    required String deviceId,
    required BuildContext context,
    VoidCallback? onSuccess,
  }) async {
    if (_adminLoginState.value == CurrentAppState.LOADING) return false;

    try {
      _adminLoginState.value = CurrentAppState.LOADING;
      _adminLoginErrorMsg.value = "";

      final response = await httpClient.post(
        "/api/v1/auth/admin-login",
        data: {
          "phoneNumber": phoneNumber,
          "password": password,
          "deviceId": deviceId,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];

        final user = UserModel.fromJson(data['admin']);
        _user.value = user;
        await SessionManager().saveUserData(user);

        final bool tokensSaved = await SessionManager().saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
          accessTokenExpiry: data['accessTokenValidTill'],
          refreshTokenExpiry: data['refreshTokenValidTill'],
        );

        if (tokensSaved) {
          _adminLoginState.value = CurrentAppState.SUCCESS;
          ToastUtils.showSuccess(
            context,
            response.data['message'] ?? "Admin login successful!",
          );
          onSuccess?.call();
          return true;
        }
      } else {
        _adminLoginErrorMsg.value =
            response.data['message'] ?? "Admin login failed";
        _adminLoginState.value = CurrentAppState.ERROR;
        ToastUtils.showError(context, _adminLoginErrorMsg.value);
      }
    } on DioException catch (e) {
      _handleLoginError(e, isUserLogin: false);
    } catch (e) {
      _adminLoginErrorMsg.value = "An unexpected error occurred";
      _adminLoginState.value = CurrentAppState.ERROR;
      ToastUtils.showError(context, _adminLoginErrorMsg.value);
    }
    return false;
  }

  void _handleLoginError(DioException e, {required bool isUserLogin}) {
    String errorMsg = "An unexpected error occurred";

    if (e.response?.data != null) {
      errorMsg =
          e.response!.data['error']['message'] ??
          e.response!.data['detail'] ??
          errorMsg;
    }

    if (isUserLogin) {
      _userLoginErrorMsg.value = errorMsg;
      _userLoginState.value = CurrentAppState.ERROR;
      ToastUtils.showError(Get.context!, _userLoginErrorMsg.value);
    } else {
      _adminLoginErrorMsg.value = errorMsg;
      _adminLoginState.value = CurrentAppState.ERROR;
      ToastUtils.showError(Get.context!, _adminLoginErrorMsg.value);
    }
  }

  Future<void> logoutUser(
    BuildContext context, {
    VoidCallback? onComplete,
  }) async {
    final sessionManager = SessionManager();
    try {
      await sessionManager.clearAll();
      _user.value = null;
      ToastUtils.showSuccess(context, "Logged out successfully!");
      onComplete?.call();
    } catch (e) {
      ToastUtils.showError(context, "Logout failed. Please try again.");
    }
  }

  Future<void> logoutAdmin(
    BuildContext context, {
    VoidCallback? onComplete,
  }) async {
    final sessionManager = SessionManager();
    try {
      await sessionManager.clearAll();
      _user.value = null;
      ToastUtils.showSuccess(context, "Admin logged out successfully!");
      onComplete?.call();
    } catch (e) {
      ToastUtils.showError(context, "Logout failed. Please try again.");
    }
  }


  // NAMAN - add fnc for register
}


