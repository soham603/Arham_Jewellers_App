import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/presentation/controllers/admin/ImageSyncController.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';

class ImageSyncPage extends StatelessWidget {
  const ImageSyncPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = ImageSyncController.instance;

    return Scaffold(
      backgroundColor: context.colorPalette.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.colorPalette.backgroundColor,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(Icons.arrow_back_rounded, color: context.colorPalette.textColor),
        ),
        title: Text(
          'Image Sync',
          style: TextStyle(
            color: context.colorPalette.textColor,
            fontSize: context.getResponsiveSize(5),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          _dateRangeCard(context, ctrl),
          SizedBox(height: context.heightPercent(2)),
          _syncControls(context, ctrl),
          SizedBox(height: context.heightPercent(2)),
          Expanded(child: _resultsList(context, ctrl)),
        ],
      ),
    );
  }

  Widget _dateRangeCard(BuildContext context, ImageSyncController ctrl) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.getResponsiveSize(4)),
      child: Container(
        padding: EdgeInsets.all(context.getResponsiveSize(4)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE7DED2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.date_range_rounded, color: AppColors.primaryGold),
                SizedBox(width: context.getResponsiveSize(2)),
                Text(
                  'Select Date Range (Tag Generate Date)',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                    fontSize: context.getResponsiveSize(4),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.heightPercent(2)),
            Row(
              children: [
                Expanded(
                  child: _dateField(
                    context,
                    label: 'Start',
                    date: ctrl.startDate.value,
                    onTap: () => _pickDate(context, ctrl, isStart: true),
                  ),
                ),
                SizedBox(width: context.getResponsiveSize(3)),
                Expanded(
                  child: _dateField(
                    context,
                    label: 'End',
                    date: ctrl.endDate.value,
                    onTap: () => _pickDate(context, ctrl, isStart: false),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.heightPercent(2)),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: ctrl.findMissingImages,
                icon: const Icon(Icons.search_rounded),
                label: const Text('Find Missing Images'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: context.heightPercent(1.5)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context, ImageSyncController ctrl,
      {required bool isStart}) async {
    final initial = (isStart ? ctrl.startDate : ctrl.endDate).value ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      if (isStart) {
        ctrl.startDate.value = picked;
      } else {
        ctrl.endDate.value = picked;
      }
    }
  }

  Widget _dateField(BuildContext context,
      {required String label, DateTime? date, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.getResponsiveSize(3),
          vertical: context.heightPercent(1.5),
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF5EFE7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: context.getResponsiveSize(3),
              ),
            ),
            SizedBox(height: context.heightPercent(0.3)),
            Text(
              date == null
                  ? 'Select'
                  : '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}',
              style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
                fontSize: context.getResponsiveSize(3.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _syncControls(BuildContext context, ImageSyncController ctrl) {
    return Obx(() {
      if (ctrl.total == 0) return const SizedBox.shrink();
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: context.getResponsiveSize(4)),
        child: Container(
          padding: EdgeInsets.all(context.getResponsiveSize(3.5)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE7DED2)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${ctrl.total} missing image(s) found',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                      fontSize: context.getResponsiveSize(4),
                    ),
                  ),
                  if (ctrl.isSyncing)
                    Text(
                      '${ctrl.currentIndex}/${ctrl.items.length}',
                      style: TextStyle(
                        color: AppColors.primaryGold,
                        fontWeight: FontWeight.w700,
                        fontSize: context.getResponsiveSize(4),
                      ),
                    ),
                ],
              ),
              if (ctrl.isSyncing) ...[
                SizedBox(height: context.heightPercent(1.5)),
                LinearProgressIndicator(
                  value: ctrl.items.isEmpty
                      ? 0
                      : (ctrl.currentIndex / ctrl.items.length).clamp(0.0, 1.0),
                  backgroundColor: const Color(0xFFF5EFE7),
                  color: AppColors.primaryGold,
                  minHeight: 8,
                ),
              ],
              SizedBox(height: context.heightPercent(1.5)),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: ctrl.isSyncing ? null : ctrl.findMissingImages,
                      child: const Text('Refresh'),
                    ),
                  ),
                  SizedBox(width: context.getResponsiveSize(3)),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: ctrl.isSyncing ? null : ctrl.syncMissingImages,
                      icon: ctrl.isSyncing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.cloud_sync_rounded),
                      label: Text(ctrl.isSyncing ? 'Syncing…' : 'Sync All (1 by 1)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGold,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.primaryGold.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
              if (ctrl.isSyncing || ctrl.syncedCount > 0 || ctrl.failedCount > 0)
                Padding(
                  padding: EdgeInsets.only(top: context.heightPercent(1.2)),
                  child: Row(
                    children: [
                      _statChip(context, 'Synced', ctrl.syncedCount, Colors.green),
                      SizedBox(width: context.getResponsiveSize(2)),
                      _statChip(context, 'Failed', ctrl.failedCount, Colors.red),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _statChip(BuildContext context, String label, int count, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.getResponsiveSize(3),
        vertical: context.heightPercent(0.5),
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: context.getResponsiveSize(3.2),
        ),
      ),
    );
  }

  Widget _resultsList(BuildContext context, ImageSyncController ctrl) {
    return Obx(() {
      switch (ctrl.listState) {
        case CurrentAppState.LOADING:
          return const Center(child: CircularProgressIndicator());
        case CurrentAppState.ERROR:
          return const Center(
            child: Text('Failed to load products. Try again.'),
          );
        case CurrentAppState.INITIAL:
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_sync_rounded,
                    size: context.getResponsiveSize(12), color: AppColors.textMuted),
                SizedBox(height: context.heightPercent(1)),
                Text(
                  'Select a date range and tap "Find Missing Images".',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ],
            ),
          );
        case CurrentAppState.SUCCESS:
          if (ctrl.items.isEmpty) {
            return const Center(
              child: Text('No missing images in the selected range.'),
            );
          }
          return ListView.separated(
            padding: EdgeInsets.fromLTRB(
              context.getResponsiveSize(4),
              0,
              context.getResponsiveSize(4),
              context.getResponsiveSize(4),
            ),
            itemCount: ctrl.items.length,
            separatorBuilder: (_, _) => SizedBox(height: context.heightPercent(1)),
            itemBuilder: (context, index) => _itemTile(context, ctrl, ctrl.items[index], index),
          );
      }
    });
  }

  Widget _itemTile(BuildContext context, ImageSyncController ctrl,
      MissingImageItem item, int index) {
    final result = ctrl.results[item.id];
    final status = result?.status;

    return Container(
      padding: EdgeInsets.all(context.getResponsiveSize(3.5)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7DED2)),
      ),
      child: Row(
        children: [
          Container(
            width: context.getResponsiveSize(11),
            height: context.getResponsiveSize(11),
            decoration: BoxDecoration(
              color: const Color(0xFFF5EFE7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.image_outlined, color: AppColors.primaryGold),
          ),
          SizedBox(width: context.getResponsiveSize(3)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                    fontSize: context.getResponsiveSize(3.8),
                  ),
                ),
                SizedBox(height: context.heightPercent(0.3)),
                Text(
                  'Tag: ${item.tagNo ?? '-'}',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: context.getResponsiveSize(3.2),
                  ),
                ),
                if (item.tagGenerateDate != null)
                  Text(
                    'Generated: ${item.tagGenerateDate}',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: context.getResponsiveSize(3),
                    ),
                  ),
              ],
            ),
          ),
          _statusIcon(context, status),
        ],
      ),
    );
  }

  Widget _statusIcon(BuildContext context, String? status) {
    if (status == null) {
      return const Icon(Icons.hourglass_empty_rounded,
          color: AppColors.textMuted);
    }
    switch (status) {
      case 'SUCCESS':
        return const Icon(Icons.check_circle_rounded, color: Colors.green);
      case 'SKIPPED':
        return const Icon(Icons.remove_circle_outline_rounded,
            color: Colors.orange);
      default:
        return const Icon(Icons.error_rounded, color: Colors.red);
    }
  }
}
