import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/domain/entities/category_model.dart';
import 'package:ratnesh_gold_app/domain/entities/sent_notification_model.dart';
import 'package:ratnesh_gold_app/presentation/controllers/admin/NotificationManagerController.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';

class NotificationManagerScreen extends StatefulWidget {
  const NotificationManagerScreen({super.key});

  @override
  State<NotificationManagerScreen> createState() =>
      _NotificationManagerScreenState();
}

class _NotificationManagerScreenState extends State<NotificationManagerScreen> {
  final NotificationManagerController controller =
      Get.isRegistered<NotificationManagerController>()
      ? Get.find<NotificationManagerController>()
      : Get.put(NotificationManagerController());

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _userSearchController = TextEditingController();
  final TextEditingController _productSearchController =
      TextEditingController();
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
    _userSearchController.dispose();
    _productSearchController.dispose();
    _scrollController.dispose();
    if (Get.isRegistered<NotificationManagerController>()) {
      Get.delete<NotificationManagerController>();
    }
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
          _buildImagePicker(context),
          SizedBox(height: context.heightPercent(1.5)),
          _buildLinkSelector(context),
          SizedBox(height: context.heightPercent(1.5)),
          _buildTargetSelector(context),
          SizedBox(height: context.heightPercent(2)),
          Obx(() {
            if (controller.targetType != 'users') {
              return const SizedBox.shrink();
            }
            return _buildUserPicker(context);
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
                        _userSearchController.clear();
                        _productSearchController.clear();
                      }
                    },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  vertical: context.heightPercent(1.8),
                ),
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
                          const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
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

  Widget _buildImagePicker(BuildContext context) {
    return Obx(() {
      final path = controller.imagePath;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Image (optional)',
            style: TextStyle(
              fontSize: context.getResponsiveSize(3.5),
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: context.heightPercent(0.5)),
          if (path == null)
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  vertical: context.heightPercent(2),
                ),
                decoration: BoxDecoration(
                  color: context.colorPalette.boxColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primaryGold.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      color: AppColors.primaryGold,
                      size: context.getResponsiveSize(6),
                    ),
                    SizedBox(height: context.heightPercent(0.5)),
                    Text(
                      'Tap to attach an image',
                      style: TextStyle(
                        fontSize: context.getResponsiveSize(3.2),
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(
                    File(path),
                    width: double.infinity,
                    height: context.heightPercent(18),
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: controller.clearImage,
                    child: Container(
                      padding: EdgeInsets.all(context.getResponsiveSize(1)),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.getResponsiveSize(2.5),
                        vertical: context.heightPercent(0.5),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Change',
                        style: TextStyle(
                          fontSize: context.getResponsiveSize(2.8),
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      );
    });
  }

  Future<void> _pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1600,
      );
      if (picked != null) {
        controller.setImage(picked.path);
      }
    } catch (_) {}
  }

  Widget _buildLinkSelector(BuildContext context) {
    final options = [
      {'value': 'none', 'label': 'None', 'icon': Icons.block_rounded},
      {
        'value': 'product',
        'label': 'Product',
        'icon': Icons.shopping_bag_rounded,
      },
      {
        'value': 'category',
        'label': 'Category',
        'icon': Icons.category_rounded,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Link to (optional)',
          style: TextStyle(
            fontSize: context.getResponsiveSize(3.5),
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        SizedBox(height: context.heightPercent(0.3)),
        Text(
          'Tapping the notification opens the linked product or category.',
          style: TextStyle(
            fontSize: context.getResponsiveSize(2.8),
            color: AppColors.textMuted,
          ),
        ),
        SizedBox(height: context.heightPercent(0.8)),
        Obx(() {
          return Row(
            children: options.map((opt) {
              final isSelected = controller.linkType == opt['value'];
              return Expanded(
                child: GestureDetector(
                  onTap: () => controller.setLinkType(opt['value'] as String),
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
                            : context.colorPalette.subTitleColor.withValues(
                                alpha: 0.15,
                              ),
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
        Obx(() {
          if (controller.linkType == 'product') {
            return Padding(
              padding: EdgeInsets.only(top: context.heightPercent(1)),
              child: _buildProductLinkPicker(context),
            );
          }
          if (controller.linkType == 'category') {
            return Padding(
              padding: EdgeInsets.only(top: context.heightPercent(1)),
              child: _buildCategoryLinkPicker(context),
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  Widget _buildProductLinkPicker(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(() {
          final product = controller.linkProduct;
          if (product == null) return const SizedBox.shrink();
          return Padding(
            padding: EdgeInsets.only(bottom: context.heightPercent(1)),
            child: Chip(
              label: Text(
                product.name,
                style: TextStyle(
                  fontSize: context.getResponsiveSize(3),
                  color: AppColors.textDark,
                ),
              ),
              backgroundColor: AppColors.primaryGold.withValues(alpha: 0.1),
              onDeleted: controller.clearLinkProduct,
              deleteIcon: const Icon(Icons.close_rounded, size: 16),
            ),
          );
        }),
        _buildTextField(
          context,
          controller: _productSearchController,
          label: 'Product',
          hint: 'Search by product name or tag number',
          maxLines: 1,
          onChanged: controller.onProductSearchChanged,
        ),
        Obx(() {
          if (controller.linkProduct != null) return const SizedBox.shrink();

          final state = controller.productSearchState;
          final results = controller.productResults;

          if (state == CurrentAppState.LOADING && results.isEmpty) {
            return Padding(
              padding: EdgeInsets.symmetric(
                vertical: context.heightPercent(1.5),
              ),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }

          if (results.isEmpty) return const SizedBox.shrink();

          return Container(
            margin: EdgeInsets.only(top: context.heightPercent(0.8)),
            constraints: BoxConstraints(maxHeight: context.heightPercent(28)),
            decoration: BoxDecoration(
              color: context.colorPalette.boxColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: context.colorPalette.subTitleColor.withValues(
                  alpha: 0.15,
                ),
              ),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: results.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                color: context.colorPalette.subTitleColor.withValues(
                  alpha: 0.1,
                ),
              ),
              itemBuilder: (context, index) {
                final product = results[index];
                final isSelected = controller.isLinkProductSelected(product.id);
                return ListTile(
                  dense: true,
                  leading: Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    color: isSelected
                        ? AppColors.primaryGold
                        : AppColors.textMuted,
                    size: context.getResponsiveSize(4.5),
                  ),
                  title: Text(
                    product.name,
                    style: TextStyle(
                      fontSize: context.getResponsiveSize(3.4),
                      color: AppColors.textDark,
                    ),
                  ),
                  subtitle: (product.tagNo != null && product.tagNo!.isNotEmpty)
                      ? Text(
                          'Tag ${product.tagNo}',
                          style: TextStyle(
                            fontSize: context.getResponsiveSize(2.8),
                            color: AppColors.textMuted,
                          ),
                        )
                      : null,
                  onTap: () => controller.selectLinkProduct(product),
                );
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCategoryLinkPicker(BuildContext context) {
    return Obx(() {
      final category = controller.linkCategory;
      return GestureDetector(
        onTap: () => _openCategoryPicker(context),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: context.getResponsiveSize(4),
            vertical: context.heightPercent(1.4),
          ),
          decoration: BoxDecoration(
            color: context.colorPalette.boxColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: context.colorPalette.subTitleColor.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  category?.name ?? 'Select a level-3 category',
                  style: TextStyle(
                    fontSize: context.getResponsiveSize(3.5),
                    color: category == null
                        ? context.colorPalette.subTitleColor.withValues(
                            alpha: 0.6,
                          )
                        : AppColors.textDark,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      );
    });
  }

  Future<void> _openCategoryPicker(BuildContext context) async {
    final selected = await showModalBottomSheet<CategoryModel>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SizedBox(
          height: MediaQuery.of(sheetContext).size.height * 0.6,
          child: FutureBuilder<List<CategoryModel>>(
            future: controller.loadLevel3Categories(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final categories = snapshot.data ?? const <CategoryModel>[];
              if (categories.isEmpty) {
                return Center(
                  child: Text(
                    'No categories available',
                    style: TextStyle(
                      fontSize: context.getResponsiveSize(3.6),
                      color: AppColors.textMuted,
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(context.getResponsiveSize(4)),
                    child: Text(
                      'Select a category',
                      style: TextStyle(
                        fontSize: context.getResponsiveSize(4.2),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  Divider(height: 1, color: AppColors.divider),
                  Expanded(
                    child: ListView.separated(
                      itemCount: categories.length,
                      separatorBuilder: (_, _) =>
                          Divider(height: 1, color: AppColors.divider),
                      itemBuilder: (itemContext, index) {
                        final category = categories[index];
                        return ListTile(
                          title: Text(
                            category.name,
                            style: TextStyle(
                              fontSize: itemContext.getResponsiveSize(3.6),
                              color: AppColors.textDark,
                            ),
                          ),
                          onTap: () => Navigator.of(sheetContext).pop(category),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (selected != null) {
      controller.selectLinkCategory(selected);
    }
  }

  Widget _buildTargetSelector(BuildContext context) {
    final options = [
      {'value': 'all', 'label': 'All Users', 'icon': Icons.people_rounded},
      {
        'value': 'users',
        'label': 'Specific Users',
        'icon': Icons.person_add_alt_1_rounded,
      },
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
                  onTap: () => controller.setTargetType(opt['value'] as String),
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
                            : context.colorPalette.subTitleColor.withValues(
                                alpha: 0.15,
                              ),
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

  Widget _buildUserPicker(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          context,
          controller: _userSearchController,
          label: 'Users',
          hint: 'Search by name or phone number',
          maxLines: 1,
          onChanged: controller.onSearchChanged,
        ),
        SizedBox(height: context.heightPercent(1)),
        Obx(() {
          final selected = controller.selectedUsers;
          if (selected.isEmpty) return const SizedBox.shrink();
          return Wrap(
            spacing: context.getResponsiveSize(1.5),
            runSpacing: context.getResponsiveSize(1),
            children: selected.map((user) {
              final label = user.name.isNotEmpty
                  ? user.name
                  : (user.phoneNumber.isNotEmpty
                        ? user.phoneNumber
                        : user.email);
              return Chip(
                label: Text(
                  label,
                  style: TextStyle(
                    fontSize: context.getResponsiveSize(3),
                    color: AppColors.textDark,
                  ),
                ),
                backgroundColor: AppColors.primaryGold.withValues(alpha: 0.1),
                side: BorderSide(
                  color: AppColors.primaryGold.withValues(alpha: 0.4),
                ),
                onDeleted: () => controller.removeUser(user.id),
                deleteIconColor: AppColors.primaryGold,
              );
            }).toList(),
          );
        }),
        SizedBox(height: context.heightPercent(1)),
        Obx(() {
          final searchState = controller.searchState;

          if (searchState == CurrentAppState.LOADING) {
            return Padding(
              padding: EdgeInsets.symmetric(
                vertical: context.heightPercent(1.5),
              ),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryGold,
                  ),
                ),
              ),
            );
          }

          if (searchState == CurrentAppState.ERROR) {
            return Text(
              controller.searchError.isNotEmpty
                  ? controller.searchError
                  : 'Could not search users',
              style: TextStyle(
                fontSize: context.getResponsiveSize(3.2),
                color: Colors.redAccent,
              ),
            );
          }

          if (searchState != CurrentAppState.SUCCESS) {
            return const SizedBox.shrink();
          }

          final results = controller.searchResults;
          // Read the selection inside the Obx builder: itemBuilder runs lazily
          // during layout, outside GetX's dependency-tracking window, so
          // isUserSelected() called there would never rebuild the list.
          final selectedIds = controller.selectedUserIds.toSet();
          if (results.isEmpty) {
            return Text(
              'No users found',
              style: TextStyle(
                fontSize: context.getResponsiveSize(3.2),
                color: context.colorPalette.subTitleColor,
              ),
            );
          }

          return Container(
            constraints: BoxConstraints(maxHeight: context.heightPercent(28)),
            decoration: BoxDecoration(
              color: context.colorPalette.boxColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primaryGold.withValues(alpha: 0.25),
              ),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.symmetric(
                vertical: context.heightPercent(0.8),
              ),
              itemCount: results.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                color: context.colorPalette.subTitleColor.withValues(
                  alpha: 0.12,
                ),
              ),
              itemBuilder: (context, index) {
                final user = results[index];
                final isSelected = selectedIds.contains(user.id);
                final label = user.name.isNotEmpty
                    ? user.name
                    : (user.phoneNumber.isNotEmpty
                          ? user.phoneNumber
                          : user.email);
                final subtitle = [
                  if (user.phoneNumber.isNotEmpty) user.phoneNumber,
                  if (user.email.isNotEmpty) user.email,
                ].join(' · ');

                return InkWell(
                  onTap: () => controller.toggleUser(user),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.getResponsiveSize(3),
                      vertical: context.heightPercent(1),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: context.getResponsiveSize(5),
                          color: isSelected
                              ? AppColors.primaryGold
                              : AppColors.textMuted,
                        ),
                        SizedBox(width: context.getResponsiveSize(2.5)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: context.getResponsiveSize(3.5),
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                ),
                              ),
                              if (subtitle.isNotEmpty)
                                Text(
                                  subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: context.getResponsiveSize(3),
                                    color: context.colorPalette.subTitleColor,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }),
        SizedBox(height: context.heightPercent(2)),
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
              borderSide: BorderSide(color: AppColors.primaryGold, width: 1.5),
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
                  color: context.colorPalette.subTitleColor.withValues(
                    alpha: 0.4,
                  ),
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
    return GestureDetector(
      onTap: () => _showHistoryDetail(context, notification),
      child: Container(
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
                    color: _targetBadgeColor(
                      notification.targetType,
                    ).withValues(alpha: 0.1),
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
            if (notification.sentBy != null &&
                notification.sentBy!.trim().isNotEmpty)
              Padding(
                padding: EdgeInsets.only(bottom: context.heightPercent(0.6)),
                child: Text(
                  'Sent by ${notification.sentBy}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.getResponsiveSize(2.6),
                    color: AppColors.textMuted,
                  ),
                ),
              ),
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
                const Spacer(),
                Icon(
                  Icons.chevron_right_rounded,
                  size: context.getResponsiveSize(4),
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showHistoryDetail(BuildContext context, SentNotification notification) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(
                  context.getResponsiveSize(5),
                  context.heightPercent(1.5),
                  context.getResponsiveSize(5),
                  context.heightPercent(3),
                ),
                children: [
                  Center(
                    child: Container(
                      width: context.getResponsiveSize(10),
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  SizedBox(height: context.heightPercent(2)),
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontSize: context.getResponsiveSize(5),
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: context.heightPercent(0.8)),
                  Text(
                    notification.body,
                    style: TextStyle(
                      fontSize: context.getResponsiveSize(3.5),
                      color: AppColors.textMuted,
                    ),
                  ),
                  if (notification.imageUrl != null &&
                      notification.imageUrl!.isNotEmpty) ...[
                    SizedBox(height: context.heightPercent(1.5)),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                        context.getResponsiveSize(3),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: notification.imageUrl!,
                        width: double.infinity,
                        height: context.heightPercent(24),
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                  ],
                  SizedBox(height: context.heightPercent(2)),
                  _detailRow(
                    context,
                    'Audience',
                    '${_targetLabel(notification.targetType)}${notification.targetValue != null ? ' (${notification.targetValue})' : ''}',
                  ),
                  _detailRow(
                    context,
                    'Recipients',
                    '${notification.recipientCount ?? '—'}',
                  ),
                  _detailRow(context, 'Sent by', notification.sentBy ?? '—'),
                  _detailRow(
                    context,
                    'Sent at',
                    DateFormat(
                      'dd MMM yyyy, hh:mm a',
                    ).format(notification.sentAt),
                  ),
                  _detailRow(
                    context,
                    'Push mode',
                    notification.pushMode ?? '—',
                  ),
                  _detailRow(
                    context,
                    'Delivered',
                    '${notification.pushSuccessCount ?? '—'}',
                  ),
                  _detailRow(
                    context,
                    'Failed',
                    '${notification.pushFailureCount ?? '—'}',
                  ),
                  if ((notification.noTokenCount ?? 0) > 0)
                    Padding(
                      padding: EdgeInsets.only(top: context.heightPercent(1)),
                      child: Text(
                        '${notification.noTokenCount} recipient(s) had no registered device — saved in-app only.',
                        style: TextStyle(
                          fontSize: context.getResponsiveSize(2.8),
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  if (notification.pushError != null &&
                      notification.pushError!.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: context.heightPercent(1.5)),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(context.getResponsiveSize(3)),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.danger.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          notification.pushError!,
                          style: TextStyle(
                            fontSize: context.getResponsiveSize(3),
                            color: AppColors.danger,
                          ),
                        ),
                      ),
                    ),
                  if (notification.failures.isNotEmpty) ...[
                    SizedBox(height: context.heightPercent(2)),
                    Text(
                      'Failed deliveries (${notification.failures.length})',
                      style: TextStyle(
                        fontSize: context.getResponsiveSize(3.8),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: context.heightPercent(1)),
                    ...notification.failures.map(
                      (failure) => Padding(
                        padding: EdgeInsets.only(
                          bottom: context.heightPercent(0.8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: context.getResponsiveSize(3.5),
                              color: AppColors.danger,
                            ),
                            SizedBox(width: context.getResponsiveSize(2)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    failure.label,
                                    style: TextStyle(
                                      fontSize: context.getResponsiveSize(3.2),
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  Text(
                                    '${failure.code ?? 'error'}${failure.message != null ? ' — ${failure.message}' : ''}',
                                    style: TextStyle(
                                      fontSize: context.getResponsiveSize(2.8),
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (notification.recipients.isNotEmpty) ...[
                    SizedBox(height: context.heightPercent(2)),
                    Text(
                      'Sent to (${notification.recipients.length})',
                      style: TextStyle(
                        fontSize: context.getResponsiveSize(3.8),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: context.heightPercent(1)),
                    Wrap(
                      spacing: context.getResponsiveSize(1.5),
                      runSpacing: context.getResponsiveSize(1),
                      children: notification.recipients
                          .map(
                            (recipient) => Chip(
                              label: Text(
                                recipient.label,
                                style: TextStyle(
                                  fontSize: context.getResponsiveSize(2.8),
                                  color: AppColors.textDark,
                                ),
                              ),
                              backgroundColor: AppColors.primaryGold.withValues(
                                alpha: 0.1,
                              ),
                              side: BorderSide(
                                color: AppColors.primaryGold.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.heightPercent(0.8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: context.getResponsiveSize(28),
            child: Text(
              label,
              style: TextStyle(
                fontSize: context.getResponsiveSize(3.2),
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: context.getResponsiveSize(3.2),
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _targetBadgeColor(String targetType) {
    switch (targetType) {
      case 'users':
      case 'user':
        return const Color(0xFF8B5CF6);
      case 'topic':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF2E7D32);
    }
  }

  String _targetLabel(String targetType) {
    switch (targetType) {
      case 'users':
        return 'Users';
      case 'user':
        return 'User';
      case 'topic':
        return 'Topic';
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
