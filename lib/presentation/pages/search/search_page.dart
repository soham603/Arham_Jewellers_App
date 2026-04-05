import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/product_card.dart';
import '../../controllers/catalog_controller.dart';

class SearchPage extends StatelessWidget {
  SearchPage({super.key});

  final CatalogController catalogController = Get.find<CatalogController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFCFC7BC)),
                          color: const Color(0xFFF4F1EC),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.search, color: Color(0xFF8D847A), size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Search gold, diamonds, rings...',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 19, color: Color(0xFFA29A90)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('Recent Searches', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: Color(0xFF675F55))),
                      const SizedBox(height: 8),
                      ...catalogController.recentSearches.map((term) {
                        return Column(
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(term, style: const TextStyle(fontSize: 31, color: Color(0xFF3A2D21))),
                            ),
                            const Divider(height: 1),
                          ],
                        );
                      }),
                      const SizedBox(height: 12),
                      const Text('Results', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF675F55))),
                      const SizedBox(height: 8),
                      GridView.builder(
                        itemCount: 4,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 0.66,
                        ),
                        itemBuilder: (context, index) {
                          return ProductCard(product: catalogController.products[index]);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const AppBottomNav(currentIndex: 1),
          ],
        ),
      ),
    );
  }
}
