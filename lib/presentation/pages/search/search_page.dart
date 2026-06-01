import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/core/widgets/app_bottom_nav.dart';
import 'package:ratnesh_gold_app/core/widgets/product_card.dart';
import 'package:ratnesh_gold_app/core/widgets/search_bar_widget.dart';
import 'package:ratnesh_gold_app/domain/entities/category_model.dart';
import 'package:ratnesh_gold_app/presentation/controllers/CategoryController.dart';
import 'package:ratnesh_gold_app/presentation/controllers/searchProductController.dart';
import 'package:ratnesh_gold_app/presentation/pages/product/product_details_page.dart';
import 'package:ratnesh_gold_app/presentation/shimmers/categoryShimmer.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (categoryController.k18Categories.isEmpty &&
        categoryController.k20Categories.isEmpty &&
        categoryController.k22Categories.isEmpty) {
      categoryController.fetchAllKaratCategories();
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (controller.isSearching) {
        controller.loadMoreSearchResults();
      } else {
        controller.loadInitialProducts(isPagination: true);
      }
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
              autofocus: true,
              onBack: () => Get.back(),
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
            ),
            Expanded(
              child: Obx(() {
                final isSearching = controller.isSearching;

                return CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    // ── Browse Categories ────────────────────────────────
                    if (!isSearching || controller.searchResults.isEmpty)
                      _browseCategoriesSliver(context),

                    // ── Recent Searches ──────────────────────────────────
                    if (!isSearching && controller.recentSearches.isNotEmpty)
                      _recentSearchesSliver(context),

                    // ── Section Header ───────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          context.getScreenWidth(4),
                          context.getScreenHeight(1.5),
                          context.getScreenWidth(4),
                          context.getScreenHeight(0.8),
                        ),
                        child: Text(
                          isSearching ? 'Results' : 'Suggested for You',
                          style: TextStyle(
                            fontSize: context.getScreenWidth(4.2),
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF675F55),
                          ),
                        ),
                      ),
                    ),

                    // ── Content ──────────────────────────────────────────
                    if (isSearching)
                      _searchResultsSliver(context)
                    else
                      _initialProductsSliver(context),

                    // ── Load More Indicator ──────────────────────────────
                    _loadMoreSliver(context),

                    SliverToBoxAdapter(
                      child: SizedBox(height: context.getScreenHeight(2)),
                    ),
                  ],
                );
              }),
            ),
            const AppBottomNav(currentIndex: 1),
          ],
        ),
      ),
    );
  }

  // ── Browse Categories Sliver ──────────────────────────────────────────────
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
          if (seen.add(cat.name.toLowerCase())) {
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
                context.getScreenWidth(4),
                context.getScreenHeight(1.5),
                context.getScreenWidth(4),
                0,
              ),
              child: Text(
                'Browse Categories',
                style: TextStyle(
                  fontSize: context.getScreenWidth(4.2),
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF675F55),
                ),
              ),
            ),
            SizedBox(height: context.getScreenHeight(0.6)),
            SizedBox(
              height: context.getScreenWidth(16) + context.getScreenHeight(4),
              child: ListView.separated(
                padding: EdgeInsets.only(left: context.getScreenWidth(4)),
                scrollDirection: Axis.horizontal,
                itemCount: unique.length,
                separatorBuilder: (_, __) => const SizedBox(width: 4),
                itemBuilder: (_, index) {
                  final cat = unique[index];
                  return GestureDetector(
                    onTap: () {
                      _textController.text = cat.name;
                      setState(() {});
                      controller.onSearchSubmitted(cat.name);
                      _focusNode.unfocus();
                    },
                    child: Column(
                      children: [
                        Container(
                          width: context.getScreenWidth(16),
                          height: context.getScreenWidth(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: context.colorPalette.gold.withOpacity(0.5),
                              width: 1.5,
                            ),
                          ),
                          child: ClipOval(
                            child: cat.imageUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: cat.imageUrl,
                                    width: context.getScreenWidth(16),
                                    height: context.getScreenWidth(16),
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => Container(
                                      color: context.colorPalette.goldLight,
                                      child: Icon(
                                        Icons.diamond_outlined,
                                        size: context.getScreenWidth(5.5),
                                        color: context.colorPalette.goldDark,
                                      ),
                                    ),
                                  )
                                : Container(
                                    color: context.colorPalette.goldLight,
                                    child: Icon(
                                      Icons.diamond_outlined,
                                      size: context.getScreenWidth(5.5),
                                      color: context.colorPalette.goldDark,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        SizedBox(
                          width: context.getScreenWidth(20),
                          child: Text(
                            cat.name
                                .replaceAll(RegExp(r'[^a-zA-Z\s]'), '')
                                .replaceAll(RegExp(r'collection', caseSensitive: false), '')
                                .trim(),
                            style: TextStyle(
                              fontSize: context.getScreenWidth(2.4),
                              fontWeight: FontWeight.w700,
                              color: context.colorPalette.goldDeep,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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

  // ── Recent Searches Sliver ────────────────────────────────────────────────
  SliverToBoxAdapter _recentSearchesSliver(BuildContext context) {
    final all = controller.recentSearches;
    final visible = all.take(5).toList();

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          context.getScreenWidth(4),
          context.getScreenHeight(1.5),
          context.getScreenWidth(4),
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
                    fontSize: context.getScreenWidth(4.2),
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
                        fontSize: context.getScreenWidth(3.2),
                        color: context.colorPalette.goldDark,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: context.getScreenHeight(0.8)),
            Wrap(
              spacing: context.getScreenWidth(2),
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
            left: context.getScreenWidth(2.5),
            right: context.getScreenWidth(1),
            top: context.getScreenHeight(0.45),
            bottom: context.getScreenHeight(0.45),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                term,
                style: TextStyle(
                  fontSize: context.getScreenWidth(3.2),
                  color: context.colorPalette.textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: context.getScreenWidth(1)),
              GestureDetector(
                onTap: () => controller.removeRecentSearch(term),
                child: Icon(
                  Icons.close_rounded,
                  size: context.getScreenWidth(3.2),
                  color: const Color(0xFF8D847A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Initial Products Sliver ───────────────────────────────────────────────
  Widget _initialProductsSliver(BuildContext context) {
    final state = controller.initialState;
    final list = controller.initialProducts;

    if (state == CurrentAppState.LOADING && list.isEmpty) {
      return SliverToBoxAdapter(child: _gridShimmer(context));
    }

    if (state == CurrentAppState.ERROR && list.isEmpty) {
      return SliverToBoxAdapter(
        child: _errorWidget(context, onRetry: controller.loadInitialProducts),
      );
    }

    if (state == CurrentAppState.SUCCESS && list.isEmpty) {
      return SliverToBoxAdapter(
        child: _emptyWidget(context, 'No products available'),
      );
    }

    return _productGrid(context, list);
  }

  // ── Search Results Sliver ─────────────────────────────────────────────────
  Widget _searchResultsSliver(BuildContext context) {
    final state = controller.searchState;
    final list = controller.searchResults;

    if (state == CurrentAppState.LOADING && list.isEmpty) {
      return SliverToBoxAdapter(child: _gridShimmer(context));
    }

    if (state == CurrentAppState.ERROR && list.isEmpty) {
      return SliverToBoxAdapter(
        child: _errorWidget(
          context,
          onRetry: () => controller.onSearchSubmitted(controller.searchQuery),
        ),
      );
    }

    if (state == CurrentAppState.SUCCESS && list.isEmpty) {
      return SliverToBoxAdapter(
        child: _emptyWidget(
          context,
          'No results for "${controller.searchQuery}"',
        ),
      );
    }

    return _productGrid(context, list);
  }

  // ── Load More Sliver ──────────────────────────────────────────────────────
  SliverToBoxAdapter _loadMoreSliver(BuildContext context) {
    final isSearching = controller.isSearching;
    final state = isSearching
        ? controller.searchState
        : controller.initialState;
    final hasMore = isSearching
        ? controller.searchHasMore
        : controller.initialHasMore;
    final list = isSearching
        ? controller.searchResults
        : controller.initialProducts;

    if (list.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    // pagination spinner while loading more
    if (state == CurrentAppState.LOADING && list.isNotEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
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
        ),
      );
    }

    if (!hasMore) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: context.getScreenHeight(2)),
          child: Center(
            child: Text(
              'You\'ve seen it all',
              style: TextStyle(
                fontSize: context.getScreenWidth(3.2),
                color: context.colorPalette.subTitleColor,
              ),
            ),
          ),
        ),
      );
    }

    return const SliverToBoxAdapter(child: SizedBox.shrink());
  }

  // ── Product Grid (SliverGrid) ─────────────────────────────────────────────
  SliverGrid _productGrid(BuildContext context, List list) {
    return SliverGrid(
      delegate: SliverChildBuilderDelegate(
        (context, index) => Padding(
          padding: EdgeInsets.all(context.getScreenWidth(1)),
          child: ProductCard(
            product: list[index],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ProductDetailsPage(product: list[index]),
                ),
              );
            },
          ),
        ),
        childCount: list.length,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: context.getScreenWidth(2),
        crossAxisSpacing: context.getScreenWidth(2),
        childAspectRatio: 0.66,
      ),
    );
  }

  // ── Shimmer Placeholder ───────────────────────────────────────────────────
  Widget _gridShimmer(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.getScreenWidth(4)),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: context.getScreenWidth(2),
        crossAxisSpacing: context.getScreenWidth(2),
        childAspectRatio: 0.488,
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
    );
  }

  // ── Error Widget ──────────────────────────────────────────────────────────
  Widget _errorWidget(BuildContext context, {required VoidCallback onRetry}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.getScreenHeight(6)),
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
            onPressed: onRetry,
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
    );
  }

  // ── Empty Widget ──────────────────────────────────────────────────────────
  Widget _emptyWidget(BuildContext context, String message) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.getScreenHeight(6)),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: context.getScreenWidth(12),
            color: const Color(0xFF8D847A),
          ),
          SizedBox(height: context.getScreenHeight(1.5)),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: context.getScreenWidth(3.8),
              color: context.colorPalette.subTitleColor,
            ),
          ),
        ],
      ),
    );
  }
}
