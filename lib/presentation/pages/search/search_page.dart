import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/presentation/controllers/searchProductController.dart';
import 'package:ratnesh_gold_app/presentation/pages/product/product_details_page.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/product_card.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final SearchProductController controller = Get.put(SearchProductController());
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  // toggle: show all recent searches or just 2
  bool _showAllRecent = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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
            _buildSearchBar(context),
            Expanded(
              child: Obx(() {
                final isSearching = controller.isSearching;

                return CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    // ── Recent Searches ──────────────────────────────────
                    if (!isSearching && controller.recentSearches.isNotEmpty)
                      _recentSearchesSliver(context),

                    // ── Section Header ───────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          context.getScreenWidth(4),
                          context.getScreenHeight(2),
                          context.getScreenWidth(4),
                          context.getScreenHeight(1),
                        ),
                        child: Text(
                          isSearching ? 'Results' : 'Products',
                          style: TextStyle(
                            fontSize: context.getScreenWidth(6),
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                            letterSpacing: 0.5,
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

  // ── PREMIUM Search Bar ───────────────────────────────────────────────────
  Widget _buildSearchBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        context.getScreenWidth(4),
        context.getScreenHeight(1.5),
        context.getScreenWidth(4),
        context.getScreenHeight(1),
      ),
      color: context.colorPalette.backgroundColor,
      child: Row(
        children: [
          // Elegant Back Button
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              padding: EdgeInsets.all(context.getScreenWidth(2.5)),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryGold.withOpacity(0.15),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGold.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: context.getScreenWidth(4.5),
                color: AppColors.textDark,
              ),
            ),
          ),
          SizedBox(width: context.getScreenWidth(3)),

          // Modern Floating Search Input
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.getScreenWidth(4),
                vertical: context.getScreenHeight(
                  0.6,
                ), // Tightened for sleekness
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24), // Smoother pill shape
                border: Border.all(
                  color: AppColors.primaryGold.withOpacity(0.2),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGold.withOpacity(
                      0.08,
                    ), // Soft gold shadow
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: AppColors.primaryGold, // Theme color
                    size: context.getScreenWidth(6),
                  ),
                  SizedBox(width: context.getScreenWidth(2.5)),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      autofocus: true,
                      style: TextStyle(
                        fontSize: context.getScreenWidth(4),
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: 'Search collections, rings...',
                        hintStyle: TextStyle(
                          fontSize: context.getScreenWidth(3.6),
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      onChanged: (v) {
                        setState(() {});
                        controller.onSearchChanged(v);
                      },
                      onSubmitted: (v) {
                        controller.onSearchSubmitted(v);
                        _focusNode.unfocus();
                      },
                    ),
                  ),
                  if (_textController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _textController.clear();
                        controller.clearSearch();
                        setState(() {});
                      },
                      child: Container(
                        padding: EdgeInsets.all(context.getScreenWidth(1)),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGold.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: context.getScreenWidth(4.5),
                          color: AppColors.primaryGold,
                        ),
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

  // ── Recent Searches Sliver ────────────────────────────────────────────────
  SliverToBoxAdapter _recentSearchesSliver(BuildContext context) {
    final all = controller.recentSearches;
    // show 2 by default, up to 5 if expanded
    final visible = _showAllRecent
        ? all.take(5).toList()
        : all.take(2).toList();
    final hasMore = all.length > 2 && !_showAllRecent;

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
                  'Recent Searches',
                  style: TextStyle(
                    fontSize: context.getScreenWidth(4.5),
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                GestureDetector(
                  onTap: controller.clearAllRecentSearches,
                  child: Text(
                    'Clear all',
                    style: TextStyle(
                      fontSize: context.getScreenWidth(3.2),
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryGold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.getScreenHeight(0.8)),
            ...visible.map((term) => _recentSearchTile(context, term)),
            if (hasMore)
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => setState(() => _showAllRecent = true),
                  child: Padding(
                    padding: EdgeInsets.only(top: context.getScreenHeight(0.5)),
                    child: Text(
                      'Show more',
                      style: TextStyle(
                        fontSize: context.getScreenWidth(3.2),
                        color: AppColors.primaryGold,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            if (_showAllRecent && all.length > 2)
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => setState(() => _showAllRecent = false),
                  child: Padding(
                    padding: EdgeInsets.only(top: context.getScreenHeight(0.5)),
                    child: Text(
                      'Show less',
                      style: TextStyle(
                        fontSize: context.getScreenWidth(3.2),
                        color: AppColors.primaryGold,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            SizedBox(height: context.getScreenHeight(1)),
            Divider(
              color: AppColors.primaryGold.withOpacity(0.1),
              thickness: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _recentSearchTile(BuildContext context, String term) {
    return InkWell(
      onTap: () {
        _textController.text = term;
        setState(() {});
        controller.onSearchSubmitted(term);
        _focusNode.unfocus();
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.getScreenHeight(1)),
        child: Row(
          children: [
            Icon(
              Icons.history_rounded,
              size: context.getScreenWidth(5),
              color: Colors.grey.shade400,
            ),
            SizedBox(width: context.getScreenWidth(3)),
            Expanded(
              child: Text(
                term,
                style: TextStyle(
                  fontSize: context.getScreenWidth(4),
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => controller.removeRecentSearch(term),
              child: Icon(
                Icons.close_rounded,
                size: context.getScreenWidth(4.5),
                color: Colors.grey.shade400,
              ),
            ),
          ],
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
          childAspectRatio: 0.66,
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
