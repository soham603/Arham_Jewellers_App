import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/core/widgets/responsive_wrapper.dart';
import 'package:ratnesh_gold_app/domain/entities/notification_model.dart';
import 'package:ratnesh_gold_app/presentation/controllers/notification_controller.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final NotificationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<NotificationController>()
        ? Get.find<NotificationController>()
        : Get.put(NotificationController());
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
            if (_controller.notifications.isEmpty) return const SizedBox();
            return IconButton(
              onPressed: () {
                _showClearAllDialog();
              },
              icon: Icon(
                Icons.delete_outline_rounded,
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
              if (_controller.notifications.isEmpty) {
                return _EmptyState();
              }
              return _NotificationList(controller: _controller);
            }),
          ),
        ],
      ),
      ),
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text('Are you sure you want to clear all notifications?'),
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
              _controller.clearAll();
              Navigator.pop(context);
            },
            child: Text(
              'Clear',
              style: TextStyle(color: AppColors.primaryGold),
            ),
          ),
        ],
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
            color: AppColors.textMuted.withOpacity(0.5),
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

  const _NotificationList({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: context.getResponsiveSize(4),
        vertical: context.getScreenHeight(1),
      ),
      itemCount: controller.notifications.length,
      itemBuilder: (context, index) {
        final notification = controller.notifications[index];
        return _NotificationCard(
          notification: notification,
          onTap: () {
            controller.markAsRead(notification.id);
          },
        );
      },
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
          color: notification.isRead ? Colors.white : AppColors.primaryGold.withOpacity(0.05),
          borderRadius: BorderRadius.circular(context.getResponsiveSize(3)),
          border: Border.all(
            color: notification.isRead
                ? AppColors.divider
                : AppColors.primaryGold.withOpacity(0.3),
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
                    ? AppColors.textMuted.withOpacity(0.1)
                    : AppColors.primaryGold.withOpacity(0.15),
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
                      color: AppColors.textMuted.withOpacity(0.7),
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
