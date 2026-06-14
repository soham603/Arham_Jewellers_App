import 'dart:convert';

import 'package:get/get.dart';
import 'package:ratnesh_gold_app/app/routes/app_routes.dart';
import 'package:ratnesh_gold_app/data/repositories/notification_repository.dart';
import 'package:ratnesh_gold_app/domain/entities/notification_model.dart';
import 'package:ratnesh_gold_app/services/notification_service.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';
import 'package:ratnesh_gold_app/utils/Logger.dart';
import 'package:ratnesh_gold_app/utils/SessionManager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationController extends GetxController {
  static const String _storageKey = 'notifications_list';
  static const int _maxNotifications = 100;
  static const int _pageSize = 20;

  final _notificationRepo = NotificationRepository();

  static const Set<String> _allowedRoutes = {
    AppRoutes.userOrderDetail,
    AppRoutes.adminOrderDetail,
    AppRoutes.goldRateDetail,
    AppRoutes.myOrders,
  };

  static Set<String> get allowedRoutes => _allowedRoutes;

  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxInt unreadCount = 0.obs;
  final Rx<CurrentAppState> state = CurrentAppState.INITIAL.obs;
  final RxString errorMessage = ''.obs;
  final RxString loadMoreError = ''.obs;

  final RxBool _hasMore = true.obs;
  bool get hasMore => _hasMore.value;
  int _currentPage = 1;

  int _fetchGeneration = 0;
  bool _isFetching = false;
  bool _fetchDirty = false;

  final NotificationService _notificationService = NotificationService();

  @override
  void onInit() {
    super.onInit();
    _loadLocalNotifications().then((_) => _setupListeners());
  }

  void _setupListeners() {
    _notificationService.onTokenRefreshed = (newToken) {
      _sendTokenToBackend(newToken);
    };

    _notificationService.onMessageReceived = (message) {
      if (_isFetching) {
        _fetchDirty = true;
      } else {
        fetchNotifications();
      }
    };

    _notificationService.onMessageOpenedApp = (message) {
      final data = message.data;
      _handleNotificationTap(data);
    };

    fetchNotifications();
  }

  Future<void> fetchNotifications({bool append = false}) async {
    if (_isFetching) return;
    _isFetching = true;

    final generation = ++_fetchGeneration;

    if (!append) {
      state.value = CurrentAppState.LOADING;
      _currentPage = 1;
      _hasMore.value = true;
    }

    loadMoreError.value = '';

    try {
      final queryParams = <String, dynamic>{
        'page': _currentPage,
        'limit': _pageSize,
      };

      final responseData = await _notificationRepo.getAllNotifications(
        queryParams: queryParams,
      );

      if (generation != _fetchGeneration) return;

      final List<dynamic> items = responseData['data'] ?? responseData['notifications'] ?? [];
      final fetched = items.map((json) => NotificationModel.fromJson(json)).toList();

      if (append) {
        notifications.addAll(fetched);
      } else {
        notifications.value = fetched;
      }

      _hasMore.value = fetched.length >= _pageSize;
      _currentPage++;
      _updateUnreadCount();
      _saveNotifications();
      state.value = CurrentAppState.SUCCESS;
    } catch (e) {
      if (generation != _fetchGeneration) return;
      Logger.error("NotificationController", "Failed to fetch notifications: $e");
      errorMessage.value = e.toString();
      if (append) {
        loadMoreError.value = 'Failed to load more notifications';
      } else {
        state.value = CurrentAppState.ERROR;
      }
    } finally {
      if (generation == _fetchGeneration) {
        _isFetching = false;
        if (_fetchDirty) {
          _fetchDirty = false;
          fetchNotifications();
        }
      }
    }
  }

  Future<void> refreshNotifications() async {
    await fetchNotifications();
  }

  Future<void> loadMore() async {
    if (!_hasMore.value || _isFetching) return;
    await fetchNotifications(append: true);
  }

  Future<void> markAsRead(String id) async {
    final index = notifications.indexWhere((n) => n.id == id);
    if (index == -1 || notifications[index].isRead) return;

    final previousState = notifications.toList();

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

    try {
      await _notificationRepo.markNotificationsAsRead(
        data: {'notificationIds': [id]},
      );
      _saveNotifications();
    } catch (e) {
      Logger.error("NotificationController", "Failed to mark notification as read on backend: $e");
      notifications.value = previousState;
      _updateUnreadCount();
      _saveNotifications();
    }
  }

  Future<void> markAllAsRead() async {
    final unreadIds = notifications
        .where((n) => !n.isRead)
        .map((n) => n.id)
        .toList();

    if (unreadIds.isEmpty) return;

    final previousState = notifications.toList();

    final updated = notifications.map((n) {
      if (!n.isRead) {
        return NotificationModel(
          id: n.id,
          title: n.title,
          body: n.body,
          timestamp: n.timestamp,
          isRead: true,
          data: n.data,
        );
      }
      return n;
    }).toList();

    notifications.value = updated;
    _updateUnreadCount();

    try {
      await _notificationRepo.markNotificationsAsRead(
        data: {'notificationIds': unreadIds},
      );
      _saveNotifications();
    } catch (e) {
      Logger.error("NotificationController", "Failed to mark all as read on backend: $e");
      notifications.value = previousState;
      _updateUnreadCount();
      _saveNotifications();
    }
  }

  void addLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      timestamp: DateTime.now(),
      isRead: false,
      data: data,
    );
    notifications.insert(0, notification);
    if (notifications.length > _maxNotifications) {
      notifications.removeRange(_maxNotifications, notifications.length);
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

    if (route != null && route is String && _allowedRoutes.contains(route)) {
      try {
        Get.toNamed(route, arguments: data);
      } catch (e) {
        Logger.error("NotificationController", "Failed to navigate to route '$route': $e");
      }
    }
  }

  Future<void> _loadLocalNotifications() async {
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

  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = notifications.map((n) => n.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
    } catch (e) {
      Logger.error("NotificationController", "Failed to save notifications: $e");
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
