import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/core/widgets/ratnesh_fallback.dart';
import 'package:ratnesh_gold_app/core/widgets/responsive_wrapper.dart';
import 'package:ratnesh_gold_app/domain/entities/admin/adminOrderModel.dart';
import 'package:ratnesh_gold_app/domain/entities/craftsmanModel.dart';
import 'package:ratnesh_gold_app/presentation/controllers/admin/AdminOrderController.dart';
import 'package:ratnesh_gold_app/presentation/controllers/craftsmanController.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ratnesh_gold_app/core/widgets/status_border_card.dart';
import 'package:ratnesh_gold_app/utils/whatsapp_util.dart';
import 'package:ratnesh_gold_app/core/utils/image_zoom_dialog.dart';
import 'package:ratnesh_gold_app/utils/product_navigation_util.dart';
import 'package:ratnesh_gold_app/core/services/share_service.dart';

class AdminCustomOrderDetailPage extends StatefulWidget {
  final AdminOrderModel order;

  const AdminCustomOrderDetailPage({super.key, required this.order});

  @override
  State<AdminCustomOrderDetailPage> createState() => _AdminCustomOrderDetailPageState();
}

class _AdminCustomOrderDetailPageState extends State<AdminCustomOrderDetailPage> {
  late final AdminOrderController _controller;
  late final CraftsmanController _craftsmanController;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    // Both controllers are registered as permanent by AdminPanelScreen
    // and ApproveOrdersScreen respectively, so they survive route pops.
    _controller = Get.isRegistered<AdminOrderController>()
        ? Get.find<AdminOrderController>()
        : Get.put(AdminOrderController(), permanent: true);
    _craftsmanController = Get.isRegistered<CraftsmanController>()
        ? Get.find<CraftsmanController>()
        : Get.put(CraftsmanController(), permanent: true);
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final statusInfo = getStatusInfo(order.status);
    final isPending = order.status.toUpperCase() == 'PENDING';
    final isAssigned = order.status.toUpperCase() == 'ASSIGNED';

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.pageBg,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark, size: context.getResponsiveSize(5)),
        ),
        title: const SizedBox.shrink(),
        titleSpacing: context.getResponsiveSize(4),
        actions: [
          Container(
            margin: EdgeInsets.only(right: context.getResponsiveSize(2)),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primaryGold.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              "CUSTOM",
              style: TextStyle(
                color: AppColors.primaryGold,
                fontWeight: FontWeight.w800,
                fontSize: context.getResponsiveSize(2.6),
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: context.getResponsiveSize(4)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusInfo.bgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusInfo.label,
              style: TextStyle(fontSize: context.getResponsiveSize(3), fontWeight: FontWeight.w600, color: statusInfo.color),
            ),
          ),
        ],
      ),
      body: ResponsiveWrapper(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: context.getResponsiveSize(4),
            vertical: context.heightPercent(1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Order Info ──
              _buildInfoCard(
                context,
                children: [
                  _buildInfoRow(context, 'Order ID', '#${order.id.length >= 8 ? order.id.substring(0, 8).toUpperCase() : order.id.toUpperCase()}'),
                  _buildInfoDivider(),
                  _buildInfoRow(context, 'Date', _formatDate(order.createdAt)),
                  _buildInfoDivider(),
                  _buildInfoRow(context, 'Status', order.status.toUpperCase()),
                ],
              ),

              SizedBox(height: context.heightPercent(2)),

              // ── Customer Details ──
              if (order.partyName != null || order.contactNumber != null || order.user.name.isNotEmpty || order.user.phoneNumber.isNotEmpty || order.user.companyName.isNotEmpty || order.user.city.isNotEmpty) ...[
                _buildSectionTitle(context, 'Customer Details'),
                SizedBox(height: context.heightPercent(1)),
                _buildInfoCard(
                  context,
                  children: [
                    if (order.partyName != null && order.partyName!.isNotEmpty) ...[
                      _buildInfoRow(context, 'Party Name', order.partyName!),
                      _buildInfoDivider(),
                    ] else if (order.user.name.isNotEmpty) ...[
                      _buildInfoRow(context, 'Name', order.user.name),
                      _buildInfoDivider(),
                    ],
                    if (order.contactNumber != null && order.contactNumber!.isNotEmpty) ...[
                      _buildInfoRow(context, 'Contact', order.contactNumber!),
                      _buildInfoDivider(),
                    ] else if (order.user.phoneNumber.isNotEmpty) ...[
                      _buildInfoRow(context, 'Phone', order.user.phoneNumber),
                      _buildInfoDivider(),
                    ],
                    if (order.area != null && order.area!.isNotEmpty) ...[
                      _buildInfoRow(context, 'Area', order.area!),
                      _buildInfoDivider(),
                    ],
                    if (order.user.companyName.isNotEmpty) ...[
                      _buildInfoRow(context, 'Company', order.user.companyName),
                      _buildInfoDivider(),
                    ],
                    if (order.user.city.isNotEmpty)
                      _buildInfoRow(context, 'City', order.user.city),
                  ],
                ),
                SizedBox(height: context.heightPercent(2)),
              ],

              // ── Item Details ──
              if (order.itemName != null || order.orderItems.isNotEmpty) ...[
                _buildSectionTitle(context, 'Item Details'),
                SizedBox(height: context.heightPercent(1)),
                _buildInfoCard(
                  context,
                  children: [
                    if (order.itemName != null && order.itemName!.isNotEmpty)
                      _buildInfoRow(context, 'Item Name', order.itemName!),
                    if (order.itemName != null && order.itemName!.isNotEmpty) _buildInfoDivider(),
                    if (order.purity != null && order.purity!.isNotEmpty)
                      _buildInfoRow(context, 'Purity', order.purity!),
                    if (order.purity != null && order.purity!.isNotEmpty) _buildInfoDivider(),
                    if (order.style != null && order.style!.isNotEmpty)
                      _buildInfoRow(context, 'Style', order.style!),
                    if (order.style != null && order.style!.isNotEmpty) _buildInfoDivider(),
                    if (order.marking != null && order.marking!.isNotEmpty)
                      _buildInfoRow(context, 'Marking', order.marking!),
                    if (order.marking != null && order.marking!.isNotEmpty) _buildInfoDivider(),
                    if (order.weight != null && order.weight!.isNotEmpty)
                      _buildInfoRow(context, 'Weight', '${order.weight}g'),
                    if (order.weight != null && order.weight!.isNotEmpty) _buildInfoDivider(),
                    if (order.noOfPieces != null && order.noOfPieces!.isNotEmpty)
                      _buildInfoRow(context, 'No. of Pieces', order.noOfPieces!),
                    if (order.noOfPieces != null && order.noOfPieces!.isNotEmpty) _buildInfoDivider(),
                    if (order.size != null && order.size!.isNotEmpty)
                      _buildInfoRow(context, 'Size', order.size!),
                    if (order.size != null && order.size!.isNotEmpty) _buildInfoDivider(),
                    if (order.lengthBroadness != null && order.lengthBroadness!.isNotEmpty)
                      _buildInfoRow(context, 'Dimensions', order.lengthBroadness!),
                    if (order.lengthBroadness != null && order.lengthBroadness!.isNotEmpty) _buildInfoDivider(),
                    if (order.productDescription != null && order.productDescription!.isNotEmpty)
                      _buildInfoRow(context, 'Description', order.productDescription!),
                  ],
                ),
                SizedBox(height: context.heightPercent(2)),
              ],

              // ── Catalog Items ──
              if (order.orderItems.isNotEmpty) ...[
                _buildSectionTitle(context, 'Catalog Items'),
                SizedBox(height: context.heightPercent(1)),
                _buildInfoCard(
                  context,
                  children: [
                    ...order.orderItems.map(
                      (item) {
                        final hasImage = item.product.imageUrl != null && item.product.imageUrl!.isNotEmpty;
                        return Padding(
                          padding: EdgeInsets.only(bottom: context.heightPercent(1)),
                          child: GestureDetector(
                            onTap: () {
                              final isStock = item.product.rawData?['IsStock'];
                              final bool isActive = isStock != null
                                  ? (isStock == 1 || isStock == true || isStock == '1')
                                  : true;
                              ProductNavigationUtil.navigateToProductDetails(
                                id: item.product.id,
                                name: item.product.name,
                                tagNo: item.product.tagNo,
                                karat: item.product.karat,
                                nameSlug: item.product.slug,
                                imageUrl: item.product.imageUrl,
                                isActive: isActive,
                                rawData: item.product.rawData,
                              );
                            },
                            child: Row(
                              children: [
                                GestureDetector(
                                onTap: hasImage
                                    ? () => showImageZoomDialog(context, item.product.imageUrl!)
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
                                            placeholder: (_, _) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                            errorWidget: (_, _, _) => const RatneshFallback.xs(),
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
                                      if (item.product.tagNo != null && item.product.tagNo!.isNotEmpty)
                                        _buildItemChip(context, label: item.product.tagNo!),
                                      if (item.quantity > 0)
                                        _buildItemChip(context, label: 'x${item.quantity}'),
                                      if (item.price > 0)
                                        _buildItemChip(context, label: '₹${item.price.toStringAsFixed(2)}'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                              ],
                            ),
                          ),
                        );
                    },
                  ),
                  ],
                ),
                SizedBox(height: context.heightPercent(2)),
              ],

              // ── Reference Images ──
              if (order.referenceImages.isNotEmpty) ...[
                _buildSectionTitle(context, 'Reference Images'),
                SizedBox(height: context.heightPercent(1)),
                SizedBox(
                  height: context.getResponsiveSize(25),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: order.referenceImages.length,
                    separatorBuilder: (_, _) => SizedBox(width: context.getResponsiveSize(3)),
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => showImageZoomDialog(context, order.referenceImages[index]),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: context.getResponsiveSize(25),
                            height: context.getResponsiveSize(25),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE7DED2)),
                            ),
                            child: CachedNetworkImage(
                              imageUrl: order.referenceImages[index],
                              fit: BoxFit.cover,
                              placeholder: (_, _) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                              errorWidget: (_, _, _) => const RatneshFallback.xs(),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: context.heightPercent(2)),
              ],

              // ── Admin Message ──
              if (order.adminMessage != null && order.adminMessage!.isNotEmpty) ...[
                _buildSectionTitle(context, 'Admin Message'),
                SizedBox(height: context.heightPercent(1)),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(context.getResponsiveSize(4)),
                  decoration: BoxDecoration(
                    color: order.status.toUpperCase() == 'REJECTED'
                        ? const Color(0xFFFEE2E2).withValues(alpha: 0.5)
                        : AppColors.tileBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: order.status.toUpperCase() == 'REJECTED'
                          ? const Color(0xFFDC2626).withValues(alpha: 0.2)
                          : const Color(0xFFE7DED2),
                    ),
                  ),
                  child: Text(
                    order.adminMessage!,
                    style: TextStyle(fontSize: context.getResponsiveSize(3.5), color: AppColors.textMuted, height: 1.5),
                  ),
                ),
                SizedBox(height: context.heightPercent(2)),
              ],

              // ── Assigned Craftsman ──
              if (isAssigned || order.status.toUpperCase() == 'COMPLETED') ...[
                if (order.assignedKarigarId != null && order.assignedKarigarId!.isNotEmpty) ...[
                  _buildSectionTitle(context, 'Assigned Craftsman'),
                  SizedBox(height: context.heightPercent(1)),
                  _buildInfoCard(
                    context,
                    children: [
                      _buildInfoRow(context, 'Name', _craftsmanController.getById(order.assignedKarigarId!)?.name ?? order.assignedKarigarId!),
                      if (_craftsmanController.getById(order.assignedKarigarId!)?.phoneNumber.isNotEmpty == true) ...[
                        _buildInfoDivider(),
                        _buildInfoRow(context, 'Phone', _craftsmanController.getById(order.assignedKarigarId!)!.phoneNumber),
                      ],
                      if (_craftsmanController.getById(order.assignedKarigarId!)?.whatsAppNo?.isNotEmpty == true) ...[
                        _buildInfoDivider(),
                        _buildInfoRow(context, 'WhatsApp', _craftsmanController.getById(order.assignedKarigarId!)!.whatsAppNo!),
                      ],
                      if (() {
                        final c = _craftsmanController.getById(order.assignedKarigarId!);
                        return [c?.taluka, c?.areaName, c?.cityName, c?.state].any((e) => e != null && e.isNotEmpty);
                      }()) ...[
                        _buildInfoDivider(),
                        _buildInfoRow(context, 'Address', [
                          _craftsmanController.getById(order.assignedKarigarId!)?.taluka,
                          _craftsmanController.getById(order.assignedKarigarId!)?.areaName,
                          _craftsmanController.getById(order.assignedKarigarId!)?.cityName,
                          _craftsmanController.getById(order.assignedKarigarId!)?.state,
                        ].where((e) => e != null && e.isNotEmpty).join(', ')),
                      ],
                      if (_craftsmanController.getById(order.assignedKarigarId!)?.emailId?.isNotEmpty == true) ...[
                        _buildInfoDivider(),
                        _buildInfoRow(context, 'Email', _craftsmanController.getById(order.assignedKarigarId!)!.emailId!),
                      ],
                      if (order.talkedToStaffName != null && order.talkedToStaffName!.isNotEmpty) ...[
                        _buildInfoDivider(),
                        _buildInfoRow(context, 'Contact Person', order.talkedToStaffName!),
                      ],
                      if (order.assignAdminNotes != null && order.assignAdminNotes!.isNotEmpty) ...[
                        _buildInfoDivider(),
                        _buildInfoRow(context, 'Notes', order.assignAdminNotes!),
                      ],
                      if (order.deliveryDate != null && order.deliveryDate!.isNotEmpty) ...[
                        _buildInfoDivider(),
                        _buildInfoRow(context, 'Delivery Date', order.deliveryDate!),
                      ],
                      if (order.completeAdminNotes != null && order.completeAdminNotes!.isNotEmpty) ...[
                        _buildInfoDivider(),
                        _buildInfoRow(context, 'Completion Notes', order.completeAdminNotes!),
                      ],
                    ],
                  ),
                  SizedBox(height: context.heightPercent(2)),
                ],
              ],

              // ── Action Buttons ──
              if (isPending) ...[
                SizedBox(
                  width: double.infinity,
                  height: context.heightPercent(5.5),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFDC2626)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => _showRejectDialog(context),
                    child: Text(
                      "Reject Order",
                      style: TextStyle(fontSize: context.getResponsiveSize(4), fontWeight: FontWeight.w700, color: const Color(0xFFDC2626)),
                    ),
                  ),
                ),
                SizedBox(height: context.heightPercent(1.5)),
                SizedBox(
                  width: double.infinity,
                  height: context.heightPercent(5.5),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => _showApproveAssignDialog(context),
                    child: Obx(() {
                      return _controller.isActionLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text("Approve & Assign", style: TextStyle(fontSize: context.getResponsiveSize(4), fontWeight: FontWeight.w700));
                    }),
                  ),
                ),
              ],

              if (isAssigned) ...[
                SizedBox(
                  width: double.infinity,
                  height: context.heightPercent(5.5),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => _showCompleteDialog(context),
                    child: Obx(() {
                      return _controller.isActionLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text("Mark Completed", style: TextStyle(fontSize: context.getResponsiveSize(4), fontWeight: FontWeight.w700));
                    }),
                  ),
                ),
              ],

              if (isAssigned) ...[
                SizedBox(height: context.heightPercent(1.5)),
                _buildSendToKarigarButton(context),
              ],

              // ── WhatsApp Button ──
              SizedBox(height: context.heightPercent(2)),
              _buildWhatsAppButton(context, order),

              SizedBox(height: context.heightPercent(3)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Send to Karigar Button ──
  Widget _buildSendToKarigarButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: context.heightPercent(5.5),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.primaryGold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: _isSharing ? null : () => _showShareOptionsBottomSheet(context),
        child: _isSharing
            ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryGold))
            : Text("Send to Karigar", style: TextStyle(fontSize: context.getResponsiveSize(4), fontWeight: FontWeight.w700, color: AppColors.primaryGold)),
      ),
    );
  }

  // ── Share Options Bottom Sheet ──
  void _showShareOptionsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.of(ctx).padding.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: context.heightPercent(2)),
            Text(
              'Share Order Details',
              style: TextStyle(
                fontSize: context.getResponsiveSize(4.5),
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: context.heightPercent(1.5)),
            _shareOptionTile(
              context,
              icon: Icons.image_outlined,
              iconColor: const Color(0xFF25D366),
              title: 'Share as Images',
              subtitle: 'Send order images directly',
              onTap: () {
                Navigator.pop(ctx);
                _shareOrderAsImages(context);
              },
            ),
            SizedBox(height: context.heightPercent(1)),
            _shareOptionTile(
              context,
              icon: Icons.picture_as_pdf_outlined,
              iconColor: const Color(0xFFE53935),
              title: 'Share as PDF',
              subtitle: 'Create a branded order document',
              onTap: () {
                Navigator.pop(ctx);
                _shareOrderAsPdf(context);
              },
            ),
            SizedBox(height: context.heightPercent(1.5)),
          ],
        ),
      ),
    );
  }

  Widget _shareOptionTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(context.getResponsiveSize(3.5)),
        decoration: BoxDecoration(
          color: AppColors.tileBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(context.getResponsiveSize(2)),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: context.getResponsiveSize(5.5),
              ),
            ),
            SizedBox(width: context.getResponsiveSize(3)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: context.getResponsiveSize(3.8),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: context.heightPercent(0.2)),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: context.getResponsiveSize(2.8),
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: context.getResponsiveSize(5),
            ),
          ],
        ),
      ),
    );
  }

  // ── Share Order as Images ──
  void _shareOrderAsImages(BuildContext context) async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    final progress = ValueNotifier(0.0);
    _showProgressLoadingDialog(context, progress);

    final result = await ShareService.shareCustomOrderAsImages(
      order: widget.order,
      progress: progress,
    );

    if (mounted) Navigator.of(context).pop();
    progress.dispose();

    if (!mounted) return;
    setState(() => _isSharing = false);
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No images available to share'),
          backgroundColor: Color(0xFFDC2626),
          duration: Duration(seconds: 2),
        ),
      );
    } else if (result == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to share images. Please try again.'),
          backgroundColor: Color(0xFFDC2626),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // ── Share Order as PDF ──
  void _shareOrderAsPdf(BuildContext context) async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    final progress = ValueNotifier(0.0);
    _showProgressLoadingDialog(context, progress);

    final success = await ShareService.shareCustomOrderAsPdf(
      order: widget.order,
      progress: progress,
    );

    if (mounted) Navigator.of(context).pop();
    progress.dispose();

    if (!mounted) return;
    setState(() => _isSharing = false);
    if (success != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to share PDF. Please try again.'),
          backgroundColor: Color(0xFFDC2626),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // ── Progress Loading Dialog ──
  void _showProgressLoadingDialog(BuildContext context, ValueNotifier<double> progress) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: Center(
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: EdgeInsets.all(context.getResponsiveSize(8)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: context.getResponsiveSize(5),
                        height: context.getResponsiveSize(5),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryGold,
                        ),
                      ),
                      SizedBox(width: context.getResponsiveSize(2)),
                      ValueListenableBuilder<double>(
                        valueListenable: progress,
                        builder: (context, value, _) => Text(
                          '${(value * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: context.getResponsiveSize(5),
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryGold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Approve & Assign Dialog ──
  void _showApproveAssignDialog(BuildContext context) {
    CraftsmanModel? selectedCraftsman;
    final staffNameCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(horizontal: context.getResponsiveSize(4)),
            child: Container(
              padding: EdgeInsets.all(context.getResponsiveSize(5)),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Approve & Assign Karigar", style: TextStyle(fontSize: context.getResponsiveSize(5), fontWeight: FontWeight.w700, color: AppColors.textDark)),
                    SizedBox(height: context.heightPercent(2)),

                    Text("Select Craftsman", style: TextStyle(fontSize: context.getResponsiveSize(3.3), fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                    SizedBox(height: context.heightPercent(0.8)),
                    Obx(() {
                      final craftsmen = _craftsmanController.craftsmen;
                      return Container(
                        padding: EdgeInsets.symmetric(horizontal: context.getResponsiveSize(3)),
                        decoration: BoxDecoration(
                          color: AppColors.pageBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<CraftsmanModel>(
                            isExpanded: true,
                            value: selectedCraftsman,
                            hint: Text('Select craftsman', style: TextStyle(color: AppColors.textMuted, fontSize: context.getResponsiveSize(3.3))),
                            items: craftsmen.map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c.displayName, style: TextStyle(fontSize: context.getResponsiveSize(3.3))),
                            )).toList(),
                            onChanged: (val) => setDialogState(() => selectedCraftsman = val),
                          ),
                        ),
                      );
                    }),

                    SizedBox(height: context.heightPercent(2)),
                    Text("Staff Name", style: TextStyle(fontSize: context.getResponsiveSize(3.3), fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                    SizedBox(height: context.heightPercent(0.8)),
                    TextField(
                      controller: staffNameCtrl,
                      style: TextStyle(fontSize: context.getResponsiveSize(3.3)),
                      decoration: InputDecoration(
                        hintText: 'Who you spoke with',
                        hintStyle: TextStyle(color: AppColors.textMuted, fontSize: context.getResponsiveSize(3.3)),
                        filled: true,
                        fillColor: AppColors.pageBg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),

                    SizedBox(height: context.heightPercent(2)),
                    Text("Notes", style: TextStyle(fontSize: context.getResponsiveSize(3.3), fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                    SizedBox(height: context.heightPercent(0.8)),
                    TextField(
                      controller: notesCtrl,
                      maxLines: 2,
                      style: TextStyle(fontSize: context.getResponsiveSize(3.3)),
                      decoration: InputDecoration(
                        hintText: 'Optional notes',
                        hintStyle: TextStyle(color: AppColors.textMuted, fontSize: context.getResponsiveSize(3.3)),
                        filled: true,
                        fillColor: AppColors.pageBg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),

                    SizedBox(height: context.heightPercent(3)),
                    SizedBox(
                      width: double.infinity,
                      height: context.heightPercent(5.5),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGold,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: selectedCraftsman == null
                            ? null
                            : () async {
                                Get.back();
                                await _controller.performCustomOrderAction(
                                  orderId: widget.order.id,
                                  action: 'APPROVE_AND_ASSIGN',
                                  assignedKarigarId: selectedCraftsman!.id,
                                  talkedToStaffName: staffNameCtrl.text.trim(),
                                  assignAdminNotes: notesCtrl.text.trim(),
                                );
                              },
                        child: Text("Confirm", style: TextStyle(fontSize: context.getResponsiveSize(4), fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Reject Dialog ──
  void _showRejectDialog(BuildContext context) {
    final reasonCtrl = TextEditingController();

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: context.getResponsiveSize(6)),
        child: Container(
          padding: EdgeInsets.all(context.getResponsiveSize(5)),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: context.getResponsiveSize(16),
                height: context.getResponsiveSize(16),
                decoration: const BoxDecoration(color: Color(0xFFFEE2E2), shape: BoxShape.circle),
                child: Icon(Icons.close_rounded, color: const Color(0xFFDC2626), size: context.getResponsiveSize(7)),
              ),
              SizedBox(height: context.heightPercent(2)),
              Text("Reject Order", style: TextStyle(fontSize: context.getResponsiveSize(5.5), fontWeight: FontWeight.w700, color: AppColors.textDark)),
              SizedBox(height: context.heightPercent(1)),
              Text("Provide a reason for rejection", style: TextStyle(fontSize: context.getResponsiveSize(3.5), color: AppColors.textMuted)),
              SizedBox(height: context.heightPercent(2)),
              TextField(
                controller: reasonCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Reason...',
                  hintStyle: TextStyle(color: AppColors.textMuted, fontSize: context.getResponsiveSize(3.3)),
                  filled: true,
                  fillColor: AppColors.pageBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              SizedBox(height: context.heightPercent(3)),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: context.heightPercent(5),
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.grey.shade300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        onPressed: () => Get.back(),
                        child: Text("Cancel", style: TextStyle(fontSize: context.getResponsiveSize(3.8), color: AppColors.textDark)),
                      ),
                    ),
                  ),
                  SizedBox(width: context.getResponsiveSize(3)),
                  Expanded(
                    child: SizedBox(
                      height: context.heightPercent(5),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        onPressed: () async {
                          Get.back();
                          await _controller.performCustomOrderAction(
                            orderId: widget.order.id,
                            action: 'REJECT',
                            adminMessage: reasonCtrl.text.trim(),
                          );
                        },
                        child: Text("Reject", style: TextStyle(fontSize: context.getResponsiveSize(3.8), fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Complete Dialog ──
  void _showCompleteDialog(BuildContext context) {
    final dateCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    DateTime? selectedDate;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(horizontal: context.getResponsiveSize(6)),
            child: Container(
              padding: EdgeInsets.all(context.getResponsiveSize(5)),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Mark as Completed", style: TextStyle(fontSize: context.getResponsiveSize(5), fontWeight: FontWeight.w700, color: AppColors.textDark)),
                    SizedBox(height: context.heightPercent(2)),

                    Text("Delivery Date", style: TextStyle(fontSize: context.getResponsiveSize(3.3), fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                    SizedBox(height: context.heightPercent(0.8)),
                    GestureDetector(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setDialogState(() {
                            selectedDate = date;
                            dateCtrl.text = '${date.day}/${date.month}/${date.year}';
                          });
                        }
                      },
                      child: AbsorbPointer(
                        child: TextField(
                          controller: dateCtrl,
                          decoration: InputDecoration(
                            hintText: 'Select delivery date',
                            hintStyle: TextStyle(color: AppColors.textMuted, fontSize: context.getResponsiveSize(3.3)),
                            filled: true,
                            fillColor: AppColors.pageBg,
                            suffixIcon: Icon(Icons.calendar_today_rounded, color: AppColors.primaryGold, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: context.heightPercent(2)),
                    Text("Completion Notes", style: TextStyle(fontSize: context.getResponsiveSize(3.3), fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                    SizedBox(height: context.heightPercent(0.8)),
                    TextField(
                      controller: notesCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Optional notes',
                        hintStyle: TextStyle(color: AppColors.textMuted, fontSize: context.getResponsiveSize(3.3)),
                        filled: true,
                        fillColor: AppColors.pageBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),

                    SizedBox(height: context.heightPercent(3)),
                    SizedBox(
                      width: double.infinity,
                      height: context.heightPercent(5.5),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D9D59),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () async {
                          Get.back();
                          await _controller.performCustomOrderAction(
                            orderId: widget.order.id,
                            action: 'COMPLETE',
                            deliveryDate: selectedDate?.toIso8601String().split('T').first,
                            completeAdminNotes: notesCtrl.text.trim(),
                          );
                        },
                        child: Text("Confirm Complete", style: TextStyle(fontSize: context.getResponsiveSize(4), fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── WhatsApp Button ──
  Widget _buildWhatsAppButton(BuildContext context, AdminOrderModel order) {
    final phone = order.contactNumber ?? order.user.phoneNumber;
    if (phone.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () async {
        final url = WhatsAppUtil.buildUrl(phone);
        await launchUrl(url);
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: context.heightPercent(1.5)),
        decoration: BoxDecoration(
          color: const Color(0xFF25D366),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white),
            SizedBox(width: context.getResponsiveSize(2)),
            Text(
              "Contact Customer",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: context.getResponsiveSize(3.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Row(
      children: [
        Container(width: 4, height: 16, decoration: BoxDecoration(color: AppColors.primaryGold, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: context.getResponsiveSize(4.2), fontWeight: FontWeight.w800, color: AppColors.textDark)),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context, {required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.getResponsiveSize(4)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(color: AppColors.primaryGold.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: context.getResponsiveSize(28),
            child: Text(label, style: TextStyle(fontSize: context.getResponsiveSize(3.2), fontWeight: FontWeight.w600, color: AppColors.textMuted)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: context.getResponsiveSize(3.5), fontWeight: FontWeight.w700, color: AppColors.textDark)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoDivider() => Divider(height: 1, color: AppColors.divider);

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

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

