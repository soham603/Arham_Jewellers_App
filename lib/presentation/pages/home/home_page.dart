import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/domain/entities/category_model.dart';
import 'package:ratnesh_gold_app/presentation/controllers/CategoryController.dart';
import 'package:ratnesh_gold_app/presentation/controllers/carousel_controller.dart';
import 'package:ratnesh_gold_app/presentation/shimmers/carouselShimmer.dart';
import 'package:ratnesh_gold_app/presentation/shimmers/categoryShimmer.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_bottom_nav.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //final CatalogController catalogController = Get.put(CatalogController());
  final CarouselsController carouselController = Get.put(CarouselsController());
  final CategoryController categoryController = Get.put(CategoryController());

  final PageController pageController = PageController();
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    carouselController.getAllCarousels();
    // fetch all 3 karats in parallel — single call, no repeat
    categoryController.fetchAllKaratCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Search Bar ────────────────────────────────────────
                      InkWell(
                        onTap: () => Get.toNamed(AppRoutes.search),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFCFC7BC)),
                            color: const Color(0xFFF4F1EC),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.search, color: Color(0xFF8D847A), size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Search gold, diamonds, rings...',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 19,
                                    color: Color(0xFFA29A90),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Carousel ──────────────────────────────────────────
                      Obx(() {
                        if (carouselController.getCarouselState == CurrentAppState.LOADING) {
                          return const CarouselShimmer();
                        }

                        if (carouselController.getCarouselState == CurrentAppState.ERROR) {
                          return Container(
                            width: double.infinity,
                            height: context.getScreenHeight(22),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error, color: Colors.red, size: 32),
                                const SizedBox(height: 8),
                                Text(
                                  "Failed to load banners",
                                  style: TextStyle(
                                    color: context.colorPalette.textColor,
                                    fontSize: context.getScreenWidth(3.8),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final list = carouselController.list;
                        if (list.isEmpty) return const SizedBox();

                        return Column(
                          children: [
                            SizedBox(
                              height: context.getScreenHeight(22),
                              child: PageView.builder(
                                controller: pageController,
                                itemCount: list.length,
                                onPageChanged: (index) =>
                                    setState(() => currentIndex = index),
                                itemBuilder: (context, index) {
                                  final item = list[index];
                                  return Container(
                                    margin: EdgeInsets.symmetric(
                                      horizontal: context.getScreenWidth(2),
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(14),
                                          child: CachedNetworkImage(
                                            imageUrl: item.imageUrl,
                                            width: double.infinity,
                                            height: double.infinity,
                                            fit: BoxFit.cover,
                                            placeholder: (_, __) => const CarouselShimmer(),
                                            errorWidget: (_, __, ___) =>
                                                Container(color: Colors.grey),
                                          ),
                                        ),
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(14),
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.black.withOpacity(0.6),
                                                Colors.transparent,
                                              ],
                                              begin: Alignment.bottomCenter,
                                              end: Alignment.topCenter,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left: 16,
                                          right: 16,
                                          bottom: 16,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.title,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: context.getScreenWidth(5),
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                item.description,
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: context.getScreenWidth(3.5),
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                "→ Shop Now",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: context.getScreenWidth(3.8),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(list.length, (index) {
                                final isActive = index == currentIndex;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  width: isActive ? 10 : 6,
                                  height: isActive ? 10 : 6,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? context.colorPalette.primaryColor
                                        : Colors.grey,
                                    shape: BoxShape.circle,
                                  ),
                                );
                              }),
                            ),
                          ],
                        );
                      }),

                      const SizedBox(height: 20),

                     Text(
                        'Arham Gold Categories',
                        style: TextStyle(
                          fontSize: context.getScreenWidth(5),
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 14),

                      _KaratSection(
                        karat: Karat.k18,
                        controller: categoryController,
                      ),
                      const SizedBox(height: 16),
                      _KaratSection(
                        karat: Karat.k20,
                        controller: categoryController,
                      ),
                      const SizedBox(height: 16),
                      const SizedBox(height: 16),
                      Text(
                        'Ratnesh Gold Categories',
                        style: TextStyle(
                          fontSize: context.getScreenWidth(5),
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _KaratSection(
                        karat: Karat.k22,
                        controller: categoryController,
                      ),

                      const SizedBox(height: 20),

                      // ── Trending Now ──────────────────────────────────────
                      const Text(
                        'Trending Now',
                        style: TextStyle(
                          fontSize: 31,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GridView.builder(
                        itemCount: 4,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 0.66,
                        ),
                        itemBuilder: (context, index) {
                          //final item = catalogController.products[index];
                          return GestureDetector(
                            onTap: () => Get.toNamed(AppRoutes.details),
                            //child: ProductCard(product: item),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const AppBottomNav(currentIndex: 0),
          ],
        ),
      ),
    );
  }
}

// ── Karat Section Widget ──────────────────────────────────────────────────────

class _KaratSection extends StatelessWidget {
  final Karat karat;
  final CategoryController controller;

  const _KaratSection({required this.karat, required this.controller});

  CurrentAppState _stateFor() {
    switch (karat) {
      case Karat.k18: return controller.k18State;
      case Karat.k20: return controller.k20State;
      case Karat.k22: return controller.k22State;
    }
  }

  List<CategoryModel> _listFor() {
    switch (karat) {
      case Karat.k18: return controller.k18Categories;
      case Karat.k20: return controller.k20Categories;
      case Karat.k22: return controller.k22Categories;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = _stateFor();
      final list = _listFor();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Karat Header Row ────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4EED8),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFD4AF37)),
                    ),
                    child: Text(
                      karat.displayName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF8B6914),
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Gold',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: context.colorPalette.textColor,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  // navigate to full category listing for this karat
                  // e.g. Get.toNamed(AppRoutes.categoryList, arguments: karat)
                },
                child: Text(
                  'See all →',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.colorPalette.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Content ─────────────────────────────────────────────────────
          if (state == CurrentAppState.LOADING)
            const CategoryShimmer()
          else if (state == CurrentAppState.ERROR)
            _ErrorRow(onRetry: () => controller.fetchCategoriesForKarat(karat))
          else if (list.isEmpty && state == CurrentAppState.SUCCESS)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No categories found',
                style: TextStyle(
                  color: context.colorPalette.subTitleColor,
                  fontSize: 13,
                ),
              ),
            )
          else
            SizedBox(
              height: context.getScreenHeight(12),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: list.length,
                separatorBuilder: (_, __) =>
                    SizedBox(width: context.getScreenWidth(3)),
                itemBuilder: (context, index) {
                  final c = list[index];
                  return GestureDetector(
                    onTap: () {
                      // e.g. Get.toNamed(AppRoutes.subCategory, arguments: c)
                    },
                    child: Container(
                      width: context.getScreenWidth(18),
                      padding: EdgeInsets.symmetric(
                        vertical: context.getScreenHeight(0.8),
                      ),
                      decoration: BoxDecoration(
                        color: context.colorPalette.backgroundColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: context.colorPalette.boxColor),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: context.getScreenWidth(11),
                            height: context.getScreenHeight(5),
                            decoration: BoxDecoration(
                              color: context.colorPalette.boxColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: c.imageUrl ?? '',
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  color: context.colorPalette.shimmerBaseColor,
                                ),
                                errorWidget: (_, __, ___) => Icon(
                                  Icons.image_not_supported,
                                  size: context.getScreenWidth(4),
                                  color: context.colorPalette.subTitleColor,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: context.getScreenHeight(0.6)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              c.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: context.getScreenWidth(3),
                                color: context.colorPalette.textColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      );
    });
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
        Text(
          'Failed to load',
          style: TextStyle(
            color: Colors.red,
            fontSize: context.getScreenWidth(3.2),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onRetry,
          child: Text(
            'Retry',
            style: TextStyle(
              color: context.colorPalette.primaryColor,
              fontSize: context.getScreenWidth(3.2),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}