import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ratnesh_gold_app/domain/entities/user_model.dart';
import 'package:ratnesh_gold_app/utils/Logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseKeyConstants {
  static const String ACCESS_TOKEN = 'access_token';
  static const String REFRESH_TOKEN = 'refresh_token';

  static const String ACCESS_TOKEN_EXPIRY = 'access_token_expiry';
  static const String REFRESH_TOKEN_EXPIRY = 'refresh_token_expiry';

  static const String USER = 'user_data';

  // Marker key in SharedPreferences to know migration has run
  static const String _SECURE_MIGRATION_DONE = '_secure_migration_done';
}

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();

  factory SessionManager() => _instance;

  SessionManager._internal() {
    _migrateFromPlaintext();
  }

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  final _tokenController = StreamController<bool>.broadcast();
  Stream<bool> get tokenStatusStream => _tokenController.stream;

  bool _migrationAttempted = false;

  // ── One-time migration from SharedPreferences to Secure Storage ─────
  Future<void> _migrateFromPlaintext() async {
    if (_migrationAttempted) return;
    _migrationAttempted = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final alreadyMigrated =
          prefs.getBool(DatabaseKeyConstants._SECURE_MIGRATION_DONE) ?? false;

      if (alreadyMigrated) return;

      Logger.info("SessionManager", "Migrating tokens to secure storage…");

      final accessToken = prefs.getString(DatabaseKeyConstants.ACCESS_TOKEN);
      final refreshToken = prefs.getString(DatabaseKeyConstants.REFRESH_TOKEN);
      final accessExpiry =
          prefs.getInt(DatabaseKeyConstants.ACCESS_TOKEN_EXPIRY);
      final refreshExpiry =
          prefs.getInt(DatabaseKeyConstants.REFRESH_TOKEN_EXPIRY);
      final userData = prefs.getString(DatabaseKeyConstants.USER);

      if (accessToken != null) {
        await _secureStorage.write(
            key: DatabaseKeyConstants.ACCESS_TOKEN, value: accessToken);
      }
      if (refreshToken != null) {
        await _secureStorage.write(
            key: DatabaseKeyConstants.REFRESH_TOKEN, value: refreshToken);
      }
      if (accessExpiry != null) {
        await _secureStorage.write(
            key: DatabaseKeyConstants.ACCESS_TOKEN_EXPIRY,
            value: accessExpiry.toString());
      }
      if (refreshExpiry != null) {
        await _secureStorage.write(
            key: DatabaseKeyConstants.REFRESH_TOKEN_EXPIRY,
            value: refreshExpiry.toString());
      }
      if (userData != null) {
        await _secureStorage.write(
            key: DatabaseKeyConstants.USER, value: userData);
      }

      // Clear plaintext values
      await prefs.remove(DatabaseKeyConstants.ACCESS_TOKEN);
      await prefs.remove(DatabaseKeyConstants.REFRESH_TOKEN);
      await prefs.remove(DatabaseKeyConstants.ACCESS_TOKEN_EXPIRY);
      await prefs.remove(DatabaseKeyConstants.REFRESH_TOKEN_EXPIRY);
      await prefs.remove(DatabaseKeyConstants.USER);

      await prefs.setBool(DatabaseKeyConstants._SECURE_MIGRATION_DONE, true);

      Logger.info("SessionManager", "Migration to secure storage complete");
    } catch (e, st) {
      Logger.error(
        "SessionManager",
        "Error migrating tokens to secure storage → $e",
        stackTrace: st,
      );
    }
  }

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

      await Future.wait([
        _secureStorage.write(
            key: DatabaseKeyConstants.ACCESS_TOKEN, value: accessToken),
        _secureStorage.write(
            key: DatabaseKeyConstants.REFRESH_TOKEN, value: refreshToken),
        _secureStorage.write(
            key: DatabaseKeyConstants.ACCESS_TOKEN_EXPIRY,
            value: accessExpiry.toString()),
        _secureStorage.write(
            key: DatabaseKeyConstants.REFRESH_TOKEN_EXPIRY,
            value: refreshExpiry.toString()),
      ]);

      _tokenController.add(true);
      Logger.info("SessionManager", "Tokens saved to secure storage");
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
    return _secureStorage.read(key: DatabaseKeyConstants.ACCESS_TOKEN);
  }

  Future<String?> getRefreshToken() async {
    return _secureStorage.read(key: DatabaseKeyConstants.REFRESH_TOKEN);
  }

  Future<int?> getAccessTokenExpiry() async {
    final value =
        await _secureStorage.read(key: DatabaseKeyConstants.ACCESS_TOKEN_EXPIRY);
    return value != null ? int.tryParse(value) : null;
  }

  Future<int?> getRefreshTokenExpiry() async {
    final value = await _secureStorage.read(
        key: DatabaseKeyConstants.REFRESH_TOKEN_EXPIRY);
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
      await Future.wait([
        _secureStorage.delete(key: DatabaseKeyConstants.ACCESS_TOKEN),
        _secureStorage.delete(key: DatabaseKeyConstants.REFRESH_TOKEN),
        _secureStorage.delete(key: DatabaseKeyConstants.ACCESS_TOKEN_EXPIRY),
        _secureStorage.delete(key: DatabaseKeyConstants.REFRESH_TOKEN_EXPIRY),
      ]);

      _tokenController.add(false);
      Logger.info("SessionManager", "Tokens cleared from secure storage");
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

  // ── User data persistence ───────────────────────────────────────────
  Future<bool> saveUserData(UserModel user) async {
    try {
      String userJson = jsonEncode(user.toJson());
      await _secureStorage.write(
          key: DatabaseKeyConstants.USER, value: userJson);
      Logger.info("SessionManager", "User saved to secure storage");
      return true;
    } catch (e, st) {
      Logger.error("SessionManager", "Error saving user → $e", stackTrace: st);
      return false;
    }
  }

  Future<UserModel?> getUserData() async {
    final jsonString =
        await _secureStorage.read(key: DatabaseKeyConstants.USER);
    if (jsonString == null) return null;

    try {
      return UserModel.fromJson(jsonDecode(jsonString));
    } catch (e) {
      return null;
    }
  }

  Future<void> clearUser() async {
    await _secureStorage.delete(key: DatabaseKeyConstants.USER);
    Logger.info("SessionManager", "User cleared from secure storage");
  }

  Future<void> clearAll() async {
    await clearTokens();
    await clearUser();
  }

  void dispose() {
    _tokenController.close();
  }
}
