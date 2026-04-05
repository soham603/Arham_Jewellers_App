import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/presentation/controllers/CategoryController.dart';
import 'package:ratnesh_gold_app/presentation/controllers/carousel_controller.dart';
import 'package:ratnesh_gold_app/presentation/shimmers/carouselShimmer.dart';
import 'package:ratnesh_gold_app/presentation/shimmers/categoryShimmer.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/product_card.dart';
import '../../controllers/catalog_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CatalogController catalogController = Get.put(CatalogController());
  final CarouselsController carouselController = Get.put(CarouselsController());
  final CategoryController categoryController = Get.put(CategoryController());

  final PageController pageController = PageController();
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    carouselController.getAllCarousels();
    categoryController.getAllCategories();
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
                              Icon(
                                Icons.search,
                                color: Color(0xFF8D847A),
                                size: 20,
                              ),
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

                      // Carousel Slder Section
                      Obx(() {
                        if (carouselController.getCarouselState ==
                            CurrentAppState.LOADING) {
                          return const CarouselShimmer();
                        }

                        if (carouselController.getCarouselState ==
                            CurrentAppState.ERROR) {
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
                                const Icon(
                                  Icons.error,
                                  color: Colors.red,
                                  size: 32,
                                ),
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
                                onPageChanged: (index) {
                                  setState(() => currentIndex = index);
                                },
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
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          child: CachedNetworkImage(
                                            imageUrl: item.imageUrl,
                                            width: double.infinity,
                                            height: double.infinity,
                                            fit: BoxFit.cover,
                                            placeholder: (_, _) =>
                                                const CarouselShimmer(),
                                            errorWidget: (_, __, ___) =>
                                                Container(color: Colors.grey),
                                          ),
                                        ),
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
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
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.title,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: context
                                                      .getScreenWidth(5),
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                item.description,
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: context
                                                      .getScreenWidth(3.5),
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                "→ Shop Now",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: context
                                                      .getScreenWidth(3.8),
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

                            /// 🔥 DOT INDICATOR
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(list.length, (index) {
                                final isActive = index == currentIndex;

                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
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

                      const SizedBox(height: 14),

                      const Text(
                        'Categories',
                        style: TextStyle(
                          fontSize: 31,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Category List Section
                      Obx(() {
                        switch (categoryController.state) {
                          case CurrentAppState.LOADING:
                            return const CategoryShimmer();

                          case CurrentAppState.ERROR:
                            return Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                    size: context.getScreenWidth(8),
                                  ),
                                  SizedBox(height: context.getScreenHeight(1)),
                                  Text(
                                    "Failed to load categories",
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: context.getScreenWidth(3.5),
                                    ),
                                  ),
                                  SizedBox(height: context.getScreenHeight(1)),
                                  TextButton(
                                    onPressed: () =>
                                        categoryController.getAllCategories(),
                                    child: const Text("Retry"),
                                  ),
                                ],
                              ),
                            );

                          case CurrentAppState.SUCCESS:
                            if (categoryController.categoryList.isEmpty) {
                              return const SizedBox();
                            }

                            return SizedBox(
                              height: context.getScreenHeight(12),
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: categoryController.categoryList.length,
                                separatorBuilder: (_, __) =>
                                    SizedBox(width: context.getScreenWidth(3)),
                                itemBuilder: (context, index) {
                                  final c = categoryController.categoryList[index];
                                  return Container(
                                    width: context.getScreenWidth(18),
                                    padding: EdgeInsets.symmetric(
                                      vertical: context.getScreenHeight(0.8),
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          context.colorPalette.backgroundColor,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: context.colorPalette.boxColor,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          width: context.getScreenWidth(11),
                                          height: context.getScreenHeight(5),
                                          decoration: BoxDecoration(
                                            color:
                                                context.colorPalette.boxColor,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: CachedNetworkImage(
                                              imageUrl: c.imageUrl,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) =>
                                                  Container(
                                                    color: context
                                                        .colorPalette
                                                        .shimmerBaseColor,
                                                  ),
                                              errorWidget: (_, __, ___) => Icon(
                                                Icons.image_not_supported,
                                                size: context.getScreenWidth(4),
                                                color: context
                                                    .colorPalette
                                                    .subTitleColor,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          height: context.getScreenHeight(0.6),
                                        ),
                                        Text(
                                          c.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: context.getScreenWidth(3),
                                            color:
                                                context.colorPalette.textColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            );
                          default:
                            return const SizedBox();
                        }
                      }),

                      const SizedBox(height: 12),
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
                          final item = catalogController.products[index];
                          return GestureDetector(
                            onTap: () => Get.toNamed(AppRoutes.details),
                            child: ProductCard(product: item),
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
