import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:ratnesh_gold_app/core/services/share_service.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/core/widgets/pdf_loading_dialog.dart';
import 'package:ratnesh_gold_app/core/widgets/ratnesh_fallback.dart';
import 'package:ratnesh_gold_app/domain/entities/userOrderModel.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:ratnesh_gold_app/core/constants/admin_constants.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ratnesh_gold_app/utils/whatsapp_util.dart';
import 'package:ratnesh_gold_app/utils/Logger.dart';
import 'package:ratnesh_gold_app/presentation/controllers/AuthController.dart';
import 'package:ratnesh_gold_app/core/widgets/status_border_card.dart';
import 'package:ratnesh_gold_app/presentation/controllers/admin/GoldRateController.dart';
import 'package:ratnesh_gold_app/core/utils/image_zoom_dialog.dart';
import 'package:ratnesh_gold_app/utils/product_navigation_util.dart';
import 'package:ratnesh_gold_app/utils/ToastUtil.dart' show ToastUtils;
import 'package:ratnesh_gold_app/core/constants/karat_constants.dart';
import 'package:ratnesh_gold_app/data/repositories/product_repository.dart';
import 'package:ratnesh_gold_app/presentation/pages/product/product_details_page.dart';

class UserOrderDetailScreen extends StatefulWidget {
  const UserOrderDetailScreen({super.key, required this.order});

  final UserOrderModel order;

  @override
  State<UserOrderDetailScreen> createState() => _UserOrderDetailScreenState();
}

class _UserOrderDetailScreenState extends State<UserOrderDetailScreen> {

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.pageBg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "Order Details",
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
            fontSize: context.getResponsiveSize(5),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(context.getResponsiveSize(4)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusBadge(context, order),
            SizedBox(height: context.heightPercent(2)),
            _buildOrderItems(context, order),
            if (order.totalAmount != null) ...[
              SizedBox(height: context.heightPercent(2)),
              _buildTotalAmount(context, order),
            ],
            if (order.adminMessage != null &&
                order.adminMessage!.isNotEmpty) ...[
              SizedBox(height: context.heightPercent(2)),
              _buildAdminMessage(context, order),
            ],
            SizedBox(height: context.heightPercent(2)),
            _buildActionButtons(context, order),
            SizedBox(height: context.heightPercent(4)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, UserOrderModel order) {
    final statusInfo = getStatusInfo(order.status);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.getResponsiveSize(3),
          vertical: context.heightPercent(0.5),
        ),
        decoration: BoxDecoration(
          color: statusInfo.bgColor,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          statusInfo.label,
          style: TextStyle(
            color: statusInfo.color,
            fontWeight: FontWeight.w700,
            fontSize: context.getResponsiveSize(3),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderItems(BuildContext context, UserOrderModel order) {
    Logger.info("OrderDetail", "isCustomOrder=${order.isCustomOrder} purity=${order.purity} items=${order.items.length}");
    if (order.isCustomOrder) {
      return _buildCustomOrderDetails(context, order);
    }
    return _buildStandardOrderItems(context, order);
  }

  Widget _buildStandardOrderItems(BuildContext context, UserOrderModel order) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.getResponsiveSize(4)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7DED2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Order Items",
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: context.getResponsiveSize(4.4),
            ),
          ),
          SizedBox(height: context.heightPercent(1.5)),
          ...List.generate(order.items.length, (index) {
            final item = order.items[index];
            final imageUrl = item.product.imageUrl;

            return Padding(
              padding: EdgeInsets.only(bottom: context.heightPercent(1.2)),
              child: GestureDetector(
                onTap: () {
                  ProductNavigationUtil.navigateToProductDetails(
                    id: item.product.id,
                    name: item.product.name,
                    tagNo: item.product.tagNo,
                    karat: item.product.karat,
                    nameSlug: item.product.slug,
                    imageUrl: item.product.imageUrl,
                    isActive: item.product.isActive,
                    rawData: {
                      if (item.product.karigarNetWt != null)
                        'KarigarNetWt': item.product.karigarNetWt,
                      if (item.product.karigarFineWt != null)
                        'KarigarFineWt': item.product.karigarFineWt,
                      if (item.product.size1 != null)
                        'Size1': item.product.size1,
                    },
                  );
                },
                child: Container(
                padding: EdgeInsets.all(context.getResponsiveSize(3)),
                decoration: BoxDecoration(
                  color: item.isRejected
                      ? Colors.red.withValues(alpha: 0.05)
                      : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: item.isRejected
                        ? Colors.red.withValues(alpha: 0.2)
                        : Colors.grey.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: imageUrl != null && imageUrl.isNotEmpty
                          ? () => showImageZoomDialog(context, imageUrl)
                          : null,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: context.getResponsiveSize(14),
                          height: context.getResponsiveSize(14),
                          child: imageUrl != null && imageUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (_, _) => const Center(
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  errorWidget: (_, _, _) =>
                                      const RatneshFallback.xs(),
                                )
                              : const RatneshFallback.xs(),
                        ),
                      ),
                    ),
                    SizedBox(width: context.getResponsiveSize(3)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _cleanText(item.product.name) ?? 'Untitled',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: context.getResponsiveSize(3.8),
                                  ),
                                ),
                              ),
                              if (item.isRejected)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: context.getResponsiveSize(1.5),
                                    vertical: context.heightPercent(0.2),
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Text(
                                    "REJECTED",
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.w700,
                                      fontSize: context.getResponsiveSize(2.2),
                                    ),
                                  ),
                              ),
                            ],
                          ),
                          SizedBox(height: context.heightPercent(0.5)),
                          if (item.product.karigarNetWt != null)
                            Padding(
                              padding: EdgeInsets.only(
                                bottom: context.heightPercent(0.3),
                              ),
                              child: Text(
                                'Net Wt: ${item.product.karigarNetWt!.toStringAsFixed(2)}g',
                                style: TextStyle(
                                  fontSize: context.getResponsiveSize(3.0),
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          if (item.product.size1 != null)
                            Padding(
                              padding: EdgeInsets.only(
                                bottom: context.heightPercent(0.3),
                              ),
                              child: Text(
                                'Size: ${item.product.size1}',
                                style: TextStyle(
                                  fontSize: context.getResponsiveSize(3.0),
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: context.heightPercent(0.3),
                            ),
                            child: Text(
                              'Qty: ${item.quantity}',
                              style: TextStyle(
                                fontSize: context.getResponsiveSize(3.0),
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                          if (Get.find<AuthController>().user?.isRetailer == true)
                            _priceRow(context, item),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCustomOrderDetails(BuildContext context, UserOrderModel order) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.getResponsiveSize(4)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7DED2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.handyman_rounded,
                size: context.getResponsiveSize(5),
                color: AppColors.primaryGold,
              ),
              SizedBox(width: context.getResponsiveSize(2)),
              Text(
                "Custom Order Details",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: context.getResponsiveSize(4.4),
                ),
              ),
            ],
          ),
          SizedBox(height: context.heightPercent(1.5)),

          if (order.itemName != null)
            _customDetailRow(context, "Item", order.itemName!),
          if (order.weight != null)
            _customDetailRow(context, "Weight", "${order.weight}g"),
          if (order.noOfPieces != null)
            _customDetailRow(context, "Pieces", order.noOfPieces!),
          if (order.size != null)
            _customDetailRow(context, "Size", order.size!),
          if (order.lengthBroadness != null)
            _customDetailRow(context, "Length/Broadness", order.lengthBroadness!),
          if (order.productDescription != null)
            _customDetailRow(context, "Description", order.productDescription!),
          _customDetailRow(context, "Purity", order.purity ?? '-'),
          _customDetailRow(context, "Style", order.style ?? '-'),
          _customDetailRow(context, "Marking", order.marking ?? '-'),

          if (order.talkedToStaffName != null)
            _customDetailRow(context, "Contact Person", order.talkedToStaffName!),
          if (order.deliveryDate != null)
            _customDetailRow(
              context,
              "Delivery Date",
              DateFormat("dd MMM yyyy").format(order.deliveryDate!.toLocal()),
            ),

          if (order.items.isNotEmpty) ...[
            SizedBox(height: context.heightPercent(1.5)),
            Text(
              "Catalog Items",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: context.getResponsiveSize(3.8),
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: context.heightPercent(1)),
            ...order.items.map((item) {
              final hasImage =
                  item.product.imageUrl != null &&
                  item.product.imageUrl!.isNotEmpty;
              return Padding(
                padding: EdgeInsets.only(bottom: context.heightPercent(1)),
                child: GestureDetector(
                  onTap: () => _navigateToProduct(context, item.product),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: hasImage
                            ? () => showImageZoomDialog(
                                context,
                                item.product.imageUrl!,
                              )
                            : null,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: context.getResponsiveSize(12),
                            height: context.getResponsiveSize(12),
                            child: hasImage
                                ? CachedNetworkImage(
                                    imageUrl: item.product.imageUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (_, _) =>
                                        const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                    errorWidget: (_, _, _) =>
                                        const RatneshFallback.xs(),
                                  )
                                : const RatneshFallback.xs(),
                          ),
                        ),
                      ),
                      SizedBox(width: context.getResponsiveSize(3)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.product.name,
                              style: TextStyle(
                                fontSize: context.getResponsiveSize(3.6),
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                            SizedBox(height: context.heightPercent(0.3)),
                            Wrap(
                              spacing: context.getResponsiveSize(2),
                              runSpacing: context.heightPercent(0.3),
                              children: [
                                if (item.product.tagNo != null &&
                                    item.product.tagNo!.isNotEmpty)
                                  _buildItemChip(
                                    context,
                                    label: item.product.tagNo!,
                                  ),
                                if (item.quantity > 0)
                                  _buildItemChip(
                                    context,
                                    label: 'x${item.quantity}',
                                  ),
                                if (item.price > 0)
                                  _buildItemChip(
                                    context,
                                    label:
                                        '₹${item.price.toStringAsFixed(2)}',
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],

          if (order.referenceImages.isNotEmpty) ...[
            SizedBox(height: context.heightPercent(1.5)),
            Text(
              "Reference Images",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: context.getResponsiveSize(3.8),
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: context.heightPercent(1)),
            SizedBox(
              height: context.getResponsiveSize(20),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: order.referenceImages.length,
                separatorBuilder: (_, _) => SizedBox(
                  width: context.getResponsiveSize(2),
                ),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: order.referenceImages[i],
                    width: context.getResponsiveSize(20),
                    height: context.getResponsiveSize(20),
                    fit: BoxFit.cover,
                    placeholder: (_, _) => const RatneshFallback.xs(),
                    errorWidget: (_, _, _) => const RatneshFallback.xs(),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemChip(BuildContext context, {required String label}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.getResponsiveSize(2),
        vertical: context.heightPercent(0.2),
      ),
      decoration: BoxDecoration(
        color: AppColors.pageBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: context.getResponsiveSize(2.8),
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  Future<void> _navigateToProduct(
    BuildContext context,
    UserOrderProductModel product,
  ) async {
    if (product.tagNo == null || product.tagNo!.isEmpty) {
      ProductNavigationUtil.navigateToProductDetails(
        id: product.id,
        name: product.name,
        tagNo: product.tagNo,
        karat: product.karat,
        nameSlug: product.slug,
        imageUrl: product.imageUrl,
        isActive: product.isActive,
        rawData: {
          if (product.karigarNetWt != null)
            'KarigarNetWt': product.karigarNetWt,
          if (product.karigarFineWt != null)
            'KarigarFineWt': product.karigarFineWt,
          if (product.size1 != null) 'Size1': product.size1,
        },
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final repo = ProductRepository();
      final fullProduct = await repo.fetchProductByTagNo(product.tagNo!);

      if (mounted) Navigator.of(context).pop();

      if (fullProduct != null && mounted) {
        Get.to(() => ProductDetailsPage(product: fullProduct));
      } else if (mounted) {
        ToastUtils.showError('Product not found');
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      Logger.error('UserOrderDetail', 'Failed to fetch product: $e');
      if (mounted) {
        ToastUtils.showError('Failed to load product');
      }
    }
  }

  Widget _customDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.heightPercent(0.8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: context.getResponsiveSize(24),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: context.getResponsiveSize(3.5),
                color: AppColors.textMuted,
              ),
            ),
          ),
          SizedBox(width: context.getResponsiveSize(2)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: context.getResponsiveSize(3.5),
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(BuildContext context, UserOrderItemModel item) {
    final goldRate = Get.find<GoldRateController>().currentRate;
    final netWt = item.product.karigarNetWt;
    if (goldRate == null || netWt == null) return const SizedBox.shrink();
    final price = GoldRateController.calculatePrice(
      fineWeight: netWt,
      ratePer10Gram: goldRate.rate,
    );
    if (price == null) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: context.heightPercent(0.3)),
      child: Text(
        'Price: ${_formatPrice(price)}',
        style: TextStyle(
          fontSize: context.getResponsiveSize(3.0),
          color: AppColors.primaryGold,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatPrice(double value) {
    final intVal = value.toInt();
    final str = intVal.toString();
    if (str.length <= 3) return '\u20B9$intVal';
    String result = str.substring(str.length - 3);
    int i = str.length - 3;
    while (i > 0) {
      final chunk = str.substring(i - 2 < 0 ? 0 : i - 2, i);
      result = '$chunk,$result';
      i -= 2;
    }
    return '\u20B9$result';
  }

  Widget _buildTotalAmount(BuildContext context, UserOrderModel order) {
    final total = order.totalAmount;
    if (total == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.getResponsiveSize(4)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7DED2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(context.getResponsiveSize(2.5)),
            decoration: BoxDecoration(
              color: AppColors.primaryGold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.account_balance_wallet_rounded,
              color: AppColors.primaryGold,
              size: context.getResponsiveSize(5),
            ),
          ),
          SizedBox(width: context.getResponsiveSize(3)),
          Expanded(
            child: Text(
              "Total Amount",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: context.getResponsiveSize(4),
                color: AppColors.textMuted,
              ),
            ),
          ),
          Text(
            "₹${_formatAmount(total)}",
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: context.getResponsiveSize(5),
              color: AppColors.primaryGold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminMessage(BuildContext context, UserOrderModel order) {
    final isRejected = order.status.toLowerCase() == 'rejected';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.getResponsiveSize(4)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7DED2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: isRejected ? Colors.red : AppColors.primaryGold,
                size: context.getResponsiveSize(4.5),
              ),
              SizedBox(width: context.getResponsiveSize(2)),
              Text(
                isRejected ? "Rejection Reason" : "Message",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: context.getResponsiveSize(4.4),
                ),
              ),
            ],
          ),
          SizedBox(height: context.heightPercent(1)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(context.getResponsiveSize(3)),
            decoration: BoxDecoration(
              color: isRejected
                  ? Colors.red.withValues(alpha: 0.05)
                  : AppColors.primaryGold.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isRejected
                    ? Colors.red.withValues(alpha: 0.15)
                    : AppColors.primaryGold.withValues(alpha: 0.15),
              ),
            ),
            child: Text(
              order.adminMessage!,
              style: TextStyle(
                fontSize: context.getResponsiveSize(3.4),
                color: AppColors.textDark,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, UserOrderModel order) {
    return SizedBox(
      width: double.infinity,
      height: context.heightPercent(5),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.primaryGold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: () => _openWhatsAppWithPdf(context, order),
        child: Text(
          'Enquire',
          style: TextStyle(
            fontSize: context.getResponsiveSize(4),
            color: AppColors.primaryGold,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _openWhatsAppWithPdf(BuildContext context, UserOrderModel order) async {
    final displayId = order.orderToken != null
        ? '#${order.orderToken}'
        : '#${order.id.substring(0, 8).toUpperCase()}';
    final message = 'Hello, I need help with my order $displayId';

    _shareWithLoading(
      context,
      (progress, cancelled) async {
        final items = order.items.map((item) {
          final name = item.product.name;
          String? karat;

          // 1. Explicit karat field from server
          if (item.product.karat != null && item.product.karat!.isNotEmpty) {
            final n = KaratConstants.karatNumber(item.product.karat!);
            if (n != null) {
              final purity = KaratConstants.touchValueFor('${n}K');
              karat = purity > 0 ? '${n}K ($purity)' : '${n}K';
            }
          }

          // 2. Tag number prefix (e.g. "76GR-303" → 76 → 18K)
          if (karat == null && item.product.tagNo != null && item.product.tagNo!.length >= 2) {
            final prefix = item.product.tagNo!.substring(0, 2);
            final n = int.tryParse(prefix);
            if (n != null) {
              final touch = n < 100 ? n * 10 : n;
              final karatNum = KaratConstants.karatFromTouchValue(touch);
              if (karatNum != null) {
                final purity = KaratConstants.touchValueFor('${karatNum}K');
                karat = purity > 0 ? '${karatNum}K ($purity)' : '${karatNum}K';
              }
            }
          }

          // 3. Product name — validate against known karat values only
          if (karat == null) {
            final match = RegExp(r'(\d+)\s*K', caseSensitive: false).firstMatch(name);
            if (match != null) {
              final n = int.tryParse(match.group(1)!);
              if (n != null && [9, 14, 18, 20, 22, 24].contains(n)) {
                final purity = KaratConstants.touchValueFor('${n}K');
                karat = purity > 0 ? '${n}K ($purity)' : '${n}K';
              }
            }
          }
          return {
            'name': name,
            'imageUrl': item.product.displayImageUrl,
            'quantity': item.quantity,
            'price': item.price,
            'isRejected': item.isRejected,
            'netWeight': item.product.karigarNetWt,
            'karat': karat,
          };
        }).toList();

        final phone = await AdminConstants.adminPhoneAsync;

        final success = await ShareService.shareOrderPdfToWhatsApp(
          orderId: order.id,
          orderToken: order.orderToken,
          status: order.status,
          createdAt: order.createdAt,
          updatedAt: order.updatedAt,
          items: items,
          totalAmount: order.totalAmount,
          message: message,
          phone: phone,
          progress: progress,
          cancelled: cancelled,
        );

        if (!success && !cancelled.value && mounted) {
          final url = WhatsAppUtil.buildUrl(
            phone,
            message: message,
          );
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          } else {
            ToastUtils.showError('Could not open WhatsApp');
          }
        }
      },
      'Preparing PDF...',
    );
  }


  void _shareWithLoading(
    BuildContext context,
    Future<void> Function(ValueNotifier<double> progress, ValueNotifier<bool> cancelled) shareFn,
    String message, {
    VoidCallback? onComplete,
  }) {
    final progress = ValueNotifier<double>(0.0);
    final cancelled = ValueNotifier<bool>(false);

    PdfLoadingDialog.show(
      context,
      message: message,
      progress: progress,
      onCancel: () {
        cancelled.value = true;
      },
    );

    shareFn(progress, cancelled).whenComplete(() {
      progress.dispose();
      cancelled.dispose();
      if (mounted && !cancelled.value) {
        Navigator.of(context).pop();
        onComplete?.call();
      }
    });
  }



  static String? _cleanText(String? value) {
    final cleaned = value?.trim();
    if (cleaned == null ||
        cleaned.isEmpty ||
        cleaned.toLowerCase() == 'null') {
      return null;
    }
    return cleaned;
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      final formatted = amount.toStringAsFixed(0);
      final parts = <String>[];
      var s = formatted;
      while (s.length > 3) {
        parts.insert(0, s.substring(s.length - 3));
        s = s.substring(0, s.length - 3);
      }
      parts.insert(0, s);
      return parts.join(',');
    }
    return amount.toStringAsFixed(0);
  }



}



