import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/core/widgets/filter_bottom_sheet.dart';
import 'package:ratnesh_gold_app/core/widgets/search_bar_widget.dart';
import 'package:ratnesh_gold_app/presentation/controllers/share_controller.dart';
import 'package:ratnesh_gold_app/presentation/pages/share/widgets/share_product_card.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';

class SharePage extends StatefulWidget {
  const SharePage({super.key});

  @override
  State<SharePage> createState() => _SharePageState();
}

class _SharePageState extends State<SharePage> {
  final ShareController controller = Get.put(ShareController());
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      controller.loadMore();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorPalette.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            SearchBarWidget(
              controller: _textController,
              focusNode: _focusNode,
              autofocus: false,
              showScanner: false,
              hintText: 'Search products to share...',
              onChanged: (v) {
                setState(() {});
                controller.onSearchChanged(v);
              },
              onSubmitted: (v) {
                controller.onSearchSubmitted(v);
                _focusNode.unfocus();
              },
              onClear: () {
                _textController.clear();
                controller.onSearchChanged('');
                setState(() {});
              },
              onFilterTap: () {
                _focusNode.unfocus();
                FilterBottomSheet.show(
                  context,
                  initialSelectedKarats: controller.selectedKarats,
                  initialSelectedCategoryIds: controller.selectedCategoryIds,
                  initialSelectedCategoryNames: controller.selectedCategoryNames,
                  initialShowAllStock: controller.showAllStock,
                  initialWeightMin: controller.weightMin,
                  initialWeightMax: controller.weightMax,
                  onApply: controller.applyFilters,
                );
              },
              filterActiveCount: controller.activeFilterCount,
            ),
            _buildFilterChips(context),
            Expanded(child: _buildProductGrid(context)),
          ],
        ),
      ),
      bottomNavigationBar: _buildSelectionBar(context),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    return Obx(() {
      if (!controller.hasActiveFilters) return const SizedBox.shrink();

      final karats = controller.selectedKarats;
      final categoryNames = controller.selectedCategoryNames;
      final showAll = controller.showAllStock;
      final wMin = controller.weightMin;
      final wMax = controller.weightMax;
      final hasWeightFilter = wMin > 0 || wMax < 500;

      return Container(
        padding: EdgeInsets.only(
          left: context.getScreenWidth(4),
          right: context.getScreenWidth(4),
          bottom: context.getScreenHeight(0.8),
        ),
        child: Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final karat in karats)
                      _activeFilterChip(
                        context,
                        label: karat,
                        onRemove: () {
                          controller.toggleKaratFilter(karat);
                          controller.loadProducts();
                          setState(() {});
                        },
                      ),
                    for (final name in categoryNames)
                      _activeFilterChip(
                        context,
                        label: name,
                        onRemove: () {
                          final idx = categoryNames.indexOf(name);
                          controller.selectedCategoryNames.removeAt(idx);
                          controller.selectedCategoryIds.removeAt(idx);
                          controller.loadProducts();
                          setState(() {});
                        },
                      ),
                    if (showAll)
                      _activeFilterChip(
                        context,
                        label: 'All Stock',
                        onRemove: () {
                          controller.setShowAllStock(false);
                          controller.loadProducts();
                          setState(() {});
                        },
                      ),
                    if (hasWeightFilter)
                      _activeFilterChip(
                        context,
                        label: '${wMin.round()}–${wMax.round()}g',
                        onRemove: () {
                          controller.setWeightRange(0, 500);
                          controller.loadProducts();
                          setState(() {});
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                controller.clearAllFilters();
                controller.loadProducts();
                setState(() {});
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: context.colorPalette.cardBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: context.colorPalette.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.close,
                      size: context.getScreenWidth(3),
                      color: context.colorPalette.goldDark,
                    ),
                    SizedBox(width: context.getScreenWidth(0.8)),
                    Text(
                      'Clear',
                      style: TextStyle(
                        fontSize: context.getScreenWidth(2.8),
                        fontWeight: FontWeight.w500,
                        color: context.colorPalette.goldDark,
                      ),
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

  Widget _activeFilterChip(
    BuildContext context, {
    required String label,
    required VoidCallback onRemove,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: context.colorPalette.gold,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 12, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid(BuildContext context) {
    return Obx(() {
      final state = controller.state;
      final products = controller.displayProducts;

      if (state == CurrentAppState.LOADING && products.isEmpty) {
        return _gridShimmer(context);
      }

      if (state == CurrentAppState.ERROR && products.isEmpty) {
        return _errorWidget(context);
      }

      if (state == CurrentAppState.SUCCESS && products.isEmpty) {
        return _emptyWidget(context);
      }

      return RefreshIndicator(
        onRefresh: () => controller.loadProducts(),
        color: context.colorPalette.gold,
        child: GridView.builder(
          controller: _scrollController,
          padding: EdgeInsets.symmetric(
            horizontal: context.getScreenWidth(4),
            vertical: context.getScreenHeight(0.5),
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: context.gridColumns(phone: 2, tablet: 3),
            mainAxisSpacing: context.getScreenWidth(2.5),
            crossAxisSpacing: context.getScreenWidth(2.5),
            childAspectRatio: context.isTablet ? 0.68 : 0.62,
          ),
          itemCount: products.length + (controller.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == products.length) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(context.getScreenHeight(2)),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.colorPalette.gold,
                    ),
                  ),
                ),
              );
            }

            final product = products[index];
            final isSelected = controller.isSelected(product.id);

            return ShareProductCard(
              product: product,
              isSelected: isSelected,
              onTap: () {
                controller.toggleSelection(product);
                setState(() {});
              },
            );
          },
        ),
      );
    });
  }

  Widget _buildSelectionBar(BuildContext context) {
    return Obx(() {
      final count = controller.selectedCount;
      if (count == 0) return const SizedBox.shrink();

      return Container(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          12 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: context.colorPalette.border),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                controller.clearSelection();
                setState(() {});
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: context.colorPalette.cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.colorPalette.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.close,
                      size: 16,
                      color: context.colorPalette.goldDark,
                    ),
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
                '$count item${count == 1 ? '' : 's'} selected',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: context.colorPalette.goldDeep,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                _showShareOptions(context);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.share_rounded, size: 16, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Share',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
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

  Widget _gridShimmer(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.getScreenWidth(4)),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: context.gridColumns(phone: 2, tablet: 3),
          mainAxisSpacing: context.getScreenWidth(2.5),
          crossAxisSpacing: context.getScreenWidth(2.5),
          childAspectRatio: context.isTablet ? 0.68 : 0.62,
        ),
        itemBuilder: (context, _) => Container(
          decoration: BoxDecoration(
            color: context.colorPalette.shimmerBaseColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: context.colorPalette.shimmerHighLightColor,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(14)),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(context.getScreenWidth(2)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: context.getScreenHeight(1),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: context.colorPalette.shimmerHighLightColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      SizedBox(height: context.getScreenHeight(0.5)),
                      Container(
                        height: context.getScreenHeight(1),
                        width: context.getScreenWidth(20),
                        decoration: BoxDecoration(
                          color: context.colorPalette.shimmerHighLightColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _errorWidget(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.getScreenHeight(4)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: context.getScreenWidth(12),
              color: const Color(0xFF8D847A),
            ),
            SizedBox(height: context.getScreenHeight(1.5)),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: context.getScreenWidth(4),
                color: context.colorPalette.textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: context.getScreenHeight(0.5)),
            Text(
              'Check your connection and try again',
              style: TextStyle(
                fontSize: context.getScreenWidth(3.2),
                color: context.colorPalette.subTitleColor,
              ),
            ),
            SizedBox(height: context.getScreenHeight(2)),
            ElevatedButton(
              onPressed: () => controller.loadProducts(),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colorPalette.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: context.getScreenWidth(8),
                  vertical: context.getScreenHeight(1.2),
                ),
              ),
              child: Text(
                'Retry',
                style: TextStyle(
                  fontSize: context.getScreenWidth(3.8),
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyWidget(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.getScreenHeight(4)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: context.getScreenWidth(12),
              color: const Color(0xFF8D847A),
            ),
            SizedBox(height: context.getScreenHeight(1.5)),
            Text(
              'No products found',
              style: TextStyle(
                fontSize: context.getScreenWidth(4),
                color: context.colorPalette.textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: context.getScreenHeight(0.5)),
            Text(
              'Try adjusting your filters',
              style: TextStyle(
                fontSize: context.getScreenWidth(3.2),
                color: context.colorPalette.subTitleColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showShareOptions(BuildContext context) {
    final count = controller.selectedCount;
    final filterInfo = controller.filterInfo;

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
              'Share $count item${count == 1 ? '' : 's'}',
              style: TextStyle(
                fontSize: context.getScreenWidth(4.5),
                fontWeight: FontWeight.w700,
                color: context.colorPalette.textColor,
              ),
            ),
            SizedBox(height: context.getScreenHeight(0.5)),
            Text(
              'Filters: $filterInfo',
              style: TextStyle(
                fontSize: context.getScreenWidth(3),
                color: context.colorPalette.subTitleColor,
              ),
            ),
            SizedBox(height: context.getScreenHeight(2.5)),
            _shareOptionTile(
              context,
              icon: Icons.image_outlined,
              iconColor: const Color(0xFF25D366),
              title: 'Share Images',
              subtitle: 'Send product images with filter details',
              onTap: () {
                Navigator.pop(ctx);
                controller.shareImages();
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
                controller.shareAsPdf();
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
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(context.getScreenWidth(4)),
        decoration: BoxDecoration(
          color: context.colorPalette.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.colorPalette.border),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(context.getScreenWidth(2.5)),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: context.getScreenWidth(6)),
            ),
            SizedBox(width: context.getScreenWidth(3)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: context.getScreenWidth(3.8),
                      fontWeight: FontWeight.w600,
                      color: context.colorPalette.textColor,
                    ),
                  ),
                  SizedBox(height: context.getScreenHeight(0.3)),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: context.getScreenWidth(2.8),
                      color: context.colorPalette.subTitleColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: context.colorPalette.subTitleColor,
              size: context.getScreenWidth(5),
            ),
          ],
        ),
      ),
    );
  }
}
