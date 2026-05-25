import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide MultipartFile, FormData;
import 'package:image_picker/image_picker.dart';
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
            fontSize: context.getScreenWidth(5.5),
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: context.getScreenWidth(4)),
            child: GestureDetector(
              onTap: () => _showCreateSheet(context),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.getScreenWidth(4),
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
                      size: context.getScreenWidth(4.5),
                    ),
                    SizedBox(width: context.getScreenWidth(1.5)),
                    Text(
                      'Add New',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: context.getScreenWidth(3.5),
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
            fontSize: context.getScreenWidth(3.8),
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

  // ── Active Tab ─────────────────────────────────────────────────────────────
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
          padding: EdgeInsets.all(context.getScreenWidth(4)),
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

  // ── Deleted Tab ────────────────────────────────────────────────────────────
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
          padding: EdgeInsets.all(context.getScreenWidth(4)),
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
            color: Colors.black.withOpacity(0.04),
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
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  width: double.infinity,
                  height: context.getScreenHeight(20),
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: context.colorPalette.shimmerBaseColor,
                    height: context.getScreenHeight(20),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: context.getScreenHeight(20),
                    color: context.colorPalette.boxColor,
                    child: Icon(
                      Icons.image_not_supported,
                      color: context.colorPalette.subTitleColor,
                    ),
                  ),
                ),
              ),
              // Position badge
              Positioned(
                top: context.getScreenHeight(1),
                left: context.getScreenWidth(3),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.getScreenWidth(2.5),
                    vertical: context.getScreenHeight(0.4),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '#${index + 1}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: context.getScreenWidth(3.2),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              // Active badge
              Positioned(
                top: context.getScreenHeight(1),
                right: context.getScreenWidth(3),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.getScreenWidth(2.5),
                    vertical: context.getScreenHeight(0.4),
                  ),
                  decoration: BoxDecoration(
                    color: item.isActive
                        ? Colors.green.withOpacity(0.85)
                        : Colors.orange.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: context.getScreenWidth(2.8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              // Drag handle
              Positioned(
                bottom: context.getScreenHeight(1),
                right: context.getScreenWidth(3),
                child: Container(
                  padding: EdgeInsets.all(context.getScreenWidth(1.5)),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.drag_handle_rounded,
                    color: Colors.white,
                    size: context.getScreenWidth(4),
                  ),
                ),
              ),
            ],
          ),

          // ── Info ──────────────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.all(context.getScreenWidth(3.5)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.title.isNotEmpty)
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: context.getScreenWidth(4.2),
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
                      fontSize: context.getScreenWidth(3.2),
                      color: context.colorPalette.subTitleColor,
                    ),
                  ),
                ],
                SizedBox(height: context.getScreenHeight(1.2)),

                // ── Action Row ────────────────────────────────────────────
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
                            controller.editState == CurrentAppState.LOADING,
                        onTap: () => controller.editCarousel(
                          id: item.id,
                          isActive: !item.isActive,
                        ),
                      ),
                    ),
                    SizedBox(width: context.getScreenWidth(2)),

                    // Edit
                    _actionChip(
                      context,
                      icon: Icons.edit_rounded,
                      label: 'Edit',
                      color: context.colorPalette.primaryColor,
                      onTap: () => _showEditSheet(context, item),
                    ),
                    SizedBox(width: context.getScreenWidth(2)),

                    // Delete
                    Obx(
                      () => _actionChip(
                        context,
                        icon: Icons.delete_rounded,
                        label: 'Delete',
                        color: Colors.red,
                        isLoading:
                            controller.deleteState == CurrentAppState.LOADING,
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

  // ── Deleted Carousel Card ─────────────────────────────────────────────────
  Widget _deletedCarouselCard(BuildContext context, CarouselModel item) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorPalette.boxColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
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
              width: context.getScreenWidth(28),
              height: context.getScreenHeight(12),
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  Container(color: context.colorPalette.shimmerBaseColor),
              errorWidget: (_, __, ___) => Container(
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
              padding: EdgeInsets.all(context.getScreenWidth(3)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.getScreenWidth(2),
                          vertical: context.getScreenHeight(0.3),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Deleted',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: context.getScreenWidth(2.8),
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
                      fontSize: context.getScreenWidth(3.8),
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
                                  controller.restoreState ==
                                      CurrentAppState.LOADING
                                  ? Center(
                                      child: SizedBox(
                                        width: context.getScreenWidth(4),
                                        height: context.getScreenWidth(4),
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
                                          size: context.getScreenWidth(4),
                                        ),
                                        SizedBox(
                                          width: context.getScreenWidth(1.5),
                                        ),
                                        Text(
                                          'Restore',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: context.getScreenWidth(
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
                      SizedBox(width: context.getScreenWidth(2)),
                      GestureDetector(
                        onTap: () => _showRestoreWithImageSheet(context, item),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: context.getScreenHeight(0.8),
                            horizontal: context.getScreenWidth(3),
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
                            size: context.getScreenWidth(5),
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

  // ── Create Bottom Sheet ───────────────────────────────────────────────────
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
            }) async {
              if (imageFile == null) {
                _showSnack(context, 'Please select an image', isError: true);
                return;
              }
              final ok = await controller.createCarousel(
                title: title,
                description: description,
                linkUrl: linkUrl,
                imageFile: imageFile,
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

  // ── Edit Bottom Sheet ─────────────────────────────────────────────────────
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
            }) async {
              final ok = await controller.editCarousel(
                id: item.id,
                title: title,
                description: description,
                linkUrl: linkUrl,
                imageFile: imageFile,
                isActive: isActive,
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

  // ── Restore + Re-upload Image Sheet ──────────────────────────────────────
  void _showRestoreWithImageSheet(BuildContext context, CarouselModel item) {
    File? newImage;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => Container(
          padding: EdgeInsets.fromLTRB(
            context.getScreenWidth(5),
            context.getScreenHeight(2),
            context.getScreenWidth(5),
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
                  width: context.getScreenWidth(10),
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
                  fontSize: context.getScreenWidth(5),
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: context.getScreenHeight(0.5)),
              Text(
                'Optionally replace the image before restoring',
                style: TextStyle(
                  fontSize: context.getScreenWidth(3.2),
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
                              size: context.getScreenWidth(10),
                              color: context.colorPalette.subTitleColor,
                            ),
                            SizedBox(height: context.getScreenHeight(0.8)),
                            Text(
                              'Tap to select image (optional)',
                              style: TextStyle(
                                color: context.colorPalette.subTitleColor,
                                fontSize: context.getScreenWidth(3.2),
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
                        controller.restoreState == CurrentAppState.LOADING
                        ? null
                        : () async {
                            bool ok = false;
                            if (newImage != null) {
                              ok = await controller.editCarousel(
                                id: item.id,
                                imageFile: newImage,
                              );
                            }
                            ok = await controller.restoreCarousel(item.id);
                            if (ok && context.mounted) {
                              Get.back();
                              _showSnack(
                                context,
                                'Carousel restored',
                                isError: false,
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
                              fontSize: context.getScreenWidth(4),
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

  // ── Confirm Delete Dialog ─────────────────────────────────────────────────
  void _confirmDelete(BuildContext context, CarouselModel item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.colorPalette.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Carousel?',
          style: TextStyle(
            fontSize: context.getScreenWidth(4.5),
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        content: Text(
          'This will soft-delete the carousel. You can restore it later from the Deleted tab.',
          style: TextStyle(
            fontSize: context.getScreenWidth(3.5),
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
              onPressed: controller.deleteState == CurrentAppState.LOADING
                  ? null
                  : () async {
                      final ok = await controller.deleteCarousel(item.id);
                      if (ok && context.mounted) {
                        Get.back();
                        _showSnack(context, 'Carousel deleted', isError: false);
                      }
                    },
              child: controller.deleteState == CurrentAppState.LOADING
                  ? SizedBox(
                      width: context.getScreenWidth(4),
                      height: context.getScreenWidth(4),
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

  // ── Helpers ───────────────────────────────────────────────────────────────
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
          horizontal: context.getScreenWidth(2.5),
          vertical: context.getScreenHeight(0.6),
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: isLoading
            ? SizedBox(
                width: context.getScreenWidth(4),
                height: context.getScreenWidth(4),
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: color, size: context.getScreenWidth(3.8)),
                  SizedBox(width: context.getScreenWidth(1.2)),
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: context.getScreenWidth(3),
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
      padding: EdgeInsets.all(context.getScreenWidth(4)),
      itemCount: 3,
      separatorBuilder: (_, __) =>
          SizedBox(height: context.getScreenHeight(1.5)),
      itemBuilder: (_, __) => Container(
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
            size: context.getScreenWidth(14),
            color: context.colorPalette.subTitleColor,
          ),
          SizedBox(height: context.getScreenHeight(1.5)),
          Text(
            'Failed to load',
            style: TextStyle(
              fontSize: context.getScreenWidth(4.5),
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
            size: context.getScreenWidth(14),
            color: context.colorPalette.subTitleColor,
          ),
          SizedBox(height: context.getScreenHeight(1.5)),
          Text(
            msg,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: context.getScreenWidth(4),
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

// ── Reusable Form Sheet ────────────────────────────────────────────────────
class _CarouselFormSheet extends StatefulWidget {
  final CarouselModel? existing;
  final Future<void> Function({
    required String? title,
    required String? description,
    required String? linkUrl,
    required File? imageFile,
    required bool? isActive,
  })
  onSubmit;

  const _CarouselFormSheet({this.existing, required this.onSubmit});

  @override
  State<_CarouselFormSheet> createState() => _CarouselFormSheetState();
}

class _CarouselFormSheetState extends State<_CarouselFormSheet> {
  final CarouselsController controller = Get.find();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _linkController = TextEditingController();
  File? _pickedImage;
  bool _isActive = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _titleController.text = widget.existing!.title;
      _descController.text = widget.existing!.description;
      _linkController.text = widget.existing!.linkUrl ?? '';
      _isActive = widget.existing!.isActive;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) setState(() => _pickedImage = File(picked.path));
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
          context.getScreenWidth(5),
          context.getScreenHeight(2),
          context.getScreenWidth(5),
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
                  width: context.getScreenWidth(10),
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
                  fontSize: context.getScreenWidth(5.5),
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: context.getScreenHeight(2)),

              // ── Image Picker ────────────────────────────────────────────
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: context.getScreenHeight(20),
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
                  child: _pickedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_pickedImage!, fit: BoxFit.cover),
                        )
                      : widget.existing?.imageUrl != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: widget.existing!.imageUrl,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.edit_rounded,
                                      color: Colors.white,
                                      size: context.getScreenWidth(8),
                                    ),
                                    SizedBox(
                                      height: context.getScreenHeight(0.5),
                                    ),
                                    Text(
                                      'Tap to change image',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: context.getScreenWidth(3.2),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_rounded,
                              size: context.getScreenWidth(12),
                              color: context.colorPalette.subTitleColor,
                            ),
                            SizedBox(height: context.getScreenHeight(0.8)),
                            Text(
                              'Tap to select image',
                              style: TextStyle(
                                color: context.colorPalette.subTitleColor,
                                fontSize: context.getScreenWidth(3.5),
                              ),
                            ),
                            if (!isEdit) ...[
                              SizedBox(height: context.getScreenHeight(0.3)),
                              Text(
                                '* Required',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: context.getScreenWidth(3),
                                ),
                              ),
                            ],
                          ],
                        ),
                ),
              ),
              SizedBox(height: context.getScreenHeight(2)),

              // ── Title ───────────────────────────────────────────────────
              _buildField(context, 'Title (optional)', _titleController),
              SizedBox(height: context.getScreenHeight(1.5)),

              // ── Description ─────────────────────────────────────────────
              _buildField(
                context,
                'Description (optional)',
                _descController,
                maxLines: 3,
              ),
              SizedBox(height: context.getScreenHeight(1.5)),

              // ── Link URL ─────────────────────────────────────────────────
              _buildField(
                context,
                'Link URL (optional)',
                _linkController,
                keyboardType: TextInputType.url,
              ),
              SizedBox(height: context.getScreenHeight(1.5)),

              // ── isActive toggle (edit only) ───────────────────────────
              if (isEdit) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Show on homepage',
                      style: TextStyle(
                        fontSize: context.getScreenWidth(4),
                        color: context.colorPalette.textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Switch(
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                      activeColor: context.colorPalette.primaryColor,
                    ),
                  ],
                ),
                SizedBox(height: context.getScreenHeight(1.5)),
              ],

              // ── Submit ───────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () async {
                          setState(() => _isSubmitting = true);
                          await widget.onSubmit(
                            title: _titleController.text.trim().isEmpty
                                ? null
                                : _titleController.text.trim(),
                            description: _descController.text.trim().isEmpty
                                ? null
                                : _descController.text.trim(),
                            linkUrl: _linkController.text.trim().isEmpty
                                ? null
                                : _linkController.text.trim(),
                            imageFile: _pickedImage,
                            isActive: isEdit ? _isActive : null,
                          );
                          if (mounted) setState(() => _isSubmitting = false);
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
                            fontSize: context.getScreenWidth(4.2),
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
        fontSize: context.getScreenWidth(3.8),
        color: context.colorPalette.textColor,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: context.colorPalette.subTitleColor,
          fontSize: context.getScreenWidth(3.5),
        ),
        filled: true,
        fillColor: context.colorPalette.boxColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: context.getScreenWidth(4),
          vertical: context.getScreenHeight(1.4),
        ),
      ),
    );
  }
}
