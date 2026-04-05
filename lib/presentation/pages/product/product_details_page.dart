import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';

class ProductDetailsPage extends StatelessWidget {
  const ProductDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 350,
              width: double.infinity,
              color: const Color(0xFFE6E1D9),
              alignment: Alignment.center,
              child: const Text('[ Product Image ]', style: TextStyle(fontSize: 30, color: Color(0xFF8C7E68))),
            ),
            const SizedBox(height: 8),
            const Text('•  •  •', style: TextStyle(fontSize: 20, color: Color(0xFFC5B9A7))),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                width: double.infinity,
                color: AppColors.pageBg,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('22K Yellow Gold Floral Ring', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                      const SizedBox(height: 6),
                      const Text('⭐ 4.8  (124 reviews)', style: TextStyle(fontSize: 21, color: AppColors.textMuted)),
                      const SizedBox(height: 2),
                      const Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('₹ 12,450', style: TextStyle(fontSize: 50, fontWeight: FontWeight.w700, color: AppColors.primaryGold)),
                          SizedBox(width: 6),
                          Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Text('(incl. making charges)', style: TextStyle(fontSize: 18, color: AppColors.textMuted)),
                          ),
                        ],
                      ),
                      const Divider(height: 18),
                      const Text('Product Details', style: TextStyle(fontSize: 31, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      _detailRow('Purity', '22K (916 Hallmark)'),
                      _detailRow('Weight', '1.2 grams'),
                      _detailRow('Making Charges', '₹850'),
                      _detailRow('Stone', 'None'),
                      const SizedBox(height: 12),
                      const Text('Reviews', style: TextStyle(fontSize: 31, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      const Text('⭐⭐⭐⭐⭐ 4.8 out of 5', style: TextStyle(fontSize: 29, color: AppColors.textDark)),
                      const Text('Based on 124 reviews', style: TextStyle(fontSize: 18, color: AppColors.textMuted)),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE2DCD4),
                      foregroundColor: AppColors.primaryGold,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {},
                    child: const Text('Add to Cart', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Get.toNamed(AppRoutes.cart),
                    child: const Text('Buy Now', style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w700)),
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

Widget _detailRow(String left, String right) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(child: Text(left, style: const TextStyle(fontSize: 24, color: AppColors.textMuted))),
        Text(right, style: const TextStyle(fontSize: 24, color: AppColors.textDark)),
      ],
    ),
  );
}
