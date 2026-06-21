import 'package:flutter/material.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';

/// Shows a bottom sheet with "Edit", "Upload", and "Remove" options for an existing image.
///
/// - [onEdit]: called when the user taps "Edit" (open crop editor).
/// - [onUpload]: called when the user taps "Upload" (open file picker).
/// - [onRemove]: called when the user taps "Remove" (delete the image).
/// - [isVideo]: when true, the edit icon changes to a video icon.
void showImageActionSheet(
  BuildContext context, {
  required VoidCallback onEdit,
  required VoidCallback onUpload,
  required VoidCallback onRemove,
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
            // Edit option
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
            Divider(
              height: 1,
              indent: context.getResponsiveSize(5),
              endIndent: context.getResponsiveSize(5),
              color: context.colorPalette.boxColor,
            ),
            // Upload option
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
            Divider(
              height: 1,
              indent: context.getResponsiveSize(5),
              endIndent: context.getResponsiveSize(5),
              color: context.colorPalette.boxColor,
            ),
            // Remove option
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
            SizedBox(height: context.heightPercent(0.5)),
          ],
        ),
      ),
    ),
  );
}
