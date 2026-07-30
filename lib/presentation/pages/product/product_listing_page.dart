import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ratnesh_gold_app/core/constants/karat_constants.dart';
import 'package:ratnesh_gold_app/core/services/share_service.dart';
import 'package:ratnesh_gold_app/core/utils/string_utils.dart';
import 'package:ratnesh_gold_app/presentation/controllers/CategoryController.dart';
import 'package:ratnesh_gold_app/presentation/pages/share/widgets/share_products_per_page_sheet.dart';
import 'package:ratnesh_gold_app/core/widgets/custom_divider.dart';
import 'package:ratnesh_gold_app/core/widgets/filter_bottom_sheet.dart';
import 'package:ratnesh_gold_app/core/widgets/pdf_loading_dialog.dart';
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
    this.startInSelectMode = true,
  });

  @override
  State<ProductListingPage> createState() => _ProductListingPageState();
}

class _ProductListingPageState extends State<ProductListingPage> {
  late final SearchProductController _controller;
  final ScrollController _scrollController = ScrollController();

  String _stockFilter = 'ready';
  int? _approvalFilter;
  double _weightMin = 0;
  double _weightMax = 500;
  double _priceMin = 0;
  double _priceMax = 5000000;
  List<String> _selectedSizes = [];
  bool? _isActiveFilter;

  // ── Selection state
  final Set<String> _selectedProductIds = {};
  bool _isSelectModeEnabled = false;
  bool get _isSelectMode => _isSelectModeEnabled || _selectedProductIds.isNotEmpty;
  bool get _isAdmin => Get.find<AuthController>().isAdmin;
  bool get _isRetailer => Get.find<AuthController>().user?.isRetailer == true;

  bool _isLoadingMore = false;
  static const int _shimmerLoadMoreCount = 4;
  static const int _initialShimmerGridCount = 6;
  static const int _initialShimmerListCount = 4;

  late String _selectedKarat;
  List<String> _filteredCategoryIds = [];

  void _toggleSelection(String productId) {
    setState(() {
      _clearCategoryCaches();
      if (_selectedProductIds.contains(productId)) {
        _selectedProductIds.remove(productId);
      } else {
        _selectedProductIds.add(productId);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _clearCategoryCaches();
      _isSelectModeEnabled = false;
      _selectedProductIds.clear();
    });
  }

  Map<String, List<ProductModel>>? _cachedPurityCategoryGroups;
  Map<String, List<ProductModel>> get _purityCategoryGroups {
    if (_cachedPurityCategoryGroups != null) return _cachedPurityCategoryGroups!;
    final groups = <String, List<ProductModel>>{};
    final categoryController = Get.find<CategoryController>();

    for (final product in _displayedProducts) {
      final categoryId = product.category?.id;
      String? purity;

      if (categoryId != null) {
        final karat = categoryController.getLevel3Karat(categoryId);
        if (karat != null) {
          final touchValue = KaratConstants.touchValueFor(karat);
          purity = touchValue.toString();
        }
      }

      purity ??= product.karatNumber != null
          ? KaratConstants.touchValueFor('${product.karatNumber}K').toString()
          : '??';

      final categoryName = cleanCategoryName(
          product.category?.name ?? '').toUpperCase().isEmpty
          ? 'OTHER'
          : cleanCategoryName(product.category?.name ?? '').toUpperCase();
      final key = '$purity $categoryName';
      groups.putIfAbsent(key, () => []).add(product);
    }
    return _cachedPurityCategoryGroups = groups;
  }

  Map<String, ({int selected, int total})>? _cachedCategorySelectionBreakdown;
  Map<String, ({int selected, int total})> get _categorySelectionBreakdown {
    if (_cachedCategorySelectionBreakdown != null) return _cachedCategorySelectionBreakdown!;
    final breakdown = <String, ({int selected, int total})>{};
    for (final entry in _purityCategoryGroups.entries) {
      final selected = entry.value
          .where((p) => _selectedProductIds.contains(p.id))
          .length;
      breakdown[entry.key] = (selected: selected, total: entry.value.length);
    }
    return _cachedCategorySelectionBreakdown = breakdown;
  }

  void _clearCategoryCaches() {
    _cachedPurityCategoryGroups = null;
    _cachedCategorySelectionBreakdown = null;
  }

  void _toggleGroupSelection(String groupKey) {
    final products = _purityCategoryGroups[groupKey];
    if (products == null || products.isEmpty) return;
    final allSelected = products.every((p) => _selectedProductIds.contains(p.id));
    setState(() {
      _clearCategoryCaches();
      if (allSelected) {
        for (final p in products) {
          _selectedProductIds.remove(p.id);
        }
      } else {
        for (final p in products) {
          _selectedProductIds.add(p.id);
        }
      }
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

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    if (!_hasMore || _currentStockState == CurrentAppState.LOADING) return;
    setState(() => _isLoadingMore = true);
    final stockFilter = _stockFilter;
    final approvalFilter = _stockFilter == 'ready' ? _approvalFilter : null;
    if (_isMultiCategory) {
      _controller.loadMoreMultipleCategories(stockFilter: stockFilter, approvalFilter: approvalFilter);
    } else if (_isCategoryFilter) {
      _controller.loadMoreFilteredProducts(stockFilter: stockFilter, approvalFilter: approvalFilter);
    } else {
      _controller.loadMoreKaratProducts(stockFilter: stockFilter, approvalFilter: approvalFilter);
    }
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted && _currentStockState == CurrentAppState.LOADING) {
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _onRefresh() async {
    _clearCategoryCaches();
    final approvalFilter = _stockFilter == 'ready' ? _approvalFilter : null;
    if (_isMultiCategory) {
      await Future.wait([
        _controller.loadProductsByMultipleCategories(widget.categoryIds!, stockFilter: 'ready', approvalFilter: approvalFilter),
        _controller.loadProductsByMultipleCategories(widget.categoryIds!, stockFilter: 'out'),
        _controller.loadProductsByMultipleCategories(widget.categoryIds!, stockFilter: 'all'),
      ]);
    } else if (_isCategoryFilter && _hasKarat) {
      await Future.wait([
        _controller.loadByCategoryWithKaratFilter(widget.categoryId!, widget.karat!, stockFilter: 'ready', approvalFilter: approvalFilter),
        _controller.loadByCategoryWithKaratFilter(widget.categoryId!, widget.karat!, stockFilter: 'out'),
        _controller.loadByCategoryWithKaratFilter(widget.categoryId!, widget.karat!, stockFilter: 'all'),
      ]);
    } else if (_isCategoryFilter) {
      await Future.wait([
        _controller.loadProductsByCategory(widget.categoryId!, stockFilter: 'ready', approvalFilter: approvalFilter),
        _controller.loadProductsByCategory(widget.categoryId!, stockFilter: 'out'),
        _controller.loadProductsByCategory(widget.categoryId!, stockFilter: 'all'),
      ]);
    } else {
      final karatsToLoad =
          widget.karats ??
          (widget.karat != null ? [widget.karat!] : <String>[]);
      await Future.wait([
        _controller.loadProductsByKarats(karatsToLoad, stockFilter: 'ready', approvalFilter: approvalFilter),
        _controller.loadProductsByKarats(karatsToLoad, stockFilter: 'out'),
        _controller.loadProductsByKarats(karatsToLoad, stockFilter: 'all'),
      ]);
    }
  }

  List<ProductModel> get _displayedProducts {
    List<ProductModel> base;
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
    if (!_isAdmin) {
      base = base.where((p) => p.isActive).toList();
    } else if (_isActiveFilter != null) {
      base = base.where((p) => p.isActive == _isActiveFilter).toList();
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
      final targetKarats = _selectedKarat
          .split(',')
          .map((k) => int.tryParse(k.trim().replaceAll(RegExp(r'[^0-9]'), '')))
          .whereType<int>()
          .toList();
      if (targetKarats.isNotEmpty) {
        result = result.where((p) => targetKarats.contains(p.karatNumber)).toList();
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

    if (widget.startInSelectMode && _isMultiCategory && _isAdmin) {
      _isSelectModeEnabled = true;
    }

    _selectedKarat = widget.karat ??
        (_isMultiCategory
            ? (widget.karats != null && widget.karats!.isNotEmpty
                ? widget.karats!.join(', ')
                : '')
            : '22K');

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

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      if (_hasMore && !_isLoadingMore && !(_isCategoryOnly && !_isMultiCategory)) {
        _loadMore();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
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
          if (_karatPurityLabel != null && !_isMultiCategory)
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
                if (layoutType == LayoutType.list) {
                  return ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: context.responsiveWidth(8, largeTabletVal: 16)),
                    itemCount: _initialShimmerListCount,
                    itemBuilder: (_, index) => _shimmerListTile(context),
                  );
                }
                final gridCrossCount = layoutType == LayoutType.fullScreen
                    ? 1
                    : MediaQuery.of(context).size.width >= 1000
                        ? 3
                        : context.gridColumns(phone: 2, tablet: 3);
                final gridAspectRatio = layoutType == LayoutType.fullScreen
                    ? (MediaQuery.of(context).size.width >= 1000
                        ? 0.7
                        : MediaQuery.of(context).size.width >= 600
                            ? 0.68
                            : 0.65)
                    : (MediaQuery.of(context).size.width >= 1000
                        ? 0.62
                        : MediaQuery.of(context).size.width >= 600
                            ? 0.55
                            : 0.488);
                return CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: gridCrossCount,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: gridAspectRatio,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (_, index) => _shimmerCard(context),
                          childCount: _initialShimmerGridCount,
                        ),
                      ),
                    ),
                  ],
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
                        onPressed: () {
                          final approvalFilter = _stockFilter == 'ready' ? _approvalFilter : null;
                          if (_isMultiCategory) {
                            _controller.loadProductsByMultipleCategories(widget.categoryIds!, stockFilter: 'ready', approvalFilter: approvalFilter);
                            _controller.loadProductsByMultipleCategories(widget.categoryIds!, stockFilter: 'out');
                            _controller.loadProductsByMultipleCategories(widget.categoryIds!, stockFilter: 'all');
                          } else if (_isCategoryOnly) {
                            _controller.loadProductsByCategory(widget.categoryId!, stockFilter: 'ready', approvalFilter: approvalFilter);
                            _controller.loadProductsByCategory(widget.categoryId!, stockFilter: 'out');
                            _controller.loadProductsByCategory(widget.categoryId!, stockFilter: 'all');
                          } else if (_isCategoryFilter) {
                            _controller.loadByCategoryWithKaratFilter(widget.categoryId!, widget.karat!, stockFilter: 'ready', approvalFilter: approvalFilter);
                            _controller.loadByCategoryWithKaratFilter(widget.categoryId!, widget.karat!, stockFilter: 'out');
                            _controller.loadByCategoryWithKaratFilter(widget.categoryId!, widget.karat!, stockFilter: 'all');
                          } else {
                            final karatsToLoad =
                                widget.karats ??
                                (widget.karat != null
                                    ? [widget.karat!]
                                    : <String>[]);
                            _controller.loadProductsByKarats(karatsToLoad, stockFilter: 'ready', approvalFilter: approvalFilter);
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
                return RefreshIndicator(
                  color: context.colorPalette.gold,
                  onRefresh: _onRefresh,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(vertical: context.responsiveWidth(8, largeTabletVal: 16)),
                    itemCount: products.length + shimmerCount,
                    itemBuilder: (_, index) {
                      if (_isLoadingMore && index >= products.length) {
                        return _shimmerListTile(context);
                      }
                      final product = products[index];
                      return ProductListTile(
                        key: ValueKey(product.id),
                        product: product,
                        isSelected: _selectedProductIds.contains(product.id),
                        isSelectMode: _isSelectMode,
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
                  ),
                );
              }

              if (layoutType == LayoutType.fullScreen) {
                return RefreshIndicator(
                  color: context.colorPalette.gold,
                  onRefresh: _onRefresh,
                  child: CustomScrollView(
                    controller: _scrollController,
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
                              isSelectMode: _isSelectMode,
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
                  ],
                  ),
                );
              }

              return RefreshIndicator(
                color: context.colorPalette.gold,
                onRefresh: _onRefresh,
                child: CustomScrollView(
                controller: _scrollController,
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
                            isSelectMode: _isSelectMode,
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
                ],
                ),
              );
            }),
          ),
        ],
      ),
      bottomNavigationBar: _isSelectMode ? _buildSelectionBar(context) : null,
    );
  }

  Widget _buildSortLayoutBar(BuildContext context) {
    return Obx(() {
      final currentSort = _controller.sortBy;
      final layoutType = _controller.layoutType;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_isMultiCategory) ...[
            SizedBox(height: context.responsiveWidth(8)),
            const CategoryDivider(vertical: 4),
            SizedBox(height: context.responsiveWidth(4)),
          ],
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
          if (_stockFilter == 'ready') ...[
            SizedBox(height: context.responsiveWidth(6)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.responsiveWidth(16)),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildApprovalChip('All', null, context),
                    SizedBox(width: context.responsiveWidth(6)),
                    _buildApprovalChip('Approved', 1, context),
                    SizedBox(width: context.responsiveWidth(6)),
                    _buildApprovalChip('Not Approved', 0, context),
                  ],
                ),
              ),
            ),
          ],
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
            if (value != 'ready') _approvalFilter = null;
          });
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(0);
          }
          _reloadStockFilter(value);
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

  Widget _buildApprovalChip(
    String label,
    int? value,
    BuildContext context,
  ) {
    final isSelected = _approvalFilter == value;
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          setState(() {
            _approvalFilter = value;
          });
          _reloadWithApprovalFilter(value);
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.responsiveWidth(8, largeTabletVal: 14),
          vertical: context.responsiveWidth(4, largeTabletVal: 8),
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? context.colorPalette.gold.withValues(alpha: 0.12)
              : context.colorPalette.cream,
          borderRadius: BorderRadius.circular(context.responsiveWidth(6, largeTabletVal: 10)),
          border: Border.all(
            color: isSelected
                ? context.colorPalette.gold
                : context.colorPalette.border.withValues(alpha: 0.6),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: context.responsiveFont(10, largeTabletMultiplier: 1.6),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? context.colorPalette.gold
                : context.colorPalette.goldDark.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  void _reloadWithApprovalFilter(int? approvalFilter) {
    if (_isMultiCategory) {
      _controller.loadProductsByMultipleCategories(widget.categoryIds!, stockFilter: _stockFilter, approvalFilter: approvalFilter);
    } else if (_isCategoryOnly) {
      _controller.loadProductsByCategory(widget.categoryId!, stockFilter: _stockFilter, approvalFilter: approvalFilter);
    } else if (_isCategoryFilter) {
      _controller.loadByCategoryWithKaratFilter(widget.categoryId!, widget.karat!, stockFilter: _stockFilter, approvalFilter: approvalFilter);
    } else {
      final karatsToLoad = widget.karats ?? (widget.karat != null ? [widget.karat!] : <String>[]);
      _controller.loadProductsByKarats(karatsToLoad, stockFilter: _stockFilter, approvalFilter: approvalFilter);
    }
  }

  void _reloadStockFilter(String stockFilter) {
    final approvalFilter = stockFilter == 'ready' ? _approvalFilter : null;
    if (_isMultiCategory) {
      _controller.loadProductsByMultipleCategories(widget.categoryIds!, stockFilter: stockFilter, approvalFilter: approvalFilter);
    } else if (_isCategoryOnly) {
      _controller.loadProductsByCategory(widget.categoryId!, stockFilter: stockFilter, approvalFilter: approvalFilter);
    } else if (_isCategoryFilter) {
      _controller.loadByCategoryWithKaratFilter(widget.categoryId!, widget.karat!, stockFilter: stockFilter, approvalFilter: approvalFilter);
    } else {
      final karatsToLoad = widget.karats ?? (widget.karat != null ? [widget.karat!] : <String>[]);
      _controller.loadProductsByKarats(karatsToLoad, stockFilter: stockFilter, approvalFilter: approvalFilter);
    }
  }

  bool get _hasActiveFilter =>
      _weightMin > 0 ||
      _weightMax < _displayedWeightMax ||
      _priceMin > 0 ||
      _priceMax < 5000000 ||
      _selectedSizes.isNotEmpty ||
      _isActiveFilter != null;

  int get _activeFilterCount {
    var count = 0;
    if (_weightMin > 0 || _weightMax < _displayedWeightMax) count++;
    if (_priceMin > 0 || _priceMax < 5000000) count++;
    count += _selectedSizes.length;
    if (_isActiveFilter != null) count++;
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

    if (karatLabel.contains(',')) {
      final parts = karatLabel.split(',').map((k) {
        final trimmed = k.trim();
        final purity = _purityForKarat(trimmed);
        return purity != null ? '$trimmed·$purity%' : trimmed;
      }).join(', ');
      return parts;
    }

    final purity = _purityForKarat(karatLabel);
    if (purity == null) return null;
    return '$karatLabel · $purity%';
  }

  String? _purityForKarat(String karat) {
    if (karat.isEmpty) return null;
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
      showPriceFilter: _isRetailer || _isAdmin,
      showCategoryFilter: _isMultiCategory,
      categories: categoryModels,
      initialSelectedCategoryIds: _filteredCategoryIds,
      weightSliderMax: _displayedWeightMax,
      products: _displayedProducts,
      priceSliderMax: 5000000,
      showSizeFilter: _displayedAvailableSizes.isNotEmpty,
      initialSelectedSizes: _selectedSizes,
      availableSizes: _displayedAvailableSizes,
      showIsActiveFilter: _isAdmin,
      initialIsActive: _isActiveFilter,
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
            bool? isActive,
          }) {
            setState(() {
              _stockFilter = stockFilter;
              _weightMin = wMin;
              _weightMax = wMax;
              _priceMin = pMin;
              _priceMax = pMax;
              _selectedSizes = sizes;
              _isActiveFilter = isActive;
              if (_isMultiCategory && categoryIds.isNotEmpty) {
                _filteredCategoryIds = categoryIds;
              }
            });
            if (_scrollController.hasClients) {
              _scrollController.jumpTo(0);
            }
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(() {
            _currentStockState;
            _clearCategoryCaches();
            return _buildCategoryBreakdownRow(context);
          }),
          Row(
            children: [
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
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdownRow(BuildContext context) {
    final breakdown = _categorySelectionBreakdown;
    if (breakdown.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: breakdown.entries.map((entry) {
            final groupKey = entry.key;
            final selected = entry.value.selected;
            final total = entry.value.total;
            final isGroupFullySelected = selected == total && total > 0;
            final isPartiallySelected = selected > 0 && selected < total;

            return GestureDetector(
              onTap: () => _toggleGroupSelection(groupKey),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isGroupFullySelected
                      ? context.colorPalette.gold.withValues(alpha: 0.12)
                      : isPartiallySelected
                          ? context.colorPalette.gold.withValues(alpha: 0.06)
                          : context.colorPalette.cardBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isGroupFullySelected
                        ? context.colorPalette.gold
                        : isPartiallySelected
                            ? context.colorPalette.gold.withValues(alpha: 0.5)
                            : context.colorPalette.border,
                    width: isGroupFullySelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isPartiallySelected)
                      Icon(
                        Icons.indeterminate_check_box_outlined,
                        size: 14,
                        color: context.colorPalette.gold.withValues(alpha: 0.7),
                      ),
                    if (isPartiallySelected) const SizedBox(width: 4),
                    Text(
                      '$groupKey $selected/$total',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isGroupFullySelected
                            ? FontWeight.w700
                            : isPartiallySelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                        color: isGroupFullySelected
                            ? context.colorPalette.gold
                            : isPartiallySelected
                                ? context.colorPalette.gold
                                : context.colorPalette.goldDark,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
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
    final compressNotifier = ValueNotifier(true);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ValueListenableBuilder<bool>(
        valueListenable: compressNotifier,
        builder: (ctx, compressImages, _) => Container(
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
              const SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(context.getResponsiveSize(3)),
                decoration: BoxDecoration(
                  color: context.colorPalette.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.colorPalette.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      compressImages ? Icons.compress_rounded : Icons.expand_rounded,
                      size: context.getResponsiveSize(5),
                      color: context.colorPalette.goldDeep,
                    ),
                    SizedBox(width: context.getResponsiveSize(2.5)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Compress images',
                            style: TextStyle(
                              fontSize: context.getResponsiveSize(3.5),
                              fontWeight: FontWeight.w600,
                              color: context.colorPalette.textColor,
                            ),
                          ),
                          SizedBox(height: context.heightPercent(0.15)),
                          Text(
                            compressImages
                                ? 'Smaller file size, but slower processing'
                                : 'Maximum quality, larger file size',
                            style: TextStyle(
                              fontSize: context.getResponsiveSize(2.8),
                              color: context.colorPalette.subTitleColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: compressImages,
                      onChanged: (value) => compressNotifier.value = value,
                      activeThumbColor: context.colorPalette.gold,
                      activeTrackColor: context.colorPalette.gold.withValues(alpha: 0.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _shareOptionTile(
                ctx,
                icon: Icons.image_outlined,
                iconColor: const Color(0xFF25D366),
                title: 'Share Images',
                subtitle: 'Send product images directly',
                onTap: () {
                  Navigator.pop(ctx);
                  _shareAsImages(context, titleController.text.trim(), compressImages: compressImages);
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
                  _showProductsPerPageDialog(context, titleController.text.trim(), compressImages: compressImages);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _showProductsPerPageDialog(BuildContext context, String title, {bool compressImages = true}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ShareProductsPerPageSheet(
        onSelected: (productsPerPage) {
          Navigator.pop(ctx);
          _shareAsPdf(context, title, productsPerPage: productsPerPage, compressImages: compressImages);
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
                  SizedBox(height: context.heightPercent(0.2)),
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
    return _displayedProducts
        .where((p) => _selectedProductIds.contains(p.id))
        .toList();
  }

  void _shareAsImages(BuildContext context, String title, {bool compressImages = true}) {
    final products = _getSelectedProducts();
    if (products.isEmpty) return;

    final cancelled = ValueNotifier(false);
    final progress = ValueNotifier(0.0);

    PdfLoadingDialog.show(context, message: 'Sharing images...', progress: progress, onCancel: () {
      cancelled.value = true;
    });

    ShareService.shareImagesDirectly(
      products: products,
      filterInfo: title.isNotEmpty ? title : 'Products',
      title: title.isNotEmpty ? title : null,
      compressImages: compressImages,
      cancelled: cancelled,
      progress: progress,
    ).whenComplete(() {
      if (mounted && !cancelled.value) Navigator.of(context).pop();
      if (!cancelled.value) _clearSelection();
      cancelled.dispose();
      progress.dispose();
    });
  }

  void _shareAsPdf(BuildContext context, String title, {int productsPerPage = 1, bool compressImages = true}) {
    final products = _getSelectedProducts();
    if (products.isEmpty) return;

    final cancelled = ValueNotifier(false);
    final progress = ValueNotifier(0.0);

    PdfLoadingDialog.show(context, message: 'Generating PDF...', progress: progress, onCancel: () {
      cancelled.value = true;
    });

    ShareService.shareAsPdf(
      products: products,
      filterInfo: title.isNotEmpty ? title : 'Products',
      title: title.isNotEmpty ? title : null,
      productsPerPage: productsPerPage,
      compressImages: compressImages,
      cancelled: cancelled,
      progress: progress,
    ).whenComplete(() {
      if (mounted && !cancelled.value) Navigator.of(context).pop();
      if (!cancelled.value) _clearSelection();
      cancelled.dispose();
      progress.dispose();
    });
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
                      height: context.heightPercent(1),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: context.colorPalette.shimmerHighLightColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    SizedBox(height: context.heightPercent(0.5)),
                    Container(
                      height: context.heightPercent(1),
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
                    height: context.heightPercent(1.2),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: context.colorPalette.shimmerHighLightColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(height: context.heightPercent(0.8)),
                  Container(
                    height: context.heightPercent(1),
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
