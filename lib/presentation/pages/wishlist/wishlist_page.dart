import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/core/widgets/product_card.dart';
import 'package:ratnesh_gold_app/presentation/controllers/wishlist_controller.dart';
import 'package:ratnesh_gold_app/presentation/pages/product/product_details_page.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  late final WishlistController _wishlistController;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<WishlistController>()) {
      _wishlistController = Get.find<WishlistController>();
    } else {
      _wishlistController = Get.put(WishlistController());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.pageBg,
        titleSpacing: context.getResponsiveSize(4),
        title: Text(
          'Wishlist',
          style: TextStyle(
            fontSize: context.getResponsiveSize(5.5),
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        actions: [
          Obx(
            () => Padding(
              padding: EdgeInsets.only(right: context.getResponsiveSize(4)),
              child: Center(
                child: Text(
                  '${_wishlistController.totalItems} item${_wishlistController.totalItems != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: context.getResponsiveSize(4),
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Obx(() {
        final items = _wishlistController.items;

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.favorite_border_rounded,
                  color: AppColors.primaryGold.withOpacity(0.4),
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'No wishlisted items yet',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: context.getResponsiveSize(4.2),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the heart icon on any product to save it here',
                  style: TextStyle(
                    color: AppColors.textMuted.withOpacity(0.6),
                    fontSize: context.getResponsiveSize(3.2),
                  ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: context.gridColumns(phone: 2, tablet: 3),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: context.isTablet ? 0.55 : 0.488,
          ),
          itemBuilder: (_, index) {
            final product = items[index];
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
