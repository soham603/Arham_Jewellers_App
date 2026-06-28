import 'dart:async';

import 'package:ratnesh_gold_app/utils/ToastUtil.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/core/widgets/nav_bar_spacer.dart';
import 'package:ratnesh_gold_app/presentation/pages/product/widgets/product_list_tile.dart';
import 'package:ratnesh_gold_app/core/widgets/search_bar_widget.dart';
import 'package:ratnesh_gold_app/presentation/controllers/product_search_controller.dart';
import 'package:ratnesh_gold_app/presentation/pages/admin/product_edit_page.dart';
import 'package:ratnesh_gold_app/presentation/pages/search/barcode_scanner_page.dart';
import 'package:ratnesh_gold_app/presentation/pages/product/category_listing_page.dart';
import 'package:ratnesh_gold_app/presentation/controllers/CategoryController.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';

class ProductSearchPage extends StatefulWidget {
  const ProductSearchPage({super.key});

  @override
  State<ProductSearchPage> createState() => _ProductSearchPageState();
}

class _ProductSearchPageState extends State<ProductSearchPage> {
  final ProductSearchController controller = Get.put(ProductSearchController());
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  final RxBool _isCatalogLoading = false.obs;
  bool _catalogFlowActive = false;

  static const Duration _minSpinnerDisplay = Duration(milliseconds: 450);
  static const Duration _maxSpinnerDisplay = Duration(seconds: 16);

  bool _hasAnyCatalogData() {
    if (!Get.isRegistered<CategoryController>()) return false;
    final c = Get.find<CategoryController>();
    return c.k18Categories.isNotEmpty ||
        c.k20Categories.isNotEmpty ||
        c.k22Categories.isNotEmpty;
  }

  bool _isCatalogReady() {
    if (!Get.isRegistered<CategoryController>()) return false;
    final c = Get.find<CategoryController>();
    final allSuccess = c.k18State == CurrentAppState.SUCCESS &&
        c.k20State == CurrentAppState.SUCCESS &&
        c.k22State == CurrentAppState.SUCCESS;
    return allSuccess && _hasAnyCatalogData();
  }

  void _onOpenCatalog() {
    if (_catalogFlowActive) return;
    _catalogFlowActive = true;
    _isCatalogLoading.value = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        _catalogFlowActive = false;
        return;
      }

      await _waitForCatalogReady();

      if (!mounted) {
        _catalogFlowActive = false;
        return;
      }

      _navigateToCatalog();

      _isCatalogLoading.value = false;
      _catalogFlowActive = false;
    });
  }

  Future<void> _waitForCatalogReady() async {
    final minStart = DateTime.now();
    while (true) {
      if (_isCatalogReady()) {
        final elapsed = DateTime.now().difference(minStart);
        if (elapsed >= _minSpinnerDisplay) return;
        await Future<void>.delayed(_minSpinnerDisplay - elapsed);
        return;
      }
      final totalElapsed = DateTime.now().difference(minStart);
      if (totalElapsed >= _maxSpinnerDisplay) return;
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }
  }

  void _navigateToCatalog() {
    Get.to(() => CategoryListingPage(
          karats: [Karat.k18, Karat.k20, Karat.k22],
          title: 'Collections',
          showBothLogos: true,
        ));
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    if (Get.isRegistered<ProductSearchController>()) {
      Get.delete<ProductSearchController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorPalette.backgroundColor,
      floatingActionButton: Obx(() {
        final isLoading = _isCatalogLoading.value;
        return Transform.scale(
          scale: 0.88,
          alignment: Alignment.bottomRight,
          child: FloatingActionButton.extended(
            onPressed: isLoading ? null : _onOpenCatalog,
            backgroundColor: context.colorPalette.gold,
            foregroundColor: Colors.white,
            disabledElevation: 0,
            icon: SizedBox(
              width: 22,
              height: 22,
              child: isLoading
                  ? const CircularProgressIndicator(
                      strokeWidth: 2.6,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  : const Icon(Icons.category_rounded, size: 22),
            ),
            label: const Text(
              'Search in Catalog',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        );
      }),
      body: Column(
        children: [
          SearchBarWidget(
            controller: _textController,
            focusNode: _focusNode,
            autofocus: false,
            showScanner: true,
            hintText: 'Search Products',
            onBack: () {
              if (_textController.text.isNotEmpty || controller.isSearching) {
                _textController.clear();
                controller.clearSearch();
                setState(() {});
              } else {
                Navigator.pop(context);
              }
            },
            onChanged: (v) {
              setState(() {});
            },
            onSubmitted: (v) {
              controller.search(v);
              _focusNode.unfocus();
            },
            onClear: () {
              _textController.clear();
              controller.clearSearch();
              setState(() {});
            },
            onScannerTap: () async {
              _focusNode.unfocus();
              final barcode = await Get.to(() => BarcodeScannerPage(
                onDetect: (barcode) async {},
              )) as String?;

              if (barcode == null) return;

              final product = await controller.searchByBarcode(barcode);
              if (!mounted) return;
              if (product != null) {
                Get.to(() => ProductEditPage(product: product));
              } else {
                ToastUtils.showError('No product found for barcode: $barcode');
              }
            },
          ),
          _buildKaratRow(context),
          _buildFilterDropdowns(context),
          SizedBox(height: context.heightPercent(0.6)),
          Expanded(
            child: Obx(() {
              final products = controller.products;
              final state = controller.state;

              if (state == CurrentAppState.LOADING && products.isEmpty) {
                return Center(
                  child: CircularProgressIndicator(
                    color: context.colorPalette.gold,
                  ),
                );
              }

              if (state == CurrentAppState.ERROR && products.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: context.colorPalette.goldDark,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load products',
                        style: TextStyle(
                          color: context.colorPalette.goldDark,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => controller.search(controller.query),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.colorPalette.gold,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (products.isEmpty) {
                if (controller.isSearching) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          color: context.colorPalette.goldDark,
                          size: 64,
                        ),
                        SizedBox(height: context.heightPercent(2)),
                        Text(
                          'No Products Found',
                          style: TextStyle(
                            color: context.colorPalette.goldDark,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: context.heightPercent(1)),
                        Text(
                          'Try adjusting your search or filters',
                          style: TextStyle(
                            color: context.colorPalette.goldDark,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              }

              return CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      vertical: context.getResponsiveSize(2),
                    ),
                    sliver: SliverList.separated(
                      itemCount: products.length,
                      itemBuilder: (_, index) {
                        final product = products[index];
                        return ProductListTile(
                          key: ValueKey(product.id),
                          product: product,
                          onTap: () => Get.to(() => ProductEditPage(product: product)),
                        );
                      },
                      separatorBuilder: (_, __) => SizedBox(height: context.getResponsiveSize(1)),
                    ),
                  ),
                  if (controller.hasMore)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.getResponsiveSize(4),
                          vertical: context.getResponsiveSize(2),
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: state == CurrentAppState.LOADING
                                ? null
                                : () => controller.loadMore(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.colorPalette.gold,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                vertical: context.getResponsiveSize(3),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(context.getResponsiveSize(2)),
                              ),
                            ),
                            child: state == CurrentAppState.LOADING
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Load More'),
                          ),
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: NavBarSpacer(),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
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
        context.getResponsiveSize(4),
        context.heightPercent(0.4),
        context.getResponsiveSize(4),
        0,
      ),
      child: Obx(() {
        return Row(
          children: [
            for (int i = 0; i < karatOptions.length; i++) ...[
              Expanded(
                child: _buildKaratChip(context, karatOptions[i]),
              ),
              if (i < karatOptions.length - 1)
                SizedBox(width: context.getResponsiveSize(2)),
            ],
          ],
        );
      }),
    );
  }

  Widget _buildKaratChip(BuildContext context, Map<String, String> option) {
    final karat = option['label']!;
    final percent = option['percent']!;
    final isSelected = controller.selectedKarats.contains(karat);
    return GestureDetector(
      onTap: () {
        controller.toggleKaratFilter(karat);
      },
      child: AnimatedContainer(
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
      ),
    );
  }

  Widget _buildFilterDropdowns(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        context.getResponsiveSize(4),
        context.heightPercent(0.6),
        context.getResponsiveSize(4),
        0,
      ),
      child: Obx(() {
        return Row(
          children: [
            Expanded(
              child: _buildStockDropdown(context),
            ),
            SizedBox(width: context.getResponsiveSize(2)),
            Expanded(
              child: _buildActiveDropdown(context),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildStockDropdown(BuildContext context) {
    final value = controller.stockFilter;
    return _FilterDropdownContainer(
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          isDense: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: context.colorPalette.goldDark,
            size: context.getResponsiveSize(5),
          ),
          style: TextStyle(
            fontSize: context.getResponsiveSize(3.3),
            fontWeight: FontWeight.w600,
            color: context.colorPalette.goldDeep,
          ),
          items: const [
            DropdownMenuItem(value: 'ready', child: Text('Ready Stock')),
            DropdownMenuItem(value: 'out', child: Text('Out of Stock')),
            DropdownMenuItem(value: 'all', child: Text('All Stock')),
          ],
          onChanged: (val) {
            if (val != null) controller.setStockFilter(val);
          },
        ),
      ),
    );
  }

  Widget _buildActiveDropdown(BuildContext context) {
    final value = controller.isActiveFilter;
    return _FilterDropdownContainer(
      child: DropdownButtonHideUnderline(
        child: DropdownButton<bool?>(
          value: value,
          isExpanded: true,
          isDense: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: context.colorPalette.goldDark,
            size: context.getResponsiveSize(5),
          ),
          style: TextStyle(
            fontSize: context.getResponsiveSize(3.3),
            fontWeight: FontWeight.w600,
            color: context.colorPalette.goldDeep,
          ),
          items: const [
            DropdownMenuItem<bool?>(value: true, child: Text('Active')),
            DropdownMenuItem<bool?>(value: false, child: Text('Inactive')),
            DropdownMenuItem<bool?>(value: null, child: Text('All Status')),
          ],
          onChanged: (val) {
            controller.setIsActiveFilter(val);
          },
        ),
      ),
    );
  }

}

class _FilterDropdownContainer extends StatelessWidget {
  final Widget child;
  const _FilterDropdownContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.getResponsiveSize(2.5),
        vertical: context.heightPercent(0.4),
      ),
      decoration: BoxDecoration(
        color: context.colorPalette.cardBg,
        borderRadius: BorderRadius.circular(context.getResponsiveSize(2.5)),
        border: Border.all(
          color: context.colorPalette.border,
          width: 1.5,
        ),
      ),
      child: child,
    );
  }
}
