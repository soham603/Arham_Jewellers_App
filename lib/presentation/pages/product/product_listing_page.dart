import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/core/widgets/product_card.dart';
import 'package:ratnesh_gold_app/presentation/controllers/searchProductController.dart';
import 'package:ratnesh_gold_app/presentation/pages/product/product_details_page.dart';
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
          widget.title ?? '${widget.karat} Collection',
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
      body: Obx(() {
        final state = _isCategoryOnly
            ? _controller.categoryState
            : _isCategoryFilter
                ? _controller.filteredState
                : _controller.karatState;
        final products = _isCategoryOnly
            ? _controller.categoryProducts
            : _isCategoryFilter
                ? _controller.filteredProducts
                : _controller.karatProducts;
        final hasMore = _isCategoryOnly
            ? false
            : _isCategoryFilter
                ? _controller.filteredHasMore
                : _controller.karatHasMore;

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

        return GridView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: products.length + (hasMore ? 1 : 0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.488,
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
    );
  }
}
