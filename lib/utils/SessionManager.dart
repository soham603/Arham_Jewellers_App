import 'dart:convert';
import 'package:ratnesh_gold_app/domain/entities/user_model.dart';
import 'package:ratnesh_gold_app/utils/Logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DatabaseKeyConstants {
  static const String ACCESS_TOKEN = 'access_token';
  static const String REFRESH_TOKEN = 'refresh_token';

  static const String ACCESS_TOKEN_EXPIRY = 'access_token_expiry';
  static const String REFRESH_TOKEN_EXPIRY = 'refresh_token_expiry';

  static const String USER = 'user_data';
  static const String FCM_TOKEN = 'fcm_token';
}

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();

  factory SessionManager() => _instance;

  SessionManager._internal();

  final _storage = const FlutterSecureStorage();

  // ── Token persistence 
  Future<bool> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String accessTokenExpiry,
    required String refreshTokenExpiry,
  }) async {
    try {
      final accessExpiry =
          DateTime.parse(accessTokenExpiry).millisecondsSinceEpoch;
      final refreshExpiry =
          DateTime.parse(refreshTokenExpiry).millisecondsSinceEpoch;

      await _storage.write(key: DatabaseKeyConstants.ACCESS_TOKEN, value: accessToken);
      await _storage.write(key: DatabaseKeyConstants.REFRESH_TOKEN, value: refreshToken);
      await _storage.write(
          key: DatabaseKeyConstants.ACCESS_TOKEN_EXPIRY, value: accessExpiry.toString());
      await _storage.write(
          key: DatabaseKeyConstants.REFRESH_TOKEN_EXPIRY, value: refreshExpiry.toString());

      Logger.info("SessionManager", "Tokens saved");
      return true;
    } catch (e, st) {
      Logger.error("SessionManager", "Error saving tokens → $e",
          stackTrace: st);
      return false;
    }
  }

  Future<String?> getAccessToken() async {
    final token = await _storage.read(key: DatabaseKeyConstants.ACCESS_TOKEN);
    Logger.info("SessionManager",
        "getAccessToken: ${token != null ? 'present' : 'null'}");
    return token;
  }

  Future<String?> getRefreshToken() async {
    final token = await _storage.read(key: DatabaseKeyConstants.REFRESH_TOKEN);
    Logger.info("SessionManager",
        "getRefreshToken: ${token != null ? 'present' : 'null'}");
    return token;
  }

  Future<int?> getAccessTokenExpiry() async {
    final value = await _storage.read(key: DatabaseKeyConstants.ACCESS_TOKEN_EXPIRY);
    return value != null ? int.tryParse(value) : null;
  }

  Future<int?> getRefreshTokenExpiry() async {
    final value = await _storage.read(key: DatabaseKeyConstants.REFRESH_TOKEN_EXPIRY);
    return value != null ? int.tryParse(value) : null;
  }

  Future<bool> isAccessTokenExpired() async {
    final expiry = await getAccessTokenExpiry();
    if (expiry == null) return true;
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    Logger.info(
      "SessionManager",
      "Checking access token expiry : ${now >= expiry}",
    );
    return now >= expiry;
  }

  Future<bool> isRefreshTokenExpired() async {
    final expiry = await getRefreshTokenExpiry();
    if (expiry == null) return true;
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    return now >= expiry;
  }

  Future<bool> clearTokens() async {
    try {
      await _storage.delete(key: DatabaseKeyConstants.ACCESS_TOKEN);
      await _storage.delete(key: DatabaseKeyConstants.REFRESH_TOKEN);
      await _storage.delete(key: DatabaseKeyConstants.ACCESS_TOKEN_EXPIRY);
      await _storage.delete(key: DatabaseKeyConstants.REFRESH_TOKEN_EXPIRY);

      Logger.info("SessionManager", "Tokens cleared");
      return true;
    } catch (e, st) {
      Logger.error("SessionManager", "Error clearing tokens → $e",
          stackTrace: st);
      return false;
    }
  }

  // ── Admin flag persistence 
  static const _isAdminKey = 'IS_ADMIN';

  Future<void> saveIsAdmin(bool isAdmin) async {
    await _storage.write(key: _isAdminKey, value: isAdmin.toString());
  }

  Future<bool> getIsAdmin() async {
    final value = await _storage.read(key: _isAdminKey);
    return value == 'true';
  }

  // ── User data persistence 
  Future<bool> saveUserData(UserModel user) async {
    try {
      String userJson = jsonEncode(user.toJson());
      await _storage.write(key: DatabaseKeyConstants.USER, value: userJson);
      Logger.info("SessionManager", "User saved");
      return true;
    } catch (e, st) {
      Logger.error("SessionManager", "Error saving user → $e",
          stackTrace: st);
      return false;
    }
  }

  Future<UserModel?> getUserData() async {
    final jsonString = await _storage.read(key: DatabaseKeyConstants.USER);
    if (jsonString == null) return null;

    try {
      return UserModel.fromJson(jsonDecode(jsonString));
    } catch (e, st) {
      Logger.error("SessionManager", "Failed to parse user data from secure storage", stackTrace: st);
      return null;
    }
  }

  Future<void> clearUser() async {
    await _storage.delete(key: DatabaseKeyConstants.USER);
    Logger.info("SessionManager", "User cleared");
  }

  // ── FCM token persistence 
  Future<bool> saveFcmToken(String token) async {
    try {
      await _storage.write(key: DatabaseKeyConstants.FCM_TOKEN, value: token);
      Logger.info("SessionManager", "FCM token saved");
      return true;
    } catch (e, st) {
      Logger.error("SessionManager", "Error saving FCM token → $e",
          stackTrace: st);
      return false;
    }
  }

  Future<String?> getFcmToken() async {
    return await _storage.read(key: DatabaseKeyConstants.FCM_TOKEN);
  }

  Future<void> clearFcmToken() async {
    await _storage.delete(key: DatabaseKeyConstants.FCM_TOKEN);
    Logger.info("SessionManager", "FCM token cleared");
  }

  Future<void> clearAll() async {
    await clearTokens();
    await clearUser();
    await clearFcmToken();
  }
}
