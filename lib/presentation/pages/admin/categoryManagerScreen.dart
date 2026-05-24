import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/domain/entities/category_model.dart';
import 'package:ratnesh_gold_app/presentation/controllers/admin/AdminCategoryController.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';

class CategoryManagerScreen extends StatefulWidget {
  const CategoryManagerScreen({super.key});

  @override
  State<CategoryManagerScreen> createState() => _CategoryManagerScreenState();
}

class _CategoryManagerScreenState extends State<CategoryManagerScreen> {
  final CategoryManagerController ctrl = Get.put(CategoryManagerController());
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ctrl.loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorPalette.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.colorPalette.backgroundColor,
        elevation: 0,
        title: Text(
          'Category Manager',
          style: TextStyle(
            fontSize: context.getScreenWidth(5),
            fontWeight: FontWeight.w700,
            color: context.colorPalette.textColor,
          ),
        ),
        actions: [
          Obx(
            () => Padding(
              padding: EdgeInsets.only(right: context.getScreenWidth(4)),
              child: Text(
                '${ctrl.total} total',
                style: TextStyle(
                  fontSize: context.getScreenWidth(3.2),
                  color: context.colorPalette.subTitleColor,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(context),
          const Divider(height: 1),
          Expanded(
            child: Obx(() {
              if (ctrl.state == CurrentAppState.LOADING &&
                  ctrl.categories.isEmpty) {
                return _buildShimmerList(context);
              }

              if (ctrl.state == CurrentAppState.ERROR &&
                  ctrl.categories.isEmpty) {
                return _buildError(context);
              }

              if (ctrl.state == CurrentAppState.SUCCESS &&
                  ctrl.categories.isEmpty) {
                return _buildEmpty(context);
              }

              return RefreshIndicator(
                onRefresh: ctrl.refresh,
                color: context.colorPalette.primaryColor,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(
                    horizontal: context.getScreenWidth(4),
                    vertical: context.getScreenHeight(1),
                  ),
                  itemCount: ctrl.categories.length + 1,
                  itemBuilder: (context, index) {
                    if (index == ctrl.categories.length) {
                      return _buildListFooter(context);
                    }
                    return _buildCategoryCard(context, ctrl.categories[index]);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Filter Bar ────────────────────────────────────────────────────────────
  Widget _buildFilters(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.getScreenWidth(4),
        vertical: context.getScreenHeight(1),
      ),
      color: context.colorPalette.backgroundColor,
      child: Column(
        children: [
          // Search
          Container(
            height: context.getScreenHeight(5.5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCFC7BC)),
              color: const Color(0xFFF4F1EC),
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(
                fontSize: context.getScreenWidth(3.8),
                color: context.colorPalette.textColor,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: context.getScreenWidth(3),
                  vertical: context.getScreenHeight(1.5),
                ),
                border: InputBorder.none,
                hintText: 'Search by name...',
                hintStyle: TextStyle(
                  color: const Color(0xFFA29A90),
                  fontSize: context.getScreenWidth(3.5),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: context.getScreenWidth(4.5),
                  color: const Color(0xFF8D847A),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          ctrl.setNameSearch('');
                          setState(() {});
                        },
                        child: Icon(
                          Icons.close,
                          size: context.getScreenWidth(4),
                          color: const Color(0xFF8D847A),
                        ),
                      )
                    : null,
              ),
              onChanged: (v) {
                setState(() {});
                ctrl.setNameSearch(v);
              },
            ),
          ),
          SizedBox(height: context.getScreenHeight(1)),
          // Level filter + show deleted toggle
          Row(
            children: [
              Expanded(child: _buildLevelDropdown(context)),
              SizedBox(width: context.getScreenWidth(3)),
              Obx(() => _buildDeletedToggle(context)),
              SizedBox(width: context.getScreenWidth(2)),
              _buildClearButton(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLevelDropdown(BuildContext context) {
    return Obx(
      () => Container(
        height: context.getScreenHeight(5),
        padding: EdgeInsets.symmetric(horizontal: context.getScreenWidth(3)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFCFC7BC)),
          color: const Color(0xFFF4F1EC),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int?>(
            value: ctrl.selectedLevel,
            isExpanded: true,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: context.getScreenWidth(4.5),
              color: const Color(0xFF8D847A),
            ),
            style: TextStyle(
              fontSize: context.getScreenWidth(3.5),
              color: context.colorPalette.textColor,
            ),
            hint: Text(
              'All Levels',
              style: TextStyle(
                fontSize: context.getScreenWidth(3.5),
                color: const Color(0xFFA29A90),
              ),
            ),
            items: [
              DropdownMenuItem<int?>(
                value: null,
                child: Text(
                  'All Levels',
                  style: TextStyle(fontSize: context.getScreenWidth(3.5)),
                ),
              ),
              ...List.generate(
                3,
                (i) => DropdownMenuItem<int?>(
                  value: i + 1,
                  child: Text(
                    'Level ${i + 1}',
                    style: TextStyle(fontSize: context.getScreenWidth(3.5)),
                  ),
                ),
              ),
            ],
            onChanged: ctrl.setLevelFilter,
          ),
        ),
      ),
    );
  }

  Widget _buildDeletedToggle(BuildContext context) {
    final active = ctrl.showDeleted;
    return GestureDetector(
      onTap: () => ctrl.setShowDeleted(!active),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.getScreenWidth(3),
          vertical: context.getScreenHeight(1.2),
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: active
              ? Colors.red.withOpacity(0.12)
              : const Color(0xFFF4F1EC),
          border: Border.all(
            color: active
                ? Colors.red.withOpacity(0.4)
                : const Color(0xFFCFC7BC),
          ),
        ),
        child: Row(
          children: [
            Icon(
              active ? Icons.visibility : Icons.visibility_off_outlined,
              size: context.getScreenWidth(4),
              color: active ? Colors.red : const Color(0xFF8D847A),
            ),
            SizedBox(width: context.getScreenWidth(1.5)),
            Text(
              'Deleted',
              style: TextStyle(
                fontSize: context.getScreenWidth(3.2),
                color: active ? Colors.red : const Color(0xFF8D847A),
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClearButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _searchController.clear();
        setState(() {});
        ctrl.clearFilters();
      },
      child: Container(
        padding: EdgeInsets.all(context.getScreenWidth(2.5)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFCFC7BC)),
          color: const Color(0xFFF4F1EC),
        ),
        child: Icon(
          Icons.refresh_rounded,
          size: context.getScreenWidth(4.5),
          color: const Color(0xFF8D847A),
        ),
      ),
    );
  }

  // ── Category Card ─────────────────────────────────────────────────────────
  Widget _buildCategoryCard(BuildContext context, CategoryModel cat) {
    return Obx(() {
      final isDeleted = cat.isDeleted;
      final isLoading = ctrl.actionLoadingId == cat.id;

      return Opacity(
        opacity: isDeleted ? 0.45 : 1.0,
        child: Container(
          margin: EdgeInsets.only(bottom: context.getScreenHeight(1.2)),
          decoration: BoxDecoration(
            color: isDeleted
                ? Colors.red.withOpacity(0.04)
                : context.colorPalette.boxColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDeleted
                  ? Colors.red.withOpacity(0.2)
                  : context.colorPalette.boxColor,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(context.getScreenWidth(3.5)),
            child: Row(
              children: [
                // ── Image ─────────────────────────────────────────────────
                _buildCategoryImage(context, cat),
                SizedBox(width: context.getScreenWidth(3)),

                // ── Info ──────────────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildLevelBadge(context, cat.level),
                          SizedBox(width: context.getScreenWidth(2)),
                          if (isDeleted)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: context.getScreenWidth(2),
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'DELETED',
                                style: TextStyle(
                                  fontSize: context.getScreenWidth(2.5),
                                  color: Colors.red,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: context.getScreenHeight(0.5)),
                      Text(
                        cat.name,
                        style: TextStyle(
                          fontSize: context.getScreenWidth(4),
                          fontWeight: FontWeight.w600,
                          color: context.colorPalette.textColor,
                          decoration: isDeleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      SizedBox(height: context.getScreenHeight(0.3)),
                      Text(
                        cat.nameSlug,
                        style: TextStyle(
                          fontSize: context.getScreenWidth(3),
                          color: context.colorPalette.subTitleColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Actions ───────────────────────────────────────────────
                if (isLoading)
                  SizedBox(
                    width: context.getScreenWidth(5),
                    height: context.getScreenWidth(5),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.colorPalette.primaryColor,
                    ),
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isDeleted) ...[
                        _iconButton(
                          context,
                          icon: Icons.edit_outlined,
                          color: context.colorPalette.primaryColor,
                          onTap: () => _showEditSheet(context, cat),
                        ),
                        SizedBox(width: context.getScreenWidth(1)),
                        _iconButton(
                          context,
                          icon: Icons.delete_outline_rounded,
                          color: Colors.red,
                          onTap: () => _confirmDelete(context, cat),
                        ),
                      ] else
                        _iconButton(
                          context,
                          icon: Icons.restore_rounded,
                          color: Colors.green,
                          onTap: () => ctrl.restoreCategory(cat.id),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildCategoryImage(BuildContext context, CategoryModel cat) {
    final size = context.getScreenWidth(14);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: context.colorPalette.boxColor,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: cat.imageUrl != null && cat.imageUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: cat.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    Container(color: context.colorPalette.shimmerBaseColor),
                errorWidget: (_, __, ___) => _imagePlaceholder(context),
              )
            : _imagePlaceholder(context),
      ),
    );
  }

  Widget _imagePlaceholder(BuildContext context) {
    return Container(
      color: context.colorPalette.boxColor,
      child: Icon(
        Icons.image_outlined,
        size: context.getScreenWidth(6),
        color: context.colorPalette.subTitleColor,
      ),
    );
  }

  Widget _buildLevelBadge(BuildContext context, int? level) {
    final colors = {
      1: const Color(0xFFD4AF37),
      2: const Color(0xFF8B6914),
      3: const Color(0xFF5C4A1E),
    };
    final color = colors[level] ?? context.colorPalette.subTitleColor;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.getScreenWidth(2),
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        'L${level ?? "?"}',
        style: TextStyle(
          fontSize: context.getScreenWidth(2.8),
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _iconButton(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(context.getScreenWidth(2)),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: context.getScreenWidth(4.5), color: color),
      ),
    );
  }

  // ── Edit Bottom Sheet ─────────────────────────────────────────────────────
  void _showEditSheet(BuildContext context, CategoryModel cat) {
    final nameController = TextEditingController(text: cat.name);
    ctrl.clearPickedImage();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: context.colorPalette.backgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(context.getScreenWidth(5)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // handle
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
                    'Edit Category',
                    style: TextStyle(
                      fontSize: context.getScreenWidth(5),
                      fontWeight: FontWeight.w700,
                      color: context.colorPalette.textColor,
                    ),
                  ),
                  SizedBox(height: context.getScreenHeight(0.5)),
                  Text(
                    cat.nameSlug,
                    style: TextStyle(
                      fontSize: context.getScreenWidth(3.2),
                      color: context.colorPalette.subTitleColor,
                    ),
                  ),
                  SizedBox(height: context.getScreenHeight(2.5)),

                  // Name field
                  Text(
                    'Name',
                    style: TextStyle(
                      fontSize: context.getScreenWidth(3.5),
                      fontWeight: FontWeight.w600,
                      color: context.colorPalette.textColor,
                    ),
                  ),
                  SizedBox(height: context.getScreenHeight(0.8)),
                  TextField(
                    controller: nameController,
                    style: TextStyle(
                      fontSize: context.getScreenWidth(4),
                      color: context.colorPalette.textColor,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: context.getScreenWidth(4),
                        vertical: context.getScreenHeight(1.5),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: context.colorPalette.boxColor,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: context.colorPalette.boxColor,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: context.colorPalette.primaryColor,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: context.getScreenHeight(2)),

                  // Image picker
                  Text(
                    'Image',
                    style: TextStyle(
                      fontSize: context.getScreenWidth(3.5),
                      fontWeight: FontWeight.w600,
                      color: context.colorPalette.textColor,
                    ),
                  ),
                  SizedBox(height: context.getScreenHeight(1)),
                  Obx(() {
                    final picked = ctrl.pickedImage;
                    return GestureDetector(
                      onTap: () async {
                        await ctrl.pickImage();
                        setSheetState(() {});
                      },
                      child: Container(
                        height: context.getScreenHeight(15),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: picked != null
                                ? context.colorPalette.primaryColor
                                : context.colorPalette.boxColor,
                            width: picked != null ? 2 : 1,
                          ),
                          color: context.colorPalette.boxColor.withOpacity(0.4),
                        ),
                        child: picked != null
                            ? Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      picked,
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () {
                                        ctrl.clearPickedImage();
                                        setSheetState(() {});
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.close,
                                          size: context.getScreenWidth(4),
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // show existing image preview if any
                                  if (cat.imageUrl != null &&
                                      cat.imageUrl!.isNotEmpty)
                                    _existingImagePreview(context, cat)
                                  else ...[
                                    Icon(
                                      Icons.add_photo_alternate_outlined,
                                      size: context.getScreenWidth(8),
                                      color: context.colorPalette.subTitleColor,
                                    ),
                                    SizedBox(
                                      height: context.getScreenHeight(0.5),
                                    ),
                                    Text(
                                      'Tap to pick image',
                                      style: TextStyle(
                                        fontSize: context.getScreenWidth(3.5),
                                        color:
                                            context.colorPalette.subTitleColor,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                      ),
                    );
                  }),
                  SizedBox(height: context.getScreenHeight(3)),

                  // Save button
                  Obx(() {
                    final loading = ctrl.actionLoadingId == cat.id;
                    return SizedBox(
                      width: double.infinity,
                      height: context.getScreenHeight(6.5),
                      child: ElevatedButton(
                        onPressed: loading
                            ? null
                            : () async {
                                final success = await ctrl.editCategory(
                                  id: cat.id,
                                  name: nameController.text.trim(),
                                  existingImages: cat.imageUrl != null
                                      ? [
                                          {
                                            "url": cat.imageUrl!,
                                            "publicId": cat.imagePublicId ?? '',
                                          },
                                        ]
                                      : [],
                                );
                                if (success && context.mounted) {
                                  Get.back();
                                  Get.snackbar(
                                    'Updated',
                                    '${cat.name} updated successfully',
                                    backgroundColor: Colors.green.withOpacity(
                                      0.9,
                                    ),
                                    colorText: Colors.white,
                                    duration: const Duration(seconds: 2),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.colorPalette.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: context.getScreenWidth(4),
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    );
                  }),
                  SizedBox(height: context.getScreenHeight(1)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _existingImagePreview(BuildContext context, CategoryModel cat) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CachedNetworkImage(
            imageUrl: cat.imageUrl!,
            height: context.getScreenHeight(10),
            fit: BoxFit.cover,
          ),
        ),
        Container(
          height: context.getScreenHeight(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.black.withOpacity(0.35),
          ),
        ),
        Column(
          children: [
            Icon(
              Icons.edit,
              color: Colors.white,
              size: context.getScreenWidth(5),
            ),
            SizedBox(height: context.getScreenHeight(0.3)),
            Text(
              'Tap to change',
              style: TextStyle(
                color: Colors.white,
                fontSize: context.getScreenWidth(3),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Delete confirm ────────────────────────────────────────────────────────
  void _confirmDelete(BuildContext context, CategoryModel cat) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.colorPalette.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Category?',
          style: TextStyle(
            fontSize: context.getScreenWidth(4.5),
            fontWeight: FontWeight.w700,
            color: context.colorPalette.textColor,
          ),
        ),
        content: Text(
          '"${cat.name}" will be soft-deleted. You can restore it later.',
          style: TextStyle(
            fontSize: context.getScreenWidth(3.8),
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
          ElevatedButton(
            onPressed: () async {
              Get.back();
              final success = await ctrl.deleteCategory(cat.id);
              if (success) {
                Get.snackbar(
                  'Deleted',
                  '"${cat.name}" has been soft-deleted',
                  backgroundColor: Colors.red.withOpacity(0.9),
                  colorText: Colors.white,
                  duration: const Duration(seconds: 2),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Shimmer List ──────────────────────────────────────────────────────────
  Widget _buildShimmerList(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(context.getScreenWidth(4)),
      itemCount: 8,
      itemBuilder: (_, __) => Container(
        margin: EdgeInsets.only(bottom: context.getScreenHeight(1.2)),
        height: context.getScreenHeight(10),
        decoration: BoxDecoration(
          color: context.colorPalette.shimmerBaseColor,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _buildListFooter(BuildContext context) {
    if (ctrl.state == CurrentAppState.LOADING) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: context.getScreenHeight(2)),
        child: Center(
          child: SizedBox(
            width: context.getScreenWidth(6),
            height: context.getScreenWidth(6),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: context.colorPalette.primaryColor,
            ),
          ),
        ),
      );
    }

    if (!ctrl.hasMore) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: context.getScreenHeight(2)),
        child: Center(
          child: Text(
            'All ${ctrl.total} categories loaded',
            style: TextStyle(
              fontSize: context.getScreenWidth(3.2),
              color: context.colorPalette.subTitleColor,
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: context.getScreenWidth(12),
            color: Colors.red,
          ),
          SizedBox(height: context.getScreenHeight(1.5)),
          Text(
            'Failed to load categories',
            style: TextStyle(
              fontSize: context.getScreenWidth(4),
              color: context.colorPalette.textColor,
            ),
          ),
          SizedBox(height: context.getScreenHeight(2)),
          ElevatedButton(
            onPressed: ctrl.refresh,
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

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: context.getScreenWidth(12),
            color: context.colorPalette.subTitleColor,
          ),
          SizedBox(height: context.getScreenHeight(1.5)),
          Text(
            'No categories found',
            style: TextStyle(
              fontSize: context.getScreenWidth(4),
              color: context.colorPalette.subTitleColor,
            ),
          ),
        ],
      ),
    );
  }
}
