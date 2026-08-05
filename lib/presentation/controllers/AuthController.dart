import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/data/repositories/auth_repository.dart';
import 'package:ratnesh_gold_app/domain/entities/user_model.dart';
import 'package:ratnesh_gold_app/services/Dependencies.dart';
import 'package:ratnesh_gold_app/services/notification_service.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';
import 'package:ratnesh_gold_app/core/utils/dio_error_helper.dart';
import 'package:ratnesh_gold_app/utils/SessionManager.dart';
import 'package:ratnesh_gold_app/utils/ToastUtil.dart';
import 'package:ratnesh_gold_app/presentation/controllers/notification_controller.dart';

class AuthController extends GetxController with WidgetsBindingObserver {
  final _authRepo = AuthRepository();

  final _userLoginState = CurrentAppState.INITIAL.obs;
  CurrentAppState get userLoginState => _userLoginState.value;

  final _adminLoginState = CurrentAppState.INITIAL.obs;
  CurrentAppState get adminLoginState => _adminLoginState.value;

  final _userRegisterState = CurrentAppState.INITIAL.obs;
  CurrentAppState get userRegisterState => _userRegisterState.value;

  final RxString _userLoginErrorMsg = "".obs;
  String get userLoginErrorMsg => _userLoginErrorMsg.value;

  final RxString _adminLoginErrorMsg = "".obs;
  String get adminLoginErrorMsg => _adminLoginErrorMsg.value;

  final RxString _userRegisterErrorMsg = "".obs;
  String get userRegisterErrorMsg => _userRegisterErrorMsg.value;

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
    try {
      return await SessionManager()
          .getFcmToken()
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      return null;
    }
  }

  Future<void> _safePersist(Future<void> Function() op) async {
    try {
      await op().timeout(const Duration(seconds: 5));
    } catch (e) {
    }
  }

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _restoreSession();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _onAppResumed();
    }
  }

  void _onAppResumed() async {
    try {
      final isAccessExpired = await SessionManager().isAccessTokenExpired();
      if (isAccessExpired) {
        await baseHttpService.proactiveTokenRefresh();
      }
    } catch (e) {
    }
  }

  void _restoreSession() async {
    final sessionManager = SessionManager();
    final userData = await sessionManager.getUserData();
    final isAdminFlag = await sessionManager.getIsAdmin();
    if (userData != null) {
      _user.value = userData;
      _isAdmin.value = isAdminFlag;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (isAdminFlag) {
          NotificationService().subscribeAdminTopics();
        } else {
          NotificationService().subscribeUserTopics();
        }
      });
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

      final response = await _authRepo.loginUser(
        phone: phoneNumber,
        password: password,
        deviceId: deviceId,
        fcmToken: fcmToken,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];

        final user = UserModel.fromJson(data['user']);
        _user.value = user;
        _isAdmin.value = false;
        await _safePersist(() => SessionManager().saveUserData(user));
        await _safePersist(() => SessionManager().saveIsAdmin(false));

        await _safePersist(
          () => SessionManager().saveTokens(
            accessToken: data['accessToken'],
            refreshToken: data['refreshToken'],
            accessTokenExpiry: data['accessTokenValidTill'],
            refreshTokenExpiry: data['enableAccessTill'],
          ),
        );

        _userLoginState.value = CurrentAppState.SUCCESS;
        ToastUtils.showSuccess(response.data['message'] ?? "Login successful!");
        await NotificationService().subscribeUserTopics();
        onSuccess?.call();
        return true;
      } else if (response.statusCode == 202) {
        _userLoginState.value = CurrentAppState.SUCCESS;
        ToastUtils.showInfo(
          response.data['message'] ??
              "Your approval request has been sent. Please wait for admin approval.",
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

      final response = await _authRepo.loginAdmin(
        phone: phoneNumber,
        password: password,
        deviceId: deviceId,
        fcmToken: fcmToken,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];

        final user = UserModel.fromJson(data['admin']);
        _user.value = user;
        _isAdmin.value = true;
        await _safePersist(() => SessionManager().saveUserData(user));
        await _safePersist(() => SessionManager().saveIsAdmin(true));

        await _safePersist(
          () => SessionManager().saveTokens(
            accessToken: data['accessToken'],
            refreshToken: data['refreshToken'],
            accessTokenExpiry: data['accessTokenValidTill'],
            refreshTokenExpiry: data['refreshTokenValidTill'],
          ),
        );

        _adminLoginState.value = CurrentAppState.SUCCESS;
        ToastUtils.showSuccess(
          response.data['message'] ?? "Admin login successful!",
        );
        await NotificationService().subscribeAdminTopics();
        onSuccess?.call();
        return true;
      } else if (response.statusCode == 202) {
        _adminLoginState.value = CurrentAppState.SUCCESS;
        ToastUtils.showInfo(
          response.data['message'] ??
              "Your approval request has been sent. Please wait for admin approval.",
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
    final errorMsg = DioErrorHelper.getMessage(e);
    final ctx = Get.context;
    if (ctx != null) {
      _scheduleError(ctx, errorMsg, isUserLogin: isUserLogin);
    }
  }

  void _scheduleError(
    BuildContext context,
    String message, {
    required bool isUserLogin,
  }) {
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
      await NotificationService().unsubscribeAllTopics();
      await NotificationService().clearAllNotifications();
      await NotificationService().resetIdCounter();
      if (Get.isRegistered<NotificationController>()) {
        Get.find<NotificationController>().clearAll();
      }
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
      await NotificationService().unsubscribeAllTopics();
      await NotificationService().clearAllNotifications();
      await NotificationService().resetIdCounter();
      if (Get.isRegistered<NotificationController>()) {
        Get.find<NotificationController>().clearAll();
      }
      await sessionManager.clearAll();
      _user.value = null;
      _isAdmin.value = false;
      ToastUtils.showSuccess("Admin logged out successfully!");
      onComplete?.call();
    } catch (e) {
      ToastUtils.showError("Logout failed. Please try again.");
    }
  }

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
    String? staffName,
    String? staffPhoneNumber,
    required BuildContext context,
    VoidCallback? onSuccess,
  }) async {
    if (_userRegisterState.value == CurrentAppState.LOADING) return false;

    try {
      _userRegisterState.value = CurrentAppState.LOADING;
      _userRegisterErrorMsg.value = "";

      final response = await _authRepo.registerUser(
        userData: {
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
          if (staffName != null && staffName.isNotEmpty) "staffName": staffName,
          if (staffPhoneNumber != null && staffPhoneNumber.isNotEmpty)
            "staffPhoneNumber": staffPhoneNumber,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data['success'] == true ||
            response.data['success'] == null) {
          _userRegisterState.value = CurrentAppState.SUCCESS;
          ToastUtils.showSuccess(
            response.data['message'] ?? "Registration successful!",
          );
          onSuccess?.call();
          return true;
        } else {
          _userRegisterErrorMsg.value =
              response.data['message'] ?? "Registration failed";
          _userRegisterState.value = CurrentAppState.ERROR;
          ToastUtils.showError(_userRegisterErrorMsg.value);
        }
      } else {
        _userRegisterErrorMsg.value =
            response.data['message'] ?? "Registration failed";
        _userRegisterState.value = CurrentAppState.ERROR;
        ToastUtils.showError(_userRegisterErrorMsg.value);
      }
    } on DioException catch (e) {
      final errorMsg = DioErrorHelper.getMessage(e);
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

      final response = await _authRepo.forgotPassword(phone: phoneNumber);

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
      final errorMsg = DioErrorHelper.getMessage(e);
      _forgotPasswordState.value = CurrentAppState.ERROR;
      ToastUtils.showError(errorMsg);
    } catch (e) {
      _forgotPasswordState.value = CurrentAppState.ERROR;
      ToastUtils.showError("An unexpected error occurred");
    }
    return false;
  }
}
