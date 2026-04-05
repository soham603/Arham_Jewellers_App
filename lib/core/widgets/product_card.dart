import 'package:flutter/material.dart';

import '../../domain/entities/product.dart';
import '../theme/app_colors.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({required this.product, this.compact = false, super.key});

  final Product product;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3DDD5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFE7E2DB),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: const Text('[ Product Image ]', style: TextStyle(fontSize: 9, color: Color(0xFF887A67))),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
            child: Text(product.name, style: const TextStyle(fontSize: 29, fontWeight: FontWeight.w700, color: AppColors.textDark), maxLines: 1),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
            child: Text('₹${product.price}', style: const TextStyle(fontSize: 31, fontWeight: FontWeight.w700, color: AppColors.primaryGold)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
            child: Row(
              children: const [
                Icon(Icons.star, size: 14, color: Color(0xFFF4C949)),
                SizedBox(width: 4),
                Text('4.8', style: TextStyle(fontSize: 17, color: AppColors.textMuted)),
              ],
            ),
          ),
          if (!compact)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 9),
              child: SizedBox(
                height: 40,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 0,
                  ),
                  onPressed: () {},
                  child: const Text('Add to Cart', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
