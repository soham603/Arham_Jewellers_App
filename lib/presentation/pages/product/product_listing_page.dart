import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/core/widgets/product_card.dart';
import 'package:ratnesh_gold_app/domain/entities/productModel.dart';
import 'package:ratnesh_gold_app/presentation/controllers/searchProductController.dart';
import 'package:ratnesh_gold_app/presentation/pages/product/product_details_page.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';

class ProductListingPage extends StatefulWidget {
  final String? karat;
  final List<String>? karats;
  final String? title;

  const ProductListingPage({super.key, this.karat, this.karats, this.title});

  @override
  State<ProductListingPage> createState() => _ProductListingPageState();
}

class _ProductListingPageState extends State<ProductListingPage> {
  late final SearchProductController _controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = Get.put(SearchProductController(), tag: 'listing_${widget.karat ?? widget.karats?.join("_")}');

    final karatsToLoad = widget.karats ?? (widget.karat != null ? [widget.karat!] : <String>[]);
    _controller.loadProductsByKarats(karatsToLoad);

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    Get.delete<SearchProductController>(tag: 'listing_${widget.karat ?? widget.karats?.join("_")}');
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _controller.loadMoreKaratProducts();
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
        final state = _controller.karatState;
        final products = _controller.karatProducts;

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
                    final karatsToLoad = widget.karats ?? (widget.karat != null ? [widget.karat!] : <String>[]);
                    _controller.loadProductsByKarats(karatsToLoad);
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
          itemCount: products.length + (_controller.karatHasMore ? 1 : 0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.65,
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
