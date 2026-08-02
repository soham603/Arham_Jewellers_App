import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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

  Function(RemoteMessage)? onMessageReceived;
  Function(RemoteMessage)? onMessageOpenedApp;
  Function(String)? onTokenRefreshed;

  Future<void> init() async {
    try {
      await _setupLocalNotifications();
      await _loadNotificationIdCounter();
    } catch (e, st) {
      _initError = e.toString();
    }

    try {
      await Firebase.initializeApp();
      _messaging = FirebaseMessaging.instance;

      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      await _requestPermission();
      await _getFcmToken();
      _setupMessageListeners();

      _isInitialized = true;
    } catch (e) {
      _initError = e.toString();
    }
  }

  Future<void> _requestPermission() async {
    if (_messaging == null) return;
    final settings = await _messaging!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      criticalAlert: false,
    );


    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    } else {
    }
  }

  Future<void> _setupLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
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

    try {
      _fcmToken = await _messaging!.getToken();
      if (_fcmToken != null && _fcmToken!.isNotEmpty) {
        await SessionManager().saveFcmToken(_fcmToken!);
      } else {
      }

      _messaging!.onTokenRefresh.listen((newToken) async {
        _fcmToken = newToken;
        await SessionManager().saveFcmToken(newToken);
        onTokenRefreshed?.call(newToken);
      });
    } catch (e) {
    }
  }

  void _setupMessageListeners() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
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
    final title = notification?.title ?? message.data['title'] ?? message.data['notification_title'] ?? '';
    final body = notification?.body ?? message.data['body'] ?? message.data['notification_body'] ?? '';

    if (title.isEmpty && body.isEmpty) return;

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
      icon: '@mipmap/ic_launcher',
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

    await _localNotifications.show(
      _notificationIdCounter++,
      title,
      body,
      details,
      payload: payload != null ? jsonEncode(payload) : null,
    );
    await _saveNotificationIdCounter();
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
      return;
    }
    await _messaging!.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    if (_messaging == null) {
      return;
    }
    await _messaging!.unsubscribeFromTopic(topic);
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
