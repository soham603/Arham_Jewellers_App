import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/core/widgets/responsive_wrapper.dart';
import 'package:ratnesh_gold_app/domain/entities/admin/adminOrderModel.dart';
import 'package:ratnesh_gold_app/presentation/controllers/admin/AdminCustomOrderController.dart';
import 'package:ratnesh_gold_app/presentation/pages/admin/adminCustomOrderDetailPage.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';

class AdminCustomOrdersPage extends StatefulWidget {
  const AdminCustomOrdersPage({super.key});

  @override
  State<AdminCustomOrdersPage> createState() => _AdminCustomOrdersPageState();
}

class _AdminCustomOrdersPageState extends State<AdminCustomOrdersPage> {
  late final AdminCustomOrderController _controller;
  final ScrollController _scrollController = ScrollController();

  static const _statusFilters = ['PENDING', 'ASSIGNED', 'COMPLETED', 'REJECTED'];

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<AdminCustomOrderController>()
        ? Get.find<AdminCustomOrderController>()
        : Get.put(AdminCustomOrderController());

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        _controller.fetchCustomOrders(isPagination: true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          'Custom Orders',
          style: TextStyle(
            fontSize: context.getScreenWidth(5.5),
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        titleSpacing: context.getScreenWidth(4),
      ),
      body: ResponsiveWrapper(
        child: Column(
          children: [
            Container(height: 3, color: AppColors.divider),

            // ── Search bar ──
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.getScreenWidth(4),
                context.getScreenHeight(1.5),
                context.getScreenWidth(4),
                0,
              ),
              child: TextField(
                controller: _controller.searchController,
                onChanged: _controller.onSearchChanged,
                style: TextStyle(fontSize: context.getScreenWidth(3.5), color: AppColors.textDark),
                decoration: InputDecoration(
                  hintText: 'Search by party name or phone...',
                  hintStyle: TextStyle(color: AppColors.textMuted, fontSize: context.getScreenWidth(3.3)),
                  prefixIcon: Icon(Icons.search_rounded, color: AppColors.textMuted, size: context.getScreenWidth(5)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(vertical: context.getScreenHeight(1.5)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE7DED2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE7DED2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.primaryGold, width: 1.5),
                  ),
                ),
              ),
            ),

            SizedBox(height: context.getScreenHeight(1.5)),

            // ── Status filter chips ──
            SizedBox(
              height: context.getScreenHeight(4.5),
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: context.getScreenWidth(4)),
                scrollDirection: Axis.horizontal,
                itemCount: _statusFilters.length,
                separatorBuilder: (_, __) => SizedBox(width: context.getScreenWidth(2)),
                itemBuilder: (context, index) {
                  final status = _statusFilters[index];
                  return Obx(() {
                    final isSelected = _controller.selectedStatus.value == status;
                    return GestureDetector(
                      onTap: () => _controller.changeStatus(status),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.symmetric(horizontal: context.getScreenWidth(4)),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primaryGold : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.primaryGold : const Color(0xFFE7DED2),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          status[0] + status.substring(1).toLowerCase(),
                          style: TextStyle(
                            fontSize: context.getScreenWidth(3.3),
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : AppColors.textMuted,
                          ),
                        ),
                      ),
                    );
                  });
                },
              ),
            ),

            SizedBox(height: context.getScreenHeight(1.5)),

            // ── Orders list ──
            Expanded(
              child: Obx(() {
                final state = _controller.orderState;
                final orders = _controller.orders;

                if (state == CurrentAppState.LOADING) {
                  return _AdminOrderShimmer(context: context);
                }

                if (state == CurrentAppState.ERROR) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline_rounded, size: context.getScreenWidth(12), color: AppColors.textMuted),
                        SizedBox(height: context.getScreenHeight(2)),
                        Text('Failed to load orders', style: TextStyle(fontSize: context.getScreenWidth(4.5), fontWeight: FontWeight.w600, color: AppColors.textDark)),
                        SizedBox(height: context.getScreenHeight(1)),
                        TextButton(
                          onPressed: () => _controller.fetchCustomOrders(),
                          child: Text('Tap to retry', style: TextStyle(fontSize: context.getScreenWidth(4), color: AppColors.primaryGold, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  );
                }

                if (orders.isEmpty && state == CurrentAppState.SUCCESS) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: context.getScreenWidth(14), color: AppColors.textMuted),
                        SizedBox(height: context.getScreenHeight(2)),
                        Text('No custom orders found', style: TextStyle(fontSize: context.getScreenWidth(4.5), fontWeight: FontWeight.w600, color: AppColors.textDark)),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primaryGold,
                  backgroundColor: Colors.white,
                  onRefresh: () => _controller.fetchCustomOrders(),
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: EdgeInsets.fromLTRB(
                      context.getScreenWidth(4),
                      0,
                      context.getScreenWidth(4),
                      context.getScreenHeight(2),
                    ),
                    itemCount: orders.length + (_controller.hasMore ? 1 : 0),
                    separatorBuilder: (_, __) => SizedBox(height: context.getScreenHeight(1.5)),
                    itemBuilder: (context, index) {
                      if (index == orders.length) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: context.getScreenHeight(2)),
                          child: const Center(child: CircularProgressIndicator(color: AppColors.primaryGold, strokeWidth: 2)),
                        );
                      }
                      return _AdminCustomOrderCard(
                        order: orders[index],
                        context: context,
                        onTap: () => Get.to(() => AdminCustomOrderDetailPage(order: orders[index])),
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminCustomOrderCard extends StatelessWidget {
  final AdminOrderModel order;
  final BuildContext context;
  final VoidCallback onTap;

  const _AdminCustomOrderCard({required this.order, required this.context, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo(order.status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE7DED2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: statusInfo.color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(context.getScreenWidth(4)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #${order.id.substring(0, 8).toUpperCase()}',
                            style: TextStyle(fontSize: context.getScreenWidth(4.5), fontWeight: FontWeight.w700, color: AppColors.textDark),
                          ),
                          SizedBox(height: context.getScreenHeight(0.4)),
                          Text(
                            _formatDate(order.createdAt),
                            style: TextStyle(fontSize: context.getScreenWidth(3.2), color: AppColors.textMuted),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: statusInfo.bgColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              statusInfo.label,
                              style: TextStyle(fontSize: context.getScreenWidth(3), fontWeight: FontWeight.w600, color: statusInfo.color),
                            ),
                          ),
                          SizedBox(width: context.getScreenWidth(2)),
                          Icon(Icons.arrow_forward_ios_rounded, size: context.getScreenWidth(3), color: AppColors.textMuted),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: context.getScreenHeight(1.5)),
                  Container(height: 1, color: AppColors.divider),
                  SizedBox(height: context.getScreenHeight(1.5)),
                  ...order.orderItems.take(2).map(
                    (item) => Padding(
                      padding: EdgeInsets.only(bottom: context.getScreenHeight(0.5)),
                      child: Text(
                        item.product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: context.getScreenWidth(3.8), fontWeight: FontWeight.w600, color: AppColors.textDark),
                      ),
                    ),
                  ),
                  if (order.orderItems.length > 2)
                    Text(
                      '+${order.orderItems.length - 2} more',
                      style: TextStyle(fontSize: context.getScreenWidth(3.2), color: AppColors.primaryGold, fontWeight: FontWeight.w500),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
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
}

class _StatusInfo {
  final String label;
  final Color color;
  final Color bgColor;
  const _StatusInfo(this.label, this.color, this.bgColor);
}

class _AdminOrderShimmer extends StatelessWidget {
  final BuildContext context;
  const _AdminOrderShimmer({required this.context});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        context.getScreenWidth(4),
        0,
        context.getScreenWidth(4),
        context.getScreenHeight(2),
      ),
      itemCount: 4,
      separatorBuilder: (_, __) => SizedBox(height: context.getScreenHeight(1.5)),
      itemBuilder: (_, __) => Container(
        width: double.infinity,
        height: context.getScreenHeight(14),
        decoration: BoxDecoration(
          color: AppColors.tileBg,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
