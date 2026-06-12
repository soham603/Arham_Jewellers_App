import 'package:ratnesh_gold_app/utils/ToastUtil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/core/widgets/ratnesh_fallback.dart';
import 'package:ratnesh_gold_app/core/widgets/category_picker_sheet.dart';
import 'package:ratnesh_gold_app/core/widgets/filter_bottom_sheet.dart';
import 'package:ratnesh_gold_app/core/widgets/search_bar_widget.dart';
import 'package:ratnesh_gold_app/domain/entities/category_model.dart';
import 'package:ratnesh_gold_app/presentation/controllers/CategoryController.dart';
import 'package:ratnesh_gold_app/presentation/controllers/navigation_controller.dart';
import 'package:ratnesh_gold_app/presentation/controllers/searchProductController.dart';
import 'package:ratnesh_gold_app/presentation/pages/product/product_details_page.dart';
import 'package:ratnesh_gold_app/presentation/pages/product/product_listing_page.dart';
import 'package:ratnesh_gold_app/presentation/pages/search/barcode_scanner_page.dart';
import 'package:ratnesh_gold_app/presentation/shimmers/categoryShimmer.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';
import 'package:ratnesh_gold_app/utils/fuzzy_match.dart';

class SearchPage extends StatefulWidget {
  final String? initialQuery;
  final String? initialCategoryId;
  final String? initialCategoryName;

  const SearchPage({
    super.key,
    this.initialQuery,
    this.initialCategoryId,
    this.initialCategoryName,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final SearchProductController controller = Get.put(SearchProductController());
  final CategoryController categoryController = Get.isRegistered<CategoryController>()
      ? Get.find<CategoryController>()
      : Get.put(CategoryController());
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  late final Worker _tabWorker;

  Set<SelectedCategory> _tempSelectedCategories = {};
  List<CategoryModel> _allCategories = [];
  Map<String, List<CategoryModel>> _categoryVariants = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // CategoryController fetches tree eagerly in onInit()
    // Just load local category variants from cached data
    _loadCategories();
    if (widget.initialCategoryId != null &&
        widget.initialCategoryId!.isNotEmpty &&
        widget.initialCategoryName != null &&
        widget.initialCategoryName!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          controller.applyFilters(
            karats: controller.selectedKarats,
            categoryIds: [widget.initialCategoryId!],
            categoryNames: [widget.initialCategoryName!],
            stockFilter: controller.stockFilter,
            wMin: controller.weightMin,
            wMax: controller.weightMax,
            pMin: controller.priceMin,
            pMax: controller.priceMax,
            sizes: controller.selectedSizes,
          );
        }
      });
    } else if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _textController.text = widget.initialQuery!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) controller.onSearchSubmitted(widget.initialQuery!);
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
          controller.ensureProductsLoaded();
        }
      });
    }

    final navController = Get.find<NavigationController>();
    _tabWorker = ever(navController.selectedIndex, (int index) {
      if (index == 1 && mounted && _textController.text.isEmpty) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _focusNode.requestFocus();
        });
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (controller.isSearching) {
        controller.loadMoreSearchResults();
      } else if (controller.hasActiveFilters) {
        controller.loadFilteredProducts(isPagination: true);
      }
    }
  }

  void _loadCategories() {
    final all = <CategoryModel>[
      ...categoryController.k18Categories,
      ...categoryController.k20Categories,
      ...categoryController.k22Categories,
    ];

    final variants = <String, List<CategoryModel>>{};
    for (final cat in all) {
      final key = cat.name.toLowerCase().trim();
      variants.putIfAbsent(key, () => []).add(cat);
    }

    setState(() {
      _categoryVariants = variants;
      _allCategories = variants.values.map((list) => list.first).toList();
    });
  }

  String _cleanCategoryName(String name) {
    return name
        .replaceAll(RegExp(r'[^a-zA-Z\s]'), '')
        .replaceAll(RegExp(r'collection', caseSensitive: false), '')
        .trim();
  }

  Set<String> _expandCategoryIds(List<String> selectedIds) {
    final cleanedSelected = <String>{};
    for (final id in selectedIds) {
      for (final entry in _categoryVariants.entries) {
        if (entry.value.any((c) => c.id == id)) {
          cleanedSelected.add(_cleanCategoryName(entry.key).toLowerCase());
          break;
        }
      }
    }
    if (cleanedSelected.isEmpty) return selectedIds.toSet();
    final expanded = <String>{};
    for (final entry in _categoryVariants.entries) {
      final cleanedKey = _cleanCategoryName(entry.key).toLowerCase();
      if (cleanedSelected.contains(cleanedKey)) {
        for (final cat in entry.value) {
          expanded.add(cat.id);
        }
      }
    }
    return expanded;
  }

  String? _getCategoryKarat(CategoryModel cat) {
    if (categoryController.k18Categories.any((c) => c.id == cat.id)) return '18K';
    if (categoryController.k20Categories.any((c) => c.id == cat.id)) return '20K';
    if (categoryController.k22Categories.any((c) => c.id == cat.id)) return '22K';
    return null;
  }

  String _getKaratPurity(String? karat) {
    switch (karat) {
      case '18K': return '76%';
      case '20K': return '84%';
      case '22K': return '92%';
      default: return '';
    }
  }

  @override
  void dispose() {
    _tabWorker.dispose();
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
            Obx(() => SearchBarWidget(
              controller: _textController,
              focusNode: _focusNode,
              autofocus: false,
              showScanner: true,
              onBack: () {
                if (_textController.text.isNotEmpty ||
                    controller.isSearching ||
                    controller.hasActiveFilters) {
                  _textController.clear();
                  controller.clearSearch();
                  controller.clearAllFilters();
                  controller.loadInitialProducts();
                  setState(() {});
                } else {
                  if (Get.previousRoute.isNotEmpty) {
                    Get.back();
                  } else {
                    Get.find<NavigationController>().switchTab(0);
                  }
                }
              },
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
                controller.clearSearch();
                setState(() {});
              },
              onFilterTap: () {
                _focusNode.unfocus();
                _loadCategories();
                FilterBottomSheet.show(
                  context,
                  initialSelectedKarats: controller.selectedKarats,
                  initialStockFilter: controller.stockFilter,
                  initialWeightMin: controller.weightMin,
                  initialWeightMax: controller.weightMax,
                  showKaratFilter: false,
                  showStockFilter: false,
                  showCategoryFilter: true,
                  showPriceFilter: false,
                  showWeightFilter: false,
                  weightSliderMax: controller.availableWeightMax,
                  products: controller.allProducts,
                  categories: _allCategories,
                  initialSelectedCategoryIds: controller.selectedCategoryIds,
                  onApply: controller.applyFilters,
                ).then((_) => setState(() {}));
              },
              onScannerTap: () async {
                _focusNode.unfocus();
                final barcode = await Get.to(() => BarcodeScannerPage(
                  onDetect: (barcode) async {
                    // The barcode scanner page will now close itself and return the value
                    // We don't need to do anything here since the page handles closing
                  },
                )) as String?;
                
                if (barcode == null) return;
                
                final product = await controller.searchByBarcode(barcode);
                if (!mounted) return;
                if (product != null) {
                  Get.to(() => ProductDetailsPage(product: product));
                } else {
                  ToastUtils.showError('No product found for barcode: $barcode');
                }
              },
              filterActiveCount: controller.activeFilterCount,
            ),
            ),
            _buildKaratRow(context),
            Obx(() {
              final categoryIds = controller.selectedCategoryIds;
              final categoryNames = controller.selectedCategoryNames;
              if (categoryIds.isEmpty) return const SizedBox.shrink();
              return Container(
                padding: EdgeInsets.fromLTRB(
                  context.getResponsiveSize(4),
                  context.getScreenHeight(0.4),
                  context.getResponsiveSize(4),
                  0,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (int i = 0; i < categoryNames.length; i++)
                          _activeFilterChip(
                            context,
                            label: categoryNames[i],
                            onRemove: () {
                              final newIds = List<String>.from(categoryIds);
                              final newNames = List<String>.from(categoryNames);
                              newIds.removeAt(i);
                              newNames.removeAt(i);
                              controller.applyFilters(
                                karats: controller.selectedKarats,
                                categoryIds: newIds,
                                categoryNames: newNames,
                                stockFilter: controller.stockFilter,
                                wMin: controller.weightMin,
                                wMax: controller.weightMax,
                                pMin: controller.priceMin,
                                pMax: controller.priceMax,
                                sizes: controller.selectedSizes,
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            SizedBox(height: context.getScreenHeight(0.6)),
            Expanded(
              child: Obx(() {
                final isSearching = controller.isSearching;
                controller.sortByObs.value;

                return CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    // ── Latest Level-3 Categories 
                    if (!isSearching &&
                        !controller.hasActiveFilters &&
                        controller.searchResults.isEmpty)
                      _latestLevel3CategoriesSliver(context),

                    // ── Recent Searches 
                    if (!isSearching &&
                        !controller.hasActiveFilters &&
                        controller.recentSearches.isNotEmpty)
                      _recentSearchesSliver(context),

                    // ── Browse Categories 
                    if (!isSearching &&
                        !controller.hasActiveFilters &&
                        controller.searchResults.isEmpty)
                      _browseCategoriesSliver(context),

                    // ── Section Header 
                    if (isSearching || controller.hasActiveFilters)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            context.getResponsiveSize(4),
                            context.getScreenHeight(0.4),
                            context.getResponsiveSize(4),
                            context.getScreenHeight(0.8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Results ($_filteredCategoryCount)',
                                    style: TextStyle(
                                      fontSize: context.getResponsiveSize(4.2),
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF675F55),
                                    ),
                                  ),
                                ],
                              ),
                              Obx(() {
                                final currentSort = controller.sortBy;
                                return GestureDetector(
                                  onTap: () => _showSortSheet(context),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: context.responsiveWidth(10, tabletVal: 16),
                                      vertical: context.responsiveWidth(6, tabletVal: 10),
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(context.responsiveWidth(8, tabletVal: 12)),
                                      border: Border.all(color: context.colorPalette.border),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.sort_rounded,
                                          size: context.responsiveWidth(18, tabletVal: 24),
                                          color: context.colorPalette.goldDark,
                                        ),
                                        SizedBox(width: context.responsiveWidth(6, tabletVal: 10)),
                                        Text(
                                          currentSort.label,
                                          style: TextStyle(
                                            fontSize: context.responsiveWidth(12, tabletVal: 16),
                                            fontWeight: FontWeight.w500,
                                            color: context.colorPalette.goldDark,
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
                      ),

                    // ── Category Results 
                    if (isSearching || controller.hasActiveFilters)
                      _level3CategoryResultsSliver(context),

                    SliverToBoxAdapter(
                      child: SizedBox(height: context.getScreenHeight(2)),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
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
        context.getScreenHeight(0.4),
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
        if (controller.isSearching) {
          controller.applyFilters(
            karats: controller.selectedKarats,
            categoryIds: controller.selectedCategoryIds,
            categoryNames: controller.selectedCategoryNames,
            stockFilter: controller.stockFilter,
            wMin: controller.weightMin,
            wMax: controller.weightMax,
            pMin: controller.priceMin,
            pMax: controller.priceMax,
            sizes: controller.selectedSizes,
          );
        } else if (controller.hasActiveFilters) {
          controller.loadFilteredProducts();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: context.getResponsiveSize(2),
          vertical: context.getScreenHeight(0.8),
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

  Widget _buildCategoriesFilter(BuildContext context) {
    return Obx(() {
      final categoryIds = controller.selectedCategoryIds;
      final categoryNames = controller.selectedCategoryNames;
      final hasCategories = categoryIds.isNotEmpty;

      return Container(
        padding: EdgeInsets.fromLTRB(
          context.getResponsiveSize(4),
          0,
          context.getResponsiveSize(4),
          0,
        ),
        child: Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    _focusNode.unfocus();
                    CategoryPickerSheet.show(
                      context,
                      categories: _allCategories,
                      categoryVariants: _categoryVariants,
                      categoryController: categoryController,
                      selectedCategories: _tempSelectedCategories,
                      cleanName: _cleanCategoryName,
                      onSelectionChanged: (updated) {
                        setState(() {
                          _tempSelectedCategories = updated;
                        });
                      },
                      onClear: () {
                        setState(() {
                          _tempSelectedCategories.clear();
                        });
                        Navigator.pop(context);
                      },
                    ).then((_) {
                      final newIds = _tempSelectedCategories.map((c) => c.id).toList();
                      final newNames = _tempSelectedCategories.map((c) => c.displayName).toList();
                      controller.applyFilters(
                        karats: controller.selectedKarats,
                        categoryIds: newIds,
                        categoryNames: newNames,
                        stockFilter: controller.stockFilter,
                        wMin: controller.weightMin,
                        wMax: controller.weightMax,
                        pMin: controller.priceMin,
                        pMax: controller.priceMax,
                        sizes: controller.selectedSizes,
                      );
                      setState(() {});
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: hasCategories
                          ? context.colorPalette.gold
                          : context.colorPalette.cardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: hasCategories
                            ? context.colorPalette.gold
                            : context.colorPalette.border,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add,
                          size: 14,
                          color: hasCategories
                              ? Colors.white
                              : context.colorPalette.goldDark,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          hasCategories
                              ? '${categoryNames.length} Categories'
                              : 'Categories',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: hasCategories
                                ? Colors.white
                                : context.colorPalette.goldDeep,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (hasCategories) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final name in categoryNames)
                            _activeFilterChip(
                              context,
                              label: name,
                              onRemove: () {
                                final idx = categoryNames.indexOf(name);
                                final newIds = List<String>.from(categoryIds);
                                final newNames = List<String>.from(categoryNames);
                                if (idx != -1) {
                                  newIds.removeAt(idx);
                                  newNames.removeAt(idx);
                                }
                                controller.applyFilters(
                                  karats: controller.selectedKarats,
                                  categoryIds: newIds,
                                  categoryNames: newNames,
                                  stockFilter: controller.stockFilter,
                                  wMin: controller.weightMin,
                                  wMax: controller.weightMax,
                                  pMin: controller.priceMin,
                                  pMax: controller.priceMax,
                                  sizes: controller.selectedSizes,
                                );
                                setState(() {
                                  _tempSelectedCategories.removeWhere((c) => c.id == categoryIds[idx]);
                                });
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
                      controller.loadInitialProducts();
                      setState(() {
                        _tempSelectedCategories.clear();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
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
                            size: context.getResponsiveSize(3),
                            color: context.colorPalette.goldDark,
                          ),
                          SizedBox(width: context.getResponsiveSize(0.8)),
                          Text(
                            'Clear',
                            style: TextStyle(
                              fontSize: context.getResponsiveSize(2.8),
                              fontWeight: FontWeight.w500,
                              color: context.colorPalette.goldDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
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
      margin: EdgeInsets.only(right: context.responsiveWidth(6, tabletVal: 10)),
      padding: EdgeInsets.symmetric(horizontal: context.responsiveWidth(10, tabletVal: 16), vertical: context.responsiveWidth(4, tabletVal: 8)),
      decoration: BoxDecoration(
        color: context.colorPalette.gold,
        borderRadius: BorderRadius.circular(context.responsiveWidth(10, tabletVal: 14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: context.responsiveWidth(11, tabletVal: 16),
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(width: context.responsiveWidth(4, tabletVal: 8)),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: context.responsiveWidth(12, tabletVal: 18), color: Colors.white),
          ),
        ],
      ),
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
            ...[SortOption.newest, SortOption.oldest]
                .map((option) {
              final isSelected = controller.sortBy == option;
              return GestureDetector(
                onTap: () {
                  controller.setSortOption(option);
                  Navigator.pop(ctx);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
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

  // ── Browse Categories Sliver 
  Widget _browseCategoriesSliver(BuildContext context) {
    return SliverToBoxAdapter(
      child: Obx(() {
        final allCategories = [
          ...categoryController.k18Categories,
          ...categoryController.k20Categories,
          ...categoryController.k22Categories,
        ];

        final seen = <String>{};
        final unique = <CategoryModel>[];
        for (final cat in allCategories) {
          final displayName = cat.name
              .replaceAll(RegExp(r'[^a-zA-Z\s]'), '')
              .replaceAll(RegExp(r'collection', caseSensitive: false), '')
              .trim()
              .toLowerCase();
          if (seen.add(displayName)) {
            unique.add(cat);
          }
        }

        if (unique.isEmpty &&
            categoryController.k18State == CurrentAppState.LOADING) {
          return Padding(
            padding: EdgeInsets.only(top: context.getScreenHeight(1)),
            child: const CategoryShimmer(),
          );
        }

        if (unique.isEmpty) return const SizedBox();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.getResponsiveSize(4),
                context.getScreenHeight(1.5),
                context.getResponsiveSize(4),
                context.getScreenHeight(0.8),
              ),
              child: Text(
                'Browse Categories',
                style: TextStyle(
                  fontSize: context.responsiveWidth(16, tabletVal: 22, largeTabletVal: 28),
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF675F55),
                ),
              ),
            ),
            SizedBox(height: context.getScreenHeight(0.6)),
            SizedBox(
              height: context.responsiveWidth(100, tabletVal: 140, largeTabletVal: 185),
              child: ListView.separated(
                padding: EdgeInsets.only(left: context.getResponsiveSize(4)),
                scrollDirection: Axis.horizontal,
                itemCount: unique.length,
                separatorBuilder: (_, _) => SizedBox(width: context.responsiveWidth(4, tabletVal: 8, largeTabletVal: 12)),
                itemBuilder: (_, index) {
                  final cat = unique[index];
                  final cleanedName = cat.name
                      .replaceAll(RegExp(r'[^a-zA-Z\s]'), '')
                      .replaceAll(RegExp(r'collection', caseSensitive: false), '')
                      .trim();
                  return GestureDetector(
                    onTap: () {
                      _focusNode.unfocus();
                      controller.applyFilters(
                        karats: controller.selectedKarats,
                        categoryIds: [cat.id],
                        categoryNames: [cleanedName],
                        stockFilter: controller.stockFilter,
                        wMin: controller.weightMin,
                        wMax: controller.weightMax,
                        pMin: controller.priceMin,
                        pMax: controller.priceMax,
                        sizes: controller.selectedSizes,
                      );
                      setState(() {});
                    },
                    child: Column(
                      children: [
                        Container(
                          width: context.responsiveWidth(60, tabletVal: 80, largeTabletVal: 115),
                          height: context.responsiveWidth(60, tabletVal: 80, largeTabletVal: 115),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: context.colorPalette.gold.withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                          ),
                          child: ClipOval(
                            child: _BrowseCategoryImage(
                              cat: cat,
                            ),
                          ),
                        ),
                        SizedBox(height: context.responsiveWidth(5, tabletVal: 8)),
                        SizedBox(
                          width: context.responsiveWidth(70, tabletVal: 100),
                          child: Text(
                            cleanedName,
                            style: TextStyle(
                              fontSize: context.responsiveWidth(10, tabletVal: 14),
                              fontWeight: FontWeight.w700,
                              color: context.colorPalette.goldDeep,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: context.getScreenHeight(0.5)),
              child: Divider(color: context.colorPalette.boxColor),
            ),
          ],
        );
      }),
    );
  }

  // ── Latest Level-3 Categories Sliver 
  Widget _latestLevel3CategoriesSliver(BuildContext context) {
    return SliverToBoxAdapter(
      child: Obx(() {
        final categories = categoryController.latestLevel3Categories;
        final state = categoryController.latestLevel3State;

        if (state == CurrentAppState.LOADING && categories.isEmpty) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              context.getResponsiveSize(4),
              context.getScreenHeight(1.5),
              context.getResponsiveSize(4),
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Latest Collections',
                  style: TextStyle(
                    fontSize: context.getResponsiveSize(4.2),
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF675F55),
                  ),
                ),
                SizedBox(height: context.getScreenHeight(0.8)),
                Wrap(
                  spacing: context.getResponsiveSize(2),
                  runSpacing: context.getScreenHeight(0.6),
                  children: List.generate(
                    6,
                    (_) => Container(
                      width: context.getResponsiveSize(22),
                      height: context.getScreenHeight(3.2),
                      decoration: BoxDecoration(
                        color: context.colorPalette.shimmerBaseColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (categories.isEmpty) return const SizedBox();

        return Padding(
          padding: EdgeInsets.fromLTRB(
            context.getResponsiveSize(4),
            context.getScreenHeight(1.5),
            context.getResponsiveSize(4),
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Latest Collections',
                style: TextStyle(
                  fontSize: context.getResponsiveSize(4.2),
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF675F55),
                ),
              ),
              SizedBox(height: context.getScreenHeight(0.8)),
              Wrap(
                spacing: context.getResponsiveSize(2),
                runSpacing: context.getScreenHeight(0.6),
                children: categories.map((cat) {
                  final cleanedName = cat.name
                      .replaceAll(RegExp(r'[^a-zA-Z\s]'), '')
                      .replaceAll(RegExp(r'collection', caseSensitive: false), '')
                      .trim();
                  String? karatName;
                  String? purityLabel;
                  if (categoryController.k18Categories.any((c) => c.id == cat.parentId)) {
                    karatName = '18K';
                    purityLabel = '76';
                  } else if (categoryController.k20Categories.any((c) => c.id == cat.parentId)) {
                    karatName = '20K';
                    purityLabel = '84';
                  } else if (categoryController.k22Categories.any((c) => c.id == cat.parentId)) {
                    karatName = '22K';
                    purityLabel = '92';
                  }
                  final displayName = purityLabel != null ? '$cleanedName — $purityLabel' : cleanedName;
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductListingPage(
                            categoryId: cat.id,
                            karat: karatName,
                            title: cleanedName,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.getResponsiveSize(3),
                        vertical: context.getScreenHeight(0.6),
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F1EC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFCFC7BC)),
                      ),
                      child: Text(
                        displayName,
                        style: TextStyle(
                          fontSize: context.getResponsiveSize(3),
                          color: context.colorPalette.textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: context.getScreenHeight(0.5)),
              Divider(color: context.colorPalette.boxColor),
            ],
          ),
        );
      }),
    );
  }

  // ── Recent Searches Sliver 
  SliverToBoxAdapter _recentSearchesSliver(BuildContext context) {
    final all = controller.recentSearches;
    final visible = all.take(5).toList();

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          context.getResponsiveSize(4),
          context.getScreenHeight(1.5),
          context.getResponsiveSize(4),
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Searches (${all.length})',
                  style: TextStyle(
                    fontSize: context.getResponsiveSize(4.2),
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF675F55),
                  ),
                ),
                if (all.length >= 3)
                  GestureDetector(
                    onTap: controller.clearAllRecentSearches,
                    child: Text(
                      'Clear all',
                      style: TextStyle(
                        fontSize: context.getResponsiveSize(3.2),
                        color: context.colorPalette.goldDark,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: context.getScreenHeight(0.8)),
            Wrap(
              spacing: context.getResponsiveSize(2),
              runSpacing: context.getScreenHeight(0.6),
              children: visible.map((term) => _buildSearchChip(context, term)).toList(),
            ),
            SizedBox(height: context.getScreenHeight(1)),
            Divider(color: context.colorPalette.boxColor),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchChip(BuildContext context, String term) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F1EC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCFC7BC)),
      ),
      child: InkWell(
        onTap: () {
          _textController.text = term;
          setState(() {});
          controller.onSearchSubmitted(term);
          _focusNode.unfocus();
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: EdgeInsets.only(
            left: context.getResponsiveSize(2.5),
            right: context.getResponsiveSize(1),
            top: context.getScreenHeight(0.45),
            bottom: context.getScreenHeight(0.45),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                term,
                style: TextStyle(
                  fontSize: context.getResponsiveSize(3.2),
                  color: context.colorPalette.textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: context.getResponsiveSize(1)),
              GestureDetector(
                onTap: () => controller.removeRecentSearch(term),
                child: Icon(
                  Icons.close_rounded,
                  size: context.getResponsiveSize(3.2),
                  color: const Color(0xFF8D847A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Level-3 Category Results Sliver 
  Widget _level3CategoryResultsSliver(BuildContext context) {
    final allCategories = categoryController.allLevel3Categories;
    final searchQuery = controller.searchQuery.toLowerCase().trim();
    final selectedKarats = controller.selectedKarats;

    var filtered = allCategories;

    if (searchQuery.isNotEmpty) {
      filtered = fuzzyFilter(
        searchQuery,
        filtered,
        (cat) => cat.name
            .replaceAll(RegExp(r'[^a-zA-Z\s]'), '')
            .replaceAll(RegExp(r'collection', caseSensitive: false), '')
            .trim(),
      );
    }

    if (selectedKarats.isNotEmpty) {
      filtered = filtered.where((cat) {
        final karat = categoryController.getLevel3Karat(cat.id);
        return karat != null && selectedKarats.contains(karat);
      }).toList();
    }

    if (controller.selectedCategoryIds.isNotEmpty) {
      final expandedIds = _expandCategoryIds(controller.selectedCategoryIds);
      filtered = filtered.where((cat) {
        return cat.parentId != null && expandedIds.contains(cat.parentId);
      }).toList();
    }

    if (categoryController.latestLevel3State == CurrentAppState.LOADING &&
        allCategories.isEmpty) {
      return SliverToBoxAdapter(child: _gridShimmer(context));
    }

    if (filtered.isEmpty) {
      return SliverToBoxAdapter(
        child: _emptyWidget(
          context,
          searchQuery.isNotEmpty
              ? 'No categories match "$searchQuery"'
              : 'No categories found',
        ),
      );
    }

    // When searching, results are already sorted by fuzzy score from fuzzyFilter.
    // Otherwise apply the chosen sort option.
    final sorted = searchQuery.isNotEmpty
        ? filtered
        : _sortCategories(filtered, controller.sortBy);

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: context.getResponsiveSize(4)),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final cat = sorted[index];
            final cleanedName = cat.name
                .replaceAll(RegExp(r'[^a-zA-Z\s]'), '')
                .replaceAll(RegExp(r'collection', caseSensitive: false), '')
                .trim();
            final karatName = categoryController.getLevel3Karat(cat.id);

            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 350 + (index.clamp(0, 9) * 70)),
              curve: Curves.easeOutCubic,
              tween: Tween<double>(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 24 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductListingPage(
                        categoryId: cat.id,
                        karat: karatName,
                        title: cleanedName,
                      ),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: context.colorPalette.cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.colorPalette.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(14),
                          ),
                          child: cat.imageUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: cat.imageUrl,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, _, _) =>
                                      RatneshFallback.m(),
                                )
                              : RatneshFallback.m(),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.getResponsiveSize(2),
                          vertical: context.getScreenHeight(0.3),
                        ),
                        child: ClipRect(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                cleanedName,
                                style: TextStyle(
                                  fontSize: context.getResponsiveSize(2.8),
                                  fontWeight: FontWeight.w600,
                                  color: context.colorPalette.textColor,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (karatName != null) ...[
                                SizedBox(height: context.getScreenHeight(0.1)),
                                Text(
                                  '$karatName • ${_getKaratPurity(karatName)}',
                                  style: TextStyle(
                                    fontSize: context.getResponsiveSize(2.2),
                                    fontWeight: FontWeight.w500,
                                    color: context.colorPalette.goldDark,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          childCount: sorted.length,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: context.gridColumns(phone: 2, tablet: 3),
          mainAxisSpacing: context.getResponsiveSize(2),
          crossAxisSpacing: context.getResponsiveSize(2),
          childAspectRatio: 0.75,
        ),
      ),
    );
  }

  int get _filteredCategoryCount {
    var filtered = categoryController.allLevel3Categories;
    final searchQuery = controller.searchQuery.toLowerCase().trim();
    final selectedKarats = controller.selectedKarats;

    if (searchQuery.isNotEmpty) {
      filtered = fuzzyFilter(
        searchQuery,
        filtered,
        (cat) => cat.name
            .replaceAll(RegExp(r'[^a-zA-Z\s]'), '')
            .replaceAll(RegExp(r'collection', caseSensitive: false), '')
            .trim(),
      );
    }

    if (selectedKarats.isNotEmpty) {
      filtered = filtered.where((cat) {
        final karat = categoryController.getLevel3Karat(cat.id);
        return karat != null && selectedKarats.contains(karat);
      }).toList();
    }

    if (controller.selectedCategoryIds.isNotEmpty) {
      final expandedIds = _expandCategoryIds(controller.selectedCategoryIds);
      filtered = filtered.where((cat) {
        return cat.parentId != null && expandedIds.contains(cat.parentId);
      }).toList();
    }

    return filtered.length;
  }

  List<CategoryModel> _sortCategories(
      List<CategoryModel> categories, SortOption sort) {
    final sorted = List<CategoryModel>.from(categories);
    switch (sort) {
      case SortOption.newest:
        sorted.sort((a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
        break;
      case SortOption.oldest:
        sorted.sort((a, b) =>
            (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)));
        break;
      default:
        sorted.sort((a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    }
    return sorted;
  }

  // ── Shimmer Placeholder ───
  Widget _gridShimmer(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.getResponsiveSize(4)),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: context.gridColumns(phone: 2, tablet: 3),
        mainAxisSpacing: context.getResponsiveSize(2),
        crossAxisSpacing: context.getResponsiveSize(2),
        childAspectRatio: context.isTablet ? 0.55 : 0.488,
      ),
        itemBuilder: (context, _) => _shimmerCard(context),
      ),
    );
  }

  Widget _shimmerCard(BuildContext context) {
    return Container(
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
    );
  }

  // ── Empty Widget 
  Widget _emptyWidget(BuildContext context, String message) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.getScreenHeight(6)),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: context.getResponsiveSize(12),
            color: const Color(0xFF8D847A),
          ),
          SizedBox(height: context.getScreenHeight(1.5)),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: context.getResponsiveSize(3.8),
              color: context.colorPalette.subTitleColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _BrowseCategoryImage extends StatelessWidget {
  final CategoryModel cat;

  const _BrowseCategoryImage({
    required this.cat,
  });

  @override
  Widget build(BuildContext context) {
    if (cat.imageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: cat.imageUrl,
        fit: BoxFit.cover,
        errorWidget: (_, _, _) => const RatneshFallback.xs(),
      );
    }

    return const RatneshFallback.xs();
  }
}
