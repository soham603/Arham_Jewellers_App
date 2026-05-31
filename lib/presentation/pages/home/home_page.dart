import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/core/widgets/product_card.dart';
import 'package:ratnesh_gold_app/domain/entities/category_model.dart';
import 'package:ratnesh_gold_app/presentation/controllers/CategoryController.dart';
import 'package:ratnesh_gold_app/presentation/controllers/carousel_controller.dart';
import 'package:ratnesh_gold_app/presentation/controllers/notification_controller.dart';
import 'package:ratnesh_gold_app/presentation/pages/product/product_details_page.dart';
import 'package:ratnesh_gold_app/presentation/pages/product/product_listing_page.dart';
import 'package:ratnesh_gold_app/presentation/shimmers/carouselShimmer.dart';
import 'package:ratnesh_gold_app/presentation/shimmers/categoryShimmer.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';
import 'package:shimmer/shimmer.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/custom_divider.dart';
import '../../../core/widgets/home_search_bar.dart';

// Imported the Customise Order Page
import 'package:ratnesh_gold_app/presentation/pages/product/customise_order_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CarouselsController carouselController = Get.put(CarouselsController());
  final CategoryController categoryController = Get.put(CategoryController());
  final PageController pageController = PageController();

  final ScrollController scrollController = ScrollController();

  final GlobalKey productSectionKey = GlobalKey();

  int currentCarouselIndex = 0;
  Timer? _carouselTimer;
  DateTime? _lastBackPress;

  @override
  void initState() {
    super.initState();
    carouselController.getAllCarousels();
    categoryController.fetchAllKaratCategories();
    _startCarouselAutoSlide();
  }

  void _startCarouselAutoSlide() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      final list = carouselController.list;
      if (list.isEmpty) return;
      final nextIndex = (currentCarouselIndex + 1) % list.length;
      pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  void _onCarouselPageChanged(int index) {
    setState(() {
      currentCarouselIndex = index;
    });
    _startCarouselAutoSlide();
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    scrollController.dispose();
    pageController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      carouselController.getAllCarousels(),
      categoryController.fetchAllKaratCategories(),
      carouselController.loadLatestProducts(),
    ]);
  }

  void scrollToProductSection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = productSectionKey.currentContext;

      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          alignment: 0.05,
        );
      }
    });
  }

  void _navigateToKaratListing(String karat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductListingPage(karat: karat),
      ),
    );
  }

  void _navigateToMultiKaratListing(List<String> karats, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductListingPage(karats: karats, title: title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastBackPress != null &&
            now.difference(_lastBackPress!) < const Duration(seconds: 2)) {
          SystemNavigator.pop();
        } else {
          _lastBackPress = now;
          HapticFeedback.lightImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.only(bottom: 80, left: 16, right: 16),
            ),
          );
        }
      },
      child: Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primaryGold,
                backgroundColor: Colors.white,
                onRefresh: _onRefresh,
                child: SingleChildScrollView(
                  controller: scrollController,

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      const _TopBar(),

                      const SizedBox(height: 8),

                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: HomeSearchBar(),
                      ),

                      const SizedBox(height: 18),

                      // 🔥 Original API-driven Carousel Section (Restored exactly as before)
                      _CarouselSection(
                        controller: carouselController,
                        pageController: pageController,
                        currentIndex: currentCarouselIndex,

                        onPageChanged: _onCarouselPageChanged,
                      ),

                      const CategoryDivider(),

                      _CategoryQuickAccess(controller: categoryController),

                      const SizedBox(height: 16),

                      Container(
                        width: double.infinity,
                        color: const Color(0xFF3E2723),
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          children: [
                            const CollectionsDivider(vertical: 4, label: 'Collections'),

                            const SizedBox(height: 24),

                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  Expanded(
                                  child: GestureDetector(
                                    onTap: () => _navigateToMultiKaratListing(['18K', '20K'], '18K & 20K Collection'),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.08),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.asset(
                                          'assets/images/arham-collection.png',
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => _navigateToKaratListing('22K'),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.08),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.asset(
                                            'assets/images/ratnesh-collection.png',
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            const CollectionsDivider(vertical: 4),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      Obx(() {
                        if (!categoryController.showProductSection) {
                          return const SizedBox();
                        }

                        return Column(
                          children: [
        

                            SizedBox(height: context.getScreenHeight(1)),
                            _ProductSection(
                              key: productSectionKey,
                              category: categoryController.selectedLevel3!,
                              onClose: categoryController.clearSelectedLevel3,
                            ),
                          ],
                        );
                      }),



                      SizedBox(height: context.getScreenHeight(1)),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _SectionTitle(
                          label: 'Latest Additions',
                          subtitle: 'Newest jewellery collections',
                        ),
                      ),

                      const SizedBox(height: 12),

                      Obx(() {
                        final state = carouselController.productState;
                        final products = carouselController.latestProducts;

                        if (state == CurrentAppState.LOADING &&
                            products.isEmpty) {
                          return SizedBox(
                            height: context.getScreenHeight(44),
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              scrollDirection: Axis.horizontal,
                              itemCount: 5,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (_, __) {
                                return Shimmer.fromColors(
                                  baseColor:
                                      context.colorPalette.shimmerBaseColor,
                                  highlightColor:
                                      context.colorPalette.shimmerHighLightColor,
                                  child: Container(
                                    width: context.getScreenWidth(50),
                                    decoration: BoxDecoration(
                                      color: context.colorPalette.cardBg,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: context.colorPalette.border,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Expanded(
                                          flex: 7,
                                          child: Container(
                                            decoration: const BoxDecoration(
                                              borderRadius: BorderRadius.vertical(
                                                top: Radius.circular(15),
                                              ),
                                            ),
                                            child: Center(
                                              child: Icon(
                                                Icons.diamond_outlined,
                                                size: 36,
                                                color:
                                                    context.colorPalette.goldDark,
                                              ),
                                            ),
                                          ),
                                        ),

                                        Expanded(
                                          flex: 4,
                                          child: Padding(
                                            padding: const EdgeInsets.all(10),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  height: 12,
                                                  width: double.infinity,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(4),
                                                  ),
                                                ),

                                                const SizedBox(height: 8),

                                                Container(
                                                  height: 10,
                                                  width: 70,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(4),
                                                  ),
                                                ),

                                                const Spacer(),

                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Container(
                                                      height: 10,
                                                      width: 50,
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              4,
                                                            ),
                                                      ),
                                                    ),

                                                    Container(
                                                      width: 30,
                                                      height: 30,
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        }

                        if (state == CurrentAppState.ERROR && products.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _ErrorRow(
                              onRetry: () {
                                carouselController.loadLatestProducts();
                              },
                            ),
                          );
                        }

                        if (products.isEmpty) {
                          return const SizedBox();
                        }

                        return SizedBox(
                          height: context.getScreenHeight(44),
                          child: NotificationListener<ScrollNotification>(
                            onNotification: (scrollInfo) {
                              if (scrollInfo.metrics.pixels >=
                                  scrollInfo.metrics.maxScrollExtent - 200) {
                                carouselController.loadLatestProducts(
                                  isPagination: true,
                                );
                              }

                              return false;
                            },
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              scrollDirection: Axis.horizontal,
                              itemCount:
                                  products.length +
                                  (carouselController.productLoadingMore ? 1 : 0),
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (_, index) {
                                if (index >= products.length) {
                                  return SizedBox(
                                    width: context.getScreenWidth(50),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: context.colorPalette.gold,
                                      ),
                                    ),
                                  );
                                }

                                final product = products[index];

                                return SizedBox(
                                  width: context.getScreenWidth(50),
                                  child: ProductCard(
                                    product: product,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ProductDetailsPage(
                                                product: product,
                                              ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 30),

                      const CustomiseOrderBanner(),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),

            AppBottomNav(currentIndex: 0),
          ],
        ),
      ),
    ),
    );
  }
}

class _KaratSection extends StatelessWidget {
  final Karat karat;
  final CategoryController controller;
  final VoidCallback onLevel3Selected;
  final VoidCallback onSeeAll;

  const _KaratSection({
    required this.karat,
    required this.controller,
    required this.onLevel3Selected,
    required this.onSeeAll,
  });

  CurrentAppState _state() {
    switch (karat) {
      case Karat.k18:
        return controller.k18State;
      case Karat.k20:
        return controller.k20State;
      case Karat.k22:
        return controller.k22State;
    }
  }

  List<CategoryModel> _list() {
    switch (karat) {
      case Karat.k18:
        return controller.k18Categories;
      case Karat.k20:
        return controller.k20Categories;
      case Karat.k22:
        return controller.k22Categories;
    }
  }

  Color _accentColor(BuildContext context) {
    switch (karat) {
      case Karat.k18:
        return context.colorPalette.k18Accent;
      case Karat.k20:
        return context.colorPalette.k20Accent;
      case Karat.k22:
        return context.colorPalette.k22Accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = _state();
      final list = _list();
      final accent = _accentColor(context);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),

            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),

                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accent.withOpacity(0.85), accent],
                    ),

                    borderRadius: BorderRadius.circular(8),
                  ),

                  child: Text(
                    karat.displayName,

                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                Text(
                  'Gold',

                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.colorPalette.goldDeep,
                  ),
                ),

                const Spacer(),

                GestureDetector(
                  onTap: onSeeAll,
                  child: Text(
                    'See all →',

                    style: TextStyle(
                      fontSize: 12.5,
                      color: context.colorPalette.goldDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          if (state == CurrentAppState.LOADING)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CategoryShimmer(),
            )
          else if (state == CurrentAppState.ERROR)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _ErrorRow(
                onRetry: () => controller.fetchCategoriesForKarat(karat),
              ),
            )
          else
            SizedBox(
              height: context.getScreenHeight(14.5),

              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),

                scrollDirection: Axis.horizontal,

                itemCount: list.length,

                separatorBuilder: (_, __) => const SizedBox(width: 10),

                itemBuilder: (_, index) {
                  final cat = list[index];

                  return Obx(() {
                    final isExpanded = controller.expandedCategoryId == cat.id;

                    return GestureDetector(
                      onTap: () => controller.toggleExpand(cat),

                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),

                        width: context.getScreenWidth(20),

                        decoration: BoxDecoration(
                          color: isExpanded
                              ? context.colorPalette.goldLight
                              : context.colorPalette.cardBg,

                          borderRadius: BorderRadius.circular(14),

                          border: Border.all(
                            color: isExpanded
                                ? context.colorPalette.gold
                                : context.colorPalette.border,

                            width: isExpanded ? 2 : 1,
                          ),

                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),

                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,

                          children: [
                            Container(
                              width: context.getScreenWidth(12),
                              height: context.getScreenHeight(6),

                              decoration: BoxDecoration(
                                color: context.colorPalette.shimmerBaseColor,
                                borderRadius: BorderRadius.circular(10),
                              ),

                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),

                                child: CachedNetworkImage(
                                  imageUrl: cat.imageUrl,
                                  fit: BoxFit.cover,

                                  errorWidget: (_, __, ___) => Icon(
                                    Icons.diamond_outlined,
                                    size: context.getScreenWidth(5),
                                    color: context.colorPalette.goldDark,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 6),

                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),

                              child: Text(
                                cat.name,

                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,

                                style: TextStyle(
                                  fontSize: context.getScreenWidth(2.8),

                                  color: isExpanded
                                      ? context.colorPalette.goldDeep
                                      : Colors.grey.shade700,

                                  fontWeight: isExpanded
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  });
                },
              ),
            ),

          Obx(() {
            final expandedId = controller.expandedCategoryId;

            if (expandedId == null) return const SizedBox();

            final belongs = _list().any((c) => c.id == expandedId);

            if (!belongs) return const SizedBox();

            final expandedCat = _list().firstWhere((c) => c.id == expandedId);

            final children = controller.level3Cache[expandedId] ?? [];

            final isLoading = controller.isLevel3Loading(expandedId);

            return AnimatedSize(
              duration: const Duration(milliseconds: 300),

              child: _Level3Panel(
                parentCategory: expandedCat,
                children: children,
                isLoading: isLoading,
                selectedId: controller.selectedLevel3?.id,

                onSelect: (cat) {
                  controller.selectLevel3Category(cat);
                  onLevel3Selected();
                },
              ),
            );
          }),
        ],
      );
    });
  }
}

class _Level3Panel extends StatelessWidget {
  final CategoryModel parentCategory;
  final List<CategoryModel> children;
  final bool isLoading;
  final String? selectedId;
  final ValueChanged<CategoryModel> onSelect;

  const _Level3Panel({
    required this.parentCategory,
    required this.children,
    required this.isLoading,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),

      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: context.colorPalette.level3Bg,
        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: context.colorPalette.gold.withOpacity(0.35)),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Icon(
                Icons.grid_view_rounded,
                size: 18,
                color: context.colorPalette.goldDark,
              ),

              const SizedBox(width: 8),

              Text(
                parentCategory.name,

                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: context.colorPalette.goldDeep,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          if (isLoading)
            const _Level3Shimmer()
          else if (children.isEmpty)
            Text(
              'No styles available',

              style: TextStyle(color: context.colorPalette.goldDark),
            )
          else
            GridView.builder(
              shrinkWrap: true,

              physics: const NeverScrollableScrollPhysics(),

              itemCount: children.length,

              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.78,
              ),

              itemBuilder: (_, index) {
                final cat = children[index];

                final isSelected = selectedId == cat.id;

                return GestureDetector(
                  onTap: () => onSelect(cat),

                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),

                    padding: const EdgeInsets.all(8),

                    decoration: BoxDecoration(
                      color: isSelected
                          ? context.colorPalette.goldLight
                          : context.colorPalette.cardBg,

                      borderRadius: BorderRadius.circular(14),

                      border: Border.all(
                        color: isSelected
                            ? context.colorPalette.gold
                            : context.colorPalette.border,

                        width: isSelected ? 2 : 1,
                      ),
                    ),

                    child: Column(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),

                            child: CachedNetworkImage(
                              imageUrl: cat.imageUrl,

                              width: double.infinity,
                              fit: BoxFit.cover,

                              errorWidget: (_, __, ___) => Container(
                                color: context.colorPalette.goldLight,

                                child: Icon(
                                  Icons.diamond_outlined,
                                  color: context.colorPalette.goldDark,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          cat.name,

                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,

                          style: TextStyle(
                            fontSize: 12,

                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,

                            color: isSelected
                                ? context.colorPalette.goldDeep
                                : Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ProductSection extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onClose;

  const _ProductSection({
    super.key,
    required this.category,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 28),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      category.name,

                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: context.colorPalette.goldDeep,
                      ),
                    ),

                    Text(
                      'Browse products in this category',

                      style: TextStyle(
                        fontSize: 12,
                        color: context.colorPalette.goldDark,
                      ),
                    ),
                  ],
                ),
              ),

              GestureDetector(
                onTap: onClose,

                child: Container(
                  padding: const EdgeInsets.all(8),

                  decoration: BoxDecoration(
                    color: context.colorPalette.goldLight,
                    borderRadius: BorderRadius.circular(8),
                  ),

                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: context.colorPalette.goldDark,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          GridView.builder(
            shrinkWrap: true,

            physics: const NeverScrollableScrollPhysics(),

            itemCount: 4,

            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.70,
            ),

            itemBuilder: (_, i) => _ProductPlaceholderCard(),
          ),
        ],
      ),
    );
  }
}

class _ProductPlaceholderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorPalette.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colorPalette.border),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Expanded(
            flex: 6,

            child: Container(
              decoration: BoxDecoration(
                color: context.colorPalette.shimmerBaseColor,

                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(13),
                ),
              ),

              child: Center(
                child: Icon(
                  Icons.diamond_outlined,
                  color: context.colorPalette.goldDark,
                  size: 36,
                ),
              ),
            ),
          ),

          Expanded(
            flex: 4,

            child: Padding(
              padding: const EdgeInsets.all(10),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Container(
                    height: 11,
                    width: double.infinity,

                    decoration: BoxDecoration(
                      color: context.colorPalette.shimmerBaseColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),

                  const SizedBox(height: 5),

                  Container(
                    height: 11,
                    width: 80,

                    decoration: BoxDecoration(
                      color: context.colorPalette.shimmerBaseColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),

                  const Spacer(),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,

                    children: [
                      Container(
                        height: 13,
                        width: 60,

                        decoration: BoxDecoration(
                          color: context.colorPalette.goldLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),

                      Container(
                        width: 28,
                        height: 28,

                        decoration: BoxDecoration(
                          color: context.colorPalette.gold,
                          borderRadius: BorderRadius.circular(7),
                        ),

                        child: const Icon(
                          Icons.add,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendingPlaceholder extends StatelessWidget {
  const _TrendingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: context.getScreenHeight(22),

      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),

        scrollDirection: Axis.horizontal,

        itemCount: 5,

        separatorBuilder: (_, _) => const SizedBox(width: 10),

        itemBuilder: (_, i) {
          return Container(
            width: context.getScreenWidth(33.5),

            decoration: BoxDecoration(
              color: context.colorPalette.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.colorPalette.border),
            ),

            child: Column(
              children: [
                Expanded(
                  flex: 7,

                  child: Container(
                    decoration: BoxDecoration(
                      color: context.colorPalette.shimmerBaseColor,

                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(13),
                      ),
                    ),

                    child: Center(
                      child: Icon(
                        Icons.diamond_outlined,
                        color: context.colorPalette.goldDark,
                        size: context.getScreenHeight(4),
                      ),
                    ),
                  ),
                ),

                Expanded(
                  flex: 3,

                  child: Padding(
                    padding: const EdgeInsets.all(8),

                    child: Column(
                      children: [
                        Container(
                          height: 10,
                          width: double.infinity,

                          decoration: BoxDecoration(
                            color: context.colorPalette.shimmerBaseColor,

                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),

                        const SizedBox(height: 5),

                        Container(
                          height: 10,
                          width: 60,

                          decoration: BoxDecoration(
                            color: context.colorPalette.goldLight,

                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Level3Shimmer extends StatelessWidget {
  const _Level3Shimmer();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,

      physics: const NeverScrollableScrollPhysics(),

      itemCount: 6,

      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),

      itemBuilder: (_, __) {
        return Container(
          decoration: BoxDecoration(
            color: context.colorPalette.shimmerBaseColor,
            borderRadius: BorderRadius.circular(14),
          ),
        );
      },
    );
  }
}

class _ErrorRow extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorRow({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 18),

        const SizedBox(width: 6),

        const Text(
          'Failed to load',
          style: TextStyle(color: Colors.red, fontSize: 13),
        ),

        const SizedBox(width: 8),

        GestureDetector(
          onTap: onRetry,

          child: Text(
            'Retry',

            style: TextStyle(
              color: context.colorPalette.gold,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),

      child: Row(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/ratnesh-logo.png',
                height: 44,
                fit: BoxFit.contain,
                color: context.colorPalette.gold,
                colorBlendMode: BlendMode.srcIn,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ratnesh Gold',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: context.colorPalette.goldDeep,
                    ),
                  ),
                  Text(
                    'Purity • Quality • Trust',
                    style: TextStyle(
                      fontSize: 11,
                      color: context.colorPalette.goldDark,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const Spacer(),

          Obx(() => _IconBtn(
            icon: Icons.notifications_none_rounded,
            onTap: () => Get.toNamed(AppRoutes.notifications),
            badgeCount: Get.find<NotificationController>().unreadCount.value,
          )),

          const SizedBox(width: 8),

          _IconBtn(
            icon: Icons.shopping_bag_outlined,
            onTap: () => Get.toNamed(AppRoutes.cart),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int badgeCount;

  const _IconBtn({required this.icon, required this.onTap, this.badgeCount = 0});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.colorPalette.goldLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.colorPalette.border),
            ),
            child: Icon(icon, size: 20, color: context.colorPalette.goldDark),
          ),
          if (badgeCount > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  badgeCount > 99 ? '99+' : '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickStatsStrip extends StatelessWidget {
  const _QuickStatsStrip();

  @override
  Widget build(BuildContext context) {
    final items = [
      ('BIS Hallmark', Icons.verified_outlined),
      ('Free Shipping', Icons.local_shipping_outlined),
      ('Easy Returns', Icons.replay_outlined),
      ('EMI Available', Icons.credit_card_outlined),
    ];

    return SizedBox(
      height: 60,

      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),

        scrollDirection: Axis.horizontal,

        itemCount: items.length,

        separatorBuilder: (_, _) => const SizedBox(width: 10),

        itemBuilder: (_, i) {
          final item = items[i];

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),

            decoration: BoxDecoration(
              color: context.colorPalette.goldLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.colorPalette.border),
            ),

            child: Row(
              mainAxisSize: MainAxisSize.min,

              children: [
                Icon(item.$2, size: 16, color: context.colorPalette.goldDark),

                const SizedBox(width: 6),

                Text(
                  item.$1,

                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.colorPalette.goldDeep,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// 🔥 RESTORED EXACTLY TO YOUR ORIGINAL CODE! No default fallback banners.
class _CarouselSection extends StatelessWidget {
  final CarouselsController controller;
  final PageController pageController;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;

  const _CarouselSection({
    required this.controller,
    required this.pageController,
    required this.currentIndex,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.getCarouselState == CurrentAppState.LOADING) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: CarouselShimmer(),
        );
      }

      if (controller.getCarouselState == CurrentAppState.ERROR) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          height: 160,

          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
          ),

          child: const Center(child: Text('Failed to load banners')),
        );
      }

      final list = controller.list;

      if (list.isEmpty) return const SizedBox();

      return SizedBox(
        height: context.getScreenHeight(28),

        child: Stack(
          children: [
            PageView.builder(
              controller: pageController,

              itemCount: list.length,

              onPageChanged: onPageChanged,

              itemBuilder: (_, index) {
                final item = list[index];

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 14),

                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),

                    boxShadow: [
                      BoxShadow(
                        color: context.colorPalette.gold.withOpacity(0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),

                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),

                    child: CachedNetworkImage(
                      imageUrl: item.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => CarouselShimmer(),
                      errorWidget: (_, __, ___) => Container(
                        color: context.colorPalette.shimmerBaseColor,
                      ),
                    ),
                  ),
                );
              },
            ),

            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,

                children: List.generate(list.length, (i) {
                  final active = i == currentIndex;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),

                    margin: const EdgeInsets.symmetric(horizontal: 3),

                    width: active ? 22 : 6,
                    height: 6,

                    decoration: BoxDecoration(
                      color: active
                          ? context.colorPalette.gold
                          : context.colorPalette.border,

                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;
  final String subtitle;

  const _SectionTitle({required this.label, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 22,

              decoration: BoxDecoration(
                color: context.colorPalette.gold,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(width: 8),

            Text(
              label,

              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: context.colorPalette.goldDeep,
              ),
            ),
          ],
        ),

        const SizedBox(height: 3),

        Padding(
          padding: const EdgeInsets.only(left: 12),

          child: Text(
            subtitle,

            style: TextStyle(
              fontSize: 12.5,
              color: context.colorPalette.goldDark,
            ),
          ),
        ),
      ],
    );
  }
}

// =====================================================
// 🔥 CUSTOMISE ORDER BANNER COMPONENT
// =====================================================
class _CategoryQuickAccess extends StatelessWidget {
  final CategoryController controller;

  const _CategoryQuickAccess({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final allCategories = [
        ...controller.k18Categories,
        ...controller.k20Categories,
        ...controller.k22Categories,
      ];

      final seen = <String>{};
      final unique = <CategoryModel>[];
      for (final cat in allCategories) {
        if (seen.add(cat.name.toLowerCase())) {
          unique.add(cat);
        }
      }

      if (unique.isEmpty) return const SizedBox();

      return SizedBox(
        height: context.getScreenHeight(13),
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          scrollDirection: Axis.horizontal,
          itemCount: unique.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (_, index) {
            final cat = unique[index];
            return GestureDetector(
              onTap: () {
                controller.toggleExpand(cat);
              },
              child: Column(
                children: [
                  CircleAvatar(
                    radius: context.getScreenWidth(8.5),
                    backgroundColor: context.colorPalette.goldLight,
                    child: ClipOval(
                      child: cat.imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: cat.imageUrl,
                              width: context.getScreenWidth(17),
                              height: context.getScreenWidth(17),
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Icon(
                                Icons.diamond_outlined,
                                size: context.getScreenWidth(7),
                                color: context.colorPalette.goldDark,
                              ),
                            )
                          : Icon(
                              Icons.diamond_outlined,
                              size: context.getScreenWidth(7),
                              color: context.colorPalette.goldDark,
                            ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  SizedBox(
                    width: context.getScreenWidth(24),
                    child: Text(
                      cat.name,
                      style: TextStyle(
                        fontSize: context.getScreenWidth(3.0),
                        fontWeight: FontWeight.w600,
                        color: context.colorPalette.goldDeep,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    });
  }
}

class CustomiseOrderBanner extends StatelessWidget {
  const CustomiseOrderBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.to(() => const CustomiseOrderPage());
      },
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: context.getScreenWidth(4),
          vertical: context.getScreenHeight(1),
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [
              Color(0xFFEAD8C1), // Rich beige/gold
              Color(0xFFD6C1A1), // Deeper warm gold/brown
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: context.colorPalette.goldDeep.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: context.colorPalette.goldDeep.withOpacity(0.15),
            width: 1.5,
          ),
        ),
        child: Stack(
          children: [
            // ==========================================
            // "Bespoke Service" Ribbon (Top Right)
            // ==========================================
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.getScreenWidth(3),
                  vertical: context.getScreenHeight(0.6),
                ),
                decoration: BoxDecoration(
                  color: context.colorPalette.goldDeep,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: Text(
                  "Bespoke Service",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: context.getScreenWidth(2.6),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            // ==========================================
            // Main Content Layout
            // ==========================================
            Padding(
              padding: EdgeInsets.all(context.getScreenWidth(5)),
              child: Row(
                children: [
                  // Left Side: Text Content
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Overline Text
                        Text(
                          "BRING IDEAS TO LIFE",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: context.getScreenWidth(2.8),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: context.getScreenHeight(1)),

                        // Main Headlines
                        Text(
                          "Craft Your",
                          style: TextStyle(
                            color: const Color(
                              0xFF3E2723,
                            ), // Deep Espresso Brown
                            fontSize: context.getScreenWidth(5.5),
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          "Dream Jewelry",
                          style: TextStyle(
                            color: const Color(0xFF3E2723).withOpacity(0.8),
                            fontSize: context.getScreenWidth(4),
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        SizedBox(height: context.getScreenHeight(1.5)),

                        // Feature Bullet Points
                        Row(
                          children: [
                            _buildBulletDot(context),
                            _buildFeatureText(context, "Imagine"),
                            _buildBulletDot(context),
                            _buildFeatureText(context, "Upload"),
                            _buildBulletDot(context),
                            _buildFeatureText(context, "Craft"),
                          ],
                        ),

                        SizedBox(height: context.getScreenHeight(1.5)),

                        // Tagline
                        Text(
                          "Turn your unique inspirations into\nstunning gold masterpieces.",
                          style: TextStyle(
                            color: const Color(0xFF5D4037),
                            fontSize: context.getScreenWidth(2.8),
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),

                        SizedBox(height: context.getScreenHeight(2)),

                        // CTA Button
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.getScreenWidth(3.5),
                            vertical: context.getScreenHeight(0.8),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: context.colorPalette.gold.withOpacity(0.5),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: context.colorPalette.gold.withOpacity(
                                  0.1,
                                ),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Start Designing",
                                style: TextStyle(
                                  color: context.colorPalette.goldDeep,
                                  fontSize: context.getScreenWidth(3),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(width: context.getScreenWidth(1.5)),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: context.colorPalette.goldDeep,
                                size: context.getScreenWidth(3.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Right Side: Graphic/Illustration placeholder
                  Expanded(
                    flex: 4,
                    child: Container(
                      height: context.getScreenWidth(32),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              Icons.diamond_outlined,
                              color: context.colorPalette.gold.withOpacity(0.3),
                              size: context.getScreenWidth(20),
                            ),
                            Icon(
                              Icons.draw_outlined,
                              color: context.colorPalette.goldDeep,
                              size: context.getScreenWidth(10),
                            ),
                          ],
                        ),
                      ),
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

  // --- Helper Widgets for the UI ---
  Widget _buildBulletDot(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Icon(Icons.circle, size: 4, color: const Color(0xFF3E2723)),
    );
  }

  Widget _buildFeatureText(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        color: const Color(0xFF3E2723),
        fontSize: context.getScreenWidth(2.6),
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
