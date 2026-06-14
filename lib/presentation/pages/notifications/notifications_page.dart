import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/core/widgets/responsive_wrapper.dart';
import 'package:ratnesh_gold_app/domain/entities/notification_model.dart';
import 'package:ratnesh_gold_app/presentation/controllers/notification_controller.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';
import 'package:shimmer/shimmer.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final NotificationController _controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<NotificationController>()
        ? Get.find<NotificationController>()
        : Get.put(NotificationController());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _controller.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.pageBg,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textDark,
            size: context.getResponsiveSize(5),
          ),
        ),
        title: Text(
          'Notifications',
          style: TextStyle(
            fontSize: context.getResponsiveSize(6),
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        actions: [
          Obx(() {
            if (_controller.unreadCount.value == 0) return const SizedBox();
            return IconButton(
              onPressed: () => _showMarkAllAsReadDialog(),
              icon: Icon(
                Icons.done_all_rounded,
                color: AppColors.primaryGold,
                size: context.getResponsiveSize(6),
              ),
            );
          }),
          SizedBox(width: context.getResponsiveSize(2)),
        ],
      ),
      body: ResponsiveWrapper(
        child: Column(
          children: [
            Container(height: 3, color: AppColors.divider),
            Expanded(
              child: Obx(() {
                // Subscribe Obx to loadMoreError so list rebuilds when pagination fails
                _controller.loadMoreError.value;
                switch (_controller.state.value) {
                  case CurrentAppState.INITIAL:
                  case CurrentAppState.LOADING:
                    if (_controller.notifications.isEmpty) {
                      return _LoadingShimmer();
                    }
                    return _NotificationList(
                      controller: _controller,
                      scrollController: _scrollController,
                    );
                  case CurrentAppState.ERROR:
                    if (_controller.notifications.isEmpty) {
                      return _ErrorState(
                        onRetry: () => _controller.refreshNotifications(),
                      );
                    }
                    return _NotificationList(
                      controller: _controller,
                      scrollController: _scrollController,
                    );
                  case CurrentAppState.SUCCESS:
                    if (_controller.notifications.isEmpty) {
                      return _EmptyState();
                    }
                    return _NotificationList(
                      controller: _controller,
                      scrollController: _scrollController,
                    );
                }
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _showMarkAllAsReadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark All As Read'),
        content: const Text('Mark all notifications as read?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              _controller.markAllAsRead();
              Navigator.pop(context);
            },
            child: Text(
              'Mark All',
              style: TextStyle(color: AppColors.primaryGold),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.divider.withValues(alpha: 0.3),
      highlightColor: AppColors.divider.withValues(alpha: 0.1),
      child: ListView.builder(
        padding: EdgeInsets.symmetric(
          horizontal: context.getResponsiveSize(4),
          vertical: context.getScreenHeight(1),
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(bottom: context.getScreenHeight(1.2)),
            padding: EdgeInsets.all(context.getResponsiveSize(4)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(context.getResponsiveSize(3)),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: context.getResponsiveSize(10),
                  height: context.getResponsiveSize(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(context.getResponsiveSize(2)),
                  ),
                ),
                SizedBox(width: context.getResponsiveSize(3)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: context.getResponsiveSize(3.5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(context.getResponsiveSize(1)),
                        ),
                      ),
                      SizedBox(height: context.getScreenHeight(1)),
                      Container(
                        width: double.infinity,
                        height: context.getResponsiveSize(3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(context.getResponsiveSize(1)),
                        ),
                      ),
                      SizedBox(height: context.getScreenHeight(0.8)),
                      Container(
                        width: context.getResponsiveSize(20),
                        height: context.getResponsiveSize(2.5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(context.getResponsiveSize(1)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.getResponsiveSize(8)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: context.getResponsiveSize(16),
              color: AppColors.textMuted.withValues(alpha: 0.5),
            ),
            SizedBox(height: context.getScreenHeight(2)),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: context.getResponsiveSize(4.5),
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: context.getScreenHeight(1)),
            Text(
              'Failed to load notifications',
              style: TextStyle(
                fontSize: context.getResponsiveSize(3.5),
                color: AppColors.textMuted,
              ),
            ),
            SizedBox(height: context.getScreenHeight(3)),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.getResponsiveSize(6),
                  vertical: context.getResponsiveSize(3),
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold,
                  borderRadius: BorderRadius.circular(context.getResponsiveSize(2)),
                ),
                child: Text(
                  'Retry',
                  style: TextStyle(
                    fontSize: context.getResponsiveSize(3.5),
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: context.getResponsiveSize(20),
            color: AppColors.textMuted.withValues(alpha: 0.5),
          ),
          SizedBox(height: context.getScreenHeight(2)),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: context.getResponsiveSize(4.5),
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: context.getScreenHeight(1)),
          Text(
            'You\'ll receive notifications about\norders, offers, and updates',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: context.getResponsiveSize(3.5),
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationList extends StatelessWidget {
  final NotificationController controller;
  final ScrollController scrollController;

  const _NotificationList({
    required this.controller,
    required this.scrollController,
  });

  void _handleTap(NotificationModel notification) {
    controller.markAsRead(notification.id);

    final route = notification.data?['route']?.toString();
    if (route != null && NotificationController.allowedRoutes.contains(route)) {
      Get.toNamed(route, arguments: notification.data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primaryGold,
      onRefresh: () => controller.refreshNotifications(),
      child: ListView.builder(
        controller: scrollController,
        padding: EdgeInsets.symmetric(
          horizontal: context.getResponsiveSize(4),
          vertical: context.getScreenHeight(1),
        ),
        itemCount: controller.notifications.length + (controller.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == controller.notifications.length) {
            if (controller.loadMoreError.value.isNotEmpty) {
              return GestureDetector(
                onTap: () => controller.loadMore(),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: context.getScreenHeight(2)),
                  child: Center(
                    child: Text(
                      'Tap to retry',
                      style: TextStyle(
                        fontSize: context.getResponsiveSize(3.2),
                        color: AppColors.primaryGold,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            }
            return Padding(
              padding: EdgeInsets.symmetric(vertical: context.getScreenHeight(2)),
              child: Center(
                child: SizedBox(
                  width: context.getResponsiveSize(5),
                  height: context.getResponsiveSize(5),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryGold,
                  ),
                ),
              ),
            );
          }
          final notification = controller.notifications[index];
          return _NotificationCard(
            notification: notification,
            onTap: () => _handleTap(notification),
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final timeAgo = _getTimeAgo(notification.timestamp);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: context.getScreenHeight(1.2)),
        padding: EdgeInsets.all(context.getResponsiveSize(4)),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : AppColors.primaryGold.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(context.getResponsiveSize(3)),
          border: Border.all(
            color: notification.isRead
                ? AppColors.divider
                : AppColors.primaryGold.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: context.getResponsiveSize(10),
              height: context.getResponsiveSize(10),
              decoration: BoxDecoration(
                color: notification.isRead
                    ? AppColors.textMuted.withValues(alpha: 0.1)
                    : AppColors.primaryGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(context.getResponsiveSize(2)),
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: context.getResponsiveSize(5),
                color: notification.isRead ? AppColors.textMuted : AppColors.primaryGold,
              ),
            ),
            SizedBox(width: context.getResponsiveSize(3)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: context.getResponsiveSize(3.8),
                            fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: context.getResponsiveSize(2),
                          height: context.getResponsiveSize(2),
                          margin: EdgeInsets.only(left: context.getResponsiveSize(2)),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGold,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: context.getScreenHeight(0.5)),
                  Text(
                    notification.body,
                    style: TextStyle(
                      fontSize: context.getResponsiveSize(3.3),
                      color: AppColors.textMuted,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: context.getScreenHeight(0.8)),
                  Text(
                    timeAgo,
                    style: TextStyle(
                      fontSize: context.getResponsiveSize(2.8),
                      color: AppColors.textMuted.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return DateFormat('MMM d, yyyy').format(timestamp);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
