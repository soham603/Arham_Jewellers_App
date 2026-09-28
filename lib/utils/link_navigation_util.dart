import 'package:get/get.dart';
import 'package:ratnesh_gold_app/data/repositories/product_repository.dart';
import 'package:ratnesh_gold_app/presentation/controllers/CategoryController.dart';
import 'package:ratnesh_gold_app/presentation/pages/product/product_details_page.dart';
import 'package:ratnesh_gold_app/presentation/pages/product/product_listing_page.dart';
import 'package:ratnesh_gold_app/utils/ToastUtil.dart';

class LinkNavigationUtil {
  LinkNavigationUtil._();

  static final ProductRepository _productRepo = ProductRepository();

  static Future<void> open({
    String? linkType,
    String? linkId,
    String? linkRef,
    String? linkName,
  }) async {
    final type = linkType?.toLowerCase();

    try {
      if (type == 'product') {
        if (linkRef == null || linkRef.isEmpty) return;

        final product = await _productRepo.fetchProductByTagNo(linkRef);
        if (product != null) {
          Get.to(() => ProductDetailsPage(product: product));
        } else {
          ToastUtils.showError('This product is no longer available');
        }
        return;
      }

      if (type == 'category') {
        if (linkId == null || linkId.isEmpty) return;

        String? karat;
        if (Get.isRegistered<CategoryController>()) {
          karat = Get.find<CategoryController>().getLevel3Karat(linkId);
        }

        Get.to(
          () => ProductListingPage(
            categoryId: linkId,
            karat: karat,
            title: linkName,
          ),
        );
      }
    } catch (e) {
      ToastUtils.showError('Unable to open the linked item');
    }
  }
}
