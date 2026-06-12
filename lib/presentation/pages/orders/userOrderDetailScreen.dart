import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:ratnesh_gold_app/core/services/share_service.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/core/widgets/ratnesh_fallback.dart';
import 'package:ratnesh_gold_app/domain/entities/userOrderModel.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ratnesh_gold_app/core/constants/admin_constants.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ratnesh_gold_app/utils/Logger.dart';
import 'package:ratnesh_gold_app/presentation/controllers/AuthController.dart';
import 'package:ratnesh_gold_app/presentation/controllers/admin/GoldRateController.dart';

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
            _buildOrderHeader(context, order),
            SizedBox(height: context.getScreenHeight(2)),
            _buildOrderItems(context, order),
            SizedBox(height: context.getScreenHeight(2)),
            _buildTotalAmount(context, order),
            if (order.adminMessage != null &&
                order.adminMessage!.isNotEmpty) ...[
              SizedBox(height: context.getScreenHeight(2)),
              _buildAdminMessage(context, order),
            ],
            SizedBox(height: context.getScreenHeight(2)),
            _buildActionButtons(context, order),
            SizedBox(height: context.getScreenHeight(4)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHeader(BuildContext context, UserOrderModel order) {
    final statusInfo = _getStatusInfo(order.status);

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
              Expanded(
                child: Text(
                  order.orderToken != null
                      ? 'Order #${order.orderToken}'
                      : 'Order #${order.id.substring(0, 8).toUpperCase()}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: context.getResponsiveSize(5),
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.getResponsiveSize(2.5),
                  vertical: context.getScreenHeight(0.3),
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
            ],
          ),
          SizedBox(height: context.getScreenHeight(1.5)),
          _infoRow(
            context,
            icon: Icons.access_time_rounded,
            label: "Created",
            value: DateFormat("dd MMM yyyy • hh:mm a").format(order.createdAt.toLocal()),
          ),
          SizedBox(height: context.getScreenHeight(0.8)),
          _infoRow(
            context,
            icon: Icons.update_rounded,
            label: "Updated",
            value: DateFormat("dd MMM yyyy • hh:mm a").format(order.updatedAt.toLocal()),
          ),
        ],
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
          SizedBox(height: context.getScreenHeight(1.5)),
          ...List.generate(order.items.length, (index) {
            final item = order.items[index];
            final imageUrl = item.product.imageUrl;

            return Padding(
              padding: EdgeInsets.only(bottom: context.getScreenHeight(1.2)),
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
                    ClipRRect(
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
                                    vertical: context.getScreenHeight(0.2),
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
                          SizedBox(height: context.getScreenHeight(0.5)),
                          if (item.product.karigarNetWt != null)
                            Padding(
                              padding: EdgeInsets.only(
                                bottom: context.getScreenHeight(0.3),
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
                                bottom: context.getScreenHeight(0.3),
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
                              bottom: context.getScreenHeight(0.3),
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
          SizedBox(height: context.getScreenHeight(1.5)),

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
          if (order.assignedKarigar != null)
            _customDetailRow(context, "Assigned To", order.assignedKarigar!),
          if (order.talkedToStaffName != null)
            _customDetailRow(context, "Contact Person", order.talkedToStaffName!),
          if (order.deliveryDate != null)
            _customDetailRow(
              context,
              "Delivery Date",
              DateFormat("dd MMM yyyy").format(order.deliveryDate!.toLocal()),
            ),
          if (order.referenceImages.isNotEmpty) ...[
            SizedBox(height: context.getScreenHeight(1.5)),
            Text(
              "Reference Images",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: context.getResponsiveSize(3.8),
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: context.getScreenHeight(1)),
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

  Widget _customDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.getScreenHeight(0.8)),
      child: Row(
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
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: context.getResponsiveSize(3.5),
              color: AppColors.textDark,
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
      padding: EdgeInsets.only(bottom: context.getScreenHeight(0.3)),
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
          SizedBox(height: context.getScreenHeight(1)),
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
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: context.getScreenHeight(5),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.primaryGold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => _downloadOrderPdf(context, order),
              child: Text(
                'Enquire',
                style: TextStyle(
                  fontSize: context.getResponsiveSize(4),
                  color: AppColors.primaryGold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: context.getResponsiveSize(3)),
        Expanded(
          child: SizedBox(
            height: context.getScreenHeight(5),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: const Color(0xFF25D366),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () async {
                final orderHashtag = order.orderToken != null
                    ? '#${order.orderToken}'
                    : '#${order.id.substring(0, 8).toUpperCase()}';
                final message = Uri.encodeComponent(
                    'Hello, I need help with my order $orderHashtag');
                final url = Uri.parse(
                    "https://wa.me/${AdminConstants.adminPhone.replaceAll('+', '')}?text=$message");
                await launchUrl(url, mode: LaunchMode.externalApplication);
              },
              icon: const FaIcon(FontAwesomeIcons.whatsapp,
                  color: Colors.white, size: 16),
              label: Text(
                'WhatsApp',
                style: TextStyle(
                  fontSize: context.getResponsiveSize(4),
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _downloadOrderPdf(BuildContext context, UserOrderModel order) async {
    final ctx = context;
    _shareWithLoading(
      ctx,
      () async {
        final items = order.items.map((item) {
          final name = item.product.name ?? '';
          String? karat;
          final karatMatch = RegExp(r'(\d{2})\s*[Kk]').firstMatch(name);
          if (karatMatch != null) {
            karat = '${karatMatch.group(1)}K';
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

        await ShareService.saveOrderPdfToDownloads(
          orderId: order.id,
          orderToken: order.orderToken,
          status: order.status,
          createdAt: order.createdAt,
          items: items,
          totalAmount: order.totalAmount,
        );
      },
      'Generating order PDF...',
      onComplete: () => _showSharePdfHint(ctx, order),
    );
  }

  void _shareWithLoading(
    BuildContext context,
    Future<void> Function() shareFn,
    String message, {
    VoidCallback? onComplete,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: EdgeInsets.all(context.getResponsiveSize(6)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primaryGold,
                  ),
                ),
                SizedBox(height: context.getScreenHeight(1.5)),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: context.getResponsiveSize(3.5),
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final navigator = Navigator.of(context);

    shareFn().whenComplete(() {
      if (mounted) {
        navigator.pop();
        onComplete?.call();
      }
    });
  }

  void _showSharePdfHint(BuildContext context, UserOrderModel order) {
    final displayId = order.orderToken != null
        ? '#${order.orderToken}'
        : '#${order.id.substring(0, 8).toUpperCase()}';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 24),
            SizedBox(width: 8),
            Text(
              'PDF Ready',
              style: TextStyle(
                fontSize: context.getResponsiveSize(4.5),
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        content: Text(
          'Order $displayId PDF has been saved to your Downloads folder. Share it with us on WhatsApp for any queries.',
          style: TextStyle(
            fontSize: context.getResponsiveSize(3.8),
            color: AppColors.textMuted,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Later',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF25D366),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              final message = Uri.encodeComponent(
                'Hi, I would like to enquire about my order $displayId. Please find the attached PDF for details.',
              );
              final phone =
                  AdminConstants.adminPhone.replaceAll('+', '');
              final uri = Uri.parse(
                  'https://wa.me/$phone?text=$message');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri,
                    mode: LaunchMode.externalApplication);
              }
            },
            icon: FaIcon(FontAwesomeIcons.whatsapp, size: 16),
            label: Text(
              'Open WhatsApp',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
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

  Widget _infoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: context.getResponsiveSize(4), color: AppColors.textMuted),
        SizedBox(width: context.getResponsiveSize(2)),
        Text(
          "$label: ",
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: context.getResponsiveSize(3.2),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: context.getResponsiveSize(3.2),
            ),
          ),
        ),
      ],
    );
  }

  _StatusInfo _getStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return _StatusInfo(
          label: 'Pending',
          color: const Color(0xFFF5A623),
          bgColor: const Color(0xFFFFF4E0),
        );
      case 'confirmed':
        return _StatusInfo(
          label: 'Confirmed',
          color: const Color(0xFF2D8C56),
          bgColor: const Color(0xFFE6F7EE),
        );
      case 'processing':
        return _StatusInfo(
          label: 'Processing',
          color: const Color(0xFFA57A36),
          bgColor: const Color(0xFFF9F3E8),
        );
      case 'completed':
      case 'delivered':
        return _StatusInfo(
          label: 'Delivered',
          color: AppColors.primaryGold,
          bgColor: const Color(0xFFF9F3E8),
        );
      case 'cancelled':
      case 'rejected':
        return _StatusInfo(
          label: status[0].toUpperCase() + status.substring(1),
          color: const Color(0xFFDC2626),
          bgColor: const Color(0xFFFEE2E2),
        );
      default:
        return _StatusInfo(
          label: status.isNotEmpty
              ? '${status[0].toUpperCase()}${status.substring(1)}'
              : 'Unknown',
          color: AppColors.textMuted,
          bgColor: AppColors.tileBg,
        );
    }
  }
}

class _StatusInfo {
  final String label;
  final Color color;
  final Color bgColor;

  const _StatusInfo({
    required this.label,
    required this.color,
    required this.bgColor,
  });
}

