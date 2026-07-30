import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/core/constants/karat_constants.dart';
import 'package:ratnesh_gold_app/core/widgets/nav_bar_spacer.dart';
import 'package:ratnesh_gold_app/presentation/controllers/CategoryController.dart';
import 'package:ratnesh_gold_app/presentation/controllers/share_controller.dart';
import 'package:ratnesh_gold_app/presentation/pages/product/product_listing_page.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:ratnesh_gold_app/core/utils/string_utils.dart';

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
    controller = Get.isRegistered<ShareController>()
        ? Get.find<ShareController>()
        : Get.put(ShareController());
    categoryController = Get.isRegistered<CategoryController>()
        ? Get.find<CategoryController>()
        : Get.put(CategoryController());

    if (!categoryController.hasTreeData) {
      categoryController.fetchCategoryTree();
    }
  }

  @override
  void dispose() {
    Get.delete<ShareController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorPalette.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Share',
          style: TextStyle(
            fontSize: context.getResponsiveSize(4.5),
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
    final karatOptions = KaratConstants.commonOptions;
    return Container(
      padding: EdgeInsets.fromLTRB(
        context.getResponsiveSize(4),
        context.heightPercent(0.8),
        context.getResponsiveSize(4),
        context.heightPercent(0.6),
      ),
      child: Row(
        children: [
          for (int i = 0; i < karatOptions.length; i++) ...[
            Expanded(
              child: _buildKaratChip(context, karatOptions[i]['label']!, karatOptions[i]['percent']!),
            ),
            if (i < karatOptions.length - 1)
              SizedBox(width: context.getResponsiveSize(2)),
          ],
        ],
      ),
    );
  }

  Widget _buildKaratChip(BuildContext context, String karat, String percent) {
    return GestureDetector(
      onTap: () => controller.selectKarat(karat),
      child: Obx(() {
        final isSelected = controller.selectedKarat == karat;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: context.getResponsiveSize(2),
            vertical: context.heightPercent(0.8),
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? context.colorPalette.gold
                : context.colorPalette.cardBg,
            borderRadius: BorderRadius.circular(context.getResponsiveSize(2.5)),
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
              fontSize: context.getResponsiveSize(3.2),
              fontWeight: FontWeight.w700,
              color: isSelected
                  ? Colors.white
                  : context.colorPalette.goldDeep,
            ),
          ),
        );
      }),
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
              left: context.getResponsiveSize(4),
              top: context.heightPercent(1),
              bottom: context.heightPercent(0.6),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: context.getResponsiveSize(4),
              vertical: context.heightPercent(1),
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
                  size: context.getResponsiveSize(4),
                  color: Colors.white,
                ),
                SizedBox(width: context.getResponsiveSize(1.5)),
                Text(
                  'Back',
                  style: TextStyle(
                    fontSize: context.getResponsiveSize(3.5),
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
        padding: EdgeInsets.fromLTRB(0, context.heightPercent(0.5), 0, NavBarSpacer.heightOf(context)),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];

          return Obx(() {
            final selectedCount = controller.selectedLevel3.values
                .where((s) => s.karatName == controller.selectedKarat && s.level2Name == cat.name)
                .length;

            return GestureDetector(
              onTap: () => controller.drillIntoLevel2(cat),
              child: Container(
                margin: EdgeInsets.symmetric(
                  horizontal: context.getResponsiveSize(4),
                  vertical: context.heightPercent(0.4),
                ),
                padding: EdgeInsets.all(context.getResponsiveSize(4)),
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
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: cleanCategoryName(cat.name),
                                  style: TextStyle(
                                    fontSize: context.getResponsiveSize(3.8),
                                    fontWeight: FontWeight.w600,
                                    color: context.colorPalette.textColor,
                                  ),
                                ),
                                TextSpan(
                                  text: ' (${cat.count})',
                                  style: TextStyle(
                                    fontSize: context.getResponsiveSize(3.8),
                                    fontWeight: FontWeight.w400,
                                    color: context.colorPalette.textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (selectedCount > 0) ...[
                            SizedBox(height: context.heightPercent(0.3)),
                            Text(
                              '$selectedCount style${selectedCount == 1 ? '' : 's'} selected',
                              style: TextStyle(
                                fontSize: context.getResponsiveSize(2.8),
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
                      size: context.getResponsiveSize(5),
                    ),
                  ],
                ),
              ),
            );
          });
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
            horizontal: context.getResponsiveSize(4),
            vertical: context.heightPercent(0.6),
          ),
          child: Row(
            children: [
              Text(
                cleanCategoryName(controller.currentLevel2?.name ?? ''),
                style: TextStyle(
                  fontSize: context.getResponsiveSize(3.5),
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
                          size: context.getResponsiveSize(3.5),
                          color: allSelected ? Colors.white : context.colorPalette.goldDark,
                        ),
                        SizedBox(width: context.getResponsiveSize(1)),
                        Text(
                          allSelected ? 'Deselect All' : 'Select All',
                          style: TextStyle(
                            fontSize: context.getResponsiveSize(2.8),
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
            padding: EdgeInsets.fromLTRB(0, context.heightPercent(0.3), 0, NavBarSpacer.heightOf(context)),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return Obx(() {
                final isSelected = controller.isLevel3Selected(cat.id);
                return GestureDetector(
                  onTap: () => controller.toggleLevel3Selection(cat),
                  child: Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: context.getResponsiveSize(4),
                      vertical: context.heightPercent(0.3),
                    ),
                    padding: EdgeInsets.all(context.getResponsiveSize(3.5)),
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
                          width: context.getResponsiveSize(5.5),
                          height: context.getResponsiveSize(5.5),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? context.colorPalette.gold
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(context.getResponsiveSize(1.2)),
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
                                  size: context.getResponsiveSize(3),
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        SizedBox(width: context.getResponsiveSize(3)),
                        Expanded(
                          child: Text(
                            '${cleanCategoryName(cat.name)} (${cat.countOfIsStockOne})',
                            style: TextStyle(
                              fontSize: context.getResponsiveSize(3.5),
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
                            padding: EdgeInsets.all(context.getResponsiveSize(1.5)),
                            decoration: BoxDecoration(
                              color: context.colorPalette.gold.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.visibility_outlined,
                              size: context.getResponsiveSize(4),
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

  Widget _buildPlaceholder(BuildContext context, {required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: context.getResponsiveSize(12), color: context.colorPalette.subTitleColor),
          SizedBox(height: context.heightPercent(1.5)),
          Text(
            message,
            style: TextStyle(
              fontSize: context.getResponsiveSize(3.5),
              color: context.colorPalette.subTitleColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareBar(BuildContext context) {
    return Obx(() {
      return AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        child: controller.hasSelection
            ? Container(
                padding: EdgeInsets.fromLTRB(
                  context.getResponsiveSize(4),
                  context.responsiveWidth(12, tabletVal: 16),
                  context.getResponsiveSize(4),
                  context.responsiveWidth(12, tabletVal: 16) + MediaQuery.of(context).padding.bottom,
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
                        padding: EdgeInsets.symmetric(
                          horizontal: context.responsiveWidth(10, tabletVal: 14),
                          vertical: context.responsiveWidth(8, tabletVal: 12),
                        ),
                        decoration: BoxDecoration(
                          color: context.colorPalette.cardBg,
                          borderRadius: BorderRadius.circular(context.responsiveWidth(8, tabletVal: 12)),
                          border: Border.all(color: context.colorPalette.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.close, size: context.responsiveWidth(16, tabletVal: 20), color: context.colorPalette.goldDark),
                            SizedBox(width: context.responsiveWidth(4)),
                            Text(
                              'Clear',
                              style: TextStyle(
                                fontSize: context.responsiveWidth(12, tabletVal: 16),
                                fontWeight: FontWeight.w600,
                                color: context.colorPalette.goldDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: context.responsiveWidth(10, tabletVal: 14)),
                    Expanded(
                      child: Text(
                        '${controller.selectedCount} selected',
                        style: TextStyle(
                          fontSize: context.responsiveWidth(14, tabletVal: 18),
                          fontWeight: FontWeight.w600,
                          color: context.colorPalette.goldDeep,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        final catNames = <String, String>{
                          for (final entry in controller.selectedLevel3.entries)
                            entry.value.id: entry.value.name,
                        };
                        Get.to(() => ProductListingPage(
                          categoryIds: controller.selectedCategoryIds,
                          categoryNames: catNames,
                          karats: controller.selectedKarats,
                          title: 'Selected Products',
                          startInSelectMode: true,
                        ));
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.responsiveWidth(10, tabletVal: 14),
                          vertical: context.responsiveWidth(8, tabletVal: 12),
                        ),
                        decoration: BoxDecoration(
                          color: context.colorPalette.cardBg,
                          borderRadius: BorderRadius.circular(context.responsiveWidth(8, tabletVal: 12)),
                          border: Border.all(color: context.colorPalette.border),
                        ),
                        child: Icon(Icons.check_rounded, size: context.responsiveWidth(18, tabletVal: 22), color: context.colorPalette.goldDark),
                      ),
                    ),
                  ],
                ),
              )
            : const SizedBox.shrink(),
      );
    });
  }

}
