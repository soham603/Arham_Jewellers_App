import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';

class CustomOrderSuccessPage extends StatelessWidget {
  const CustomOrderSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: context.getResponsiveSize(8)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: context.getResponsiveSize(28),
                  height: context.getResponsiveSize(28),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryGold.withValues(alpha: 0.12),
                  ),
                  child: Icon(
                    Icons.check_circle_outline_rounded,
                    color: AppColors.primaryGold,
                    size: context.getResponsiveSize(14),
                  ),
                ),
                SizedBox(height: context.heightPercent(3)),
                Text(
                  'Order Submitted!',
                  style: TextStyle(
                    fontSize: context.getResponsiveSize(7),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: context.heightPercent(1.5)),
                Text(
                  'Your custom order has been placed successfully. Our team will review and contact you shortly.',
                  style: TextStyle(
                    fontSize: context.getResponsiveSize(3.8),
                    color: AppColors.textMuted,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: context.heightPercent(5)),
                SizedBox(
                  width: double.infinity,
                  height: context.heightPercent(6),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => Get.offAllNamed('/home'),
                    child: Text(
                      'Back to Home',
                      style: TextStyle(
                        fontSize: context.getResponsiveSize(4.2),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: context.heightPercent(2)),
                TextButton(
                  onPressed: () => Get.offAllNamed('/my-orders'),
                  child: Text(
                    'View My Orders',
                    style: TextStyle(
                      fontSize: context.getResponsiveSize(3.8),
                      color: AppColors.primaryGold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }
}
