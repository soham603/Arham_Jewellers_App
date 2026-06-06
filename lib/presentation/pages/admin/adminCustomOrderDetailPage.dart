import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/core/widgets/ratnesh_fallback.dart';
import 'package:ratnesh_gold_app/core/widgets/responsive_wrapper.dart';
import 'package:ratnesh_gold_app/domain/entities/admin/adminOrderModel.dart';
import 'package:ratnesh_gold_app/domain/entities/craftsmanModel.dart';
import 'package:ratnesh_gold_app/presentation/controllers/admin/AdminCustomOrderController.dart';
import 'package:ratnesh_gold_app/presentation/controllers/craftsmanController.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';

class AdminCustomOrderDetailPage extends StatefulWidget {
  final AdminOrderModel order;

  const AdminCustomOrderDetailPage({super.key, required this.order});

  @override
  State<AdminCustomOrderDetailPage> createState() => _AdminCustomOrderDetailPageState();
}

class _AdminCustomOrderDetailPageState extends State<AdminCustomOrderDetailPage> {
  late final AdminCustomOrderController _controller;
  late final CraftsmanController _craftsmanController;

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<AdminCustomOrderController>()
        ? Get.find<AdminCustomOrderController>()
        : Get.put(AdminCustomOrderController());
    _craftsmanController = Get.isRegistered<CraftsmanController>()
        ? Get.find<CraftsmanController>()
        : Get.put(CraftsmanController());
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
    final statusInfo = _getStatusInfo(widget.order.status);
    final isPending = widget.order.status.toUpperCase() == 'PENDING';
    final isAssigned = widget.order.status.toUpperCase() == 'ASSIGNED';

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
          'Order #${widget.order.id.substring(0, 8).toUpperCase()}',
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
              style: TextStyle(fontSize: context.getScreenWidth(3), fontWeight: FontWeight.w600, color: statusInfo.color),
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
              // ── Order Info ──
              _buildInfoCard(
                context,
                children: [
                  _buildInfoRow(context, 'Order ID', '#${widget.order.id.substring(0, 8).toUpperCase()}'),
                  _buildInfoDivider(),
                  _buildInfoRow(context, 'Date', _formatDate(widget.order.createdAt)),
                  _buildInfoDivider(),
                  _buildInfoRow(context, 'Status', widget.order.status.toUpperCase()),
                ],
              ),

              SizedBox(height: context.getScreenHeight(2)),

              // ── Item Details ──
              _buildSectionTitle(context, 'Items'),
              SizedBox(height: context.getScreenHeight(1)),
              _buildInfoCard(
                context,
                children: [
                  ...widget.order.orderItems.map(
                    (item) => Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.product.name,
                              style: TextStyle(
                                fontSize: context.getScreenWidth(3.8),
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                          Text(
                            'x${item.quantity}',
                            style: TextStyle(
                              fontSize: context.getScreenWidth(3.5),
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: context.getScreenHeight(2)),

              // ── Admin Message ──
              if (widget.order.adminMessage != null && widget.order.adminMessage!.isNotEmpty) ...[
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
                  child: Text(
                    widget.order.adminMessage!,
                    style: TextStyle(fontSize: context.getScreenWidth(3.5), color: AppColors.textMuted, height: 1.5),
                  ),
                ),
                SizedBox(height: context.getScreenHeight(2)),
              ],

              // ── Action Buttons ──
              if (isPending) ...[
                SizedBox(
                  width: double.infinity,
                  height: context.getScreenHeight(5.5),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFDC2626)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => _showRejectDialog(context),
                    child: Text(
                      "Reject Order",
                      style: TextStyle(fontSize: context.getScreenWidth(4), fontWeight: FontWeight.w700, color: const Color(0xFFDC2626)),
                    ),
                  ),
                ),
                SizedBox(height: context.getScreenHeight(1.5)),
                SizedBox(
                  width: double.infinity,
                  height: context.getScreenHeight(5.5),
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
                          : Text("Approve & Assign", style: TextStyle(fontSize: context.getScreenWidth(4), fontWeight: FontWeight.w700));
                    }),
                  ),
                ),
              ],

              if (isAssigned) ...[
                SizedBox(
                  width: double.infinity,
                  height: context.getScreenHeight(5.5),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFF2D9D59),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => _showCompleteDialog(context),
                    child: Obx(() {
                      return _controller.isActionLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text("Mark Completed", style: TextStyle(fontSize: context.getScreenWidth(4), fontWeight: FontWeight.w700));
                    }),
                  ),
                ),
              ],

              SizedBox(height: context.getScreenHeight(3)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Reject Dialog ──
  void _showRejectDialog(BuildContext context) {
    final reasonCtrl = TextEditingController();

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: context.getScreenWidth(6)),
        child: Container(
          padding: EdgeInsets.all(context.getScreenWidth(5)),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: context.getScreenWidth(16),
                height: context.getScreenWidth(16),
                decoration: const BoxDecoration(color: Color(0xFFFEE2E2), shape: BoxShape.circle),
                child: Icon(Icons.close_rounded, color: const Color(0xFFDC2626), size: context.getScreenWidth(7)),
              ),
              SizedBox(height: context.getScreenHeight(2)),
              Text("Reject Order", style: TextStyle(fontSize: context.getScreenWidth(5.5), fontWeight: FontWeight.w700, color: AppColors.textDark)),
              SizedBox(height: context.getScreenHeight(1)),
              Text("Provide a reason for rejection", style: TextStyle(fontSize: context.getScreenWidth(3.5), color: AppColors.textMuted)),
              SizedBox(height: context.getScreenHeight(2)),
              TextField(
                controller: reasonCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Reason...',
                  hintStyle: TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.pageBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              SizedBox(height: context.getScreenHeight(3)),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: context.getScreenHeight(5),
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.grey.shade300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        onPressed: () => Get.back(),
                        child: Text("Cancel", style: TextStyle(fontSize: context.getScreenWidth(3.8), color: AppColors.textDark)),
                      ),
                    ),
                  ),
                  SizedBox(width: context.getScreenWidth(3)),
                  Expanded(
                    child: SizedBox(
                      height: context.getScreenHeight(5),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        onPressed: () async {
                          Get.back();
                          await _controller.performAction(
                            orderId: widget.order.id,
                            action: 'REJECT',
                            adminMessage: reasonCtrl.text.trim(),
                          );
                        },
                        child: Text("Reject", style: TextStyle(fontSize: context.getScreenWidth(3.8), fontWeight: FontWeight.w700, color: Colors.white)),
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
            insetPadding: EdgeInsets.symmetric(horizontal: context.getScreenWidth(4)),
            child: Container(
              padding: EdgeInsets.all(context.getScreenWidth(5)),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Approve & Assign Karigar", style: TextStyle(fontSize: context.getScreenWidth(5), fontWeight: FontWeight.w700, color: AppColors.textDark)),
                    SizedBox(height: context.getScreenHeight(2)),

                    Text("Select Craftsman", style: TextStyle(fontSize: context.getScreenWidth(3.3), fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                    SizedBox(height: context.getScreenHeight(0.8)),
                    Obx(() {
                      final craftsmen = _craftsmanController.craftsmen;
                      return Container(
                        padding: EdgeInsets.symmetric(horizontal: context.getScreenWidth(3)),
                        decoration: BoxDecoration(
                          color: AppColors.pageBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<CraftsmanModel>(
                            isExpanded: true,
                            value: selectedCraftsman,
                            hint: Text('Select craftsman', style: TextStyle(color: AppColors.textMuted, fontSize: context.getScreenWidth(3.3))),
                            items: craftsmen.map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c.displayName, style: TextStyle(fontSize: context.getScreenWidth(3.3))),
                            )).toList(),
                            onChanged: (val) => setDialogState(() => selectedCraftsman = val),
                          ),
                        ),
                      );
                    }),

                    SizedBox(height: context.getScreenHeight(2)),
                    Text("Staff Name", style: TextStyle(fontSize: context.getScreenWidth(3.3), fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                    SizedBox(height: context.getScreenHeight(0.8)),
                    TextField(
                      controller: staffNameCtrl,
                      decoration: InputDecoration(
                        hintText: 'Who you spoke with',
                        hintStyle: TextStyle(color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.pageBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),

                    SizedBox(height: context.getScreenHeight(2)),
                    Text("Notes", style: TextStyle(fontSize: context.getScreenWidth(3.3), fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                    SizedBox(height: context.getScreenHeight(0.8)),
                    TextField(
                      controller: notesCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Optional notes',
                        hintStyle: TextStyle(color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.pageBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),

                    SizedBox(height: context.getScreenHeight(3)),
                    SizedBox(
                      width: double.infinity,
                      height: context.getScreenHeight(5.5),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGold,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: selectedCraftsman == null
                            ? null
                            : () async {
                                Get.back();
                                await _controller.performAction(
                                  orderId: widget.order.id,
                                  action: 'APPROVE_AND_ASSIGN',
                                  assignedKarigarId: selectedCraftsman!.id,
                                  talkedToStaffName: staffNameCtrl.text.trim(),
                                  assignAdminNotes: notesCtrl.text.trim(),
                                );
                              },
                        child: Text("Confirm", style: TextStyle(fontSize: context.getScreenWidth(4), fontWeight: FontWeight.w700, color: Colors.white)),
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
            insetPadding: EdgeInsets.symmetric(horizontal: context.getScreenWidth(6)),
            child: Container(
              padding: EdgeInsets.all(context.getScreenWidth(5)),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Mark as Completed", style: TextStyle(fontSize: context.getScreenWidth(5), fontWeight: FontWeight.w700, color: AppColors.textDark)),
                    SizedBox(height: context.getScreenHeight(2)),

                    Text("Delivery Date", style: TextStyle(fontSize: context.getScreenWidth(3.3), fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                    SizedBox(height: context.getScreenHeight(0.8)),
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
                            hintStyle: TextStyle(color: AppColors.textMuted),
                            filled: true,
                            fillColor: AppColors.pageBg,
                            suffixIcon: Icon(Icons.calendar_today_rounded, color: AppColors.primaryGold, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: context.getScreenHeight(2)),
                    Text("Completion Notes", style: TextStyle(fontSize: context.getScreenWidth(3.3), fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                    SizedBox(height: context.getScreenHeight(0.8)),
                    TextField(
                      controller: notesCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Optional notes',
                        hintStyle: TextStyle(color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.pageBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),

                    SizedBox(height: context.getScreenHeight(3)),
                    SizedBox(
                      width: double.infinity,
                      height: context.getScreenHeight(5.5),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D9D59),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () async {
                          Get.back();
                          await _controller.performAction(
                            orderId: widget.order.id,
                            action: 'COMPLETE',
                            deliveryDate: selectedDate?.toIso8601String().split('T').first,
                            completeAdminNotes: notesCtrl.text.trim(),
                          );
                        },
                        child: Text("Confirm Complete", style: TextStyle(fontSize: context.getScreenWidth(4), fontWeight: FontWeight.w700, color: Colors.white)),
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

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Row(
      children: [
        Container(width: 4, height: 16, decoration: BoxDecoration(color: AppColors.primaryGold, borderRadius: BorderRadius.circular(4))),
        SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: context.getScreenWidth(4.2), fontWeight: FontWeight.w800, color: AppColors.textDark)),
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
          BoxShadow(color: AppColors.primaryGold.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
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
            width: context.getScreenWidth(28),
            child: Text(label, style: TextStyle(fontSize: context.getScreenWidth(3.2), fontWeight: FontWeight.w600, color: AppColors.textMuted)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: context.getScreenWidth(3.5), fontWeight: FontWeight.w700, color: AppColors.textDark)),
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
