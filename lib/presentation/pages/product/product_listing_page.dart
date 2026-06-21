import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ratnesh_gold_app/core/services/share_service.dart';
import 'package:ratnesh_gold_app/presentation/pages/share/widgets/share_products_per_page_sheet.dart';
import 'package:ratnesh_gold_app/core/widgets/custom_divider.dart';
import 'package:ratnesh_gold_app/core/widgets/filter_bottom_sheet.dart';
import 'package:ratnesh_gold_app/core/widgets/product_card.dart';
import 'package:ratnesh_gold_app/domain/entities/category_model.dart';
import 'package:ratnesh_gold_app/domain/entities/productModel.dart';
import 'package:ratnesh_gold_app/presentation/controllers/AuthController.dart';
import 'package:ratnesh_gold_app/presentation/controllers/admin/GoldRateController.dart';
import 'package:ratnesh_gold_app/presentation/controllers/searchProductController.dart';
import 'package:ratnesh_gold_app/presentation/pages/product/product_details_page.dart';
import 'package:ratnesh_gold_app/presentation/pages/product/widgets/product_list_tile.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';
import 'package:shimmer/shimmer.dart';

class ProductListingPage extends StatefulWidget {
  final String? karat;
  final List<String>? karats;
  final String? categoryId;
  final List<String>? categoryIds;
  final Map<String, String>? categoryNames;
  final String? title;
  final bool startInSelectMode;

  const ProductListingPage({
    super.key,
    this.karat,
    this.karats,
    this.categoryId,
    this.categoryIds,
    this.categoryNames,
    this.title,
    this.startInSelectMode = false,
  });

  @override
  State<ProductListingPage> createState() => _ProductListingPageState();
}

class _ProductListingPageState extends State<ProductListingPage> {
  late final SearchProductController _controller;

  String _stockFilter = 'ready';
  double _weightMin = 0;
  double _weightMax = 500;
  double _priceMin = 0;
  double _priceMax = 5000000;
  List<String> _selectedSizes = [];

  // ── Selection state
  final Set<String> _selectedProductIds = {};
  bool get _isSelectMode => _selectedProductIds.isNotEmpty;
  bool get _isAdmin => Get.find<AuthController>().isAdmin;

  bool _isLoadingMore = false;
  static const int _shimmerLoadMoreCount = 4;

  late String _selectedKarat;
  List<String> _filteredCategoryIds = [];

  void _toggleSelection(String productId) {
    setState(() {
      if (_selectedProductIds.contains(productId)) {
        _selectedProductIds.remove(productId);
      } else {
        _selectedProductIds.add(productId);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedProductIds.clear();
    });
  }

  bool get _isCategoryFilter => widget.categoryId != null || _isMultiCategory;
  bool get _isMultiCategory => widget.categoryIds != null && widget.categoryIds!.isNotEmpty;
  bool get _hasKarat => widget.karat != null;
  bool get _isCategoryOnly => _isCategoryFilter && !_hasKarat;

  CurrentAppState get _currentStockState {
    switch (_stockFilter) {
      case 'ready':
        if (_isMultiCategory || _isCategoryOnly) return _controller.categoryReadyState;
        if (_isCategoryFilter) return _controller.filteredReadyState;
        return _controller.karatReadyState;
      case 'out':
        if (_isMultiCategory || _isCategoryOnly) return _controller.categoryOutState;
        if (_isCategoryFilter) return _controller.filteredOutState;
        return _controller.karatOutState;
      default:
        if (_isMultiCategory || _isCategoryOnly) return _controller.categoryAllState;
        if (_isCategoryFilter) return _controller.filteredAllState;
        return _controller.karatAllState;
    }
  }

  bool get _hasMore {
    switch (_stockFilter) {
      case 'ready':
        if (_isMultiCategory || _isCategoryOnly) return _controller.categoryReadyHasMore;
        if (_isCategoryFilter) return _controller.filteredReadyHasMore;
        return _controller.karatReadyHasMore;
      case 'out':
        if (_isMultiCategory || _isCategoryOnly) return _controller.categoryOutHasMore;
        if (_isCategoryFilter) return _controller.filteredOutHasMore;
        return _controller.karatOutHasMore;
      default:
        if (_isMultiCategory || _isCategoryOnly) return _controller.categoryAllHasMore;
        if (_isCategoryFilter) return _controller.filteredAllHasMore;
        return _controller.karatAllHasMore;
    }
  }

  void _loadMore() {
    if (_isCategoryOnly || _isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    final stockFilter = _stockFilter;
    if (_isCategoryFilter) {
      _controller.loadMoreFilteredProducts(stockFilter: stockFilter);
    } else {
      _controller.loadMoreKaratProducts(stockFilter: stockFilter);
    }
  }

  List<ProductModel> get _displayedProducts {
    final List<ProductModel> base;
    switch (_stockFilter) {
      case 'ready':
        if (_isMultiCategory) {
          base = _controller.categoryReadyProducts;
        } else if (_isCategoryOnly) {
          base = _controller.categoryReadyProducts;
        } else if (_isCategoryFilter) {
          base = _controller.filteredReadyProducts;
        } else {
          base = _controller.karatReadyProducts;
        }
        break;
      case 'out':
        if (_isMultiCategory) {
          base = _controller.categoryOutProducts;
        } else if (_isCategoryOnly) {
          base = _controller.categoryOutProducts;
        } else if (_isCategoryFilter) {
          base = _controller.filteredOutProducts;
        } else {
          base = _controller.karatOutProducts;
        }
        break;
      default:
        if (_isMultiCategory) {
          base = _controller.categoryAllProducts;
        } else if (_isCategoryOnly) {
          base = _controller.categoryAllProducts;
        } else if (_isCategoryFilter) {
          base = _controller.filteredAllProducts;
        } else {
          base = _controller.karatAllProducts;
        }
        break;
    }
    if (!_isMultiCategory) return base;
    var result = base;
    if (_filteredCategoryIds.length != (widget.categoryIds?.length ?? 0)) {
      result = result.where((p) {
        final catId = p.category?.id;
        return catId != null && _filteredCategoryIds.contains(catId);
      }).toList();
    }
    if (_selectedKarat.isNotEmpty) {
      final targetKarat = int.tryParse(
        _selectedKarat.replaceAll(RegExp(r'[^0-9]'), ''),
      );
      if (targetKarat != null) {
        result = result.where((p) => p.karatNumber == targetKarat).toList();
      }
    }
    return result;
  }

  double get _displayedWeightMax {
    double max = 0;
    for (final p in _displayedProducts) {
      final gw = p.fineWeight;
      if (gw != null && gw > max) max = gw;
    }
    return max > 0 ? max.ceilToDouble() : 200;
  }

  bool get _hasWeightData {
    return _displayedProducts.any((p) => p.fineWeight != null);
  }

  List<String> get _displayedAvailableSizes {
    final sizes = <String>{};
    for (final p in _displayedProducts) {
      final s = p.size;
      if (s != null && s.isNotEmpty) sizes.add(s);
    }
    final sorted = sizes.toList()..sort();
    return sorted;
  }

  @override
  void initState() {
    super.initState();
    final tag = _isCategoryFilter
        ? 'filtered_${widget.categoryId ?? widget.categoryIds?.join("_")}_${widget.karat ?? ''}'
        : 'listing_${widget.karat ?? widget.karats?.join("_")}';
    _controller = Get.put(SearchProductController(), tag: tag);

    if (widget.startInSelectMode && _isAdmin) {
      _selectedProductIds.add('_placeholder_');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedProductIds.remove('_placeholder_');
        });
      });
    }

    _selectedKarat = _isMultiCategory ? '' : (widget.karat ?? '22K');

    if (_isMultiCategory) {
      _filteredCategoryIds = List<String>.from(widget.categoryIds!);
      _controller.loadProductsByMultipleCategories(widget.categoryIds!, stockFilter: 'ready');
      _controller.loadProductsByMultipleCategories(widget.categoryIds!, stockFilter: 'out');
      _controller.loadProductsByMultipleCategories(widget.categoryIds!, stockFilter: 'all');
    } else if (_isCategoryFilter && _hasKarat) {
      _controller.loadByCategoryWithKaratFilter(widget.categoryId!, widget.karat!, stockFilter: 'ready');
      _controller.loadByCategoryWithKaratFilter(widget.categoryId!, widget.karat!, stockFilter: 'out');
      _controller.loadByCategoryWithKaratFilter(widget.categoryId!, widget.karat!, stockFilter: 'all');
    } else if (_isCategoryFilter) {
      _controller.loadProductsByCategory(widget.categoryId!, stockFilter: 'ready');
      _controller.loadProductsByCategory(widget.categoryId!, stockFilter: 'out');
      _controller.loadProductsByCategory(widget.categoryId!, stockFilter: 'all');
    } else {
      final karatsToLoad =
          widget.karats ??
          (widget.karat != null ? [widget.karat!] : <String>[]);
      _controller.loadProductsByKarats(karatsToLoad, stockFilter: 'ready');
      _controller.loadProductsByKarats(karatsToLoad, stockFilter: 'out');
      _controller.loadProductsByKarats(karatsToLoad, stockFilter: 'all');
    }

    ever(_controller.sortByObs, (_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    final tag = _isCategoryFilter
        ? 'filtered_${widget.categoryId ?? widget.categoryIds?.join("_")}_${widget.karat ?? ''}'
        : 'listing_${widget.karat ?? widget.karats?.join("_")}';
    Get.delete<SearchProductController>(tag: tag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorPalette.cream,
      appBar: AppBar(
        title: _isSelectMode
            ? Text(
                '${_selectedProductIds.length} selected',
                style: GoogleFonts.bodoniModa(
                  fontWeight: FontWeight.w700,
                  color: context.colorPalette.goldDeep,
                  fontSize: context.responsiveFont(18, largeTabletMultiplier: 1.8),
                ),
              )
            : _buildAppBarTitleWidget(context),
        centerTitle: true,
        backgroundColor: context.colorPalette.cream,
        elevation: 0,
        scrolledUnderElevation: 1,
        toolbarHeight: context.responsiveWidth(56, largeTabletVal: 76),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: context.colorPalette.goldDeep,
          ),
          onPressed: () {
            if (_isSelectMode) {
              _clearSelection();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          if (_isSelectMode)
            IconButton(
              icon: Icon(Icons.close, color: context.colorPalette.goldDeep),
              onPressed: _clearSelection,
            ),
        ],
      ),
      body: Column(
        children: [
          if (_isMultiCategory)
            _buildKaratRow(context)
          else if (_karatPurityLabel != null)
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 2),
                padding: EdgeInsets.symmetric(
                  horizontal: context.responsiveWidth(8),
                  vertical: context.responsiveWidth(2),
                ),
                decoration: BoxDecoration(
                  color: context.colorPalette.gold.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(context.responsiveWidth(8)),
                ),
                child: Text(
                  _karatPurityLabel!,
                  style: GoogleFonts.bodoniModa(
                    fontWeight: FontWeight.w700,
                    fontSize: context.responsiveFont(11),
                    color: context.colorPalette.goldDeep,
                  ),
                ),
              ),
            ),
          _buildSortLayoutBar(context),
          Expanded(
            child: Obx(() {
              _controller.sortByObs.value;
              final state = _currentStockState;
              final hasMore = _hasMore;

              if (_isLoadingMore && (state != CurrentAppState.LOADING || !hasMore)) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _isLoadingMore = false);
                });
              }

              final filteredProducts = _applyClientSideFilters(_displayedProducts);
              final products = _controller.sortProducts(
                filteredProducts,
                _controller.sortBy,
              );
              final layoutType = _controller.layoutType;

              if (state == CurrentAppState.LOADING && products.isEmpty) {
                return const Center(child: CircularProgressIndicator());
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
                        onPressed: () {
                          if (_isMultiCategory) {
                            _controller.loadProductsByMultipleCategories(widget.categoryIds!, stockFilter: 'ready');
                            _controller.loadProductsByMultipleCategories(widget.categoryIds!, stockFilter: 'out');
                            _controller.loadProductsByMultipleCategories(widget.categoryIds!, stockFilter: 'all');
                          } else if (_isCategoryOnly) {
                            _controller.loadProductsByCategory(widget.categoryId!, stockFilter: 'ready');
                            _controller.loadProductsByCategory(widget.categoryId!, stockFilter: 'out');
                            _controller.loadProductsByCategory(widget.categoryId!, stockFilter: 'all');
                          } else if (_isCategoryFilter) {
                            _controller.loadByCategoryWithKaratFilter(widget.categoryId!, widget.karat!, stockFilter: 'ready');
                            _controller.loadByCategoryWithKaratFilter(widget.categoryId!, widget.karat!, stockFilter: 'out');
                            _controller.loadByCategoryWithKaratFilter(widget.categoryId!, widget.karat!, stockFilter: 'all');
                          } else {
                            final karatsToLoad =
                                widget.karats ??
                                (widget.karat != null
                                    ? [widget.karat!]
                                    : <String>[]);
                            _controller.loadProductsByKarats(karatsToLoad, stockFilter: 'ready');
                            _controller.loadProductsByKarats(karatsToLoad, stockFilter: 'out');
                            _controller.loadProductsByKarats(karatsToLoad, stockFilter: 'all');
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
                      Icon(
                        Icons.diamond_outlined,
                        color: context.colorPalette.goldDark,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _stockFilter == 'ready'
                            ? 'No ready stock items available'
                            : _stockFilter == 'out'
                                ? 'No out of stock items found'
                                : 'No products found',
                        style: TextStyle(
                          color: context.colorPalette.goldDark,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (layoutType == LayoutType.list) {
                final shimmerCount = _isLoadingMore ? _shimmerLoadMoreCount : 0;
                return ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: context.responsiveWidth(8, largeTabletVal: 16)),
                  itemCount: products.length + (hasMore && !_isLoadingMore ? 1 : 0) + shimmerCount,
                  itemBuilder: (_, index) {
                    if (_isLoadingMore && index >= products.length) {
                      return _shimmerListTile(context);
                    }
                    if (hasMore && !_isLoadingMore && index == products.length) {
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.responsiveWidth(16),
                          vertical: context.responsiveWidth(8),
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loadMore,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.colorPalette.gold,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                vertical: context.responsiveWidth(12),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(context.responsiveWidth(8)),
                              ),
                            ),
                            child: const Text('Load More'),
                          ),
                        ),
                      );
                    }
                    final product = products[index];
                    return ProductListTile(
                      key: ValueKey(product.id),
                      product: product,
                      isSelected: _selectedProductIds.contains(product.id),
                      onTap: _isSelectMode
                          ? () => _toggleSelection(product.id)
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ProductDetailsPage(
                                        product: product,
                                        products: products,
                                        initialIndex: index,
                                        controller: _controller,
                                        listType: _isCategoryOnly
                                            ? 'category'
                                            : _isCategoryFilter
                                                ? 'filtered'
                                                : 'karat',
                                      ),
                                ),
                              );
                            },
                      onLongPress: _isAdmin
                          ? () => _toggleSelection(product.id)
                          : null,
                    );
                  },
                );
              }

              if (layoutType == LayoutType.fullScreen) {
                return CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 1,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: MediaQuery.of(context).size.width >= 1000
                              ? 0.7
                              : MediaQuery.of(context).size.width >= 600
                                  ? 0.68
                                  : 0.65,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (_, index) {
                            final product = products[index];
                            return ProductCard(
                              key: ValueKey(product.id),
                              product: product,
                              isSelected: _selectedProductIds.contains(product.id),
                              onTap: _isSelectMode
                                  ? () => _toggleSelection(product.id)
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              ProductDetailsPage(
                                                product: product,
                                                products: products,
                                                initialIndex: index,
                                                controller: _controller,
                                                listType: _isCategoryOnly
                                                    ? 'category'
                                                    : _isCategoryFilter
                                                        ? 'filtered'
                                                        : 'karat',
                                              ),
                                        ),
                                      );
                                    },
                              onLongPress: _isAdmin
                                  ? () => _toggleSelection(product.id)
                                  : null,
                            );
                          },
                          childCount: products.length,
                        ),
                      ),
                    ),
                    if (_isLoadingMore && hasMore)
                      SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverGrid(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 1,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: MediaQuery.of(context).size.width >= 1000
                                ? 0.7
                                : MediaQuery.of(context).size.width >= 600
                                    ? 0.68
                                    : 0.65,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (_, index) => _shimmerCard(context),
                            childCount: 2,
                          ),
                        ),
                      ),
                    if (hasMore && !_isLoadingMore)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.responsiveWidth(16),
                            vertical: context.responsiveWidth(8),
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _loadMore,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.colorPalette.gold,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  vertical: context.responsiveWidth(12),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(context.responsiveWidth(8)),
                                ),
                              ),
                              child: const Text('Load More'),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              }

              return CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: MediaQuery.of(context).size.width >= 1000
                            ? 3
                            : context.gridColumns(phone: 2, tablet: 3),
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: MediaQuery.of(context).size.width >= 1000
                            ? 0.62
                            : MediaQuery.of(context).size.width >= 600
                                ? 0.55
                                : 0.488,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (_, index) {
                          final product = products[index];
                          return ProductCard(
                            key: ValueKey(product.id),
                            product: product,
                            isSelected: _selectedProductIds.contains(product.id),
                            onTap: _isSelectMode
                                ? () => _toggleSelection(product.id)
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ProductDetailsPage(
                                              product: product,
                                              products: products,
                                              initialIndex: index,
                                              controller: _controller,
                                              listType: _isCategoryOnly
                                                  ? 'category'
                                                  : _isCategoryFilter
                                                      ? 'filtered'
                                                      : 'karat',
                                            ),
                                      ),
                                    );
                                  },
                            onLongPress: _isAdmin
                                ? () => _toggleSelection(product.id)
                                : null,
                          );
                        },
                        childCount: products.length,
                      ),
                    ),
                  ),
                  if (_isLoadingMore && hasMore)
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: MediaQuery.of(context).size.width >= 1000
                              ? 3
                              : context.gridColumns(phone: 2, tablet: 3),
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: MediaQuery.of(context).size.width >= 1000
                              ? 0.62
                              : MediaQuery.of(context).size.width >= 600
                                  ? 0.55
                                  : 0.488,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (_, index) => _shimmerCard(context),
                          childCount: _shimmerLoadMoreCount,
                        ),
                      ),
                    ),
                  if (hasMore && !_isLoadingMore)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.responsiveWidth(16),
                          vertical: context.responsiveWidth(8),
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loadMore,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.colorPalette.gold,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                vertical: context.responsiveWidth(12),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(context.responsiveWidth(8)),
                              ),
                            ),
                            child: const Text('Load More'),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            }),
          ),
        ],
      ),
      bottomNavigationBar: _isSelectMode ? _buildSelectionBar(context) : null,
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
        context.getScreenHeight(0.4),
        context.getResponsiveSize(4),
        context.getScreenHeight(0.4),
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
    final isSelected = _selectedKarat == karat;
    return GestureDetector(
      onTap: () {
        if (_selectedKarat == karat) return;
        setState(() {
          _selectedKarat = karat;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: context.getResponsiveSize(2),
          vertical: context.getScreenHeight(0.6),
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

  Widget _buildSortLayoutBar(BuildContext context) {
    return Obx(() {
      final currentSort = _controller.sortBy;
      final layoutType = _controller.layoutType;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: context.responsiveWidth(8)),
          const CategoryDivider(vertical: 4),
          SizedBox(height: context.responsiveWidth(4)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.responsiveWidth(16)),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStockChip(
                    'Ready Stock',
                    'ready',
                    Icons.check_circle_outline_rounded,
                    context,
                  ),
                  SizedBox(width: context.responsiveWidth(8)),
                  _buildStockChip(
                    'Out of Stock',
                    'out',
                    Icons.remove_circle_outline_rounded,
                    context,
                  ),
                  SizedBox(width: context.responsiveWidth(8)),
                  _buildStockChip(
                    'Show All',
                    'all',
                    Icons.select_all_rounded,
                    context,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: context.responsiveWidth(4)),
          Container(
            padding: EdgeInsets.symmetric(horizontal: context.responsiveWidth(16), vertical: context.responsiveWidth(8)),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _showSortSheet(context),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.responsiveWidth(10, largeTabletVal: 18),
                      vertical: context.responsiveWidth(6, largeTabletVal: 12),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(context.responsiveWidth(8, largeTabletVal: 14)),
                      border: Border.all(color: context.colorPalette.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.sort_rounded,
                          size: context.responsiveWidth(18, largeTabletVal: 28),
                          color: context.colorPalette.goldDark,
                        ),
                        SizedBox(width: context.responsiveWidth(6, largeTabletVal: 10)),
                        Text(
                          currentSort.label,
                          style: TextStyle(
                            fontSize: context.responsiveFont(12, largeTabletMultiplier: 1.8),
                            fontWeight: FontWeight.w500,
                            color: context.colorPalette.goldDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _showFilterSheet(context),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.responsiveWidth(10, largeTabletVal: 18),
                      vertical: context.responsiveWidth(6, largeTabletVal: 12),
                    ),
                    decoration: BoxDecoration(
                      color: _hasActiveFilter
                          ? context.colorPalette.gold.withValues(alpha: 0.08)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(context.responsiveWidth(8, largeTabletVal: 14)),
                      border: Border.all(
                        color: _hasActiveFilter
                            ? context.colorPalette.gold
                            : context.colorPalette.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: context.responsiveWidth(18, largeTabletVal: 28),
                          color: _hasActiveFilter
                              ? context.colorPalette.gold
                              : context.colorPalette.goldDark,
                        ),
                        SizedBox(width: context.responsiveWidth(6, largeTabletVal: 10)),
                        Text(
                          'Filter',
                          style: TextStyle(
                            fontSize: context.responsiveFont(12, largeTabletMultiplier: 1.8),
                            fontWeight: FontWeight.w500,
                            color: _hasActiveFilter
                                ? context.colorPalette.gold
                                : context.colorPalette.goldDark,
                          ),
                        ),
                        if (_activeFilterCount > 0) ...[
                          SizedBox(width: context.responsiveWidth(4)),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.responsiveWidth(5),
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: context.colorPalette.gold,
                              borderRadius: BorderRadius.circular(context.responsiveWidth(8)),
                            ),
                            child: Text(
                              '$_activeFilterCount',
                              style: TextStyle(
                                fontSize: context.responsiveFont(10),
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
                SizedBox(width: context.responsiveWidth(8)),
                GestureDetector(
                  onTap: () => _controller.toggleLayout(),
                  child: Container(
                    padding: EdgeInsets.all(context.responsiveWidth(6, largeTabletVal: 12)),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(context.responsiveWidth(8, largeTabletVal: 14)),
                      border: Border.all(color: context.colorPalette.border),
                    ),
                    child: Icon(
                      layoutType == LayoutType.grid
                          ? Icons.list_rounded
                          : layoutType == LayoutType.list
                              ? Icons.view_agenda_rounded
                              : Icons.grid_view_rounded,
                      size: context.responsiveWidth(20, largeTabletVal: 32),
                      color: context.colorPalette.goldDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildStockChip(
    String label,
    String value,
    IconData icon,
    BuildContext context,
  ) {
    final isSelected = _stockFilter == value;
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          setState(() {
            _stockFilter = value;
          });
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.responsiveWidth(10, largeTabletVal: 18),
          vertical: context.responsiveWidth(6, largeTabletVal: 12),
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? context.colorPalette.gold.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(context.responsiveWidth(8, largeTabletVal: 14)),
          border: Border.all(
            color: isSelected
                ? context.colorPalette.gold
                : context.colorPalette.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: context.responsiveWidth(16, largeTabletVal: 26),
              color: isSelected
                  ? context.colorPalette.gold
                  : context.colorPalette.goldDark,
            ),
            SizedBox(width: context.responsiveWidth(4)),
            Text(
              label,
              style: TextStyle(
                fontSize: context.responsiveFont(11, largeTabletMultiplier: 1.8),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? context.colorPalette.gold
                    : context.colorPalette.goldDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _hasActiveFilter =>
      _weightMin > 0 ||
      _weightMax < _displayedWeightMax ||
      _priceMin > 0 ||
      _priceMax < 5000000 ||
      _selectedSizes.isNotEmpty;

  int get _activeFilterCount {
    var count = 0;
    if (_weightMin > 0 || _weightMax < _displayedWeightMax) count++;
    if (_priceMin > 0 || _priceMax < 5000000) count++;
    count += _selectedSizes.length;
    return count;
  }

  List<ProductModel> _applyClientSideFilters(List<ProductModel> products) {
    var result = products;

    result = result.where((p) => !p.isOld22kReadyStock).toList();

    if (_weightMin > 0 || _weightMax < _displayedWeightMax) {
      result = result.where((p) {
        final gw = p.fineWeight;
        if (gw == null) return true;
        return gw >= _weightMin && gw <= _weightMax;
      }).toList();
    }

    if (_priceMin > 0 || _priceMax < 5000000) {
      final goldRate = Get.find<GoldRateController>().currentRate;
      if (goldRate != null) {
        result = result.where((p) {
          final price = _calculatePrice(p, goldRate.rate);
          if (price == null) return true;
          return price >= _priceMin && price <= _priceMax;
        }).toList();
      }
    }

    if (_selectedSizes.isNotEmpty) {
      result = result.where((p) {
        final s = p.size;
        if (s == null) return false;
        return _selectedSizes.contains(s);
      }).toList();
    }

    return result;
  }

  double? _calculatePrice(ProductModel product, double ratePer10Gram) {
    if (product.fineWeight == null) return null;
    return GoldRateController.calculatePrice(
      fineWeight:
          product.karigarNetWt ?? 0,
      ratePer10Gram: ratePer10Gram,
    );
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

  Widget _buildAppBarTitleWidget(BuildContext context) {
    final title = widget.title ?? '${widget.karat} Collection';
    return Text(
      title,
      style: GoogleFonts.bodoniModa(
        fontWeight: FontWeight.w700,
        color: context.colorPalette.goldDeep,
        fontSize: context.responsiveFont(18, largeTabletMultiplier: 1.8),
      ),
    );
  }

  String? get _karatPurityLabel {
    final karatLabel =
        widget.karat ??
        (widget.karats != null && widget.karats!.isNotEmpty
            ? widget.karats!.join(', ')
            : null);
    if (karatLabel == null) return null;
    final purity = _purityForKarat(karatLabel);
    if (purity == null) return null;
    return '$karatLabel · $purity%';
  }

  String? _purityForKarat(String karat) {
    if (karat.contains('18')) return '76';
    if (karat.contains('20')) return '84';
    if (karat.contains('22')) return '92';
    return null;
  }

  void _showFilterSheet(BuildContext context) {
    final categoryModels = _isMultiCategory
        ? (widget.categoryNames ?? {}).entries.map((e) => CategoryModel(
              id: e.key,
              name: e.value,
              nameSlug: e.value.toLowerCase().replaceAll(' ', '-'),
              imageUrl: '',
              isDeleted: false,
            )).toList()
        : <CategoryModel>[];

    FilterBottomSheet.show(
      context,
      initialSelectedKarats: const [],
      initialStockFilter: _stockFilter,
      initialWeightMin: _weightMin,
      initialWeightMax: _weightMax,
      initialPriceMin: _priceMin,
      initialPriceMax: _priceMax,
      showKaratFilter: false,
      showStockFilter: false,
      showWeightFilter: _hasWeightData,
      showPriceFilter: true,
      showCategoryFilter: _isMultiCategory,
      categories: categoryModels,
      initialSelectedCategoryIds: _filteredCategoryIds,
      weightSliderMax: _displayedWeightMax,
      products: _displayedProducts,
      priceSliderMax: 5000000,
      showSizeFilter: _displayedAvailableSizes.isNotEmpty,
      initialSelectedSizes: _selectedSizes,
      availableSizes: _displayedAvailableSizes,
      onApply:
          ({
            required List<String> karats,
            required List<String> categoryIds,
            required List<String> categoryNames,
            required String stockFilter,
            required double wMin,
            required double wMax,
            required double pMin,
            required double pMax,
            required List<String> sizes,
          }) {
            setState(() {
              _stockFilter = stockFilter;
              _weightMin = wMin;
              _weightMax = wMax;
              _priceMin = pMin;
              _priceMax = pMax;
              _selectedSizes = sizes;
              if (_isMultiCategory && categoryIds.isNotEmpty) {
                _filteredCategoryIds = categoryIds;
              }
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
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? context.colorPalette.gold.withValues(alpha: 0.08)
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
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
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

  // ── Selection bottom bar 
  Widget _buildSelectionBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
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
            onTap: _clearSelection,
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
              '${_selectedProductIds.length} selected',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: context.colorPalette.goldDeep,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _showShareOptionsDialog(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: context.colorPalette.goldDark,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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
  }

  // ── Share options dialog 
  void _showShareOptionsDialog(BuildContext context) {
    final selectedProducts = _getSelectedProducts();
    if (selectedProducts.isEmpty) return;

    final titleController = TextEditingController(
      text: widget.title ?? '${widget.karat ?? ''} Collection'.trim(),
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.of(ctx).padding.bottom + MediaQuery.of(ctx).viewInsets.bottom,
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
                'Share ${selectedProducts.length} product${selectedProducts.length == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: context.getResponsiveSize(4.5),
                  fontWeight: FontWeight.w700,
                  color: context.colorPalette.textColor,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  labelStyle: TextStyle(
                    color: context.colorPalette.subTitleColor,
                  ),
                  hintText: 'e.g. New Collection 2024',
                  hintStyle: TextStyle(
                    color: context.colorPalette.subTitleColor.withValues(alpha: 0.5),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: context.colorPalette.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: context.colorPalette.gold,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                style: TextStyle(
                  fontSize: context.getResponsiveSize(3.5),
                  color: context.colorPalette.textColor,
                ),
              ),
              const SizedBox(height: 16),
              _shareOptionTile(
                ctx,
                icon: Icons.image_outlined,
                iconColor: const Color(0xFF25D366),
                title: 'Share Images',
                subtitle: 'Send product images directly',
                onTap: () {
                  Navigator.pop(ctx);
                  _shareAsImages(context, titleController.text.trim());
                },
              ),
              const SizedBox(height: 10),
              _shareOptionTile(
                ctx,
                icon: Icons.picture_as_pdf_outlined,
                iconColor: const Color(0xFFE53935),
                title: 'Share as PDF',
                subtitle: 'Create a branded product catalog',
                onTap: () {
                  Navigator.pop(ctx);
                  _showProductsPerPageDialog(context, titleController.text.trim());
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _showProductsPerPageDialog(BuildContext context, String title) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ShareProductsPerPageSheet(
        onSelected: (productsPerPage) {
          Navigator.pop(ctx);
          _shareAsPdf(context, title, productsPerPage: productsPerPage);
        },
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
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(context.getResponsiveSize(3.5)),
        decoration: BoxDecoration(
          color: context.colorPalette.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.colorPalette.border),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(context.getResponsiveSize(2)),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: context.getResponsiveSize(5.5),
              ),
            ),
            SizedBox(width: context.getResponsiveSize(3)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: context.getResponsiveSize(3.8),
                      fontWeight: FontWeight.w600,
                      color: context.colorPalette.textColor,
                    ),
                  ),
                  SizedBox(height: context.getScreenHeight(0.2)),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: context.getResponsiveSize(2.8),
                      color: context.colorPalette.subTitleColor,
                    ),
                  ),
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
  }

  List<ProductModel> _getSelectedProducts() {
    final allProducts = _isMultiCategory
        ? _controller.categoryProducts
        : _isCategoryOnly
        ? _controller.categoryProducts
        : _isCategoryFilter
        ? _controller.filteredProducts
        : _controller.karatProducts;
    return allProducts
        .where((p) => _selectedProductIds.contains(p.id))
        .toList();
  }

  void _shareAsImages(BuildContext context, String title) {
    final products = _getSelectedProducts();
    if (products.isEmpty) return;

    final cancelled = ValueNotifier(false);

    _showLoadingDialog(context, 'Preparing images...', onCancel: () {
      cancelled.value = true;
    });

    ShareService.shareImagesDirectly(
      products: products,
      filterInfo: title.isNotEmpty ? title : 'Products',
      title: title.isNotEmpty ? title : null,
      cancelled: cancelled,
    ).whenComplete(() {
      if (mounted && !cancelled.value) Navigator.of(context).pop();
      if (!cancelled.value) _clearSelection();
    });
  }

  void _shareAsPdf(BuildContext context, String title, {int productsPerPage = 1}) {
    final products = _getSelectedProducts();
    if (products.isEmpty) return;

    final cancelled = ValueNotifier(false);

    _showLoadingDialog(context, 'Generating PDF...', onCancel: () {
      cancelled.value = true;
    });

    ShareService.shareAsPdf(
      products: products,
      filterInfo: title.isNotEmpty ? title : 'Products',
      title: title.isNotEmpty ? title : null,
      productsPerPage: productsPerPage,
      cancelled: cancelled,
    ).whenComplete(() {
      if (mounted && !cancelled.value) Navigator.of(context).pop();
      if (!cancelled.value) _clearSelection();
    });
  }

  void _showLoadingDialog(BuildContext context, String message, {VoidCallback? onCancel}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: EdgeInsets.all(context.getResponsiveSize(6)),
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
                    fontSize: context.getResponsiveSize(3.5),
                    fontWeight: FontWeight.w500,
                    color: context.colorPalette.textColor,
                  ),
                ),
                if (onCancel != null) ...[
                  SizedBox(height: context.getScreenHeight(2)),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      onCancel();
                    },
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: context.getResponsiveSize(3.2),
                        fontWeight: FontWeight.w600,
                        color: context.colorPalette.subTitleColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _shimmerCard(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: context.colorPalette.shimmerBaseColor,
      highlightColor: context.colorPalette.shimmerHighLightColor,
      child: Container(
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
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(context.getResponsiveSize(2)),
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
                      width: context.getResponsiveSize(20),
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
    );
  }

  Widget _shimmerListTile(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: context.colorPalette.shimmerBaseColor,
      highlightColor: context.colorPalette.shimmerHighLightColor,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: context.responsiveWidth(16),
          vertical: context.responsiveWidth(4),
        ),
        padding: EdgeInsets.all(context.responsiveWidth(12)),
        decoration: BoxDecoration(
          color: context.colorPalette.shimmerBaseColor,
          borderRadius: BorderRadius.circular(context.responsiveWidth(8)),
        ),
        child: Row(
          children: [
            Container(
              width: context.responsiveWidth(60),
              height: context.responsiveWidth(60),
              decoration: BoxDecoration(
                color: context.colorPalette.shimmerHighLightColor,
                borderRadius: BorderRadius.circular(context.responsiveWidth(8)),
              ),
            ),
            SizedBox(width: context.responsiveWidth(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: context.getScreenHeight(1.2),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: context.colorPalette.shimmerHighLightColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(height: context.getScreenHeight(0.8)),
                  Container(
                    height: context.getScreenHeight(1),
                    width: context.responsiveWidth(80),
                    decoration: BoxDecoration(
                      color: context.colorPalette.shimmerHighLightColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
