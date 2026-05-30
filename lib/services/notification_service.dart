import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ratnesh_gold_app/domain/entities/notification_model.dart';
import 'package:ratnesh_gold_app/utils/Logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  Logger.info("NotificationService", "Background message received: ${message.messageId}");
}

class NotificationService {
  static const String _channelId = 'arham_jewellers_high_importance';
  static const String _channelName = 'Arham Jewellers Notifications';
  static const String _channelDescription = 'High importance notifications from Arham Jewellers';

  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
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
      await Firebase.initializeApp();

      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      await _requestPermission();
      await _setupLocalNotifications();
      await _loadNotificationIdCounter();
      await _getFcmToken();
      _setupMessageListeners();

      _isInitialized = true;
      Logger.info("NotificationService", "Initialized successfully");
    } catch (e, st) {
      _initError = e.toString();
      Logger.error("NotificationService", "Initialization failed: $e", stackTrace: st);
    }
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      criticalAlert: false,
    );

    Logger.info("NotificationService", "Permission status: ${settings.authorizationStatus}");

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      Logger.info("NotificationService", "Notification permission granted");
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      Logger.info("NotificationService", "Notification permission provisional");
    } else {
      Logger.warning("NotificationService", "Notification permission denied");
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
      // Best effort persistence
    }
  }

  Future<void> _getFcmToken() async {
    _fcmToken = await _messaging.getToken();
    Logger.info("NotificationService", "FCM Token obtained");

    _messaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      Logger.info("NotificationService", "FCM Token refreshed");
      onTokenRefreshed?.call(newToken);
    });
  }

  void _setupMessageListeners() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      Logger.info("NotificationService", "Foreground message: ${message.notification?.title}");
      _showLocalNotification(message);
      onMessageReceived?.call(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      Logger.info("NotificationService", "Message opened app: ${message.notification?.title}");
      onMessageOpenedApp?.call(message);
    });

    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        Logger.info("NotificationService", "App opened from notification: ${message.notification?.title}");
        onMessageOpenedApp?.call(message);
      }
    });
  }

  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] ?? message.data['notification_title'] ?? '';
    final body = notification?.body ?? message.data['body'] ?? message.data['notification_body'] ?? '';

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

    _localNotifications.show(
      _notificationIdCounter++,
      title,
      body,
      details,
      payload: jsonEncode(message.data),
    );
    _saveNotificationIdCounter();
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        Logger.info("NotificationService", "Notification tapped with data: $data");
        final notification = NotificationModel.fromFcmPayload(data);
        onMessageOpenedApp?.call(RemoteMessage(
          data: data,
          notification: RemoteNotification(
            title: notification.title,
            body: notification.body,
          ),
        ));
      } catch (e) {
        Logger.error("NotificationService", "Error parsing notification payload: $e");
      }
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    Logger.info("NotificationService", "Subscribed to topic: $topic");
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    Logger.info("NotificationService", "Unsubscribed from topic: $topic");
  }

  Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
  }
}
