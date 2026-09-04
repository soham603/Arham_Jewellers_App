import 'package:flutter/material.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';

void showImageActionSheet(
  BuildContext context, {
  required VoidCallback onEdit,
  required VoidCallback onUpload,
  required VoidCallback onRemove,
  VoidCallback? onCamera,
  bool hasImage = true,
  bool isVideo = false,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => SafeArea(
      child: Container(
        margin: EdgeInsets.fromLTRB(
          context.getResponsiveSize(4),
          0,
          context.getResponsiveSize(4),
          context.heightPercent(1.5),
        ),
        decoration: BoxDecoration(
          color: context.colorPalette.backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.colorPalette.boxColor,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: context.heightPercent(1.2)),
            Text(
              'Choose Action',
              style: TextStyle(
                fontSize: context.getResponsiveSize(4),
                fontWeight: FontWeight.w700,
                color: context.colorPalette.textColor,
              ),
            ),
            SizedBox(height: context.heightPercent(0.6)),
            if (hasImage) ...[
              ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: context.getResponsiveSize(5),
                ),
                leading: Container(
                  padding: EdgeInsets.all(context.getResponsiveSize(2)),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isVideo ? Icons.videocam_rounded : Icons.crop_rounded,
                    color: AppColors.primaryGold,
                    size: context.getResponsiveSize(5),
                  ),
                ),
                title: Text(
                  isVideo ? 'Replace Video' : 'Edit Image',
                  style: TextStyle(
                    fontSize: context.getResponsiveSize(3.8),
                    fontWeight: FontWeight.w600,
                    color: context.colorPalette.textColor,
                  ),
                ),
                subtitle: Text(
                  isVideo
                      ? 'Choose a new video file'
                      : 'Crop, rotate or flip the current image',
                  style: TextStyle(
                    fontSize: context.getResponsiveSize(2.8),
                    color: context.colorPalette.subTitleColor,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: context.colorPalette.subTitleColor,
                ),
                onTap: () {
                  Navigator.pop(context);
                  onEdit();
                },
              ),
              const _ActionDivider(),
            ],
            if (onCamera != null) ...[
              ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: context.getResponsiveSize(5),
                ),
                leading: Container(
                  padding: EdgeInsets.all(context.getResponsiveSize(2)),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    color: AppColors.primaryGold,
                    size: context.getResponsiveSize(5),
                  ),
                ),
                title: Text(
                  'Take Photo',
                  style: TextStyle(
                    fontSize: context.getResponsiveSize(3.8),
                    fontWeight: FontWeight.w600,
                    color: context.colorPalette.textColor,
                  ),
                ),
                subtitle: Text(
                  'Capture a new photo with your camera',
                  style: TextStyle(
                    fontSize: context.getResponsiveSize(2.8),
                    color: context.colorPalette.subTitleColor,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: context.colorPalette.subTitleColor,
                ),
                onTap: () {
                  Navigator.pop(context);
                  onCamera();
                },
              ),
              const _ActionDivider(),
            ],
            ListTile(
              contentPadding: EdgeInsets.symmetric(
                horizontal: context.getResponsiveSize(5),
              ),
              leading: Container(
                padding: EdgeInsets.all(context.getResponsiveSize(2)),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isVideo
                      ? Icons.video_library_rounded
                      : Icons.add_photo_alternate_rounded,
                  color: AppColors.primaryGold,
                  size: context.getResponsiveSize(5),
                ),
              ),
              title: Text(
                isVideo ? 'Upload New Video' : 'Upload New Image',
                style: TextStyle(
                  fontSize: context.getResponsiveSize(3.8),
                  fontWeight: FontWeight.w600,
                  color: context.colorPalette.textColor,
                ),
              ),
              subtitle: Text(
                'Pick a new file from your gallery',
                style: TextStyle(
                  fontSize: context.getResponsiveSize(2.8),
                  color: context.colorPalette.subTitleColor,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: context.colorPalette.subTitleColor,
              ),
              onTap: () {
                Navigator.pop(context);
                onUpload();
              },
            ),
            if (hasImage) ...[
              const _ActionDivider(),
              ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: context.getResponsiveSize(5),
                ),
                leading: Container(
                  padding: EdgeInsets.all(context.getResponsiveSize(2)),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.danger,
                    size: context.getResponsiveSize(5),
                  ),
                ),
                title: Text(
                  'Remove',
                  style: TextStyle(
                    fontSize: context.getResponsiveSize(3.8),
                    fontWeight: FontWeight.w600,
                    color: AppColors.danger,
                  ),
                ),
                subtitle: Text(
                  'Delete this image',
                  style: TextStyle(
                    fontSize: context.getResponsiveSize(2.8),
                    color: context.colorPalette.subTitleColor,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: context.colorPalette.subTitleColor,
                ),
                onTap: () {
                  Navigator.pop(context);
                  onRemove();
                },
              ),
            ],
            SizedBox(height: context.heightPercent(0.5)),
          ],
        ),
      ),
    ),
  );
}

class _ActionDivider extends StatelessWidget {
  const _ActionDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: context.getResponsiveSize(5),
      endIndent: context.getResponsiveSize(5),
      color: context.colorPalette.boxColor,
    );
  }
}
