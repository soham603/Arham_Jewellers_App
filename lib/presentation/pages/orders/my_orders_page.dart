import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/core/widgets/ratnesh_fallback.dart';
import 'package:ratnesh_gold_app/core/widgets/status_border_card.dart';
import 'package:ratnesh_gold_app/core/widgets/responsive_wrapper.dart';
import 'package:ratnesh_gold_app/domain/entities/userOrderModel.dart';
import 'package:ratnesh_gold_app/presentation/controllers/userOrderController.dart';
import 'package:ratnesh_gold_app/presentation/pages/orders/userOrderDetailScreen.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage>
    with SingleTickerProviderStateMixin {
  late final UserOrderController _orderController;
  final ScrollController _scrollController = ScrollController();
  late final TabController _tabController;
  DateTime? _lastBackPress;

  static const _tabs = ['All', 'Pending', 'Approved', 'Rejected'];
  static const _filters = ['all', 'pending', 'approved', 'rejected'];

  @override
  void initState() {
    super.initState();
    _orderController = Get.isRegistered<UserOrderController>()
        ? Get.find<UserOrderController>()
        : Get.put(UserOrderController());

    _tabController = TabController(length: _tabs.length, vsync: this);

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _orderController.setFilter(_filters[_tabController.index]);
      }
    });

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
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildOrdersList() {
    return Obx(() {
      final state = _orderController.ordersState;
      final orders = _orderController.filteredOrders;

      if (state == CurrentAppState.LOADING) {
        return _OrdersShimmer(context: context);
      }

      if (state == CurrentAppState.ERROR) {
        return _ErrorView(
          context: context,
          onRetry: () {
            _orderController.fetchUserOrders();
          },
        );
      }

      if (orders.isEmpty && state == CurrentAppState.SUCCESS) {
        return _EmptyOrdersView(context: context);
      }

      return RefreshIndicator(
        color: AppColors.primaryGold,
        backgroundColor: Colors.white,
        onRefresh: () async {
          await _orderController.refreshOrders();
        },
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
              controller: _orderController,
            );
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastBackPress != null && now.difference(_lastBackPress!) < const Duration(seconds: 2)) {
          SystemNavigator.pop();
        } else {
          _lastBackPress = now;
          HapticFeedback.lightImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.only(bottom: 80, left: 16, right: 16),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.pageBg,
        appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.pageBg,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textDark,
            size: context.getResponsiveSize(5),
          ),
        ),
        title: Text(
          'My Orders',
          style: TextStyle(
            fontSize: context.getResponsiveSize(6),
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
              size: context.getResponsiveSize(6),
            ),
          ),
          SizedBox(width: context.getScreenWidth(2)),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryGold,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primaryGold,
          indicatorWeight: 3,
          labelStyle: TextStyle(
            fontSize: context.getResponsiveSize(3.8),
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: context.getResponsiveSize(3.8),
            fontWeight: FontWeight.w400,
          ),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: ResponsiveWrapper(
        child: Column(
        children: [
          // ── Top gold accent bar (matches Figma TopAccent) ──────────
          Container(height: 3, color: AppColors.divider),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _filters.map((_) => _buildOrdersList()).toList(),
            ),
          ),
        ],
      ),
      ),
    ),
    );
  }
}

// ── Order Card ──────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final UserOrderModel order;
  final BuildContext context;
  final UserOrderController controller;

  const _OrderCard({required this.order, required this.context, required this.controller});

  @override
  Widget build(BuildContext context) {
    final statusInfo = getStatusInfo(order.status);

    return StatusBorderCard(
      status: order.status,
      onTap: () {
        Get.to(() => UserOrderDetailScreen(order: order));
      },
      child: Padding(
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
                              fontSize: context.getResponsiveSize(4.5),
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          SizedBox(height: context.getScreenHeight(0.4)),
                          Text(
                            _formatDate(order.createdAt),
                            style: TextStyle(
                              fontSize: context.getResponsiveSize(3.2),
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          StatusBadge(
                            label: statusInfo.label,
                            color: statusInfo.color,
                            bgColor: statusInfo.bgColor,
                          ),
                          SizedBox(width: context.getScreenWidth(2)),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: context.getResponsiveSize(3),
                            color: AppColors.textMuted,
                          ),
                        ],
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
                      _OrderImagesStack(order: order, controller: controller),
                      SizedBox(width: context.getScreenWidth(3)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (order.items.isEmpty)
                              Text(
                                '${order.items.length} item(s)',
                                style: TextStyle(
                                  fontSize: context.getResponsiveSize(3.8),
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
                                              fontSize: context.getResponsiveSize(3.4),
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
                                  fontSize: context.getResponsiveSize(3.2),
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
                            size: context.getResponsiveSize(4),
                            color: AppColors.primaryGold,
                          ),
                          SizedBox(width: context.getScreenWidth(2)),
                          Expanded(
                            child: Text(
                              order.adminMessage!,
                              style: TextStyle(
                                fontSize: context.getResponsiveSize(3.4),
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
                            fontSize: context.getResponsiveSize(3.8),
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '₹${_formatAmount(order.totalAmount!)}',
                          style: TextStyle(
                            fontSize: context.getResponsiveSize(4.2),
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
              width: context.getResponsiveSize(24),
              height: context.getResponsiveSize(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.tileBg,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                color: AppColors.primaryGold,
                size: context.getResponsiveSize(11),
              ),
            ),
            SizedBox(height: context.getScreenHeight(2.5)),
            Text(
              'No Orders Yet',
              style: TextStyle(
                fontSize: context.getResponsiveSize(5.5),
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: context.getScreenHeight(1)),
            Text(
              'Your orders will appear here once you place them.',
              style: TextStyle(
                fontSize: context.getResponsiveSize(3.8),
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
                    fontSize: context.getResponsiveSize(4.5),
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
            size: context.getResponsiveSize(14),
            color: AppColors.textMuted,
          ),
          SizedBox(height: context.getScreenHeight(2)),
          Text(
            'Failed to load orders',
            style: TextStyle(
              fontSize: context.getResponsiveSize(4.5),
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
                fontSize: context.getResponsiveSize(4),
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

// ── Order Images Stack ───────────────────────────────────────────────────────

class _OrderImagesStack extends StatelessWidget {
  const _OrderImagesStack({required this.order, required this.controller});

  final UserOrderModel order;
  final UserOrderController controller;

  @override
  Widget build(BuildContext context) {
    final size = context.getScreenWidth(20);
    final items = order.items;
    final images = items
        .map((item) => item.product.imageUrl ?? controller.getProductImage(item.product.id))
        .where((url) => url != null && url.isNotEmpty)
        .toList();

    if (images.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: RatneshFallback.s(width: size, height: size),
      );
    }

    final displayImages = images.take(3).toList();
    final totalItems = order.items.length;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          for (int i = displayImages.length - 1; i >= 0; i--)
            Positioned(
              top: i * 3.0,
              left: i * 3.0,
              child: Container(
                width: size - (displayImages.length - 1) * 3.0,
                height: size - (displayImages.length - 1) * 3.0,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _ProductImage(url: displayImages[i]),
                ),
              ),
            ),
          if (totalItems > 1)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  "$totalItems",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: context.getResponsiveSize(3.2),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Product Image Widget ─────────────────────────────────────────────────────

class _ProductImage extends StatelessWidget {
  final String? url;

  const _ProductImage({this.url});

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url!,
        fit: BoxFit.cover,
        placeholder: (_, _) =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        errorWidget: (_, _, _) => const RatneshFallback.xs(),
      );
    }
    return const RatneshFallback.xs();
  }
}


