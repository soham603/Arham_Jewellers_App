import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/app/routes/app_routes.dart';

import '../theme/app_colors.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    required this.currentIndex,
    super.key,
  });

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    const labels = [
      'Home',
      'Search',
      'Wishlist',
      'Cart',
      'Profile',
    ];

    const icons = [
      Icons.home_rounded,
      Icons.search_rounded,
      Icons.favorite_rounded,
      Icons.shopping_cart_rounded,
      Icons.person_rounded,
    ];

    return Container(
      height: 70,

      decoration: const BoxDecoration(
        color: Colors.white,

        border: Border(
          top: BorderSide(
            color: AppColors.divider,
          ),
        ),
      ),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,

        children: List.generate(labels.length, (index) {
          final selected = index == currentIndex;

          return Expanded(
            child: InkWell(
              onTap: () {
                _handleNavigation(index);
              },

              borderRadius: BorderRadius.circular(14),

              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),

                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                ),

                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                  
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                  
                        width: 38,
                        height: 38,
                  
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                  
                          color: selected
                              ? const Color(0xFFE0DAD2)
                              : const Color(0xFFF2EEEA),
                        ),
                  
                        child: Icon(
                          icons[index],
                  
                          size: 20,
                  
                          color: selected
                              ? AppColors.textDark
                              : const Color(0xFF847B71),
                        ),
                      ),
                  
                      const SizedBox(height: 6),
                  
                      Text(
                        labels[index],
                  
                        style: TextStyle(
                          fontSize: 11,
                  
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                  
                          color: selected
                              ? AppColors.textDark
                              : const Color(0xFF847B71),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  void _handleNavigation(int index) {

    if (index == currentIndex) return;

    switch (index) {

      case 0:
        Get.offAllNamed("/home");
        break;

      case 1:
        Get.offAllNamed("/search");
        break;

      case 2:
        Get.offAllNamed("/wishlist");
        break;

      case 3:
        Get.offAllNamed("/cart");
        break;

      case 4:
        Get.offAllNamed(AppRoutes.profile);
        break;
    }
  }
}