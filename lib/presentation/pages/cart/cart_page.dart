import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../controllers/cart_controller.dart';

class CartPage extends StatelessWidget {
  CartPage({super.key});

  final CartController cartController = Get.put(CartController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w700)),
        leading: IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.arrow_back)),
        actions: const [Padding(padding: EdgeInsets.only(right: 16), child: Center(child: Text('3 items', style: TextStyle(fontSize: 20, color: AppColors.textMuted))))],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Column(
          children: [
            Expanded(
              child: Obx(
                () => ListView(
                  children: [
                    ...List.generate(cartController.items.length, (index) {
                      final item = cartController.items[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE3DDD5)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(color: const Color(0xFFE7E2DB), borderRadius: BorderRadius.circular(10)),
                                child: const Text('[ Product ]', style: TextStyle(fontSize: 7, color: Color(0xFF948470))),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.product.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                                    Text('₹${item.product.price}', style: const TextStyle(fontSize: 30, color: AppColors.primaryGold, fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 6),
                                    Container(
                                      width: 110,
                                      height: 34,
                                      decoration: BoxDecoration(color: const Color(0xFFF1ECE4), borderRadius: BorderRadius.circular(8)),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          InkWell(onTap: () => cartController.decrement(index), child: const Text('−', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700))),
                                          Text('${item.quantity}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                                          InkWell(onTap: () => cartController.increment(index), child: const Text('+', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700))),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              InkWell(
                                onTap: () => cartController.remove(index),
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(color: AppColors.dangerSoft, borderRadius: BorderRadius.circular(8)),
                                  child: const Text('×', style: TextStyle(fontSize: 24, color: Color(0xFFD35252), fontWeight: FontWeight.w700)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE3DDD5))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Price Breakdown', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                          SizedBox(height: 10),
                          _BreakdownRow(left: 'Gold Value', right: '₹38,600'),
                          _BreakdownRow(left: 'Making Charges', right: '₹2,150'),
                          _BreakdownRow(left: 'GST (3%)', right: '₹1,272'),
                          _BreakdownRow(left: 'Discount', right: '− ₹500'),
                          Divider(height: 16),
                          _BreakdownRow(left: 'TOTAL', right: '₹41,522', bold: true),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Get.toNamed(AppRoutes.checkout),
                child: const Text('Proceed to Checkout', style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({required this.left, required this.right, this.bold = false});

  final String left;
  final String right;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 25,
      color: bold ? AppColors.textDark : AppColors.textMuted,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(left, style: style)),
          Text(right, style: style.copyWith(color: bold ? AppColors.primaryGold : AppColors.textDark)),
        ],
      ),
    );
  }
}
