import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/core/widgets/app_bottom_nav.dart';
import 'package:ratnesh_gold_app/domain/entities/userOrderModel.dart';
import 'package:ratnesh_gold_app/presentation/controllers/userOrderController.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  late final UserOrderController _orderController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _orderController = Get.isRegistered<UserOrderController>()
        ? Get.find<UserOrderController>()
        : Get.put(UserOrderController());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _orderController.fetchUserOrders();
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _orderController.loadMoreOrders();
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
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textDark,
            size: context.getScreenWidth(5),
          ),
        ),
        title: Text(
          'My Orders',
          style: TextStyle(
            fontSize: context.getScreenWidth(6),
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        actions: [
          // Refresh button
          IconButton(
            onPressed: () => _orderController.refreshOrders(),
            icon: Icon(
              Icons.refresh_rounded,
              color: AppColors.primaryGold,
              size: context.getScreenWidth(6),
            ),
          ),
          SizedBox(width: context.getScreenWidth(2)),
        ],
      ),
      body: Column(
        children: [
          // ── Top gold accent bar (matches Figma TopAccent) ──────────
          Container(height: 3, color: AppColors.divider),

          Expanded(
            child: Obx(() {
              final state = _orderController.ordersState;
              final orders = _orderController.userOrders;

              // ── Loading state ──────────────────────────────────────
              if (state == CurrentAppState.LOADING) {
                return _OrdersShimmer(context: context);
              }

              // ── Error state ────────────────────────────────────────
              if (state == CurrentAppState.ERROR) {
                return _ErrorView(
                  context: context,
                  onRetry: () => _orderController.fetchUserOrders(),
                );
              }

              // ── Empty state ────────────────────────────────────────
              if (orders.isEmpty && state == CurrentAppState.SUCCESS) {
                return _EmptyOrdersView(context: context);
              }

              // ── Orders list ────────────────────────────────────────
              return RefreshIndicator(
                color: AppColors.primaryGold,
                backgroundColor: Colors.white,
                onRefresh: () => _orderController.refreshOrders(),
                child: ListView.separated(
                  controller: _scrollController,
                  padding: EdgeInsets.fromLTRB(
                    context.getScreenWidth(4),
                    context.getScreenHeight(2),
                    context.getScreenWidth(4),
                    context.getScreenHeight(2),
                  ),
                  itemCount: orders.length +
                      (_orderController.hasMoreOrders ? 1 : 0),
                  separatorBuilder: (_, __) =>
                      SizedBox(height: context.getScreenHeight(1.5)),
                  itemBuilder: (context, index) {
                    // ── Load more indicator ──────────────────────────
                    if (index == orders.length) {
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: context.getScreenHeight(2),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryGold,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    }

                    return _OrderCard(
                      order: orders[index],
                      context: context,
                    );
                  },
                ),
              );
            }),
          ),
          const AppBottomNav(currentIndex: 4),
        ],
      ),
    );
  }
}

// ── Order Card ──────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final UserOrderModel order;
  final BuildContext context;

  const _OrderCard({required this.order, required this.context});

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo(order.status);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7DED2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top accent bar per order status ───────────────────────
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
                // ── Header row: order token + status badge ───────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.orderToken != null
                              ? 'Order #${order.orderToken}'
                              : 'Order #${order.id.substring(0, 8).toUpperCase()}',
                          style: TextStyle(
                            fontSize: context.getScreenWidth(4.5),
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        SizedBox(height: context.getScreenHeight(0.4)),
                        Text(
                          _formatDate(order.createdAt),
                          style: TextStyle(
                            fontSize: context.getScreenWidth(3.2),
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    _StatusBadge(
                      label: statusInfo.label,
                      color: statusInfo.color,
                      bgColor: statusInfo.bgColor,
                    ),
                  ],
                ),

                SizedBox(height: context.getScreenHeight(2)),
                Container(height: 1, color: AppColors.divider),
                SizedBox(height: context.getScreenHeight(1.5)),

                // ── Product thumbnail + items list ───────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thumb placeholder (matches Figma "Thumb" rect)
                    Container(
                      width: context.getScreenWidth(18),
                      height: context.getScreenWidth(18),
                      decoration: BoxDecoration(
                        color: AppColors.tileBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.diamond_outlined,
                          color: AppColors.primaryGold,
                          size: context.getScreenWidth(8),
                        ),
                      ),
                    ),
                    SizedBox(width: context.getScreenWidth(3)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (order.items.isEmpty)
                            Text(
                              '${order.items.length} item(s)',
                              style: TextStyle(
                                fontSize: context.getScreenWidth(3.8),
                                color: AppColors.textMuted,
                              ),
                            )
                          else
                            ...order.items.take(2).map(
                                  (item) => Padding(
                                    padding: EdgeInsets.only(
                                      bottom: context.getScreenHeight(0.5),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.product.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize:
                                                  context.getScreenWidth(3.8),
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textDark,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          'x${item.quantity}',
                                          style: TextStyle(
                                            fontSize: context.getScreenWidth(3.4),
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                          if (order.items.length > 2)
                            Text(
                              '+${order.items.length - 2} more items',
                              style: TextStyle(
                                fontSize: context.getScreenWidth(3.2),
                                color: AppColors.primaryGold,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                // ── Admin message if present ─────────────────────────
                if (order.adminMessage != null &&
                    order.adminMessage!.isNotEmpty) ...[
                  SizedBox(height: context.getScreenHeight(1.5)),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(context.getScreenWidth(3)),
                    decoration: BoxDecoration(
                      color: AppColors.tileBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: context.getScreenWidth(4),
                          color: AppColors.primaryGold,
                        ),
                        SizedBox(width: context.getScreenWidth(2)),
                        Expanded(
                          child: Text(
                            order.adminMessage!,
                            style: TextStyle(
                              fontSize: context.getScreenWidth(3.4),
                              color: AppColors.textMuted,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Total amount if present ──────────────────────────
                if (order.totalAmount != null) ...[
                  SizedBox(height: context.getScreenHeight(1.5)),
                  Container(height: 1, color: AppColors.divider),
                  SizedBox(height: context.getScreenHeight(1.5)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Amount',
                        style: TextStyle(
                          fontSize: context.getScreenWidth(3.8),
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '₹${_formatAmount(order.totalAmount!)}',
                        style: TextStyle(
                          fontSize: context.getScreenWidth(4.2),
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryGold,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
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
          color: const Color(0xFF3B82F6),
          bgColor: const Color(0xFFEFF6FF),
        );
      case 'completed':
      case 'delivered':
        return _StatusInfo(
          label: 'Delivered',
          color: AppColors.primaryGold,
          bgColor: const Color(0xFFF9F3E8),
        );
      case 'cancelled':
        return _StatusInfo(
          label: 'Cancelled',
          color: const Color(0xFFDC2626),
          bgColor: const Color(0xFFFEE2E2),
        );
      case 'rejected':
        return _StatusInfo(
          label: 'Rejected',
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

// ── Status Badge ────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;

  const _StatusBadge({
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: context.getScreenWidth(3),
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ── Status Info Model ────────────────────────────────────────────────────────

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

// ── Loading Shimmer ──────────────────────────────────────────────────────────

class _OrdersShimmer extends StatelessWidget {
  final BuildContext context;
  const _OrdersShimmer({required this.context});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        context.getScreenWidth(4),
        context.getScreenHeight(2),
        context.getScreenWidth(4),
        context.getScreenHeight(2),
      ),
      itemCount: 4,
      separatorBuilder: (_, __) =>
          SizedBox(height: context.getScreenHeight(1.5)),
      itemBuilder: (_, __) => _ShimmerCard(context: context),
    );
  }
}

class _ShimmerCard extends StatefulWidget {
  final BuildContext context;
  const _ShimmerCard({required this.context});

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
          ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          width: double.infinity,
          height: context.getScreenHeight(16),
          decoration: BoxDecoration(
            color: AppColors.tileBg,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}

// ── Empty State ──────────────────────────────────────────────────────────────

class _EmptyOrdersView extends StatelessWidget {
  final BuildContext context;
  const _EmptyOrdersView({required this.context});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.getScreenWidth(10)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: context.getScreenWidth(24),
              height: context.getScreenWidth(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.tileBg,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                color: AppColors.primaryGold,
                size: context.getScreenWidth(11),
              ),
            ),
            SizedBox(height: context.getScreenHeight(2.5)),
            Text(
              'No Orders Yet',
              style: TextStyle(
                fontSize: context.getScreenWidth(5.5),
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: context.getScreenHeight(1)),
            Text(
              'Your orders will appear here once you place them.',
              style: TextStyle(
                fontSize: context.getScreenWidth(3.8),
                color: AppColors.textMuted,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.getScreenHeight(3)),
            SizedBox(
              width: double.infinity,
              height: context.getScreenHeight(6.5),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: () => Get.offAllNamed('/home'),
                child: Text(
                  'Start Shopping',
                  style: TextStyle(
                    fontSize: context.getScreenWidth(4.5),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error State ──────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final BuildContext context;
  final VoidCallback onRetry;
  const _ErrorView({required this.context, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: context.getScreenWidth(14),
            color: AppColors.textMuted,
          ),
          SizedBox(height: context.getScreenHeight(2)),
          Text(
            'Failed to load orders',
            style: TextStyle(
              fontSize: context.getScreenWidth(4.5),
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: context.getScreenHeight(1.5)),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Tap to retry',
              style: TextStyle(
                fontSize: context.getScreenWidth(4),
                color: AppColors.primaryGold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
