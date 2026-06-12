import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide MultipartFile, FormData;
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:ratnesh_gold_app/domain/entities/carousel_model.dart';
import 'package:ratnesh_gold_app/presentation/controllers/carousel_controller.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';

import '../../../core/theme/app_colors.dart';

class CarouselManagerScreen extends StatefulWidget {
  const CarouselManagerScreen({super.key});

  @override
  State<CarouselManagerScreen> createState() => _CarouselManagerScreenState();
}

class _CarouselManagerScreenState extends State<CarouselManagerScreen>
    with SingleTickerProviderStateMixin {
  late final CarouselsController controller;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<CarouselsController>()) {
      controller = Get.find<CarouselsController>();
    } else {
      controller = Get.put(CarouselsController());
    }
    _tabController = TabController(length: 2, vsync: this);
    controller.fetchAdminCarousels();
    controller.fetchDeletedCarousels();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorPalette.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.colorPalette.backgroundColor,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Carousel Manager',
          style: TextStyle(
            fontSize: context.getResponsiveSize(5.5),
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: context.getResponsiveSize(4)),
            child: GestureDetector(
              onTap: () => _showCreateSheet(context),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.getResponsiveSize(4),
                  vertical: context.getScreenHeight(0.8),
                ),
                decoration: BoxDecoration(
                  color: context.colorPalette.primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.add,
                      color: Colors.white,
                      size: context.getResponsiveSize(4.5),
                    ),
                    SizedBox(width: context.getResponsiveSize(1.5)),
                    Text(
                      'Add New',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: context.getResponsiveSize(3.5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: context.colorPalette.primaryColor,
          unselectedLabelColor: context.colorPalette.subTitleColor,
          indicatorColor: context.colorPalette.primaryColor,
          labelStyle: TextStyle(
            fontSize: context.getResponsiveSize(3.8),
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Deleted'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_activeTab(context), _deletedTab(context)],
      ),
    );
  }

  // ── Active Tab 
  Widget _activeTab(BuildContext context) {
    return Obx(() {
      final state = controller.adminState;
      final list = controller.adminList;

      if (state == CurrentAppState.LOADING) {
        return _loadingList(context);
      }

      if (state == CurrentAppState.ERROR) {
        return _errorView(context, onRetry: controller.fetchAdminCarousels);
      }

      if (list.isEmpty) {
        return _emptyView(
          context,
          'No carousels yet.\nTap "Add New" to create one.',
        );
      }

      return RefreshIndicator(
        onRefresh: controller.fetchAdminCarousels,
        color: context.colorPalette.primaryColor,
        child: ReorderableListView.builder(
          padding: EdgeInsets.all(context.getResponsiveSize(4)),
          itemCount: list.length,
          onReorder: (oldIndex, newIndex) {
            if (newIndex > oldIndex) newIndex--;
            final item = list[oldIndex];
            controller.reorderCarousel(id: item.id, newPosition: newIndex + 1);
          },
          itemBuilder: (context, index) {
            final item = list[index];
            return _activeCarouselCard(
              context,
              item,
              index,
              key: ValueKey(item.id),
            );
          },
        ),
      );
    });
  }

  // ── Deleted Tab 
  Widget _deletedTab(BuildContext context) {
    return Obx(() {
      final state = controller.deletedState;
      final list = controller.deletedList;

      if (state == CurrentAppState.LOADING) {
        return _loadingList(context);
      }

      if (state == CurrentAppState.ERROR) {
        return _errorView(context, onRetry: controller.fetchDeletedCarousels);
      }

      if (list.isEmpty) {
        return _emptyView(context, 'No deleted carousels.');
      }

      return RefreshIndicator(
        onRefresh: controller.fetchDeletedCarousels,
        color: context.colorPalette.primaryColor,
        child: ListView.separated(
          padding: EdgeInsets.all(context.getResponsiveSize(4)),
          itemCount: list.length,
          separatorBuilder: (_, _) =>
              SizedBox(height: context.getScreenHeight(1.5)),
          itemBuilder: (context, index) =>
              _deletedCarouselCard(context, list[index]),
        ),
      );
    });
  }

  Widget _activeCarouselCard(
    BuildContext context,
    CarouselModel item,
    int index, {
    required Key key,
  }) {
    return Container(
      key: key,
      margin: EdgeInsets.only(bottom: context.getScreenHeight(1.5)),
      decoration: BoxDecoration(
        color: context.colorPalette.boxColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colorPalette.boxColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: item.imageUrl,
                      width: double.infinity,
                      height: context.getScreenHeight(20),
                      fit: BoxFit.cover,
                      placeholder: (_, _) => Container(
                        color: context.colorPalette.shimmerBaseColor,
                        height: context.getScreenHeight(20),
                      ),
                      errorWidget: (_, _, _) => Container(
                        height: context.getScreenHeight(20),
                        color: context.colorPalette.boxColor,
                        child: Icon(
                          Icons.image_not_supported,
                          color: context.colorPalette.subTitleColor,
                        ),
                      ),
                    ),
                    if (item.mediaType == 'video')
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.3),
                          child: Center(
                            child: Container(
                              padding: EdgeInsets.all(context.getResponsiveSize(2)),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: context.getResponsiveSize(8),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Position badge
              Positioned(
                top: context.getScreenHeight(1),
                left: context.getResponsiveSize(3),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.getResponsiveSize(2.5),
                    vertical: context.getScreenHeight(0.4),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '#${index + 1}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: context.getResponsiveSize(3.2),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              // Active badge
              Positioned(
                top: context.getScreenHeight(1),
                right: context.getResponsiveSize(3),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.getResponsiveSize(2.5),
                    vertical: context.getScreenHeight(0.4),
                  ),
                  decoration: BoxDecoration(
                    color: item.isActive
                        ? Colors.green.withValues(alpha: 0.85)
                        : Colors.orange.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: context.getResponsiveSize(2.8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              // Drag handle
              Positioned(
                bottom: context.getScreenHeight(1),
                right: context.getResponsiveSize(3),
                child: Container(
                  padding: EdgeInsets.all(context.getResponsiveSize(1.5)),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.drag_handle_rounded,
                    color: Colors.white,
                    size: context.getResponsiveSize(4),
                  ),
                ),
              ),
            ],
          ),

          // ── Info 
          Padding(
            padding: EdgeInsets.all(context.getResponsiveSize(3.5)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.title.isNotEmpty)
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: context.getResponsiveSize(4.2),
                      fontWeight: FontWeight.w700,
                      color: context.colorPalette.textColor,
                    ),
                  ),
                if (item.description.isNotEmpty) ...[
                  SizedBox(height: context.getScreenHeight(0.4)),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.getResponsiveSize(3.2),
                      color: context.colorPalette.subTitleColor,
                    ),
                  ),
                ],
                SizedBox(height: context.getScreenHeight(1.2)),

                // ── Action Row 
                Row(
                  children: [
                    // Toggle active
                    Obx(
                      () => _actionChip(
                        context,
                        icon: item.isActive
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        label: item.isActive ? 'Deactivate' : 'Activate',
                        color: item.isActive ? Colors.orange : Colors.green,
                        isLoading:
                            controller.editLoadingId == item.id,
                        onTap: () async {
                          final ok = await controller.editCarousel(
                            id: item.id,
                            isActive: !item.isActive,
                          );
                          if (ok) {
                            await controller.fetchAdminCarousels();
                            if (context.mounted) {
                              _showSnack(
                                context,
                                'Status updated',
                                isError: false,
                              );
                            }
                          } else if (context.mounted) {
                            _showSnack(
                              context,
                              controller.error.isNotEmpty
                                  ? controller.error
                                  : 'Failed to update status',
                              isError: true,
                            );
                          }
                        },
                      ),
                    ),
                    SizedBox(width: context.getResponsiveSize(2)),

                    // Edit
                    _actionChip(
                      context,
                      icon: Icons.edit_rounded,
                      label: 'Edit',
                      color: context.colorPalette.primaryColor,
                      onTap: () => _showEditSheet(context, item),
                    ),
                    SizedBox(width: context.getResponsiveSize(2)),

                    // Delete
                    Obx(
                      () => _actionChip(
                        context,
                        icon: Icons.delete_rounded,
                        label: 'Delete',
                        color: Colors.red,
                        isLoading:
                            controller.deleteLoadingId == item.id,
                        onTap: () => _confirmDelete(context, item),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Deleted Carousel Card ─
  Widget _deletedCarouselCard(BuildContext context, CarouselModel item) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorPalette.boxColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(16),
            ),
            child: CachedNetworkImage(
              imageUrl: item.imageUrl,
              width: context.getResponsiveSize(28),
              height: context.getScreenHeight(12),
              fit: BoxFit.cover,
              placeholder: (_, _) =>
                  Container(color: context.colorPalette.shimmerBaseColor),
              errorWidget: (_, _, _) => Container(
                color: context.colorPalette.boxColor,
                child: Icon(
                  Icons.image_not_supported,
                  color: context.colorPalette.subTitleColor,
                ),
              ),
            ),
          ),

          // Info
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(context.getResponsiveSize(3)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.getResponsiveSize(2),
                          vertical: context.getScreenHeight(0.3),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Deleted',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: context.getResponsiveSize(2.8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.getScreenHeight(0.5)),
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.getResponsiveSize(3.8),
                      fontWeight: FontWeight.w600,
                      color: context.colorPalette.textColor,
                    ),
                  ),
                  SizedBox(height: context.getScreenHeight(1)),
                  Row(
                    children: [
                      Expanded(
                        child: Obx(
                          () => GestureDetector(
                            onTap: () async {
                              final ok = await controller.restoreCarousel(
                                item.id,
                              );
                              if (ok && context.mounted) {
                                _showSnack(
                                  context,
                                  'Carousel restored',
                                  isError: false,
                                );
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                vertical: context.getScreenHeight(0.8),
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child:
                                  controller.restoreLoadingId == item.id
                                  ? Center(
                                      child: SizedBox(
                                        width: context.getResponsiveSize(4),
                                        height: context.getResponsiveSize(4),
                                        child: const CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.restore_rounded,
                                          color: Colors.white,
                                          size: context.getResponsiveSize(4),
                                        ),
                                        SizedBox(
                                          width: context.getResponsiveSize(1.5),
                                        ),
                                        Text(
                                          'Restore',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: context.getResponsiveSize(
                                              3.2,
                                            ),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: context.getResponsiveSize(2)),
                      GestureDetector(
                        onTap: () => _showRestoreWithImageSheet(context, item),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: context.getScreenHeight(0.8),
                            horizontal: context.getResponsiveSize(3),
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: context.colorPalette.primaryColor,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.add_photo_alternate_rounded,
                            color: context.colorPalette.primaryColor,
                            size: context.getResponsiveSize(5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Create Bottom Sheet ───
  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CarouselFormSheet(
        onSubmit:
            ({
              required String? title,
              required String? description,
              required String? linkUrl,
              required File? imageFile,
              required bool? isActive,
              String? mediaType,
            }) async {
              if (imageFile == null) {
                _showSnack(context, 'Please select an image or video', isError: true);
                return;
              }
              final ok = await controller.createCarousel(
                title: title,
                description: description,
                linkUrl: linkUrl,
                imageFile: imageFile,
                isActive: isActive ?? true,
                mediaType: mediaType,
              );
              if (ok && context.mounted) {
                Get.back();
                _showSnack(
                  context,
                  'Carousel created successfully',
                  isError: false,
                );
              } else if (context.mounted) {
                _showSnack(context, controller.error, isError: true);
              }
            },
      ),
    );
  }

  // ── Edit Bottom Sheet 
  void _showEditSheet(BuildContext context, CarouselModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CarouselFormSheet(
        existing: item,
        onSubmit:
            ({
              required String? title,
              required String? description,
              required String? linkUrl,
              required File? imageFile,
              required bool? isActive,
              String? mediaType,
            }) async {
              final ok = await controller.editCarousel(
                id: item.id,
                title: title,
                description: description,
                linkUrl: linkUrl,
                imageFile: imageFile,
                isActive: isActive,
                mediaType: mediaType,
              );
              if (ok && context.mounted) {
                Get.back();
                _showSnack(context, 'Carousel updated', isError: false);
              } else if (context.mounted) {
                _showSnack(context, controller.error, isError: true);
              }
            },
      ),
    );
  }

  // ── Restore + Re-upload Image Sheet 
  void _showRestoreWithImageSheet(BuildContext context, CarouselModel item) {
    File? newImage;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => Container(
          padding: EdgeInsets.fromLTRB(
            context.getResponsiveSize(5),
            context.getScreenHeight(2),
            context.getResponsiveSize(5),
            context.getScreenHeight(4),
          ),
          decoration: BoxDecoration(
            color: context.colorPalette.backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: context.getResponsiveSize(10),
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.colorPalette.boxColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: context.getScreenHeight(2)),
              Text(
                'Restore with New Image',
                style: TextStyle(
                  fontSize: context.getResponsiveSize(5),
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: context.getScreenHeight(0.5)),
              Text(
                'Optionally replace the image before restoring',
                style: TextStyle(
                  fontSize: context.getResponsiveSize(3.2),
                  color: context.colorPalette.subTitleColor,
                ),
              ),
              SizedBox(height: context.getScreenHeight(2)),
              GestureDetector(
                onTap: () async {
                  final picked = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 80,
                  );
                  if (picked != null) {
                    setInner(() => newImage = File(picked.path));
                  }
                },
                child: Container(
                  height: context.getScreenHeight(18),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: context.colorPalette.boxColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: newImage != null
                          ? context.colorPalette.primaryColor
                          : context.colorPalette.boxColor,
                    ),
                  ),
                  child: newImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(newImage!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_rounded,
                              size: context.getResponsiveSize(10),
                              color: context.colorPalette.subTitleColor,
                            ),
                            SizedBox(height: context.getScreenHeight(0.8)),
                            Text(
                              'Tap to select image (optional)',
                              style: TextStyle(
                                color: context.colorPalette.subTitleColor,
                                fontSize: context.getResponsiveSize(3.2),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              SizedBox(height: context.getScreenHeight(2.5)),
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        controller.restoreState == CurrentAppState.LOADING ||
                                controller.editState ==
                                    CurrentAppState.LOADING
                            ? null
                            : () async {
                                bool ok = true;
                                if (newImage != null) {
                                  ok = await controller.editCarousel(
                                    id: item.id,
                                    imageFile: newImage,
                                  );
                                }
                                if (ok) {
                                  ok = await controller.restoreCarousel(
                                    item.id,
                                  );
                                }
                                if (ok && context.mounted) {
                                  Get.back();
                                  _showSnack(
                                    context,
                                    'Carousel restored',
                                    isError: false,
                                  );
                                } else if (context.mounted) {
                                  _showSnack(
                                    context,
                                    controller.error.isNotEmpty
                                        ? controller.error
                                        : 'Failed to restore carousel',
                                    isError: true,
                                  );
                                }
                              },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(
                        vertical: context.getScreenHeight(1.8),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: controller.restoreState == CurrentAppState.LOADING
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Restore Carousel',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: context.getResponsiveSize(4),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Confirm Delete Dialog ─
  void _confirmDelete(BuildContext context, CarouselModel item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.colorPalette.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Carousel?',
          style: TextStyle(
            fontSize: context.getResponsiveSize(4.5),
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        content: Text(
          'This will soft-delete the carousel. You can restore it later from the Deleted tab.',
          style: TextStyle(
            fontSize: context.getResponsiveSize(3.5),
            color: context.colorPalette.subTitleColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.colorPalette.subTitleColor),
            ),
          ),
          Obx(
              () => TextButton(
                onPressed: controller.deleteLoadingId == item.id
                    ? null
                    : () async {
                        final ok = await controller.deleteCarousel(item.id);
                        if (ok && context.mounted) {
                          Get.back();
                          _showSnack(context, 'Carousel deleted', isError: false);
                        } else if (!ok && context.mounted) {
                          _showSnack(
                            context,
                            controller.error.isNotEmpty
                                ? controller.error
                                : 'Delete failed',
                            isError: true,
                          );
                        }
                      },
              child: controller.deleteLoadingId == item.id
                  ? SizedBox(
                      width: context.getResponsiveSize(4),
                      height: context.getResponsiveSize(4),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.red,
                      ),
                    )
                  : const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers 
  Widget _actionChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.getResponsiveSize(2.5),
          vertical: context.getScreenHeight(0.6),
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: isLoading
            ? SizedBox(
                width: context.getResponsiveSize(4),
                height: context.getResponsiveSize(4),
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: color, size: context.getResponsiveSize(3.8)),
                  SizedBox(width: context.getResponsiveSize(1.2)),
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: context.getResponsiveSize(3),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _loadingList(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.all(context.getResponsiveSize(4)),
      itemCount: 3,
      separatorBuilder: (_, _) =>
          SizedBox(height: context.getScreenHeight(1.5)),
      itemBuilder: (_, _) => Container(
        height: context.getScreenHeight(28),
        decoration: BoxDecoration(
          color: context.colorPalette.shimmerBaseColor,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _errorView(BuildContext context, {required VoidCallback onRetry}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_off_rounded,
            size: context.getResponsiveSize(14),
            color: context.colorPalette.subTitleColor,
          ),
          SizedBox(height: context.getScreenHeight(1.5)),
          Text(
            'Failed to load',
            style: TextStyle(
              fontSize: context.getResponsiveSize(4.5),
              fontWeight: FontWeight.w600,
              color: context.colorPalette.textColor,
            ),
          ),
          SizedBox(height: context.getScreenHeight(2)),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colorPalette.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _emptyView(BuildContext context, String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_rounded,
            size: context.getResponsiveSize(14),
            color: context.colorPalette.subTitleColor,
          ),
          SizedBox(height: context.getScreenHeight(1.5)),
          Text(
            msg,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: context.getResponsiveSize(4),
              color: context.colorPalette.subTitleColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(BuildContext context, String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ── Reusable Form Sheet ────
class _CarouselFormSheet extends StatefulWidget {
  final CarouselModel? existing;
  final Future<void> Function({
    required String? title,
    required String? description,
    required String? linkUrl,
    required File? imageFile,
    required bool? isActive,
    String? mediaType,
  })
  onSubmit;

  const _CarouselFormSheet({this.existing, required this.onSubmit});

  @override
  State<_CarouselFormSheet> createState() => _CarouselFormSheetState();
}

class _CarouselFormSheetState extends State<_CarouselFormSheet> {
  final CarouselsController controller = Get.find();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _linkController = TextEditingController();
  final _formError = ''.obs;
  File? _pickedImage;
  VideoPlayerController? _videoPreviewController;
  bool _isActive = true;
  bool _isSubmitting = false;
  String? _localMediaType;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _titleController.text = widget.existing!.title;
      _descriptionController.text = widget.existing!.description;
      _linkController.text = widget.existing!.linkUrl ?? '';
      _isActive = widget.existing!.isActive;
      _localMediaType = widget.existing!.mediaType;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _linkController.dispose();
    _videoPreviewController?.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    final source = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: context.colorPalette.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(context.getResponsiveSize(5)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Media Type',
                style: TextStyle(
                  fontSize: context.getResponsiveSize(5),
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: context.getScreenHeight(2)),
              Row(
                children: [
                  Expanded(
                    child: _mediaTypeOption(
                      ctx,
                      icon: Icons.image_rounded,
                      label: 'Image',
                      onTap: () => Navigator.pop(ctx, 'image'),
                    ),
                  ),
                  SizedBox(width: context.getResponsiveSize(3)),
                  Expanded(
                    child: _mediaTypeOption(
                      ctx,
                      icon: Icons.videocam_rounded,
                      label: 'Video',
                      onTap: () => Navigator.pop(ctx, 'video'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    if (source == 'image') {
      await _videoPreviewController?.dispose();
      _videoPreviewController = null;
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (picked != null) {
        setState(() {
          _pickedImage = File(picked.path);
          _localMediaType = 'image';
        });
      }
    } else {
      final picked = await ImagePicker().pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 60),
      );
      if (picked != null) {
        await _videoPreviewController?.dispose();
        _videoPreviewController = VideoPlayerController.file(File(picked.path));
        await _videoPreviewController!.initialize();
        setState(() {
          _pickedImage = File(picked.path);
          _localMediaType = 'video';
        });
      }
    }
  }

  Widget _mediaTypeOption(
    BuildContext ctx,
    {required IconData icon, required String label, required VoidCallback onTap}
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: context.getScreenHeight(2)),
        decoration: BoxDecoration(
          color: context.colorPalette.boxColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, size: context.getResponsiveSize(10), color: context.colorPalette.primaryColor),
            SizedBox(height: context.getScreenHeight(0.8)),
            Text(
              label,
              style: TextStyle(
                fontSize: context.getResponsiveSize(3.8),
                fontWeight: FontWeight.w600,
                color: context.colorPalette.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPreview({required bool isEdit}) {
    if (_pickedImage != null) {
      if (_localMediaType == 'video') {
        if (_videoPreviewController != null && _videoPreviewController!.value.isInitialized) {
          final ctrl = _videoPreviewController!;
          return Stack(
            fit: StackFit.expand,
            children: [
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: ctrl.value.size.width,
                  height: ctrl.value.size.height,
                  child: VideoPlayer(ctrl),
                ),
              ),
              Container(color: Colors.black.withValues(alpha: 0.25)),
              Center(
                child: Container(
                  padding: EdgeInsets.all(context.getResponsiveSize(2)),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: context.getResponsiveSize(6),
                  ),
                ),
              ),
              Positioned(
                bottom: context.getResponsiveSize(2),
                right: context.getResponsiveSize(2),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.getResponsiveSize(2),
                    vertical: context.getResponsiveSize(0.5),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Tap to change',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: context.getResponsiveSize(2.5),
                    ),
                  ),
                ),
              ),
            ],
          );
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            Container(color: context.colorPalette.boxColor),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.videocam_rounded,
                    size: context.getResponsiveSize(12),
                    color: context.colorPalette.primaryColor,
                  ),
                  SizedBox(height: context.getScreenHeight(0.8)),
                  Text(
                    'Video selected',
                    style: TextStyle(
                      color: context.colorPalette.textColor,
                      fontSize: context.getResponsiveSize(3.5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: context.getScreenHeight(0.3)),
                  Text(
                    'Tap to change',
                    style: TextStyle(
                      color: context.colorPalette.subTitleColor,
                      fontSize: context.getResponsiveSize(2.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(_pickedImage!, fit: BoxFit.cover),
          Container(color: Colors.black.withValues(alpha: 0.2)),
          Center(
            child: Icon(
              Icons.edit_rounded,
              color: Colors.white,
              size: context.getResponsiveSize(8),
            ),
          ),
        ],
      );
    }

    final existingUrl = widget.existing?.imageUrl;
    final existingVideo = widget.existing?.mediaType == 'video';

    if (existingUrl != null && existingUrl.isNotEmpty) {
      if (existingVideo) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Container(color: context.colorPalette.boxColor),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.videocam_rounded,
                    size: context.getResponsiveSize(12),
                    color: context.colorPalette.primaryColor,
                  ),
                  SizedBox(height: context.getScreenHeight(0.8)),
                  Text(
                    'Video (existing)',
                    style: TextStyle(
                      color: context.colorPalette.textColor,
                      fontSize: context.getResponsiveSize(3.5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: context.getScreenHeight(0.3)),
                  Text(
                    'Tap to change',
                    style: TextStyle(
                      color: context.colorPalette.subTitleColor,
                      fontSize: context.getResponsiveSize(2.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }
      return Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: existingUrl,
            fit: BoxFit.cover,
          ),
          Container(color: Colors.black.withValues(alpha: 0.4)),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.edit_rounded,
                  color: Colors.white,
                  size: context.getResponsiveSize(8),
                ),
                SizedBox(height: context.getScreenHeight(0.5)),
                Text(
                  'Tap to change',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: context.getResponsiveSize(3.2),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_rounded,
          size: context.getResponsiveSize(12),
          color: context.colorPalette.subTitleColor,
        ),
        SizedBox(height: context.getScreenHeight(0.8)),
        Text(
          'Tap to select image/video',
          style: TextStyle(
            color: context.colorPalette.subTitleColor,
            fontSize: context.getResponsiveSize(3.5),
          ),
        ),
        if (!isEdit) ...[
          SizedBox(height: context.getScreenHeight(0.3)),
          Text(
            '* Required',
            style: TextStyle(
              color: Colors.red,
              fontSize: context.getResponsiveSize(3),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          context.getResponsiveSize(5),
          context.getScreenHeight(2),
          context.getResponsiveSize(5),
          context.getScreenHeight(4),
        ),
        decoration: BoxDecoration(
          color: context.colorPalette.backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: context.getResponsiveSize(10),
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.colorPalette.boxColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: context.getScreenHeight(2)),
              Text(
                isEdit ? 'Edit Carousel' : 'New Carousel',
                style: TextStyle(
                  fontSize: context.getResponsiveSize(5.5),
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: context.getScreenHeight(2)),

              // ── Media Picker 
              AspectRatio(
                aspectRatio: 2.0,
                child: GestureDetector(
                  onTap: _pickMedia,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: context.colorPalette.boxColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _pickedImage != null
                            ? context.colorPalette.primaryColor
                            : context.colorPalette.boxColor,
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildMediaPreview(isEdit: isEdit),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: context.getResponsiveSize(3.5),
                    color: context.colorPalette.subTitleColor,
                  ),
                  SizedBox(width: context.getResponsiveSize(1.5)),
                  Expanded(
                    child: Text(
                      'Recommended: 2:1 ratio (e.g. 1920x960) for best results',
                      style: TextStyle(
                        color: context.colorPalette.subTitleColor,
                        fontSize: context.getResponsiveSize(2.8),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.getScreenHeight(1)),

              // ── Title 
              _buildField(
                context,
                'Title (optional)',
                _titleController,
              ),
              SizedBox(height: context.getScreenHeight(1.5)),

              // ── Description 
              _buildField(
                context,
                'Description (optional)',
                _descriptionController,
                maxLines: 3,
              ),
              SizedBox(height: context.getScreenHeight(1.5)),

              // ── Link URL ─
              _buildField(
                context,
                'Link URL (optional)',
                _linkController,
                keyboardType: TextInputType.url,
              ),
              SizedBox(height: context.getScreenHeight(1.5)),

              // ── Inline Error 
              Obx(
                () => _formError.value.isNotEmpty
                    ? Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: context.getResponsiveSize(3),
                          vertical: context.getScreenHeight(1),
                        ),
                        margin: EdgeInsets.only(
                          bottom: context.getScreenHeight(1.5),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: context.getResponsiveSize(4.5),
                            ),
                            SizedBox(width: context.getResponsiveSize(2)),
                            Expanded(
                              child: Text(
                                _formError.value,
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: context.getResponsiveSize(3.2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              // ── isActive toggle ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Show on homepage',
                    style: TextStyle(
                      fontSize: context.getResponsiveSize(4),
                      color: context.colorPalette.textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Switch(
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                    activeThumbColor: context.colorPalette.primaryColor,
                  ),
                ],
              ),
              SizedBox(height: context.getScreenHeight(1.5)),

              // ── Submit ───
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () async {
                          _formError.value = '';
                          if (_pickedImage == null && widget.existing == null) {
                            _formError.value = 'Please select an image or video';
                            return;
                          }
                          setState(() => _isSubmitting = true);
                          await widget.onSubmit(
                            title: _titleController.text.trim().isEmpty
                                ? null
                                : _titleController.text.trim(),
                            description: _descriptionController.text.trim().isEmpty
                                ? null
                                : _descriptionController.text.trim(),
                            linkUrl: _linkController.text.trim().isEmpty
                                ? null
                                : _linkController.text.trim(),
                            imageFile: _pickedImage,
                            isActive: _isActive,
                            mediaType: _localMediaType,
                          );
                          if (mounted) {
                            setState(() => _isSubmitting = false);
                            if (controller.error.isNotEmpty) {
                              _formError.value = controller.error;
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colorPalette.primaryColor,
                    padding: EdgeInsets.symmetric(
                      vertical: context.getScreenHeight(1.8),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isEdit ? 'Save Changes' : 'Create Carousel',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: context.getResponsiveSize(4.2),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    BuildContext context,
    String hint,
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(
        fontSize: context.getResponsiveSize(3.8),
        color: context.colorPalette.textColor,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: context.colorPalette.subTitleColor,
          fontSize: context.getResponsiveSize(3.5),
        ),
        filled: true,
        fillColor: context.colorPalette.boxColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: context.getResponsiveSize(4),
          vertical: context.getScreenHeight(1.4),
        ),
      ),
    );
  }
}
