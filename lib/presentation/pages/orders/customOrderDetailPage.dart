import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/core/widgets/ratnesh_fallback.dart';
import 'package:ratnesh_gold_app/core/widgets/responsive_wrapper.dart';
import 'package:ratnesh_gold_app/domain/entities/customOrderModel.dart';
import 'package:ratnesh_gold_app/presentation/controllers/customOrderController.dart';
import 'package:ratnesh_gold_app/presentation/pages/product/customise_order_page.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';

class CustomOrderDetailPage extends StatefulWidget {
  final CustomOrderModel order;

  const CustomOrderDetailPage({super.key, required this.order});

  @override
  State<CustomOrderDetailPage> createState() => _CustomOrderDetailPageState();
}

class _CustomOrderDetailPageState extends State<CustomOrderDetailPage> {
  late final CustomOrderController _controller;
  late CustomOrderModel _order;

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<CustomOrderController>()
        ? Get.find<CustomOrderController>()
        : Get.put(CustomOrderController());
    _order = widget.order;
  }

  _StatusInfo _getStatusInfo(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return _StatusInfo('Pending', const Color(0xFFF5A623), const Color(0xFFFFF4E0));
      case 'APPROVED':
        return _StatusInfo('Approved', const Color(0xFF2D8C56), const Color(0xFFE6F7EE));
      case 'ASSIGNED':
        return _StatusInfo('Assigned', const Color(0xFF3B82F6), const Color(0xFFEFF6FF));
      case 'COMPLETED':
        return _StatusInfo('Completed', AppColors.primaryGold, const Color(0xFFF9F3E8));
      case 'REJECTED':
        return _StatusInfo('Rejected', const Color(0xFFDC2626), const Color(0xFFFEE2E2));
      default:
        return _StatusInfo(status, AppColors.textMuted, AppColors.tileBg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo(_order.status);

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.pageBg,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark, size: context.getScreenWidth(5)),
        ),
        title: Text(
          'Custom Order',
          style: TextStyle(
            fontSize: context.getScreenWidth(5.5),
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        titleSpacing: context.getScreenWidth(4),
        actions: [
          Container(
            margin: EdgeInsets.only(right: context.getScreenWidth(4)),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusInfo.bgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusInfo.label,
              style: TextStyle(
                fontSize: context.getScreenWidth(3),
                fontWeight: FontWeight.w600,
                color: statusInfo.color,
              ),
            ),
          ),
        ],
      ),
      body: ResponsiveWrapper(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: context.getScreenWidth(4),
            vertical: context.getScreenHeight(1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Order ID + Date ──
              _buildInfoCard(
                context,
                children: [
                  _buildInfoRow(context, 'Order ID', '#${_order.id.substring(0, 8).toUpperCase()}'),
                  _buildInfoDivider(),
                  _buildInfoRow(context, 'Date', _formatDate(_order.createdAt)),
                  if (_order.status == 'ASSIGNED' && _order.deliveryDate != null) ...[
                    _buildInfoDivider(),
                    _buildInfoRow(context, 'Expected Delivery', _order.deliveryDate!),
                  ],
                ],
              ),

              SizedBox(height: context.getScreenHeight(2)),

              // ── Item Details ──
              _buildSectionTitle(context, 'Item Details'),
              SizedBox(height: context.getScreenHeight(1)),
              _buildInfoCard(
                context,
                children: [
                  _buildInfoRow(context, 'Item Name', _order.itemName),
                  if (_order.purity.isNotEmpty) ...[
                    _buildInfoDivider(),
                    _buildInfoRow(context, 'Purity', _order.purity),
                  ],
                  if (_order.style.isNotEmpty) ...[
                    _buildInfoDivider(),
                    _buildInfoRow(context, 'Style', _order.style),
                  ],
                  if (_order.marking.isNotEmpty) ...[
                    _buildInfoDivider(),
                    _buildInfoRow(context, 'Marking', _order.marking),
                  ],
                  if (_order.weight != null && _order.weight!.isNotEmpty) ...[
                    _buildInfoDivider(),
                    _buildInfoRow(context, 'Weight', '${_order.weight}g'),
                  ],
                  if (_order.noOfPieces != null && _order.noOfPieces!.isNotEmpty) ...[
                    _buildInfoDivider(),
                    _buildInfoRow(context, 'No. of Pieces', _order.noOfPieces!),
                  ],
                  if (_order.size != null && _order.size!.isNotEmpty) ...[
                    _buildInfoDivider(),
                    _buildInfoRow(context, 'Size', _order.size!),
                  ],
                  if (_order.lengthBroadness != null && _order.lengthBroadness!.isNotEmpty) ...[
                    _buildInfoDivider(),
                    _buildInfoRow(context, 'Dimensions', _order.lengthBroadness!),
                  ],
                  if (_order.productDescription != null && _order.productDescription!.isNotEmpty) ...[
                    _buildInfoDivider(),
                    _buildInfoRow(context, 'Description', _order.productDescription!),
                  ],
                ],
              ),

              SizedBox(height: context.getScreenHeight(2)),

              // ── Reference Images ──
              if (_order.referenceImages.isNotEmpty) ...[
                _buildSectionTitle(context, 'Reference Images'),
                SizedBox(height: context.getScreenHeight(1)),
                SizedBox(
                  height: context.getScreenWidth(25),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _order.referenceImages.length,
                    separatorBuilder: (_, __) => SizedBox(width: context.getScreenWidth(3)),
                    itemBuilder: (context, index) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: context.getScreenWidth(25),
                          height: context.getScreenWidth(25),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE7DED2)),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: _order.referenceImages[index],
                            fit: BoxFit.cover,
                            placeholder: (_, _) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            errorWidget: (_, _, _) => const RatneshFallback.xs(),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: context.getScreenHeight(2)),
              ],

              // ── Assigned Karigar ──
              if (_order.assignedKarigarName != null && _order.assignedKarigarName!.isNotEmpty) ...[
                _buildSectionTitle(context, 'Assigned Craftsman'),
                SizedBox(height: context.getScreenHeight(1)),
                _buildInfoCard(
                  context,
                  children: [
                    _buildInfoRow(context, 'Name', _order.assignedKarigarName!),
                    if (_order.talkedToStaffName != null && _order.talkedToStaffName!.isNotEmpty) ...[
                      _buildInfoDivider(),
                      _buildInfoRow(context, 'Contact Person', _order.talkedToStaffName!),
                    ],
                    if (_order.assignAdminNotes != null && _order.assignAdminNotes!.isNotEmpty) ...[
                      _buildInfoDivider(),
                      _buildInfoRow(context, 'Notes', _order.assignAdminNotes!),
                    ],
                  ],
                ),
                SizedBox(height: context.getScreenHeight(2)),
              ],

              // ── Admin Message ──
              if (_order.adminMessage != null && _order.adminMessage!.isNotEmpty) ...[
                _buildSectionTitle(context, 'Admin Message'),
                SizedBox(height: context.getScreenHeight(1)),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(context.getScreenWidth(4)),
                  decoration: BoxDecoration(
                    color: AppColors.tileBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE7DED2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded, size: context.getScreenWidth(4.5), color: AppColors.primaryGold),
                      SizedBox(width: context.getScreenWidth(2.5)),
                      Expanded(
                        child: Text(
                          _order.adminMessage!,
                          style: TextStyle(
                            fontSize: context.getScreenWidth(3.5),
                            color: AppColors.textMuted,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: context.getScreenHeight(2)),
              ],

              // ── Action Buttons ──
              if (_order.status.toUpperCase() == 'PENDING') ...[
                SizedBox(height: context.getScreenHeight(1)),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: context.getScreenHeight(5.5),
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFDC2626)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () => _showDeleteDialog(context),
                          icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 20),
                          label: Text(
                            'Delete',
                            style: TextStyle(
                              fontSize: context.getScreenWidth(3.8),
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFDC2626),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: context.getScreenWidth(3)),
                    Expanded(
                      child: SizedBox(
                        height: context.getScreenHeight(5.5),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: AppColors.primaryGold,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () {
                            Get.to(() => CustomiseOrderPage(existingOrder: _order));
                          },
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          label: Text(
                            'Modify',
                            style: TextStyle(
                              fontSize: context.getScreenWidth(3.8),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.getScreenHeight(2)),
              ],

              SizedBox(height: context.getScreenHeight(2)),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: context.getScreenWidth(6)),
        child: Container(
          padding: EdgeInsets.all(context.getScreenWidth(5)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: context.getScreenWidth(16),
                height: context.getScreenWidth(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.delete_outline_rounded, color: const Color(0xFFDC2626), size: context.getScreenWidth(7)),
              ),
              SizedBox(height: context.getScreenHeight(2)),
              Text(
                "Delete Order?",
                style: TextStyle(
                  fontSize: context.getScreenWidth(5.5),
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: context.getScreenHeight(1)),
              Text(
                "This action cannot be undone. All reference images will also be removed.",
                style: TextStyle(
                  fontSize: context.getScreenWidth(3.5),
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: context.getScreenHeight(3)),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: context.getScreenHeight(5),
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => Get.back(),
                        child: Text(
                          "Cancel",
                          style: TextStyle(fontSize: context.getScreenWidth(3.8), fontWeight: FontWeight.w600, color: AppColors.textDark),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: context.getScreenWidth(3)),
                  Expanded(
                    child: SizedBox(
                      height: context.getScreenHeight(5),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: const Color(0xFFDC2626),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () async {
                          Get.back();
                          final success = await _controller.deleteCustomOrder(_order.id);
                          if (success && mounted) Get.back();
                        },
                        child: Obx(() {
                          return _controller.isDeleting
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text("Delete", style: TextStyle(fontSize: context.getScreenWidth(3.8), fontWeight: FontWeight.w700, color: Colors.white));
                        }),
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

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Row(
      children: [
        Container(width: 4, height: 16, decoration: BoxDecoration(color: AppColors.primaryGold, borderRadius: BorderRadius.circular(4))),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: context.getScreenWidth(4.2),
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context, {required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.getScreenWidth(4)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryGold.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGold.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: context.getScreenWidth(30),
            child: Text(
              label,
              style: TextStyle(
                fontSize: context.getScreenWidth(3.2),
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: context.getScreenWidth(3.5),
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoDivider() => Divider(height: 1, color: AppColors.divider);

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _StatusInfo {
  final String label;
  final Color color;
  final Color bgColor;
  const _StatusInfo(this.label, this.color, this.bgColor);
}
