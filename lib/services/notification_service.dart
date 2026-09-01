import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ratnesh_gold_app/domain/entities/notification_model.dart';
import 'package:ratnesh_gold_app/utils/SessionManager.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class NotificationService {
  static const String _channelId = 'arham_jewellers_high_importance';
  static const String _channelName = 'Arham Jewellers Notifications';
  static const String _channelDescription = 'High importance notifications from Arham Jewellers';

  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FirebaseMessaging? _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static const String _counterKey = 'notification_id_counter';
  int _notificationIdCounter = 0;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  String? _initError;
  String? get initError => _initError;

  final Completer<void> _readyCompleter = Completer<void>();
  bool _backgroundInitDone = false;

  Function(RemoteMessage)? onMessageReceived;
  Function(RemoteMessage)? onMessageOpenedApp;

  static const Duration _criticalStepTimeout = Duration(seconds: 3);
  static const Duration _readyTimeout = Duration(seconds: 10);

  Future<void> init() async {
    try {
      await _setupLocalNotifications()
          .timeout(_criticalStepTimeout);
      await _loadNotificationIdCounter()
          .timeout(_criticalStepTimeout);
    } catch (e) {
      _initError = e.toString();
    }

    try {
      await Firebase.initializeApp().timeout(_criticalStepTimeout);
      _messaging = FirebaseMessaging.instance;
    } catch (e) {
      _initError = e.toString();
    }

    _isInitialized = true;

    unawaited(_backgroundInit());
  }

  Future<void> _backgroundInit() async {
    try {
      if (_messaging == null) {
        _backgroundInitDone = true;
        if (!_readyCompleter.isCompleted) _readyCompleter.complete();
        return;
      }
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      await _getFcmToken();
      _setupMessageListeners();
      _backgroundInitDone = true;
      if (!_readyCompleter.isCompleted) _readyCompleter.complete();
      await _requestPermission();
    } catch (e) {
      _initError = e.toString();
    } finally {
      _backgroundInitDone = true;
      if (!_readyCompleter.isCompleted) _readyCompleter.complete();
    }
  }

  Future<void> awaitReady({Duration? timeout}) async {
    final deadline = DateTime.now().add(timeout ?? _readyTimeout);
    while (!_backgroundInitDone && !_readyCompleter.isCompleted) {
      if (DateTime.now().isAfter(deadline)) {
        _initError ??= 'NotificationService awaitReady timed out';
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> _requestPermission() async {
    if (_messaging == null) return;

    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final androidPlugin = _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          await androidPlugin.requestNotificationsPermission();
        }
      } catch (e) {
      }
    }

    try {
      await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        criticalAlert: false,
      );
    } catch (e) {
    }
  }

  Future<void> _setupLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('ic_notification');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );
    }
  }

  Future<void> _loadNotificationIdCounter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _notificationIdCounter = prefs.getInt(_counterKey) ?? 0;
    } catch (e) {
      _notificationIdCounter = 0;
    }
  }

  Future<void> _saveNotificationIdCounter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_counterKey, _notificationIdCounter);
    } catch (e) {
    }
  }

  Future<void> _getFcmToken() async {
    if (_messaging == null) {
      return;
    }

    String? stored;
    try {
      stored = await SessionManager().getFcmToken();
    } catch (e) {
      stored = null;
    }

    if (stored != null && stored.isNotEmpty) {
      _fcmToken = stored;
      _listenForTokenRefresh();
      return;
    }

    String? fresh;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        fresh = await _messaging!.getToken();
        if (fresh != null && fresh.isNotEmpty) break;
      } catch (e) {
      }
      if (attempt < 2) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    if (fresh != null && fresh.isNotEmpty) {
      _fcmToken = fresh;
      await SessionManager().saveFcmToken(fresh);
    } else {
      _fcmToken = null;
    }

    _listenForTokenRefresh();
  }

  void _listenForTokenRefresh() {
    if (_messaging == null) return;
    try {
      _messaging!.onTokenRefresh.listen((newToken) async {
        _fcmToken = newToken;
        await SessionManager().saveFcmToken(newToken);
      });
    } catch (e) {}
  }

  void _setupMessageListeners() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      try {
        _showLocalNotification(message);
      } catch (e) {
      }
      onMessageReceived?.call(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      onMessageOpenedApp?.call(message);
    });

    _messaging?.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        onMessageOpenedApp?.call(message);
      }
    });
  }

  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;
    final title = notification?.title ??
        data['title'] ??
        data['notification_title'] ??
        data['message'] ??
        '';
    final body = notification?.body ??
        data['body'] ??
        data['notification_body'] ??
        data['text'] ??
        data['alert'] ??
        '';

    if (title.isEmpty && body.isEmpty) {
      return;
    }

    final payload = Map<String, dynamic>.from(message.data);
    if (!payload.containsKey('title')) payload['title'] = title;
    if (!payload.containsKey('body')) payload['body'] = body;

    showSystemNotification(
      title: title,
      body: body,
      payload: payload,
    );
  }

  Future<void> showSystemNotification({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    if (title.isEmpty && body.isEmpty) return;

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_notification',
      color: const Color(0xFFB8860B),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _localNotifications.show(
        _notificationIdCounter++,
        title,
        body,
        details,
        payload: payload != null ? jsonEncode(payload) : null,
      );
      await _saveNotificationIdCounter();
    } catch (e) {
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        final notification = NotificationModel.fromFcmPayload(data);
        onMessageOpenedApp?.call(RemoteMessage(
          data: data,
          notification: RemoteNotification(
            title: notification.title,
            body: notification.body,
          ),
        ));
      } catch (e) {
      }
    }
  }

  Future<String?> getTokenWithRetry({int maxRetries = 3}) async {
    await awaitReady();
    String? stored;
    try {
      stored = await SessionManager().getFcmToken();
    } catch (e) {
      stored = null;
    }
    if (stored != null && stored.isNotEmpty) {
      _fcmToken = stored;
      return stored;
    }
    if (_fcmToken != null && _fcmToken!.isNotEmpty) {
      return _fcmToken;
    }
    for (var attempt = 0; attempt < maxRetries; attempt++) {
      if (_messaging == null) {
        return null;
      }
      try {
        final token = await _messaging!.getToken();
        if (token != null && token.isNotEmpty) {
          _fcmToken = token;
          await SessionManager().saveFcmToken(token);
          return token;
        }
      } catch (e) {
      }
      if (attempt < maxRetries - 1) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    return null;
  }

  Future<String?> retryGetFcmToken() async {
    if (_fcmToken != null && _fcmToken!.isNotEmpty) {
      return _fcmToken;
    }

    if (_messaging == null) {
      return null;
    }

    try {
      _fcmToken = await _messaging!.getToken();
      if (_fcmToken != null && _fcmToken!.isNotEmpty) {
        await SessionManager().saveFcmToken(_fcmToken!);
      }
    } catch (e) {
    }

    return _fcmToken;
  }

  Future<void> subscribeToTopic(String topic) async {
    if (_messaging == null) {
      await awaitReady();
    }
    if (_messaging == null) return;
    try {
      await _messaging!.subscribeToTopic(topic);
    } catch (e) {
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    if (_messaging == null) {
      await awaitReady();
    }
    if (_messaging == null) return;
    try {
      await _messaging!.unsubscribeFromTopic(topic);
    } catch (e) {
    }
  }

  Future<void> subscribeUserTopics() async {
    await subscribeToTopic('all_users');
  }

  Future<void> subscribeAdminTopics() async {
    await subscribeToTopic('admin_notifications');
  }

  Future<void> unsubscribeAllTopics() async {
    await unsubscribeFromTopic('all_users');
    await unsubscribeFromTopic('admin_notifications');
  }

  Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  Future<void> resetIdCounter() async {
    _notificationIdCounter = 0;
    await _saveNotificationIdCounter();
  }
}
