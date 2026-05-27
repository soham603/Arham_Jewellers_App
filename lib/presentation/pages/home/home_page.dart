import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/core/widgets/custom_divider.dart';
import 'package:ratnesh_gold_app/core/widgets/product_card.dart';
import 'package:ratnesh_gold_app/domain/entities/category_model.dart';
import 'package:ratnesh_gold_app/presentation/controllers/CategoryController.dart';
import 'package:ratnesh_gold_app/presentation/controllers/carousel_controller.dart';
import 'package:ratnesh_gold_app/presentation/pages/product/product_details_page.dart';
import 'package:ratnesh_gold_app/presentation/shimmers/carouselShimmer.dart';
import 'package:ratnesh_gold_app/presentation/shimmers/categoryShimmer.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';
import 'package:shimmer/shimmer.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/app_bottom_nav.dart';

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

  @override
  void initState() {
    super.initState();
    carouselController.getAllCarousels();
    categoryController.fetchAllKaratCategories();
  }

  @override
  void dispose() {
    scrollController.dispose();
    pageController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorPalette.cream,

      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    const _TopBar(),

                    const SizedBox(height: 6),

                    // Padding(
                    //   padding: const EdgeInsets.symmetric(horizontal: 16),
                    //   child: _SearchBar(),
                    // ),
                    const SizedBox(height: 14),

                    _CarouselSection(
                      controller: carouselController,
                      pageController: pageController,
                      currentIndex: currentCarouselIndex,

                      onPageChanged: (i) {
                        setState(() {
                          currentCarouselIndex = i;
                        });
                      },
                    ),

                    SizedBox(height: context.getScreenHeight(1)),

                    JewelleryDivider(),

                    SizedBox(height: context.getScreenHeight(1)),

                    // const _QuickStatsStrip(),

                    // const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),

                      child: _SectionTitle(
                        label: 'Arham Gold',
                        subtitle: '18K & 20K Collection',
                      ),
                    ),

                    const SizedBox(height: 12),

                    _KaratSection(
                      karat: Karat.k18,
                      controller: categoryController,
                      onLevel3Selected: scrollToProductSection,
                    ),

                    SizedBox(height: context.getScreenHeight(4)),

                    _KaratSection(
                      karat: Karat.k20,
                      controller: categoryController,
                      onLevel3Selected: scrollToProductSection,
                    ),

                    SizedBox(height: context.getScreenHeight(1)),

                    JewelleryDivider(),

                    SizedBox(height: context.getScreenHeight(1)),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),

                      child: _SectionTitle(
                        label: 'Ratnesh Gold',
                        subtitle: '22K Premium Collection',
                      ),
                    ),

                    const SizedBox(height: 12),

                    _KaratSection(
                      karat: Karat.k22,
                      controller: categoryController,
                      onLevel3Selected: scrollToProductSection,
                    ),

                   
                    SizedBox(height: context.getScreenHeight(2)),

                    Obx(() {
                      if (!categoryController.showProductSection) {
                        return const SizedBox();
                      }

                      return Column(
                        children: [

                    JewelleryDivider(),

                    SizedBox(height: context.getScreenHeight(1)),
                          _ProductSection(
                            key: productSectionKey,
                            category: categoryController.selectedLevel3!,
                            onClose: categoryController.clearSelectedLevel3,
                          ),
                        ],
                      );
                    }),

                    // Padding(
                    //   padding: const EdgeInsets.symmetric(horizontal: 16),

                    //   child: _SectionTitle(
                    //     label: 'Trending Now',
                    //     subtitle: 'Most loved this week',
                    //   ),
                    // ),

                    // const SizedBox(height: 12),

                    // const _TrendingPlaceholder(),

                    JewelleryDivider(),

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
                          height: context.getScreenHeight(36),
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
                                  width: context.getScreenWidth(42),
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
                        height: context.getScreenHeight(38),
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
                                  width: context.getScreenWidth(42),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: context.colorPalette.gold,
                                    ),
                                  ),
                                );
                              }

                              final product = products[index];

                              return SizedBox(
                                width: context.getScreenWidth(42),
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

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),

            AppBottomNav(currentIndex: 0),
          ],
        ),
      ),
    );
  }
}

class _KaratSection extends StatelessWidget {
  final Karat karat;
  final CategoryController controller;
  final VoidCallback onLevel3Selected;

  const _KaratSection({
    required this.karat,
    required this.controller,
    required this.onLevel3Selected,
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

                Text(
                  'See all →',

                  style: TextStyle(
                    fontSize: 12.5,
                    color: context.colorPalette.goldDark,
                    fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),

      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,

                    decoration: BoxDecoration(
                      color: context.colorPalette.gold,
                      borderRadius: BorderRadius.circular(8),
                    ),

                    child: const Icon(
                      Icons.diamond,
                      color: Colors.white,
                      size: 17,
                    ),
                  ),

                  const SizedBox(width: 10),

                  Text(
                    'Ratnesh Gold',

                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: context.colorPalette.goldDeep,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 2),

              Text(
                'Pure gold. Pure trust.',

                style: TextStyle(
                  fontSize: 11,
                  color: context.colorPalette.goldDark,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),

          const Spacer(),

          _IconBtn(icon: Icons.notifications_none_rounded, onTap: () {}),

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

  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        width: 40,
        height: 40,

        decoration: BoxDecoration(
          color: context.colorPalette.goldLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.colorPalette.border),
        ),

        child: Icon(icon, size: 20, color: context.colorPalette.goldDark),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Get.toNamed(AppRoutes.search),

      borderRadius: BorderRadius.circular(14),

      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),

        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),

          border: Border.all(color: context.colorPalette.border, width: 1.5),

          color: context.colorPalette.cardBg,

          boxShadow: [
            BoxShadow(
              color: context.colorPalette.gold.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),

        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: context.colorPalette.goldDark,
              size: 20,
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Text(
                'Search rings, necklaces, bangles...',

                style: TextStyle(fontSize: 14.5, color: Colors.grey.shade500),
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

              decoration: BoxDecoration(
                color: context.colorPalette.goldLight,
                borderRadius: BorderRadius.circular(6),
              ),

              child: Text(
                'Search',

                style: TextStyle(
                  fontSize: 11,
                  color: context.colorPalette.goldDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
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

      return Column(
        children: [
          SizedBox(
            height: context.getScreenHeight(22),

            child: PageView.builder(
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

                    child: Stack(
                      fit: StackFit.expand,

                      children: [
                        CachedNetworkImage(
                          imageUrl: item.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => CarouselShimmer(),
                          errorWidget: (_, __, ___) => Container(
                            color: context.colorPalette.shimmerBaseColor,
                          ),
                        ),

                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(0.62),
                                Colors.transparent,
                              ],

                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                        ),

                        Positioned(
                          top: 12,
                          right: 14,

                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),

                            decoration: BoxDecoration(
                              color: context.colorPalette.gold.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                            ),

                            child: const Text(
                              'SALE',

                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),

                        Positioned(
                          left: 16,
                          right: 60,
                          bottom: 18,

                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              Text(
                                item.title,

                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                item.description,

                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,

                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12.5,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),

                                decoration: BoxDecoration(
                                  color: context.colorPalette.gold,
                                  borderRadius: BorderRadius.circular(8),
                                ),

                                child: const Text(
                                  'Shop Now →',

                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
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
          ),

          const SizedBox(height: 10),

          Row(
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
        ],
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
