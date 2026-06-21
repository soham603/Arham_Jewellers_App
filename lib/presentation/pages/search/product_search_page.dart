import 'package:ratnesh_gold_app/utils/ToastUtil.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/core/widgets/nav_bar_spacer.dart';
import 'package:ratnesh_gold_app/presentation/pages/product/widgets/product_list_tile.dart';
import 'package:ratnesh_gold_app/core/widgets/search_bar_widget.dart';
import 'package:ratnesh_gold_app/presentation/controllers/product_search_controller.dart';
import 'package:ratnesh_gold_app/presentation/pages/admin/product_edit_page.dart';
import 'package:ratnesh_gold_app/presentation/pages/search/barcode_scanner_page.dart';
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

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorPalette.backgroundColor,
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

}
