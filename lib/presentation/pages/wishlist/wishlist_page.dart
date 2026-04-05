import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../controllers/wishlist_controller.dart';

class WishlistPage extends StatelessWidget {
  WishlistPage({super.key});

  final WishlistController wishlistController = Get.put(WishlistController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishlist', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w700)),
        actions: const [Padding(padding: EdgeInsets.only(right: 16), child: Center(child: Text('12 items', style: TextStyle(fontSize: 20, color: AppColors.textMuted))))],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Obx(
                () => ListView.separated(
                  itemCount: wishlistController.wishlist.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = wishlistController.wishlist[index];
                    return Container(
                      height: 76,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE3DDD5)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 66,
                            height: 56,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE7E2DB),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text('[ Product ]', style: TextStyle(fontSize: 7, color: Color(0xFF948470))),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                                Text('₹${item.price}', style: const TextStyle(fontSize: 18, color: AppColors.primaryGold, fontWeight: FontWeight.w700)),
                                const Text('In Stock', style: TextStyle(fontSize: 16, color: AppColors.success)),
                              ],
                            ),
                          ),
                          const Icon(Icons.favorite_border, color: AppColors.primaryGold),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {},
                child: const Text('Move All to Cart', style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
          const AppBottomNav(currentIndex: 2),
        ],
      ),
    );
  }
}
