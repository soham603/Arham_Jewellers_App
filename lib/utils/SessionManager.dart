import 'dart:async';
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
}

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();

  factory SessionManager() => _instance;

  SessionManager._internal();

  final _tokenController = StreamController<bool>.broadcast();
  Stream<bool> get tokenStatusStream => _tokenController.stream;

  Future<bool> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String accessTokenExpiry,
    required String refreshTokenExpiry,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final accessExpiry = DateTime.parse(
        accessTokenExpiry,
      ).millisecondsSinceEpoch;
      final refreshExpiry = DateTime.parse(
        refreshTokenExpiry,
      ).millisecondsSinceEpoch;

      await prefs.setString(DatabaseKeyConstants.ACCESS_TOKEN, accessToken);
      await prefs.setString(DatabaseKeyConstants.REFRESH_TOKEN, refreshToken);
      await prefs.setInt(
        DatabaseKeyConstants.ACCESS_TOKEN_EXPIRY,
        accessExpiry,
      );
      await prefs.setInt(
        DatabaseKeyConstants.REFRESH_TOKEN_EXPIRY,
        refreshExpiry,
      );

      _tokenController.add(true);

      Logger.info("SessionManager", "Tokens saved successfully");

      return true;
    } catch (e, st) {
      Logger.error(
        "SessionManager",
        "Error saving tokens → $e",
        stackTrace: st,
      );
      _tokenController.add(false);
      return false;
    }
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    Logger.info("SessionManager", "Fetching access Token :${prefs.getString(DatabaseKeyConstants.ACCESS_TOKEN)}");
    return prefs.getString(DatabaseKeyConstants.ACCESS_TOKEN);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(DatabaseKeyConstants.REFRESH_TOKEN);
  }

  Future<int?> getAccessTokenExpiry() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(DatabaseKeyConstants.ACCESS_TOKEN_EXPIRY);
  }

  Future<int?> getRefreshTokenExpiry() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(DatabaseKeyConstants.REFRESH_TOKEN_EXPIRY);
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
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove(DatabaseKeyConstants.ACCESS_TOKEN);
      await prefs.remove(DatabaseKeyConstants.REFRESH_TOKEN);
      await prefs.remove(DatabaseKeyConstants.ACCESS_TOKEN_EXPIRY);
      await prefs.remove(DatabaseKeyConstants.REFRESH_TOKEN_EXPIRY);

      _tokenController.add(false);

      Logger.info("SessionManager", "Tokens cleared");

      return true;
    } catch (e, st) {
      Logger.error(
        "SessionManager",
        "Error clearing tokens → $e",
        stackTrace: st,
      );
      return false;
    }
  }

  Future<bool> saveUserData(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String userJson = jsonEncode(user.toJson());

      final result = await prefs.setString(DatabaseKeyConstants.USER, userJson);

      Logger.info("SessionManager", "User saved");

      return result;
    } catch (e, st) {
      Logger.error("SessionManager", "Error saving user → $e", stackTrace: st);
      return false;
    }
  }

  Future<UserModel?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();

    final jsonString = prefs.getString(DatabaseKeyConstants.USER);
    if (jsonString == null) return null;

    try {
      return UserModel.fromJson(jsonDecode(jsonString));
    } catch (e) {
      return null;
    }
  }

  Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(DatabaseKeyConstants.USER);

    Logger.info("SessionManager", "User cleared");
  }

  Future<void> clearAll() async {
    await clearTokens();
    await clearUser();
  }

  void dispose() {
    _tokenController.close();
  }
}
