import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/presentation/controllers/admin/NotificationManagerController.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';

class NotificationManagerScreen extends StatefulWidget {
  const NotificationManagerScreen({super.key});

  @override
  State<NotificationManagerScreen> createState() => _NotificationManagerScreenState();
}

class _NotificationManagerScreenState extends State<NotificationManagerScreen> {
  final NotificationManagerController controller =
      Get.isRegistered<NotificationManagerController>()
          ? Get.find<NotificationManagerController>()
          : Get.put(NotificationManagerController());

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _targetValueController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      controller.loadMore();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _targetValueController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.pageBg,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Send Notification',
          style: TextStyle(
            fontSize: context.getResponsiveSize(5.5),
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          context.getResponsiveSize(4),
          context.heightPercent(1.5),
          context.getResponsiveSize(4),
          context.heightPercent(3),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _composeForm(context),
            SizedBox(height: context.heightPercent(3)),
            Text(
              'Sent History',
              style: TextStyle(
                fontSize: context.getResponsiveSize(5),
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: context.heightPercent(1.5)),
            _historyList(context),
          ],
        ),
      ),
    );
  }

  Widget _composeForm(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.getResponsiveSize(5)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7DED2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Compose Notification',
            style: TextStyle(
              fontSize: context.getResponsiveSize(4.5),
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: context.heightPercent(2)),
          _buildTextField(
            context,
            controller: _titleController,
            label: 'Title',
            hint: 'Enter notification title',
            maxLines: 1,
            onChanged: controller.setTitle,
          ),
          SizedBox(height: context.heightPercent(1.5)),
          _buildTextField(
            context,
            controller: _bodyController,
            label: 'Body',
            hint: 'Enter notification body',
            maxLines: 3,
            onChanged: controller.setBody,
          ),
          SizedBox(height: context.heightPercent(1.5)),
          _buildTargetSelector(context),
          SizedBox(height: context.heightPercent(2)),
          Obx(() {
            final showTargetField = controller.targetType != 'all';

            if (showTargetField) {
              return Column(
                children: [
                  _buildTextField(
                    context,
                    controller: _targetValueController,
                    label: controller.targetType == 'topic'
                        ? 'Topic Name'
                        : 'User ID',
                    hint: controller.targetType == 'topic'
                        ? 'e.g. promotions'
                        : 'Enter user ID',
                    maxLines: 1,
                    onChanged: controller.setTargetValue,
                  ),
                  SizedBox(height: context.heightPercent(2)),
                ],
              );
            }
            return const SizedBox.shrink();
          }),
          Obx(() {
            final isLoading = controller.sendState == CurrentAppState.LOADING;

            return GestureDetector(
              onTap: isLoading
                  ? null
                  : () async {
                      final success = await controller.sendNotification();
                      if (success) {
                        _titleController.clear();
                        _bodyController.clear();
                        _targetValueController.clear();
                      }
                    },
              child: Container(
                width: double.infinity,
                padding:
                    EdgeInsets.symmetric(vertical: context.heightPercent(1.8)),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGold.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: isLoading
                    ? Center(
                        child: SizedBox(
                          width: context.getResponsiveSize(5),
                          height: context.getResponsiveSize(5),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.send_rounded,
                              color: Colors.white, size: 20),
                          SizedBox(width: context.getResponsiveSize(2)),
                          Text(
                            'Send Notification',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: context.getResponsiveSize(4),
                            ),
                          ),
                        ],
                      ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTargetSelector(BuildContext context) {
    final options = [
      {'value': 'all', 'label': 'All Users', 'icon': Icons.people_rounded},
      {'value': 'topic', 'label': 'Topic', 'icon': Icons.tag_rounded},
      {'value': 'user', 'label': 'Specific User', 'icon': Icons.person_rounded},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target',
          style: TextStyle(
            fontSize: context.getResponsiveSize(3.5),
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        SizedBox(height: context.heightPercent(0.8)),
        Obx(() {
          return Row(
            children: options.map((opt) {
              final isSelected = controller.targetType == opt['value'];
              return Expanded(
                child: GestureDetector(
                  onTap: () =>
                      controller.setTargetType(opt['value'] as String),
                  child: Container(
                    margin: EdgeInsets.only(
                      right: opt != options.last
                          ? context.getResponsiveSize(2)
                          : 0,
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: context.heightPercent(1),
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryGold.withValues(alpha: 0.1)
                          : context.colorPalette.boxColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryGold
                            : context.colorPalette.subTitleColor
                                .withValues(alpha: 0.15),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          opt['icon'] as IconData,
                          color: isSelected
                              ? AppColors.primaryGold
                              : AppColors.textMuted,
                          size: context.getResponsiveSize(5),
                        ),
                        SizedBox(height: context.heightPercent(0.3)),
                        Text(
                          opt['label'] as String,
                          style: TextStyle(
                            fontSize: context.getResponsiveSize(2.8),
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? AppColors.primaryGold
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required String hint,
    required int maxLines,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: context.getResponsiveSize(3.5),
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        SizedBox(height: context.heightPercent(0.5)),
        TextField(
          controller: controller,
          maxLines: maxLines,
          onChanged: onChanged,
          style: TextStyle(
            fontSize: context.getResponsiveSize(3.8),
            color: AppColors.textDark,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: context.colorPalette.subTitleColor.withValues(alpha: 0.4),
            ),
            filled: true,
            fillColor: context.colorPalette.boxColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: AppColors.primaryGold,
                width: 1.5,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: context.getResponsiveSize(4),
              vertical: context.heightPercent(1.2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _historyList(BuildContext context) {
    return Obx(() {
      final histState = controller.historyState;
      final history = controller.history;

      if (histState == CurrentAppState.LOADING && history.isEmpty) {
        return Column(
          children: List.generate(
            3,
            (_) => Padding(
              padding: EdgeInsets.only(bottom: context.heightPercent(1)),
              child: _shimmerTile(context),
            ),
          ),
        );
      }

      if (histState == CurrentAppState.ERROR && history.isEmpty) {
        return Center(
          child: Text(
            controller.error.isNotEmpty
                ? controller.error
                : 'No history available',
            style: TextStyle(
              fontSize: context.getResponsiveSize(3.5),
              color: context.colorPalette.subTitleColor,
            ),
          ),
        );
      }

      if (history.isEmpty) {
        return Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: context.heightPercent(3)),
            child: Column(
              children: [
                Icon(
                  Icons.notifications_off_rounded,
                  size: context.getResponsiveSize(12),
                  color: context.colorPalette.subTitleColor
                      .withValues(alpha: 0.4),
                ),
                SizedBox(height: context.heightPercent(1)),
                Text(
                  'No notifications sent yet',
                  style: TextStyle(
                    fontSize: context.getResponsiveSize(3.8),
                    color: context.colorPalette.subTitleColor,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return Column(
        children: [
          ...List.generate(history.length, (index) {
            final notification = history[index];
            return Padding(
              padding: EdgeInsets.only(bottom: context.heightPercent(1)),
              child: _historyTile(context, notification),
            );
          }),
          if (controller.hasMore)
            Padding(
              padding: EdgeInsets.only(top: context.heightPercent(1)),
              child: Center(
                child: SizedBox(
                  width: context.getResponsiveSize(5),
                  height: context.getResponsiveSize(5),
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryGold,
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _historyTile(BuildContext context, SentNotification notification) {
    return Container(
      padding: EdgeInsets.all(context.getResponsiveSize(4)),
      decoration: BoxDecoration(
        color: context.colorPalette.boxColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: context.colorPalette.subTitleColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: context.getResponsiveSize(8),
                height: context.getResponsiveSize(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.send_rounded,
                  size: context.getResponsiveSize(3.5),
                  color: AppColors.primaryGold,
                ),
              ),
              SizedBox(width: context.getResponsiveSize(2)),
              Expanded(
                child: Text(
                  notification.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.getResponsiveSize(3.8),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.getResponsiveSize(2),
                  vertical: context.heightPercent(0.3),
                ),
                decoration: BoxDecoration(
                  color: _targetBadgeColor(notification.targetType)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _targetLabel(notification.targetType),
                  style: TextStyle(
                    fontSize: context.getResponsiveSize(2.5),
                    fontWeight: FontWeight.w600,
                    color: _targetBadgeColor(notification.targetType),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: context.heightPercent(0.8)),
          Text(
            notification.body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: context.getResponsiveSize(3.2),
              color: context.colorPalette.subTitleColor,
            ),
          ),
          SizedBox(height: context.heightPercent(0.8)),
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: context.getResponsiveSize(2.8),
                color: AppColors.textMuted,
              ),
              SizedBox(width: context.getResponsiveSize(1)),
              Text(
                _formatTime(notification.sentAt),
                style: TextStyle(
                  fontSize: context.getResponsiveSize(2.5),
                  color: AppColors.textMuted,
                ),
              ),
              if (notification.recipientCount != null) ...[
                SizedBox(width: context.getResponsiveSize(3)),
                Icon(
                  Icons.people_rounded,
                  size: context.getResponsiveSize(2.8),
                  color: AppColors.textMuted,
                ),
                SizedBox(width: context.getResponsiveSize(1)),
                Text(
                  '${notification.recipientCount} recipients',
                  style: TextStyle(
                    fontSize: context.getResponsiveSize(2.5),
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Color _targetBadgeColor(String targetType) {
    switch (targetType) {
      case 'topic':
        return const Color(0xFF3B82F6);
      case 'user':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF2E7D32);
    }
  }

  String _targetLabel(String targetType) {
    switch (targetType) {
      case 'topic':
        return 'Topic';
      case 'user':
        return 'User';
      default:
        return 'All';
    }
  }

  String _formatTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.isNegative) return 'just now';
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
  }

  Widget _shimmerTile(BuildContext context) {
    return Container(
      height: context.heightPercent(10),
      decoration: BoxDecoration(
        color: context.colorPalette.shimmerBaseColor,
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}
