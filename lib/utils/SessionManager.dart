import 'dart:convert';
import 'package:ratnesh_gold_app/domain/entities/user_model.dart';
import 'package:ratnesh_gold_app/utils/Logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // ── Token persistence ───────────────────────────────────────────────
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

      final prefs = await _prefs;
      await prefs.setString(DatabaseKeyConstants.ACCESS_TOKEN, accessToken);
      await prefs.setString(DatabaseKeyConstants.REFRESH_TOKEN, refreshToken);
      await prefs.setString(
          DatabaseKeyConstants.ACCESS_TOKEN_EXPIRY, accessExpiry.toString());
      await prefs.setString(
          DatabaseKeyConstants.REFRESH_TOKEN_EXPIRY, refreshExpiry.toString());

      Logger.info("SessionManager", "Tokens saved");
      return true;
    } catch (e, st) {
      Logger.error("SessionManager", "Error saving tokens → $e",
          stackTrace: st);
      return false;
    }
  }

  Future<String?> getAccessToken() async {
    final prefs = await _prefs;
    final token = prefs.getString(DatabaseKeyConstants.ACCESS_TOKEN);
    Logger.info("SessionManager",
        "getAccessToken: ${token != null ? 'present (${token.substring(0, 20)}...)' : 'null'}");
    return token;
  }

  Future<String?> getRefreshToken() async {
    final prefs = await _prefs;
    final token = prefs.getString(DatabaseKeyConstants.REFRESH_TOKEN);
    Logger.info("SessionManager",
        "getRefreshToken: ${token != null ? 'present (${token.substring(0, 20)}...)' : 'null'}");
    return token;
  }

  Future<int?> getAccessTokenExpiry() async {
    final prefs = await _prefs;
    final value = prefs.getString(DatabaseKeyConstants.ACCESS_TOKEN_EXPIRY);
    return value != null ? int.tryParse(value) : null;
  }

  Future<int?> getRefreshTokenExpiry() async {
    final prefs = await _prefs;
    final value = prefs.getString(DatabaseKeyConstants.REFRESH_TOKEN_EXPIRY);
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
      final prefs = await _prefs;
      await prefs.remove(DatabaseKeyConstants.ACCESS_TOKEN);
      await prefs.remove(DatabaseKeyConstants.REFRESH_TOKEN);
      await prefs.remove(DatabaseKeyConstants.ACCESS_TOKEN_EXPIRY);
      await prefs.remove(DatabaseKeyConstants.REFRESH_TOKEN_EXPIRY);

      Logger.info("SessionManager", "Tokens cleared");
      return true;
    } catch (e, st) {
      Logger.error("SessionManager", "Error clearing tokens → $e",
          stackTrace: st);
      return false;
    }
  }

  // ── Admin flag persistence ──────────────────────────────────────────
  static const _isAdminKey = 'IS_ADMIN';

  Future<void> saveIsAdmin(bool isAdmin) async {
    final prefs = await _prefs;
    await prefs.setBool(_isAdminKey, isAdmin);
  }

  Future<bool> getIsAdmin() async {
    final prefs = await _prefs;
    return prefs.getBool(_isAdminKey) ?? false;
  }

  // ── User data persistence ───────────────────────────────────────────
  Future<bool> saveUserData(UserModel user) async {
    try {
      String userJson = jsonEncode(user.toJson());
      final prefs = await _prefs;
      await prefs.setString(DatabaseKeyConstants.USER, userJson);
      Logger.info("SessionManager", "User saved");
      return true;
    } catch (e, st) {
      Logger.error("SessionManager", "Error saving user → $e",
          stackTrace: st);
      return false;
    }
  }

  Future<UserModel?> getUserData() async {
    final prefs = await _prefs;
    final jsonString = prefs.getString(DatabaseKeyConstants.USER);
    if (jsonString == null) return null;

    try {
      return UserModel.fromJson(jsonDecode(jsonString));
    } catch (e) {
      return null;
    }
  }

  Future<void> clearUser() async {
    final prefs = await _prefs;
    await prefs.remove(DatabaseKeyConstants.USER);
    Logger.info("SessionManager", "User cleared");
  }

  // ── FCM token persistence ─────────────────────────────────────────
  Future<bool> saveFcmToken(String token) async {
    try {
      final prefs = await _prefs;
      await prefs.setString(DatabaseKeyConstants.FCM_TOKEN, token);
      Logger.info("SessionManager", "FCM token saved");
      return true;
    } catch (e, st) {
      Logger.error("SessionManager", "Error saving FCM token → $e",
          stackTrace: st);
      return false;
    }
  }

  Future<String?> getFcmToken() async {
    final prefs = await _prefs;
    return prefs.getString(DatabaseKeyConstants.FCM_TOKEN);
  }

  Future<void> clearFcmToken() async {
    final prefs = await _prefs;
    await prefs.remove(DatabaseKeyConstants.FCM_TOKEN);
    Logger.info("SessionManager", "FCM token cleared");
  }

  Future<void> clearAll() async {
    await clearTokens();
    await clearUser();
    await clearFcmToken();
  }
}
