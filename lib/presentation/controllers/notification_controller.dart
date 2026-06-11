import 'dart:convert';

import 'package:get/get.dart';
import 'package:ratnesh_gold_app/app/routes/app_routes.dart';
import 'package:ratnesh_gold_app/data/repositories/notification_repository.dart';
import 'package:ratnesh_gold_app/domain/entities/notification_model.dart';
import 'package:ratnesh_gold_app/services/notification_service.dart';
import 'package:ratnesh_gold_app/utils/Logger.dart';
import 'package:ratnesh_gold_app/utils/SessionManager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationController extends GetxController {
  static const String _storageKey = 'notifications_list';
  static const int _maxNotifications = 100;

  final _notificationRepo = NotificationRepository();

  static const Set<String> _allowedRoutes = {
    AppRoutes.splash,
    AppRoutes.login,
    AppRoutes.home,
    AppRoutes.details,
    AppRoutes.checkout,
    AppRoutes.orderSuccess,
    AppRoutes.myOrders,
    AppRoutes.register,
    AppRoutes.notifications,
  };

  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxInt unreadCount = 0.obs;

  final NotificationService _notificationService = NotificationService();

  @override
  void onInit() {
    super.onInit();
    _loadNotifications().then((_) => _setupListeners());
  }

  void _setupListeners() {
    _notificationService.onTokenRefreshed = (newToken) {
      _sendTokenToBackend(newToken);
    };

    _notificationService.onMessageReceived = (message) {
      final notification = NotificationModel.fromFcmPayload(message.data);
      addNotification(notification);
    };

    _notificationService.onMessageOpenedApp = (message) {
      final data = message.data;
      _handleNotificationTap(data);
    };
  }

  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        notifications.value = jsonList
            .map((json) => NotificationModel.fromJson(json))
            .toList();
        _updateUnreadCount();
      }
    } catch (e) {
      Logger.error("NotificationController", "Failed to load notifications: $e");
    }
  }

  void _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = notifications.map((n) => n.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
    } catch (e) {
      Logger.error("NotificationController", "Failed to save notifications: $e");
    }
  }

  void addNotification(NotificationModel notification) {
    notifications.insert(0, notification);
    if (notifications.length > _maxNotifications) {
      notifications.removeRange(_maxNotifications, notifications.length);
    }
    _updateUnreadCount();
    _saveNotifications();
  }

  void markAsRead(String id) {
    final index = notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      final old = notifications[index];
      notifications[index] = NotificationModel(
        id: old.id,
        title: old.title,
        body: old.body,
        timestamp: old.timestamp,
        isRead: true,
        data: old.data,
      );
      _updateUnreadCount();
      _saveNotifications();
    }
  }

  void markAllAsRead() {
    for (var i = 0; i < notifications.length; i++) {
      final old = notifications[i];
      notifications[i] = NotificationModel(
        id: old.id,
        title: old.title,
        body: old.body,
        timestamp: old.timestamp,
        isRead: true,
        data: old.data,
      );
    }
    _updateUnreadCount();
    _saveNotifications();
  }

  void clearAll() {
    notifications.clear();
    _updateUnreadCount();
    _saveNotifications();
  }

  void _updateUnreadCount() {
    unreadCount.value = notifications.where((n) => !n.isRead).length;
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    final route = data['route'];
    final id = data['id'];

    if (route != null && route is String && _allowedRoutes.contains(route)) {
      try {
        Get.toNamed(route, arguments: id);
      } catch (e) {
        Logger.error("NotificationController", "Failed to navigate to route '$route': $e");
      }
    }
  }

  Future<void> _sendTokenToBackend(String token) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final accessToken = await SessionManager().getAccessToken();
        if (accessToken == null || accessToken.isEmpty) {
          Logger.info("NotificationController", "Skipping FCM token update — user not logged in");
          return;
        }
        await _notificationRepo.updateFcmToken(data: {'fcmToken': token});
        Logger.info("NotificationController", "FCM token updated on backend");
        return;
      } catch (e) {
        if (attempt == 0) {
          Logger.warning("NotificationController", "FCM token update failed, retrying in 5s: $e");
          await Future.delayed(const Duration(seconds: 5));
        } else {
          Logger.error("NotificationController", "Failed to update FCM token after retry: $e");
        }
      }
    }
  }
}
