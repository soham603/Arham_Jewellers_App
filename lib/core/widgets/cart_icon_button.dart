import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/presentation/controllers/cart_controller.dart';
import 'package:ratnesh_gold_app/presentation/pages/cart/cart_page.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';

class CartIconButton extends StatelessWidget {
  const CartIconButton({
    super.key,
    this.size,
    this.color,
    this.onTap,
  });

  final double? size;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final iconSize = size ?? context.responsiveWidth(20, tabletVal: 30);
    final iconColor = color ?? context.colorPalette.goldDeep;

    return GestureDetector(
      onTap: onTap ?? () => Get.to(() => const CartPage()),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.all(context.responsiveWidth(4, tabletVal: 6)),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: iconSize,
              color: iconColor,
            ),
            Obx(() {
              final count = CartController.instance.totalItems;
              if (count <= 0) return const SizedBox.shrink();
              return Positioned(
                top: -6,
                right: -6,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: context.colorPalette.goldDeep,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
