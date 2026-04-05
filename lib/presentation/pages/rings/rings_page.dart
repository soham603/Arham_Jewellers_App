import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/product_card.dart';
import '../../controllers/catalog_controller.dart';

class RingsPage extends StatelessWidget {
  RingsPage({super.key});

  final CatalogController catalogController = Get.find<CatalogController>();

  @override
  Widget build(BuildContext context) {
    final chips = ['All', 'Gold', 'Diamond', 'Platinum', 'Under ₹10K'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rings', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w700, color: Color(0xFF2D2118))),
        leading: IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.arrow_back)),
        actions: const [Padding(padding: EdgeInsets.only(right: 14), child: Icon(Icons.swap_vert, size: 24))],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                children: [
                  SizedBox(
                    height: 34,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        final selected = index == 0;
                        return Chip(
                          label: Text(chips[index], style: TextStyle(fontSize: 12, color: selected ? Colors.white : const Color(0xFF5C5146))),
                          backgroundColor: selected ? const Color(0xFFA57A36) : const Color(0xFFE4DED5),
                          side: BorderSide.none,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                        );
                      },
                      separatorBuilder: (context, index) => const SizedBox(width: 6),
                      itemCount: chips.length,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: GridView.builder(
                      itemCount: 6,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 0.66,
                      ),
                      itemBuilder: (context, index) {
                        return ProductCard(product: catalogController.products[index % 4], compact: true);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const AppBottomNav(currentIndex: 0),
        ],
      ),
    );
  }
}
