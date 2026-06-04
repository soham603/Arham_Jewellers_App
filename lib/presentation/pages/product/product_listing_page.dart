import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/core/widgets/filter_bottom_sheet.dart';
import 'package:ratnesh_gold_app/core/widgets/product_card.dart';
import 'package:ratnesh_gold_app/domain/entities/productModel.dart';
import 'package:ratnesh_gold_app/presentation/controllers/admin/GoldRateController.dart';
import 'package:ratnesh_gold_app/presentation/controllers/searchProductController.dart';
import 'package:ratnesh_gold_app/presentation/pages/product/product_details_page.dart';
import 'package:ratnesh_gold_app/presentation/pages/product/widgets/product_list_tile.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';

class ProductListingPage extends StatefulWidget {
  final String? karat;
  final List<String>? karats;
  final String? categoryId;
  final String? title;

  const ProductListingPage({super.key, this.karat, this.karats, this.categoryId, this.title});

  @override
  State<ProductListingPage> createState() => _ProductListingPageState();
}

class _ProductListingPageState extends State<ProductListingPage> {
  late final SearchProductController _controller;
  final ScrollController _scrollController = ScrollController();

  bool _showAllStock = false;
  double _weightMin = 0;
  double _weightMax = 500;
  double _priceMin = 0;
  double _priceMax = 5000000;

  bool get _isCategoryFilter => widget.categoryId != null;
  bool get _hasKarat => widget.karat != null;
  bool get _isCategoryOnly => _isCategoryFilter && !_hasKarat;

  @override
  void initState() {
    super.initState();
    final tag = _isCategoryFilter
        ? 'filtered_${widget.categoryId}_${widget.karat ?? ''}'
        : 'listing_${widget.karat ?? widget.karats?.join("_")}';
    _controller = Get.put(SearchProductController(), tag: tag);

    if (_isCategoryFilter && _hasKarat) {
      _controller.loadByCategoryWithKaratFilter(widget.categoryId!, widget.karat!);
    } else if (_isCategoryFilter) {
      _controller.loadProductsByCategory(widget.categoryId!);
    } else {
      final karatsToLoad = widget.karats ?? (widget.karat != null ? [widget.karat!] : <String>[]);
      _controller.loadProductsByKarats(karatsToLoad);
    }

    _scrollController.addListener(_onScroll);
    ever(_controller.sortByObs, (_) => setState(() {}));
    ever(_controller.isGridObs, (_) => setState(() {}));
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    final tag = _isCategoryFilter
        ? 'filtered_${widget.categoryId}_${widget.karat ?? ''}'
        : 'listing_${widget.karat ?? widget.karats?.join("_")}';
    Get.delete<SearchProductController>(tag: tag);
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      if (_isCategoryOnly) {
        // Category-only mode doesn't support pagination yet
      } else if (_isCategoryFilter) {
        _controller.loadMoreFilteredProducts();
      } else {
        _controller.loadMoreKaratProducts();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorPalette.cream,
      appBar: AppBar(
        title: Text(
          _buildAppBarTitle(),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: context.colorPalette.goldDeep,
          ),
        ),
        centerTitle: true,
        backgroundColor: context.colorPalette.cream,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: context.colorPalette.goldDeep),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildSortLayoutBar(context),
          Expanded(
            child: Obx(() {
              _controller.sortBy; // explicit dependency for reactivity
              final state = _isCategoryOnly
                  ? _controller.categoryState
                  : _isCategoryFilter
                      ? _controller.filteredState
                      : _controller.karatState;
              final rawProducts = _isCategoryOnly
                  ? _controller.categoryProducts
                  : _isCategoryFilter
                      ? _controller.filteredProducts
                      : _controller.karatProducts;
              final hasMore = _isCategoryOnly
                  ? false
                  : _isCategoryFilter
                      ? _controller.filteredHasMore
                      : _controller.karatHasMore;

              final filteredProducts = _applyClientSideFilters(rawProducts);
              final products = _controller.sortProducts(filteredProducts);
              final isGrid = _controller.isGrid;

              if (state == CurrentAppState.LOADING && products.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state == CurrentAppState.ERROR && products.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: context.colorPalette.goldDark, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load products',
                        style: TextStyle(color: context.colorPalette.goldDark, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          if (_isCategoryOnly) {
                            _controller.loadProductsByCategory(widget.categoryId!);
                          } else if (_isCategoryFilter) {
                            _controller.loadByCategoryWithKaratFilter(widget.categoryId!, widget.karat!);
                          } else {
                            final karatsToLoad = widget.karats ?? (widget.karat != null ? [widget.karat!] : <String>[]);
                            _controller.loadProductsByKarats(karatsToLoad);
                          }
                        },
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
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.diamond_outlined, color: context.colorPalette.goldDark, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'No products found',
                        style: TextStyle(color: context.colorPalette.goldDark, fontSize: 16),
                      ),
                    ],
                  ),
                );
              }

              if (!isGrid) {
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: products.length + (hasMore ? 1 : 0),
                  itemBuilder: (_, index) {
                    if (index >= products.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final product = products[index];
                    return ProductListTile(
                      product: product,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductDetailsPage(product: product),
                          ),
                        );
                      },
                    );
                  },
                );
              }

              return GridView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: products.length + (hasMore ? 1 : 0),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: context.gridColumns(phone: 2, tablet: 3),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: context.isTablet ? 0.55 : 0.488,
                ),
                itemBuilder: (_, index) {
                  if (index >= products.length) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final product = products[index];
                  return ProductCard(
                    product: product,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailsPage(product: product),
                        ),
                      );
                    },
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSortLayoutBar(BuildContext context) {
    return Obx(() {
      final currentSort = _controller.sortBy;
      final isGrid = _controller.isGrid;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _showSortSheet(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: context.colorPalette.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.sort_rounded,
                      size: 18,
                      color: context.colorPalette.goldDark,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      currentSort.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: context.colorPalette.goldDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => _showFilterSheet(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _hasActiveFilter ? context.colorPalette.gold.withOpacity(0.08) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _hasActiveFilter ? context.colorPalette.gold : context.colorPalette.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: 18,
                      color: _hasActiveFilter ? context.colorPalette.gold : context.colorPalette.goldDark,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Filter',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _hasActiveFilter ? context.colorPalette.gold : context.colorPalette.goldDark,
                      ),
                    ),
                    if (_activeFilterCount > 0) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: context.colorPalette.gold,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$_activeFilterCount',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _controller.toggleLayout(),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: context.colorPalette.border),
                ),
                child: Icon(
                  isGrid ? Icons.list_rounded : Icons.grid_view_rounded,
                  size: 20,
                  color: context.colorPalette.goldDark,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  bool get _hasActiveFilter =>
      _showAllStock ||
      _weightMin > 0 ||
      _weightMax < 500 ||
      _priceMin > 0 ||
      _priceMax < 5000000;

  int get _activeFilterCount {
    var count = 0;
    if (_showAllStock) count++;
    if (_weightMin > 0 || _weightMax < 500) count++;
    if (_priceMin > 0 || _priceMax < 5000000) count++;
    return count;
  }

  List<ProductModel> _applyClientSideFilters(List<ProductModel> products) {
    var result = products;

    if (!_showAllStock) {
      result = result.where((p) => p.isActive).toList();
    }

    if (_weightMin > 0 || _weightMax < 500) {
      result = result.where((p) {
        final gw = p.grossWeight;
        if (gw == null) return true;
        return gw >= _weightMin && gw <= _weightMax;
      }).toList();
    }

    if (_priceMin > 0 || _priceMax < 5000000) {
      final goldRate = Get.find<GoldRateController>().currentRate;
      if (goldRate != null) {
        result = result.where((p) {
          final price = _calculatePrice(p, goldRate.ratePerGram);
          if (price == null) return true;
          return price >= _priceMin && price <= _priceMax;
        }).toList();
      }
    }

    return result;
  }

  double? _calculatePrice(ProductModel product, double ratePerGram) {
    if (product.fineWeight == null) return null;
    final base = product.fineWeight! * ratePerGram;
    final labour = base * 0.10;
    final subtotal = base + labour;
    final gst = subtotal * 0.03;
    return subtotal + gst;
  }

  String _formatPrice(double value) {
    if (value >= 10000000) {
      return '\u20B9${(value / 10000000).toStringAsFixed(1)}Cr';
    } else if (value >= 100000) {
      return '\u20B9${(value / 100000).toStringAsFixed(1)}L';
    } else if (value >= 1000) {
      return '\u20B9${(value / 1000).toStringAsFixed(1)}K';
    }
    return '\u20B9${value.round()}';
  }

  String _buildAppBarTitle() {
    final title = widget.title ?? '${widget.karat} Collection';
    final karatLabel = widget.karat ?? (widget.karats != null && widget.karats!.isNotEmpty ? widget.karats!.join(', ') : null);
    if (karatLabel != null) {
      return '$title — $karatLabel';
    }
    return title;
  }

  void _showFilterSheet(BuildContext context) {
    FilterBottomSheet.show(
      context,
      initialSelectedKarats: const [],
      initialSelectedCategoryIds: const [],
      initialSelectedCategoryNames: const [],
      initialShowAllStock: _showAllStock,
      initialWeightMin: _weightMin,
      initialWeightMax: _weightMax,
      initialPriceMin: _priceMin,
      initialPriceMax: _priceMax,
      showKaratFilter: false,
      showCategoryFilter: false,
      showStockFilter: true,
      showWeightFilter: true,
      showPriceFilter: true,
      onApply: ({
        required List<String> karats,
        required List<String> categoryIds,
        required List<String> categoryNames,
        required bool showAll,
        required double wMin,
        required double wMax,
        required double pMin,
        required double pMax,
      }) {
        setState(() {
          _showAllStock = showAll;
          _weightMin = wMin;
          _weightMax = wMax;
          _priceMin = pMin;
          _priceMax = pMax;
        });
      },
    );
  }

  void _showSortSheet(BuildContext context) {
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
            const SizedBox(height: 16),
            Text(
              'Sort By',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.colorPalette.textColor,
              ),
            ),
            const SizedBox(height: 12),
            ...SortOption.values.map((option) {
              final isSelected = _controller.sortBy == option;
              return GestureDetector(
                onTap: () {
                  _controller.setSortOption(option);
                  Navigator.pop(ctx);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? context.colorPalette.gold.withOpacity(0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        size: 20,
                        color: isSelected
                            ? context.colorPalette.gold
                            : context.colorPalette.subTitleColor,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        option.label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected
                              ? context.colorPalette.gold
                              : context.colorPalette.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
