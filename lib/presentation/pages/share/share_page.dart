import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/core/services/share_service.dart';
import 'package:ratnesh_gold_app/presentation/controllers/CategoryController.dart';
import 'package:ratnesh_gold_app/presentation/controllers/share_controller.dart';
import 'package:ratnesh_gold_app/presentation/pages/product/product_listing_page.dart';
import 'package:ratnesh_gold_app/presentation/pages/share/widgets/share_products_per_page_sheet.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';

class SharePage extends StatefulWidget {
  const SharePage({super.key});

  @override
  State<SharePage> createState() => _SharePageState();
}

class _SharePageState extends State<SharePage> {
  late final ShareController controller;
  late final CategoryController categoryController;

  @override
  void initState() {
    super.initState();
    controller = Get.put(ShareController());
    categoryController = Get.isRegistered<CategoryController>()
        ? Get.find<CategoryController>()
        : Get.put(CategoryController());

    if (categoryController.k18Categories.isEmpty) {
      categoryController.fetchCategoryTree();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorPalette.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Share Categories',
          style: TextStyle(
            fontSize: context.getFontSize(4.5),
            fontWeight: FontWeight.w700,
            color: context.colorPalette.goldDeep,
          ),
        ),
        centerTitle: true,
        backgroundColor: context.colorPalette.backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: Column(
        children: [
          _buildKaratRow(context),
          _buildBackButton(context),
          Expanded(child: _buildCategoryBody(context)),
        ],
      ),
      bottomNavigationBar: _buildShareBar(context),
    );
  }

  Widget _buildKaratRow(BuildContext context) {
    final karatOptions = [
      {'label': '18K', 'percent': '76%'},
      {'label': '20K', 'percent': '84%'},
      {'label': '22K', 'percent': '92%'},
    ];
    return Container(
      padding: EdgeInsets.fromLTRB(
        context.getScreenWidth(4),
        context.getScreenHeight(0.8),
        context.getScreenWidth(4),
        context.getScreenHeight(0.6),
      ),
      child: Row(
        children: karatOptions.map((option) {
          final karat = option['label']!;
          final percent = option['percent']!;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: karatOptions.last != option ? context.getScreenWidth(2) : 0,
              ),
              child: GestureDetector(
                onTap: () => controller.selectKarat(karat),
                child: Obx(() {
                  final isSelected = controller.selectedKarat == karat;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(
                      horizontal: context.getScreenWidth(2),
                      vertical: context.getScreenHeight(0.8),
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? context.colorPalette.gold
                          : context.colorPalette.cardBg,
                      borderRadius: BorderRadius.circular(context.getScreenWidth(2.5)),
                      border: Border.all(
                        color: isSelected
                            ? context.colorPalette.gold
                            : context.colorPalette.border,
                        width: 2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: context.colorPalette.gold.withValues(alpha: 0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : [],
                    ),
                    child: Text(
                      '$karat ($percent)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: context.getFontSize(3.2),
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? Colors.white
                            : context.colorPalette.goldDeep,
                      ),
                    ),
                  );
                }),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Obx(() {
      if (controller.drillLevel != 3) return const SizedBox.shrink();

      return Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap: () => controller.goBackToLevel2(),
          child: Container(
            margin: EdgeInsets.only(
              left: context.getScreenWidth(4),
              top: context.getScreenHeight(1),
              bottom: context.getScreenHeight(0.6),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: context.getScreenWidth(4),
              vertical: context.getScreenHeight(1),
            ),
            decoration: BoxDecoration(
              color: context.colorPalette.goldDark,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_back_ios_rounded,
                  size: context.getFontSize(4),
                  color: Colors.white,
                ),
                SizedBox(width: context.getScreenWidth(1.5)),
                Text(
                  'Back',
                  style: TextStyle(
                    fontSize: context.getFontSize(3.5),
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildCategoryBody(BuildContext context) {
    return Obx(() {
      final karat = controller.selectedKarat;

      if (karat == null) {
        return _buildPlaceholder(
          context,
          icon: Icons.category_outlined,
          message: 'Select a karat to browse categories',
        );
      }

      if (controller.drillLevel == 2) {
        return _buildLevel2List(context);
      }

      return _buildLevel3List(context);
    });
  }

  Widget _buildLevel2List(BuildContext context) {
    final categories = controller.currentLevel2Categories;

    if (categories.isEmpty) {
      return _buildPlaceholder(
        context,
        icon: Icons.category_outlined,
        message: 'No collections found',
      );
    }

    return RefreshIndicator(
      onRefresh: () => categoryController.fetchCategoryTree(),
      color: context.colorPalette.gold,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(vertical: context.getScreenHeight(0.5)),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];

          return GestureDetector(
            onTap: () => controller.drillIntoLevel2(cat),
            child: Obx(() {
              final selectedCount = controller.selectedLevel3.values
                  .where((s) => s.karatName == controller.selectedKarat && s.level2Name == cat.name)
                  .length;

              return Container(
                margin: EdgeInsets.symmetric(
                  horizontal: context.getScreenWidth(4),
                  vertical: context.getScreenHeight(0.4),
                ),
                padding: EdgeInsets.all(context.getScreenWidth(4)),
                decoration: BoxDecoration(
                  color: context.colorPalette.cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.colorPalette.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _cleanCategoryName(cat.name),
                            style: TextStyle(
                              fontSize: context.getFontSize(3.8),
                              fontWeight: FontWeight.w600,
                              color: context.colorPalette.textColor,
                            ),
                          ),
                          if (selectedCount > 0) ...[
                            SizedBox(height: context.getScreenHeight(0.3)),
                            Text(
                              '$selectedCount style${selectedCount == 1 ? '' : 's'} selected',
                              style: TextStyle(
                                fontSize: context.getFontSize(2.8),
                                color: context.colorPalette.goldDark,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: context.colorPalette.subTitleColor,
                      size: context.getFontSize(5),
                    ),
                  ],
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildLevel3List(BuildContext context) {
    final categories = controller.currentLevel3Categories;

    if (categories.isEmpty) {
      return _buildPlaceholder(
        context,
        icon: Icons.style_outlined,
        message: 'No styles found',
      );
    }

    return Column(
      children: [
        // Level 2 name + Select all button
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.getScreenWidth(4),
            vertical: context.getScreenHeight(0.6),
          ),
          child: Row(
            children: [
              Text(
                _cleanCategoryName(controller.currentLevel2?.name ?? ''),
                style: TextStyle(
                  fontSize: context.getFontSize(3.5),
                  fontWeight: FontWeight.w600,
                  color: context.colorPalette.textColor,
                ),
              ),
              const Spacer(),
              Obx(() {
                final allSelected = controller.areAllCurrentLevel3Selected;
                return GestureDetector(
                  onTap: () {
                    if (allSelected) {
                      controller.deselectAllLevel3();
                    } else {
                      controller.selectAllLevel3();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: allSelected
                          ? context.colorPalette.gold
                          : context.colorPalette.cardBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: allSelected
                            ? context.colorPalette.gold
                            : context.colorPalette.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          allSelected
                              ? Icons.deselect_rounded
                              : Icons.select_all_rounded,
                          size: context.getFontSize(3.5),
                          color: allSelected ? Colors.white : context.colorPalette.goldDark,
                        ),
                        SizedBox(width: context.getScreenWidth(1)),
                        Text(
                          allSelected ? 'Deselect All' : 'Select All',
                          style: TextStyle(
                            fontSize: context.getFontSize(2.8),
                            fontWeight: FontWeight.w600,
                            color: allSelected ? Colors.white : context.colorPalette.goldDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        // Level 3 items
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(vertical: context.getScreenHeight(0.3)),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return Obx(() {
                final isSelected = controller.isLevel3Selected(cat.id);
                return GestureDetector(
                  onTap: () => controller.toggleLevel3Selection(cat),
                  child: Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: context.getScreenWidth(4),
                      vertical: context.getScreenHeight(0.3),
                    ),
                    padding: EdgeInsets.all(context.getScreenWidth(3.5)),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? context.colorPalette.gold.withValues(alpha: 0.08)
                          : context.colorPalette.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? context.colorPalette.gold
                            : context.colorPalette.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: context.getScreenWidth(5.5),
                          height: context.getScreenWidth(5.5),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? context.colorPalette.gold
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(context.getScreenWidth(1.2)),
                            border: Border.all(
                              color: isSelected
                                  ? context.colorPalette.gold
                                  : context.colorPalette.border,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check,
                                  size: context.getFontSize(3),
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        SizedBox(width: context.getScreenWidth(3)),
                        Expanded(
                          child: Text(
                            cat.name,
                            style: TextStyle(
                              fontSize: context.getFontSize(3.5),
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? context.colorPalette.goldDeep
                                  : context.colorPalette.textColor,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductListingPage(
                                categoryId: cat.id,
                                karat: controller.selectedKarat,
                                title: cat.name,
                              ),
                            ),
                          ),
                          child: Container(
                            padding: EdgeInsets.all(context.getScreenWidth(1.5)),
                            decoration: BoxDecoration(
                              color: context.colorPalette.gold.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.visibility_outlined,
                              size: context.getFontSize(4),
                              color: context.colorPalette.goldDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              });
            },
          ),
        ),
      ],
    );
  }

  String _cleanCategoryName(String name) {
    return name
        .replaceAll(RegExp(r'[^a-zA-Z\s]'), '')
        .replaceAll(RegExp(r'collection', caseSensitive: false), '')
        .trim();
  }

  Widget _buildPlaceholder(BuildContext context, {required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: context.getFontSize(12), color: context.colorPalette.subTitleColor),
          SizedBox(height: context.getScreenHeight(1.5)),
          Text(
            message,
            style: TextStyle(
              fontSize: context.getFontSize(3.5),
              color: context.colorPalette.subTitleColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareBar(BuildContext context) {
    return Obx(() {
      if (!controller.hasSelection) return const SizedBox.shrink();

      return Container(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          12 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: context.colorPalette.border)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => controller.clearSelection(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: context.colorPalette.cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.colorPalette.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.close, size: 16, color: context.colorPalette.goldDark),
                    const SizedBox(width: 4),
                    Text(
                      'Clear',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.colorPalette.goldDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${controller.selectedCount} selected',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: context.colorPalette.goldDeep,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => _showShareOptions(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: context.colorPalette.goldDark,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.share_rounded, size: 16, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Share',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  void _showShareOptions(BuildContext context) async {
    _showLoadingDialog(context, 'Checking product count...');

    await controller.fetchProductCount();

    if (!mounted) return;
    Navigator.of(context).pop();

    if (!mounted) return;

    final isImageShareDisabled = controller.productCount > 100;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.of(ctx).padding.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: context.getScreenHeight(2)),
            Text(
              'Share ${controller.selectedCount} categor${controller.selectedCount == 1 ? 'y' : 'ies'}',
              style: TextStyle(
                fontSize: context.getFontSize(4.5),
                fontWeight: FontWeight.w700,
                color: context.colorPalette.textColor,
              ),
            ),
            SizedBox(height: context.getScreenHeight(0.5)),
            Text(
              controller.selectedCategoriesInfo,
              style: TextStyle(
                fontSize: context.getFontSize(2.8),
                color: context.colorPalette.subTitleColor,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: context.getScreenHeight(2)),
            _shareOptionTile(
              context,
              icon: Icons.image_outlined,
              iconColor: const Color(0xFF25D366),
              title: 'Share Images',
              subtitle: isImageShareDisabled
                  ? 'Disabled — max 100 images for WhatsApp'
                  : 'Send product images with category details',
              disabled: isImageShareDisabled,
              onTap: isImageShareDisabled
                  ? null
                  : () {
                      Navigator.pop(ctx);
                      _shareAsImages(context);
                    },
            ),
            SizedBox(height: context.getScreenHeight(1.2)),
            _shareOptionTile(
              context,
              icon: Icons.picture_as_pdf_outlined,
              iconColor: const Color(0xFFE53935),
              title: 'Share as PDF',
              subtitle: 'Create a branded product catalog',
              onTap: () {
                Navigator.pop(ctx);
                _showProductsPerPageDialog(context);
              },
            ),
            SizedBox(height: context.getScreenHeight(1.5)),
          ],
        ),
      ),
    );
  }

  Widget _shareOptionTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    bool disabled = false,
  }) {
    final effectiveIconColor = disabled ? Colors.grey : iconColor;
    final effectiveTextColor = disabled ? Colors.grey : context.colorPalette.textColor;
    final effectiveSubtitleColor = disabled ? Colors.grey.shade400 : context.colorPalette.subTitleColor;
    final effectiveBorderColor = disabled ? Colors.grey.shade300 : context.colorPalette.border;
    final effectiveBgColor = disabled ? Colors.grey.shade100 : context.colorPalette.cardBg;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(context.getScreenWidth(4)),
        decoration: BoxDecoration(
          color: effectiveBgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: effectiveBorderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(context.getScreenWidth(2.5)),
              decoration: BoxDecoration(
                color: effectiveIconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: effectiveIconColor, size: context.getFontSize(6)),
            ),
            SizedBox(width: context.getScreenWidth(3)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: context.getFontSize(3.8),
                      fontWeight: FontWeight.w600,
                      color: effectiveTextColor,
                    ),
                  ),
                  SizedBox(height: context.getScreenHeight(0.3)),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: context.getFontSize(2.8),
                      color: effectiveSubtitleColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              disabled ? Icons.lock_outline_rounded : Icons.chevron_right_rounded,
              color: effectiveSubtitleColor,
              size: context.getFontSize(5),
            ),
          ],
        ),
      ),
    );
  }

  void _showProductsPerPageDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ShareProductsPerPageSheet(
        onSelected: (productsPerPage) {
          Navigator.pop(ctx);
          _shareAsPdf(context, productsPerPage: productsPerPage);
        },
      ),
    );
  }

  void _shareAsImages(BuildContext context) {
    final categoryIds = controller.selectedCategoryIds;
    final filterInfo = controller.selectedCategoriesInfo;

    _showLoadingDialog(context, 'Preparing images...');

    ShareService.shareImagesFromCategories(
      categoryIds: categoryIds,
      filterInfo: filterInfo,
    ).whenComplete(() {
      if (mounted) Navigator.of(context).pop();
    });
  }

  void _shareAsPdf(BuildContext context, {int productsPerPage = 1}) {
    final categoryIds = controller.selectedCategoryIds;
    final filterInfo = controller.selectedCategoriesInfo;

    _showLoadingDialog(context, 'Generating PDF...');

    ShareService.sharePdfFromCategories(
      categoryIds: categoryIds,
      filterInfo: filterInfo,
      productsPerPage: productsPerPage,
    ).whenComplete(() {
      if (mounted) Navigator.of(context).pop();
    });
  }

  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: EdgeInsets.all(context.getScreenWidth(6)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: context.colorPalette.gold,
                  ),
                ),
                SizedBox(height: context.getScreenHeight(1.5)),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: context.getFontSize(3.5),
                    fontWeight: FontWeight.w500,
                    color: context.colorPalette.textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
