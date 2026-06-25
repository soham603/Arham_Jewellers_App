import 'package:ratnesh_gold_app/utils/ToastUtil.dart';
import 'package:ratnesh_gold_app/utils/Logger.dart';
import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:ratnesh_gold_app/core/widgets/product_card.dart';
import 'package:ratnesh_gold_app/core/widgets/ratnesh_fallback.dart';
import 'package:ratnesh_gold_app/core/widgets/carousel_indicator.dart';
import 'package:ratnesh_gold_app/domain/entities/category_model.dart';
import 'package:ratnesh_gold_app/domain/entities/carousel_model.dart';
import 'package:ratnesh_gold_app/presentation/controllers/CategoryController.dart';
import 'package:ratnesh_gold_app/presentation/controllers/carousel_controller.dart';
import 'package:ratnesh_gold_app/presentation/controllers/notification_controller.dart';
import 'package:ratnesh_gold_app/presentation/controllers/searchProductController.dart';
import 'package:ratnesh_gold_app/presentation/pages/product/product_details_page.dart';
import 'package:ratnesh_gold_app/presentation/pages/product/category_listing_page.dart';
import 'package:ratnesh_gold_app/presentation/pages/product/chain_listing_page.dart';
import 'package:ratnesh_gold_app/presentation/shimmers/carouselShimmer.dart';
import 'package:ratnesh_gold_app/presentation/shimmers/carouselIndicatorShimmer.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/core/widgets/logo_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';
import 'package:shimmer/shimmer.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/custom_divider.dart';
import '../../../core/widgets/home_search_bar.dart';
import '../../../core/widgets/nav_bar_spacer.dart';
import '../../controllers/AuthController.dart';

// Imported the Customise Order Page
import 'package:ratnesh_gold_app/presentation/pages/product/customise_order_page.dart';
import 'package:ratnesh_gold_app/presentation/pages/profile/goldRateDetailScreen.dart';
import 'package:ratnesh_gold_app/presentation/pages/search/search_page.dart';
import 'package:ratnesh_gold_app/presentation/pages/search/barcode_scanner_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final CarouselsController carouselController;
  late final CategoryController categoryController;
  final PageController pageController = PageController();

  final ScrollController scrollController = ScrollController();

  final GlobalKey productSectionKey = GlobalKey();

  int currentCarouselIndex = 0;
  Timer? _carouselTimer;

  @override
  void initState() {
    super.initState();
    carouselController = Get.isRegistered<CarouselsController>()
        ? Get.find<CarouselsController>()
        : Get.put(CarouselsController());
    categoryController = Get.isRegistered<CategoryController>()
        ? Get.find<CategoryController>()
        : Get.put(CategoryController());
    // CategoryController fetches tree eagerly in onInit()
    // No need to fetch here
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
    try {
      await Future.wait([
        carouselController.getAllCarousels(),
        // On pull-to-refresh, refresh tree data
        categoryController.fetchCategoryTree(force: true),
        carouselController.loadLatestProducts(),
      ]);
    } catch (e, stackTrace) {
      Logger.error('HomePage', 'Refresh failed', stackTrace: stackTrace);
    }
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

  void _navigateToCategoryListing(List<Karat> karats, {String? title}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CategoryListingPage(karats: karats, title: title)),
    );
  }

  void _openScanner() async {
     final barcode = await Get.to(() => BarcodeScannerPage(
           onDetect: (barcode) async {
             // The barcode scanner page will now close itself and return the value
             // We don't need to do anything here since the page handles closing
           },
         )) as String?;

     if (barcode == null) return;
     
     final productController = SearchProductController.instance;
     final product = await productController.searchByBarcode(barcode);
     if (!mounted) return;
      if (product != null) {
        Get.to(() => ProductDetailsPage(product: product));
      } else {
         ToastUtils.showError('No product found for barcode: $barcode');
      }
    }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primaryGold,
      backgroundColor: Colors.white,
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        controller: scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                        const _TopBar(),

                        SizedBox(height: context.heightPercent(1)),

                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: context.getResponsiveSize(4)),
                          child: Row(
                            children: [
                              Expanded(
                                child: HomeSearchBar(onScannerTap: _openScanner, categoryController: categoryController),
                              ),
                              SizedBox(width: context.getResponsiveSize(2.5)),
GestureDetector(
  onTap: () => Get.to(() => const GoldRateDetailScreen()),
  child: Container(
    width: context.responsiveWidth(34, tabletVal: 56),
    height: context.responsiveWidth(34, tabletVal: 56),
    decoration: BoxDecoration(
      color: AppColors.warmBg,
      shape: BoxShape.circle,
      border: Border.all(
        color: context.colorPalette.gold.withValues(alpha: 0.2),
        width: 1,
      ),
    ),
    child: Center(
      child: Image.asset(
        'assets/images/gold-price-icon.png',
        width: context.responsiveWidth(24, tabletVal: 40),
        height: context.responsiveWidth(24, tabletVal: 40),
        color: context.colorPalette.goldDark,
        colorBlendMode: BlendMode.srcIn,
      ),
    ),
  ),
),
                            ],
                          ),
                        ),

                        SizedBox(height: context.heightPercent(2.2)),

                        _CarouselSection(
                          controller: carouselController,
                          pageController: pageController,
                          currentIndex: currentCarouselIndex,
                          onPageChanged: _onCarouselPageChanged,
                        ),

                        const CategoryDivider(),

                        _CategoryQuickAccess(controller: categoryController),

                        SizedBox(height: context.heightPercent(2)),

                        Container(
                          width: double.infinity,
                          color: AppColors.deepEspresso,
                          padding: EdgeInsets.symmetric(vertical: context.heightPercent(3)),
                          child: Column(
                            children: [
                              const CollectionsDivider(
                                vertical: 4,
                                label: 'Collections',
                              ),

                              SizedBox(height: context.heightPercent(3)),

                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: context.getResponsiveSize(4),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () =>
                                            _navigateToCategoryListing([Karat.k18, Karat.k20], title: '18K & 20K Collection'),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: context.colorPalette.goldLight,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.08,
                                                ),
                                                blurRadius: 8,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: AspectRatio(
                                              aspectRatio: 3 / 4,
                                              child: Image.asset(
                                                'assets/images/ratnesh-collection.jpg',
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: context.getResponsiveSize(3)),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () =>
                                            _navigateToCategoryListing([Karat.k22]),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: context.colorPalette.goldLight,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.08,
                                                ),
                                                blurRadius: 8,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: AspectRatio(
                                              aspectRatio: 3 / 4,
                                              child: Image.asset(
                                                'assets/images/arham-collection.jpg',
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 12),
                              const CategoryDivider(vertical: 8),
                              const SizedBox(height: 12),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: context.getResponsiveSize(4),
                                ),
                                child: AspectRatio(
                                  aspectRatio: 16 / 9,
                                child: GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const ChainListingPage()),
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: context.colorPalette.goldLight,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.08,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.asset(
                                        'assets/images/chain-collection-16:9.png',
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              const CollectionsDivider(vertical: 4),
                            ],
                          ),
                        ),

                        SizedBox(height: context.heightPercent(2.5)),

                        Obx(() {
                          if (!categoryController.showProductSection) {
                            return const SizedBox();
                          }

                          return Column(
                            children: [
                              SizedBox(height: context.heightPercent(1)),
                              _ProductSection(
                                key: productSectionKey,
                                category: categoryController.selectedLevel3!,
                                onClose: categoryController.clearSelectedLevel3,
                              ),
                            ],
                          );
                        }),

                        SizedBox(height: context.heightPercent(1)),

                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: context.getResponsiveSize(4)),
                          child: _SectionTitle(
                            label: 'Latest Additions',
                            subtitle: 'Newest jewellery collections',
                            badge: 'LATEST',
                          ),
                        ),

                        SizedBox(height: context.getResponsiveSize(3)),

                        Obx(() {
                          final state = carouselController.productState;
                          final products = carouselController.latestProducts;
                          final cardWidth = context.widthPercent(42);
                          final cardHeight = cardWidth * 4 / 3 + 80;

                          if (state == CurrentAppState.LOADING &&
                              products.isEmpty) {
                            return SizedBox(
                              height: context.heightPercent(34),
                              child: ListView.separated(
                                padding: EdgeInsets.symmetric(
                                  horizontal: context.getResponsiveSize(4),
                                ),
                                scrollDirection: Axis.horizontal,
                                itemCount: 5,
                                separatorBuilder: (_, _) =>
                                    SizedBox(width: context.getResponsiveSize(3)),
                                itemBuilder: (_, _) {
                          final cardWidth = context.widthPercent(42);
                                  return Shimmer.fromColors(
                                    baseColor:
                                        context.colorPalette.shimmerBaseColor,
                                    highlightColor: context
                                        .colorPalette
                                        .shimmerHighLightColor,
                                    child: Container(
                                      width: cardWidth,
                                      height: cardWidth * 0.8 + context.heightPercent(14) + 16,
                                      decoration: BoxDecoration(
                                        color: context.colorPalette.cardBg,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: context.colorPalette.border,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Container(
                                            height: cardWidth * 0.8,
                                            decoration: const BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.vertical(
                                                    top: Radius.circular(15),
                                                  ),
                                            ),
                                            child: Center(
                                              child: Icon(
                                                Icons.diamond_outlined,
                                                size: 36,
                                                color: context
                                                    .colorPalette
                                                    .goldDark,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            height: context.heightPercent(14),
                                            padding: const EdgeInsets.all(8),
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
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Container(
                                                  height: 10,
                                                  width: 70,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
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
                                },
                              ),
                            );
                          }

                          if (state == CurrentAppState.ERROR &&
                              products.isEmpty) {
                            return Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: context.getResponsiveSize(4),
                              ),
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

                          return NotificationListener<ScrollNotification>(
                            onNotification: (scrollInfo) {
                              if (scrollInfo.metrics.pixels >=
                                  scrollInfo.metrics.maxScrollExtent - 200) {
                                carouselController.loadLatestProducts(
                                  isPagination: true,
                                );
                              }
                              return false;
                            },
                            child: SizedBox(
                              height: cardHeight,
                              child: ListView.separated(
                                padding: EdgeInsets.symmetric(
                                  horizontal: context.getResponsiveSize(4),
                                ),
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                itemCount:
                                    products.length +
                                    (carouselController.productLoadingMore
                                        ? 1
                                        : 0),
                                separatorBuilder: (_, _) =>
                                    SizedBox(width: context.getResponsiveSize(3)),
                                itemBuilder: (_, index) {
                                  if (index >= products.length) {
                                    return SizedBox(
                                      width: context.widthPercent(42),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: context.colorPalette.gold,
                                        ),
                                      ),
                                    );
                                  }

                                  final product = products[index];

                                  return SizedBox(
                                    width: context.widthPercent(42),
                                    child: ProductCard(
                                      product: product,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ProductDetailsPage(
                                                  product: product,
                                                  products: products,
                                                  initialIndex: index,
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

                        SizedBox(height: context.heightPercent(4)),

                        const CustomiseOrderBanner(),

                        const NavBarSpacer(),
                      ],
                    ),
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
    final productController = SearchProductController.instance;

    return Container(
      margin: EdgeInsets.fromLTRB(context.getResponsiveSize(4), 0, context.getResponsiveSize(4), context.heightPercent(3.5)),
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
                        fontSize: context.responsiveFont(19),
                        fontWeight: FontWeight.w800,
                        color: context.colorPalette.goldDeep,
                      ),
                    ),
                    Text(
                      'Browse products in this category',
                      style: TextStyle(
                        fontSize: context.responsiveFont(12),
                        color: context.colorPalette.goldDark,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: Container(
                  padding: EdgeInsets.all(context.getResponsiveSize(2)),
                  decoration: BoxDecoration(
                    color: context.colorPalette.goldLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: context.responsiveWidth(16, tabletVal: 20),
                    color: context.colorPalette.goldDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Obx(() {
            final state = productController.categoryState;
            final products = productController.categoryProducts;

            if (state == CurrentAppState.LOADING) {
              return SizedBox(
                height: context.heightPercent(36),
                child: Center(
                  child: CircularProgressIndicator(
                    color: context.colorPalette.gold,
                  ),
                ),
              );
            }

            if (state == CurrentAppState.ERROR || products.isEmpty) {
              return SizedBox(
                height: context.heightPercent(16),
                child: Center(
                  child: Text(
                    'No products found',
                    style: TextStyle(
                      color: context.colorPalette.goldDark,
                      fontSize: context.responsiveFont(14),
                    ),
                  ),
                ),
              );
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: context.gridColumns(phone: 2, tablet: 3),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: context.isTablet ? 0.55 : 0.488,
              ),
              itemBuilder: (_, index) {
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
        ],
      ),
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
        Icon(Icons.error_outline, color: Colors.red, size: context.responsiveWidth(18, tabletVal: 22)),

        SizedBox(width: context.getResponsiveSize(1.5)),

        Text(
          'Failed to load',
          style: TextStyle(color: Colors.red, fontSize: context.responsiveFont(13)),
        ),

        SizedBox(width: context.getResponsiveSize(2)),

        GestureDetector(
          onTap: onRetry,

          child: Text(
            'Retry',

            style: TextStyle(
              color: context.colorPalette.gold,
              fontSize: context.responsiveFont(13),
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
      padding: EdgeInsets.fromLTRB(context.getResponsiveSize(4), context.heightPercent(2.5), context.getResponsiveSize(4), context.heightPercent(1)),

      child: Row(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                LogoWidget(
                  logoSize: context.responsiveWidth(36, tabletVal: 50, largeTabletVal: 58),
                  showIcon: true,
                  showName: false,
                  showSubtitle: false,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'RATNESHGOLD',
                      style: GoogleFonts.bodoniModa(
                        fontSize: context.responsiveFont(16, tabletMultiplier: 1.5, largeTabletMultiplier: 1.8),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: context.colorPalette.goldDeep,
                      ),
                    ),
                    Text(
                      'Purity • Quality • Trust',
                      style: TextStyle(
                        fontSize: context.responsiveFont(11, tabletMultiplier: 1.5, largeTabletMultiplier: 1.8),
                        color: context.colorPalette.goldDark,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Spacer(),

          Obx(
            () => _IconBtn(
              icon: Icons.notifications_none_rounded,
              onTap: () => Get.toNamed(AppRoutes.notifications),
              badgeCount: Get.isRegistered<NotificationController>()
                  ? Get.find<NotificationController>().unreadCount.value
                  : 0,
            ),
          ),

          const SizedBox(width: 8),

          Obx(() {
            final auth = Get.find<AuthController>();
            return auth.isAdmin ? const SizedBox() : _IconBtn(
              icon: Icons.favorite_border,
              onTap: () {
                Get.toNamed(AppRoutes.wishlist);
              },
            );
          }),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int badgeCount;

  const _IconBtn({
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: context.responsiveWidth(40, tabletVal: 52, largeTabletVal: 60),
            height: context.responsiveWidth(40, tabletVal: 52, largeTabletVal: 60),
            decoration: BoxDecoration(
              color: context.colorPalette.goldLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.colorPalette.border),
            ),
            child: Icon(icon, size: context.responsiveWidth(20, tabletVal: 26, largeTabletVal: 30), color: context.colorPalette.goldDark),
          ),
          if (badgeCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: EdgeInsets.all(0),
                constraints: BoxConstraints(minWidth: context.responsiveWidth(18, tabletVal: 22, largeTabletVal: 26), minHeight: context.responsiveWidth(18, tabletVal: 22, largeTabletVal: 26)),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),
                  child: Text(
                    badgeCount > 99 ? '99+' : '$badgeCount',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: context.responsiveFont(10, tabletMultiplier: 1.2, largeTabletMultiplier: 1.3),
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

class _CarouselSection extends StatefulWidget {
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
  State<_CarouselSection> createState() => _CarouselSectionState();
}

class _CarouselSectionState extends State<_CarouselSection> {
  final Map<int, VideoPlayerController> _videoControllers = {};
  final Set<String> _failedVideoUrls = {};
  final Set<String> _pendingVideoUrls = {};
  bool _hasPreloaded = false;

  @override
  void didUpdateWidget(_CarouselSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _updateVideoPlayback();
    }
    if (oldWidget.controller.list.length != widget.controller.list.length) {
      _hasPreloaded = false;
    }
  }

  void _updateVideoPlayback() {
    for (final entry in _videoControllers.entries) {
      if (entry.key == widget.currentIndex) {
        if (entry.value.value.isInitialized && !entry.value.value.isPlaying) {
          entry.value.play();
        }
      } else {
        if (entry.value.value.isPlaying) {
          entry.value.pause();
        }
      }
    }
  }

  Future<void> _maybeInitVideo(int index, String url) async {
    if (_videoControllers.containsKey(index)) return;
    if (_failedVideoUrls.contains(url)) return;
    if (_pendingVideoUrls.contains(url)) return;
    _pendingVideoUrls.add(url);

    VideoPlayerController? ctrl;

    try {
      ctrl = VideoPlayerController.networkUrl(Uri.parse(url));
      _videoControllers[index] = ctrl;
      await ctrl.initialize();
    } catch (e) {
      ctrl?.dispose();
      _videoControllers.remove(index);
      Logger.warning("HomePage", "Network video failed for index $index, trying download fallback...");

      try {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/carousel_video_$index.mp4');
        if (!await file.exists()) {
          await Dio().download(url, file.path);
        }
        ctrl = VideoPlayerController.file(file);
        _videoControllers[index] = ctrl;
        await ctrl.initialize();
      } catch (e2, st2) {
        Logger.error("HomePage", "All video playback methods failed for carousel index $index", stackTrace: st2);
        _failedVideoUrls.add(url);
        _pendingVideoUrls.remove(url);
        _videoControllers.remove(index);
        ctrl?.dispose();
        return;
      }
    }

    _pendingVideoUrls.remove(url);

    try {
      ctrl.setLooping(true);
      ctrl.setVolume(0);
      if (mounted && index == widget.currentIndex) {
        ctrl.play();
        setState(() {});
      }
    } catch (e, st) {
      Logger.error("HomePage", "Failed to setup video for carousel index $index", stackTrace: st);
      _failedVideoUrls.add(url);
      _videoControllers.remove(index);
      ctrl.dispose();
    }
  }

  void _disposeVideoIfNeeded(int index) {
    if (index != widget.currentIndex && _videoControllers.containsKey(index)) {
      _videoControllers[index]?.dispose();
      _videoControllers.remove(index);
    }
  }

  static const int _batchSize = 3;

  void _preloadAllMedia(List<CarouselModel> list) {
    if (_hasPreloaded || list.isEmpty || !mounted) return;
    _hasPreloaded = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _preloadBatch(list, 0);
    });
  }

  void _preloadBatch(List<CarouselModel> list, int startIndex) {
    if (!mounted || startIndex >= list.length) return;

    final end = (startIndex + _batchSize).clamp(0, list.length);
    for (int i = startIndex; i < end; i++) {
      final item = list[i];
      if (item.mediaType == 'video') {
        _maybeInitVideo(i, item.imageUrl);
      } else if (item.imageUrl.isNotEmpty) {
        precacheImage(
          CachedNetworkImageProvider(item.imageUrl),
          context,
        );
      }
    }

    if (end < list.length) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _preloadBatch(list, end);
      });
    }
  }

  @override
  void dispose() {
    for (final ctrl in _videoControllers.values) {
      ctrl.dispose();
    }
    _videoControllers.clear();
    _failedVideoUrls.clear();
    _pendingVideoUrls.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (widget.controller.getCarouselState == CurrentAppState.LOADING && widget.controller.list.isEmpty) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 2.0,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: context.getResponsiveSize(4)),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: const CarouselShimmer(),
                ),
              ),
            ),
            const SizedBox(height: 6),
            const CarouselIndicatorShimmer(),
          ],
        );
      }

      if (widget.controller.getCarouselState == CurrentAppState.ERROR) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: context.getResponsiveSize(4)),
          height: context.heightPercent(20),

          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
          ),

          child: const Center(child: Text('Failed to load banners')),
        );
      }

      final list = widget.controller.list;

      if (list.isEmpty) return const SizedBox();

      if (!_hasPreloaded) {
        _preloadAllMedia(list);
      }

      return Column(
        children: [
          AspectRatio(
            aspectRatio: 2.0,

            child: PageView.builder(
              controller: widget.pageController,

              itemCount: list.length,

              onPageChanged: widget.onPageChanged,

              itemBuilder: (_, index) {
                final item = list[index];

                return Container(
                  margin: EdgeInsets.symmetric(horizontal: context.getResponsiveSize(4)),

                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),

                    boxShadow: [
                      BoxShadow(
                        color: context.colorPalette.gold.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),

                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),

                    child: _CarouselMediaItem(
                      item: item,
                      isActive: index == widget.currentIndex,
                      onVisible: item.mediaType == 'video'
                          ? () => _maybeInitVideo(index, item.imageUrl)
                          : () {},
                      onInvisible: () => _disposeVideoIfNeeded(index),
                      videoController: _videoControllers[index],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 6),

          CarouselIndicator(
            itemCount: list.length,
            currentIndex: widget.currentIndex,
          ),
        ],
      );
    });
  }
}

class _CarouselMediaItem extends StatefulWidget {
  final CarouselModel item;
  final bool isActive;
  final VoidCallback onVisible;
  final VoidCallback onInvisible;
  final VideoPlayerController? videoController;

  const _CarouselMediaItem({
    required this.item,
    required this.isActive,
    required this.onVisible,
    required this.onInvisible,
    this.videoController,
  });

  @override
  State<_CarouselMediaItem> createState() => _CarouselMediaItemState();
}

class _CarouselMediaItemState extends State<_CarouselMediaItem> {
  bool _wasActive = false;

  @override
  void didUpdateWidget(_CarouselMediaItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_wasActive) {
      widget.onVisible();
    } else if (!widget.isActive && _wasActive) {
      widget.onInvisible();
    }
    _wasActive = widget.isActive;
  }

  @override
  void initState() {
    super.initState();
    _wasActive = widget.isActive;
    if (widget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onVisible());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.item.mediaType == 'video') {
      if (widget.videoController != null && widget.videoController!.value.isInitialized) {
        final ctrl = widget.videoController!;
        return SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: ctrl.value.size.width,
              height: ctrl.value.size.height,
              child: VideoPlayer(ctrl),
            ),
          ),
        );
      }
      return Container(
        color: context.colorPalette.shimmerBaseColor,
        child: Center(
          child: Icon(
            Icons.play_circle_outline_rounded,
            size: context.getResponsiveSize(8),
            color: context.colorPalette.gold.withValues(alpha: 0.4),
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: widget.item.imageUrl,
      fit: BoxFit.cover,
      placeholder: (_, _) => CarouselShimmer(),
      errorWidget: (_, _, _) => Container(
        color: context.colorPalette.shimmerBaseColor,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;
  final String subtitle;
  final String? badge;

  const _SectionTitle({
    required this.label,
    required this.subtitle,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: context.responsiveFont(20),
                  fontWeight: FontWeight.w800,
                  color: context.colorPalette.goldDeep,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: context.colorPalette.gold,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: context.responsiveFont(10),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 2),

        Text(
          subtitle,
          style: TextStyle(fontSize: context.responsiveFont(14), color: context.colorPalette.goldDark),
        ),
      ],
    );
  }
}


// 🔥 CUSTOMISE ORDER BANNER COMPONENT

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
        final displayName = cat.name
            .replaceAll(RegExp(r'[^a-zA-Z\s]'), '')
            .replaceAll(RegExp(r'collection', caseSensitive: false), '')
            .trim()
            .toLowerCase();
        if (seen.add(displayName)) {
          unique.add(cat);
        }
      }
      if (unique.isEmpty) {
        return SizedBox(
          height: context.responsiveWidth(75, tabletVal: 145, largeTabletVal: 130) + 7 + context.heightPercent(5),
          child: Shimmer.fromColors(
            baseColor: context.colorPalette.shimmerBaseColor,
            highlightColor: context.colorPalette.shimmerHighLightColor,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              scrollDirection: Axis.horizontal,
              itemCount: 6,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (_, _) {
                return Column(
                  children: [
                    Container(
                      width: context.responsiveWidth(75, tabletVal: 145, largeTabletVal: 130),
                      height: context.responsiveWidth(75, tabletVal: 145, largeTabletVal: 130),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Container(
                      width: context.responsiveWidth(60, tabletVal: 115, largeTabletVal: 90),
                      height: context.heightPercent(3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      }

      return SizedBox(
        height: context.responsiveWidth(75, tabletVal: 145, largeTabletVal: 130) + 7 + context.heightPercent(5),
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          scrollDirection: Axis.horizontal,
          itemCount: unique.length,
          separatorBuilder: (_, _) => const SizedBox(width: 6),
          itemBuilder: (_, index) {
            final cat = unique[index];
            return GestureDetector(
              onTap: () {
                final cleanedName = cat.name
                    .replaceAll(RegExp(r'[^a-zA-Z\s]'), '')
                    .replaceAll(RegExp(r'collection', caseSensitive: false), '')
                    .trim();
                Get.to(() => SearchPage(
                  initialCategoryId: cat.id,
                  initialCategoryName: cleanedName,
                ));
              },
              child: Column(
                children: [
                  Container(
                    width: context.responsiveWidth(75, tabletVal: 145, largeTabletVal: 130),
                    height: context.responsiveWidth(75, tabletVal: 145, largeTabletVal: 130),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: context.colorPalette.gold.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                    child: ClipOval(
                      child: _CategoryQuickAccessImage(cat: cat),
                    ),
                  ),
                  const SizedBox(height: 7),
                  SizedBox(
                    width: context.responsiveWidth(90, tabletVal: 170, largeTabletVal: 150),
                    child: Text(
                      cat.name
                          .replaceAll(RegExp(r'[^a-zA-Z\s]'), '')
                          .replaceAll(RegExp(r'collection', caseSensitive: false), '')
                          .trim(),
                      style: TextStyle(
                        fontSize: context.responsiveFont(11),
                        fontWeight: FontWeight.w600,
                        color: context.colorPalette.goldDeep,
                        height: 1.2,
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
      );
    });
  }
}

class _CategoryQuickAccessImage extends StatelessWidget {
  final CategoryModel cat;

  const _CategoryQuickAccessImage({
    required this.cat,
  });

  @override
  Widget build(BuildContext context) {
    if (cat.imageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: cat.imageUrl,
        width: context.responsiveWidth(75, tabletVal: 145, largeTabletVal: 130),
        height: context.responsiveWidth(75, tabletVal: 145, largeTabletVal: 130),
        fit: BoxFit.cover,
        errorWidget: (_, _, _) => const RatneshFallback.s(),
      );
    }

    return const RatneshFallback.s();
  }
}

class CustomiseOrderBanner extends StatelessWidget {
  final VoidCallback? onTap;
  const CustomiseOrderBanner({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Customise your jewelry order. Tap to start designing.',
      button: true,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.getResponsiveSize(4),
          vertical: context.heightPercent(0.5),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap ?? () => Get.to(() => const CustomiseOrderPage()),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [
                    AppColors.goldGradientLight,
                    AppColors.goldGradientDark,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: context.colorPalette.goldDeep.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(
                  color: context.colorPalette.goldDeep.withValues(alpha: 0.15),
                  width: 1.5,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.getResponsiveSize(2.5),
                        vertical: context.heightPercent(0.4),
                      ),
                      decoration: BoxDecoration(
                        color: context.colorPalette.goldDeep,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(16),
                          bottomLeft: Radius.circular(10),
                        ),
                      ),
                      child: Text(
                        "Bespoke Service",
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: context.responsiveFont(9),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.all(context.getResponsiveSize(3.5)),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Craft Your",
                                style: TextStyle(
                                  color: AppColors.deepEspresso,
                                  fontSize: context.responsiveFont(18),
                                  fontWeight: FontWeight.w900,
                                  height: 1.1,
                                ),
                              ),
                              Text(
                                "Dream Jewelry",
                                style: TextStyle(
                                  color: AppColors.deepEspresso.withValues(alpha: 0.8),
                                  fontSize: context.responsiveFont(14),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),

                              SizedBox(height: context.heightPercent(0.8)),

                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildFeatureText(context, "Imagine"),
                                    _buildBulletDot(context),
                                    _buildFeatureText(context, "Upload"),
                                    _buildBulletDot(context),
                                    _buildFeatureText(context, "Craft"),
                                  ],
                                ),
                              ),

                              SizedBox(height: context.heightPercent(0.8)),

                              Text(
                                "Turn your unique inspirations into stunning gold masterpieces.",
                                style: TextStyle(
                                  color: AppColors.espressoMuted,
                                  fontSize: context.responsiveFont(10),
                                  fontWeight: FontWeight.w600,
                                  height: 1.2,
                                ),
                              ),

                              SizedBox(height: context.heightPercent(1.2)),

                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: context.getResponsiveSize(3),
                                  vertical: context.heightPercent(0.6),
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: context.colorPalette.gold.withValues(alpha: 0.5),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: context.colorPalette.gold.withValues(alpha: 0.1),
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
                                        fontSize: context.responsiveFont(11),
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    SizedBox(width: context.getResponsiveSize(1)),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      color: context.colorPalette.goldDeep,
                                      size: context.responsiveWidth(12, tabletVal: 16),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        Expanded(
                          flex: 4,
                          child: Center(
                            child: Container(
                              width: context.responsiveWidth(80, tabletVal: 120),
                              height: context.responsiveWidth(80, tabletVal: 120),
                              decoration: BoxDecoration(
                                color: AppColors.white.withValues(alpha: 0.7),
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.white, width: 1.5),
                              ),
                              child: Center(
                                child: ClipOval(
                                  child: ColorFiltered(
                                    colorFilter: ColorFilter.mode(
                                      context.colorPalette.goldDeep,
                                      BlendMode.srcIn,
                                    ),
                                    child: Image.asset(
                                      'assets/images/bespoke-icon.png',
                                      width: context.responsiveWidth(60, tabletVal: 90),
                                      height: context.responsiveWidth(60, tabletVal: 90),
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
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
          ),
        ),
      ),
    );
  }

  Widget _buildBulletDot(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.getResponsiveSize(0.8)),
      child: Icon(Icons.circle, size: context.responsiveWidth(3, tabletVal: 4), color: AppColors.deepEspresso),
    );
  }

  Widget _buildFeatureText(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.deepEspresso,
        fontSize: context.responsiveFont(9),
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

