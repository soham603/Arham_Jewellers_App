import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/domain/entities/user_model.dart';
import 'package:ratnesh_gold_app/services/Dependencies.dart';
import 'package:ratnesh_gold_app/services/notification_service.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';
import 'package:ratnesh_gold_app/utils/Logger.dart';

import 'package:ratnesh_gold_app/utils/SessionManager.dart';
import 'package:ratnesh_gold_app/utils/ToastUtil.dart';
import 'package:ratnesh_gold_app/core/constants/ApiUrlConstants.dart';

class AuthController extends GetxController {
  final _userLoginState = CurrentAppState.INITIAL.obs;
  CurrentAppState get userLoginState => _userLoginState.value;

  final _adminLoginState = CurrentAppState.INITIAL.obs;
  CurrentAppState get adminLoginState => _adminLoginState.value;

  // New states for Registration flow
  final _userRegisterState = CurrentAppState.INITIAL.obs;
  CurrentAppState get userRegisterState => _userRegisterState.value;

  final RxString _userLoginErrorMsg = "".obs;
  String get userLoginErrorMsg => _userLoginErrorMsg.value;

  final RxString _adminLoginErrorMsg = "".obs;
  String get adminLoginErrorMsg => _adminLoginErrorMsg.value;

  // New error message state for Registration flow
  final RxString _userRegisterErrorMsg = "".obs;
  String get userRegisterErrorMsg => _userRegisterErrorMsg.value;

  // Forgot Password state
  final _forgotPasswordState = CurrentAppState.INITIAL.obs;
  CurrentAppState get forgotPasswordState => _forgotPasswordState.value;

  final Rxn<UserModel> _user = Rxn<UserModel>();
  UserModel? get user => _user.value;

  final RxBool _isAdmin = false.obs;
  bool get isAdmin => _isAdmin.value;
  RxBool get isAdminRx => _isAdmin;

  Future<String?> _getFcmToken() async {
    final inMemory = NotificationService().fcmToken;
    if (inMemory != null && inMemory.isNotEmpty) return inMemory;
    return SessionManager().getFcmToken();
  }

  @override
  void onInit() {
    super.onInit();
    _restoreSession();
  }

  void _restoreSession() async {
    final sessionManager = SessionManager();
    final userData = await sessionManager.getUserData();
    final isAdminFlag = await sessionManager.getIsAdmin();
    if (userData != null) {
      _user.value = userData;
      _isAdmin.value = isAdminFlag;
    }
  }

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

      final fcmToken = await _getFcmToken();

      final response = await httpClient.post(
        "/api/v1/auth/user-login",
        options: Options(extra: {"requiresAuth": false}),
        data: {
          "phoneNumber": phoneNumber,
          "password": password,
          "deviceId": deviceId,
          if (fcmToken != null && fcmToken.isNotEmpty) "fcmToken": fcmToken,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];

        final user = UserModel.fromJson(data['user']);
        _user.value = user;
        _isAdmin.value = false;
        await SessionManager().saveUserData(user);
        await SessionManager().saveIsAdmin(false);

        await SessionManager().saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
          accessTokenExpiry: data['accessTokenValidTill'],
          refreshTokenExpiry: data['enableAccessTill'],
        );

        _userLoginState.value = CurrentAppState.SUCCESS;
        ToastUtils.showSuccess(
          
          response.data['message'] ?? "Login successful!",
        );
        onSuccess?.call();
        return true;
      } else if (response.statusCode == 202) {
        _userLoginState.value = CurrentAppState.SUCCESS;
        ToastUtils.showInfo(
          
          response.data['message'] ?? "Your approval request has been sent. Please wait for admin approval.",
        );
      } else {
        _scheduleError(
          context,
          response.data['message'] ?? "Login failed",
          isUserLogin: true,
        );
      }
    } on DioException catch (e) {
      _handleLoginError(e, isUserLogin: true);
    } catch (e) {
      _scheduleError(
        context,
        "An unexpected error occurred",
        isUserLogin: true,
      );
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

      final fcmToken = await _getFcmToken();

      final response = await httpClient.post(
        "/api/v1/auth/admin-login",
        options: Options(extra: {"requiresAuth": false}),
        data: {
          "phoneNumber": phoneNumber,
          "password": password,
          "deviceId": deviceId,
          if (fcmToken != null && fcmToken.isNotEmpty) "fcmToken": fcmToken,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];

        final user = UserModel.fromJson(data['admin']);
        _user.value = user;
        _isAdmin.value = true;
        await SessionManager().saveUserData(user);
        await SessionManager().saveIsAdmin(true);

        await SessionManager().saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
          accessTokenExpiry: data['accessTokenValidTill'],
          refreshTokenExpiry: data['refreshTokenValidTill'],
        );

        _adminLoginState.value = CurrentAppState.SUCCESS;
        ToastUtils.showSuccess(
          
          response.data['message'] ?? "Admin login successful!",
        );
        onSuccess?.call();
        return true;
      } else if (response.statusCode == 202) {
        _adminLoginState.value = CurrentAppState.SUCCESS;
        ToastUtils.showInfo(
          
          response.data['message'] ?? "Your approval request has been sent. Please wait for admin approval.",
        );
      } else {
        _scheduleError(
          context,
          response.data['message'] ?? "Admin login failed",
          isUserLogin: false,
        );
      }
    } on DioException catch (e) {
      _handleLoginError(e, isUserLogin: false);
    } catch (e) {
      _scheduleError(
        context,
        "An unexpected error occurred",
        isUserLogin: false,
      );
    }
    return false;
  }

  void _handleLoginError(DioException e, {required bool isUserLogin}) {
    String errorMsg = "An unexpected error occurred";

    try {
      if (e.response?.data != null) {
        final data = e.response!.data as Map;
        if (data['error'] is Map) {
          errorMsg = (data['error']['message'] as String?) ?? errorMsg;
        } else {
          errorMsg = (data['message'] as String?) ??
              (data['detail'] as String?) ??
              errorMsg;
        }
      }
    } catch (e) {
      Logger.warning("AuthController", "Failed to extract error message from DioException: $e");
    }

    final ctx = Get.context;
    if (ctx != null) {
      _scheduleError(
        ctx,
        errorMsg,
        isUserLogin: isUserLogin,
      );
    }
  }

  void _scheduleError(BuildContext context, String message, {required bool isUserLogin}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isUserLogin) {
        _userLoginErrorMsg.value = message;
        _userLoginState.value = CurrentAppState.ERROR;
      } else {
        _adminLoginErrorMsg.value = message;
        _adminLoginState.value = CurrentAppState.ERROR;
      }
      ToastUtils.showError(message);
    });
  }

  Future<void> logoutUser(
    BuildContext context, {
    VoidCallback? onComplete,
  }) async {
    final sessionManager = SessionManager();
    try {
      await sessionManager.clearAll();
      _user.value = null;
      _isAdmin.value = false;
      ToastUtils.showSuccess("Logged out successfully!");
      onComplete?.call();
    } catch (e) {
      ToastUtils.showError("Logout failed. Please try again.");
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
      _isAdmin.value = false;
      ToastUtils.showSuccess("Admin logged out successfully!");
      onComplete?.call();
    } catch (e) {
      ToastUtils.showError("Logout failed. Please try again.");
    }
  }

  // NAMAN - Register Function Implementation
  Future<bool> registerUser({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
    required String deviceId,
    required String gstNumber,
    required String city,
    required String area,
    required String state,
    required String pincode,
    required String companyName,
    required String deviceName,
    String? fcmToken,
    required BuildContext context,
    VoidCallback? onSuccess,
  }) async {
    if (_userRegisterState.value == CurrentAppState.LOADING) return false;

    try {
      _userRegisterState.value = CurrentAppState.LOADING;
      _userRegisterErrorMsg.value = "";

      final response = await httpClient.post(
        "/api/v1/auth/register",
        options: Options(extra: {"requiresAuth": false}),
        data: {
          "email": email,
          "password": password,
          "name": name,
          "phoneNumber": phoneNumber,
          "deviceId": deviceId,
          "gstNumber": gstNumber,
          "state": state,
          "city": city,
          "area": area,
          "pincode": pincode,
          "companyName": companyName,
          "deviceName": deviceName,
          if (fcmToken != null && fcmToken.isNotEmpty) "fcmToken": fcmToken,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data['success'] == true || response.data['success'] == null) {
          _userRegisterState.value = CurrentAppState.SUCCESS;
          ToastUtils.showSuccess(
            
            response.data['message'] ?? "Registration successful!",
          );
          onSuccess?.call();
          return true;
        } else {
          _userRegisterErrorMsg.value = response.data['message'] ?? "Registration failed";
          _userRegisterState.value = CurrentAppState.ERROR;
          ToastUtils.showError(_userRegisterErrorMsg.value);
        }
      } else {
        _userRegisterErrorMsg.value = response.data['message'] ?? "Registration failed";
        _userRegisterState.value = CurrentAppState.ERROR;
        ToastUtils.showError(_userRegisterErrorMsg.value);
      }
    } on DioException catch (e) {
      String errorMsg = "An unexpected error occurred";
      if (e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map) {
          final error = data['error'];
          errorMsg = (error is Map ? error['message'] : error?.toString()) ??
              data['detail']?.toString() ??
              data['message']?.toString() ??
              errorMsg;
        }
      }
      _userRegisterErrorMsg.value = errorMsg;
      _userRegisterState.value = CurrentAppState.ERROR;
      ToastUtils.showError(_userRegisterErrorMsg.value);
    } catch (e) {
      _userRegisterErrorMsg.value = "An unexpected error occurred";
      _userRegisterState.value = CurrentAppState.ERROR;
      ToastUtils.showError(_userRegisterErrorMsg.value);
    }
    return false;
  }

  Future<bool> forgotPassword({
    required String phoneNumber,
    required BuildContext context,
    VoidCallback? onSuccess,
  }) async {
    if (_forgotPasswordState.value == CurrentAppState.LOADING) return false;

    try {
      _forgotPasswordState.value = CurrentAppState.LOADING;

      final response = await httpClient.post(
        ApiUrlConstants.FORGOT_PASSWORD,
        options: Options(extra: {"requiresAuth": false}),
        data: {"phoneNumber": phoneNumber},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        _forgotPasswordState.value = CurrentAppState.SUCCESS;
        ToastUtils.showSuccess(
          
          response.data['message'] ?? "Reset request submitted successfully!",
        );
        onSuccess?.call();
        return true;
      } else {
        _forgotPasswordState.value = CurrentAppState.ERROR;
        ToastUtils.showError(
          
          response.data['message'] ?? "Failed to submit reset request",
        );
      }
    } on DioException catch (e) {
      String errorMsg = "An unexpected error occurred";
      if (e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map) {
          final error = data['error'];
          errorMsg = (error is Map ? error['message'] : error?.toString()) ??
              data['detail']?.toString() ??
              data['message']?.toString() ??
              errorMsg;
        }
      }
      _forgotPasswordState.value = CurrentAppState.ERROR;
      ToastUtils.showError(errorMsg);
    } catch (e) {
      _forgotPasswordState.value = CurrentAppState.ERROR;
      ToastUtils.showError("An unexpected error occurred");
    }
    return false;
  }
}
