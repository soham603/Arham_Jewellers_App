import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';

import '../../app/routes/app_routes.dart';
import '../../presentation/controllers/navigation_controller.dart';

class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        try {
          Get.find<NavigationController>().switchTab(AppRoutes.tabIndexSearch);
        } catch (_) {
          Get.toNamed(AppRoutes.search);
        }
      },

      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),

        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          color: const Color(0xFFF5F1EC),
          border: Border.all(
            color: context.colorPalette.gold.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: context.colorPalette.gold.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
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

            const SizedBox(width: 12),

            Expanded(
              child: Text(
                'Search gold, diamonds, rings...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF9E9590),
                ),
              ),
            ),

            Icon(
              Icons.mic_none_rounded,
              color: context.colorPalette.goldDark,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
