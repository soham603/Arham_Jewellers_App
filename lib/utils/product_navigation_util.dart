import 'package:get/get.dart';
import 'package:ratnesh_gold_app/domain/entities/productModel.dart';
import 'package:ratnesh_gold_app/presentation/pages/product/product_details_page.dart';

class ProductNavigationUtil {
  static void navigateToProductDetails({
    required String id,
    required String name,
    String? tagNo,
    String? karat,
    String? nameSlug,
    String? imageUrl,
    bool isActive = true,
    Map<String, dynamic>? rawData,
  }) {
    final product = ProductModel(
      id: id,
      name: name,
      tagNo: tagNo,
      karat: karat,
      nameSlug: nameSlug,
      imageUrl: imageUrl,
      isActive: isActive,
      rawData: rawData,
    );
    Get.to(() => ProductDetailsPage(product: product));
  }
}
