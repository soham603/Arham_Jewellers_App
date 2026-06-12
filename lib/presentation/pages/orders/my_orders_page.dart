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
import 'package:shimmer/shimmer.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  late final UserOrderController _orderController;
  final ScrollController _scrollController = ScrollController();
  DateTime? _lastBackPress;
  int _activeTabIndex = 0;

  static const _tabs = ['All', 'Pending', 'Approved', 'Rejected'];
  static const _filters = ['all', 'pending', 'approved', 'rejected'];

  @override
  void initState() {
    super.initState();
    _orderController = Get.isRegistered<UserOrderController>()
        ? Get.find<UserOrderController>()
        : Get.put(UserOrderController());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _orderController.fetchUserOrders();
      _orderController.setFilter(_filters[0]);
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
            context.getResponsiveSize(4),
            context.getScreenHeight(2),
            context.getResponsiveSize(4),
            context.getScreenHeight(2),
          ),
          itemCount: orders.length +
              (_orderController.hasMoreOrders ? 1 : 0),
          separatorBuilder: (_, _) =>
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
        if ((Get.key.currentState?.canPop() ?? false)) {
          Get.back();
        } else {
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
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.pageBg,
        appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.pageBg,
        centerTitle: false,
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
          SizedBox(width: context.getResponsiveSize(2)),
        ],
      ),
      body: ResponsiveWrapper(
        child: Column(
        children: [
          // ── Filter buttons 
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.getResponsiveSize(4),
              context.getScreenHeight(1),
              context.getResponsiveSize(4),
              context.getScreenHeight(0.5),
            ),
            child: Row(
              children: List.generate(_tabs.length, (i) {
                final isActive = _activeTabIndex == i;
                final label = _tabs[i];
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _activeTabIndex = i);
                      _orderController.setFilter(_filters[i]);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: EdgeInsets.symmetric(
                        horizontal: 3,
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: context.getScreenHeight(0.9),
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primaryGold
                            : AppColors.primaryGold.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: context.getResponsiveSize(3.4),
                          fontWeight: FontWeight.w700,
                          color: isActive ? Colors.white : AppColors.primaryGold,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          Container(height: 1, color: AppColors.divider),

          Expanded(
            child: _buildOrdersList(),
          ),
        ],
      ),
      ),
    ),
    );
  }
}

// ── Order Card 

class _OrderCard extends StatelessWidget {
  final UserOrderModel order;
  final BuildContext context;

  const _OrderCard({required this.order, required this.context});

  @override
  Widget build(BuildContext context) {
    final statusInfo = getStatusInfo(order.status);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: StatusBorderCard(
      status: order.status,
      onTap: () {
        Get.to(() => UserOrderDetailScreen(order: order));
      },
      child: Padding(
              padding: EdgeInsets.all(context.getResponsiveSize(4)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header row: order token + status badge 
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
                          if (order.isCustomOrder) ...[
                            SizedBox(height: context.getScreenHeight(0.6)),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: context.getResponsiveSize(2),
                                vertical: context.getScreenHeight(0.3),
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(
                                  color: AppColors.primaryGold.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                "CUSTOM",
                                style: TextStyle(
                                  color: AppColors.primaryGold,
                                  fontWeight: FontWeight.w800,
                                  fontSize: context.getResponsiveSize(2.4),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Row(
                        children: [
                          StatusBadge(
                            label: statusInfo.label,
                            color: statusInfo.color,
                            bgColor: statusInfo.bgColor,
                          ),
                          SizedBox(width: context.getResponsiveSize(2)),
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

                  // ── Product thumbnail + items list 
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _OrderImagesStack(order: order),
                      SizedBox(width: context.getResponsiveSize(3)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (order.items.isEmpty)
                              Text(
                                order.isCustomOrder
                                    ? (order.purity ?? 'Custom item')
                                    : '${order.items.length} item(s)',
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
                                                    context.getResponsiveSize(3.8),
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

                  // ── Admin message if present 
                  if (order.adminMessage != null &&
                      order.adminMessage!.isNotEmpty) ...[
                    SizedBox(height: context.getScreenHeight(1.5)),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(context.getResponsiveSize(3)),
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
                          SizedBox(width: context.getResponsiveSize(2)),
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

                  // ── Total amount if present ─
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

// ── Loading Shimmer 

class _OrdersShimmer extends StatelessWidget {
  final BuildContext context;
  const _OrdersShimmer({required this.context});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        context.getResponsiveSize(4),
        context.getScreenHeight(2),
        context.getResponsiveSize(4),
        context.getScreenHeight(2),
      ),
      itemCount: 4,
      separatorBuilder: (_, _) =>
          SizedBox(height: context.getScreenHeight(1.5)),
      itemBuilder: (_, _) => const _ShimmerCard(),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.warmShimmerBase,
      highlightColor: AppColors.warmShimmerHighlight,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Container(height: 4, color: Colors.white),
            Padding(
              padding: EdgeInsets.all(context.getResponsiveSize(4)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ShimmerBlock(
                            width: context.getResponsiveSize(30),
                            height: context.getScreenHeight(2),
                          ),
                          SizedBox(height: context.getScreenHeight(0.8)),
                          _ShimmerBlock(
                            width: context.getResponsiveSize(20),
                            height: context.getScreenHeight(1.5),
                          ),
                        ],
                      ),
                      _ShimmerBlock(
                        width: context.getResponsiveSize(22),
                        height: context.getScreenHeight(3),
                        borderRadius: 20,
                      ),
                    ],
                  ),
                  SizedBox(height: context.getScreenHeight(2)),
                  _ShimmerBlock(height: 1),
                  SizedBox(height: context.getScreenHeight(1.5)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ShimmerBlock(
                        width: context.getResponsiveSize(20),
                        height: context.getResponsiveSize(20),
                        borderRadius: 14,
                      ),
                      SizedBox(width: context.getResponsiveSize(3)),
                      Expanded(
                        child: Column(
                          children: [
                            _ShimmerBlock(
                              width: double.infinity,
                              height: context.getScreenHeight(1.8),
                            ),
                            SizedBox(height: context.getScreenHeight(1.2)),
                            _ShimmerBlock(
                              width: context.getResponsiveSize(25),
                              height: context.getScreenHeight(1.8),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.getScreenHeight(1.5)),
                  _ShimmerBlock(height: 1),
                  SizedBox(height: context.getScreenHeight(1.5)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _ShimmerBlock(
                        width: context.getResponsiveSize(20),
                        height: context.getScreenHeight(2),
                      ),
                      _ShimmerBlock(
                        width: context.getResponsiveSize(20),
                        height: context.getScreenHeight(2.2),
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
  }
}

class _ShimmerBlock extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const _ShimmerBlock({
    this.width,
    required this.height,
    this.borderRadius = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

// ── Empty State 

class _EmptyOrdersView extends StatelessWidget {
  final BuildContext context;
  const _EmptyOrdersView({required this.context});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.getResponsiveSize(10)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: context.getResponsiveSize(24),
              height: context.getResponsiveSize(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryGold.withValues(alpha: 0.08),
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                color: AppColors.primaryGold.withValues(alpha: 0.6),
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
                    borderRadius: BorderRadius.circular(16),
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

// ── Error State 

class _ErrorView extends StatelessWidget {
  final BuildContext context;
  final VoidCallback onRetry;
  const _ErrorView({required this.context, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.getResponsiveSize(10)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: context.getResponsiveSize(22),
              height: context.getResponsiveSize(22),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.dangerSoft,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: context.getResponsiveSize(10),
                color: AppColors.danger,
              ),
            ),
            SizedBox(height: context.getScreenHeight(2.5)),
            Text(
              'Failed to load orders',
              style: TextStyle(
                fontSize: context.getResponsiveSize(4.5),
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: context.getScreenHeight(1)),
            Text(
              'Something went wrong. Please try again.',
              style: TextStyle(
                fontSize: context.getResponsiveSize(3.8),
                color: AppColors.textMuted,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.getScreenHeight(3)),
            SizedBox(
              width: double.infinity,
              height: context.getScreenHeight(6.5),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: Text(
                  'Retry',
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

// ── Order Images Stack 

class _OrderImagesStack extends StatelessWidget {
  const _OrderImagesStack({required this.order});

  final UserOrderModel order;

  @override
  Widget build(BuildContext context) {
    final size = context.getResponsiveSize(20);
    final items = order.items;
    final images = items
        .map((item) => item.product.imageUrl)
        .where((url) => url != null && url.isNotEmpty)
        .toList();

    if (images.isEmpty) {
      if (order.isCustomOrder && order.referenceImages.isNotEmpty) {
        final refImages = order.referenceImages.take(3).toList();
        return SizedBox(
          width: size,
          height: size,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: CachedNetworkImage(
              imageUrl: refImages.first,
              fit: BoxFit.cover,
              placeholder: (_, _) => RatneshFallback.s(width: size, height: size),
              errorWidget: (_, _, _) => RatneshFallback.s(width: size, height: size),
            ),
          ),
        );
      }
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
                      color: Colors.black.withValues(alpha: 0.08),
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

// ── Product Image Widget 

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


