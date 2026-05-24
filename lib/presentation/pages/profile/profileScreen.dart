import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/core/widgets/app_bottom_nav.dart';
import 'package:ratnesh_gold_app/domain/entities/userOrderModel.dart';
import 'package:ratnesh_gold_app/presentation/controllers/AuthController.dart';
import 'package:ratnesh_gold_app/presentation/controllers/userOrderController.dart';
import 'package:ratnesh_gold_app/presentation/pages/admin/widgets/adminDrawer.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final UserOrderController orderController;
  late final AuthController authController;

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();

    if (Get.isRegistered<UserOrderController>()) {
      orderController = Get.find<UserOrderController>();
    } else {
      orderController = Get.put(UserOrderController());
    }

    if (Get.isRegistered<AuthController>()) {
      authController = Get.find<AuthController>();
    } else {
      authController = Get.put(AuthController());
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      orderController.fetchUserOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      key: scaffoldKey,
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
      endDrawer: const AdminDrawer(),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.pageBg,
        title: Text(
          "Profile",
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
            fontSize: context.getScreenWidth(5.5),
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: context.getScreenWidth(2)),

            child: GestureDetector(
              onTap: () {
                scaffoldKey.currentState?.openEndDrawer();
              },

              child: Container(
                padding: EdgeInsets.all(context.getScreenWidth(2.5)),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),

                child: Icon(
                  Icons.menu_rounded,
                  color: AppColors.textDark,
                  size: context.getScreenWidth(6),
                ),
              ),
            ),
          ),
        ],
      ),

      body: Obx(() {
        if (orderController.ordersState == CurrentAppState.LOADING &&
            orderController.userOrders.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (orderController.ordersState == CurrentAppState.ERROR &&
            orderController.userOrders.isEmpty) {
          return Center(
            child: Text(
              "Failed to load orders",
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: context.getScreenWidth(4),
              ),
            ),
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: context.getScreenWidth(4),
            vertical: context.getScreenHeight(1),
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =====================================================
              // PROFILE CARD
              // =====================================================
              Container(
                width: double.infinity,
                height: context.getScreenHeight(30),

                padding: EdgeInsets.all(context.getScreenWidth(5)),

                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),

                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E1E1E), Color(0xFF2E2E2E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Row(
                      children: [
                        Container(
                          width: context.getScreenWidth(18),

                          height: context.getScreenWidth(18),

                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.15),
                          ),

                          child: Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: context.getScreenWidth(10),
                          ),
                        ),

                        SizedBox(width: context.getScreenWidth(4)),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              Text(
                                authController.user?.name ?? "User" ,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: context.getScreenWidth(5.3),
                                ),
                              ),

                              SizedBox(height: context.getScreenHeight(0.5)),

                              Text(
                                "Premium Jewellery Customer",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: context.getScreenWidth(3.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    Row(
                      children: [
                        Expanded(
                          child: _profileStat(
                            context,
                            "Orders",
                            "${orderController.totalOrders}",
                          ),
                        ),

                        SizedBox(width: context.getScreenWidth(3)),

                        Expanded(
                          child: _profileStat(context, "Status", "Active"),
                        ),
                      ],
                    ),

                    SizedBox(height: context.getScreenHeight(2)),

                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: context.getScreenWidth(4),
                        vertical: context.getScreenHeight(1.2),
                      ),

                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),

                        borderRadius: BorderRadius.circular(16),
                      ),

                      child: Row(
                        children: [
                          Icon(
                            Icons.workspace_premium,
                            color: Colors.amber,
                            size: context.getScreenWidth(5),
                          ),

                          SizedBox(width: context.getScreenWidth(2)),

                          Expanded(
                            child: Text(
                              "Trusted Jewellery Buyer",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: context.getScreenWidth(3.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: context.getScreenHeight(3)),

              Divider(color: Colors.grey.shade300),

              SizedBox(height: context.getScreenHeight(2)),

              // =====================================================
              // TITLE
              // =====================================================
              Text(
                "My Orders",
                style: TextStyle(
                  fontSize: context.getScreenWidth(6),
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),

              SizedBox(height: context.getScreenHeight(2)),

              // =====================================================
              // ORDERS
              // =====================================================
              ...List.generate(orderController.userOrders.length, (index) {
                final order = orderController.userOrders[index];

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: context.getScreenHeight(1.5),
                  ),

                  child: _OrderCard(order: order),
                );
              }),

              if (orderController.hasMoreOrders)
                Padding(
                  padding: EdgeInsets.only(
                    top: context.getScreenHeight(1),
                    bottom: context.getScreenHeight(3),
                  ),

                  child: Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: AppColors.primaryGold,

                        padding: EdgeInsets.symmetric(
                          horizontal: context.getScreenWidth(8),
                          vertical: context.getScreenHeight(1.4),
                        ),

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),

                      onPressed: orderController.isFetchingOrders
                          ? null
                          : () {
                              orderController.loadMoreOrders();
                            },

                      child: orderController.isFetchingOrders
                          ? SizedBox(
                              width: context.getScreenWidth(4),
                              height: context.getScreenWidth(4),
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              "Load More",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: context.getScreenWidth(4),
                              ),
                            ),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _profileStat(BuildContext context, String title, String value) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: context.getScreenHeight(1.4)),

      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),

        borderRadius: BorderRadius.circular(18),
      ),

      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: context.getScreenWidth(5),
            ),
          ),

          SizedBox(height: context.getScreenHeight(0.4)),

          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: context.getScreenWidth(3.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatefulWidget {
  const _OrderCard({required this.order});

  final UserOrderModel order;

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),

      width: double.infinity,

      padding: EdgeInsets.all(context.getScreenWidth(4)),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(22),

        border: Border.all(color: const Color(0xFFE7DED2)),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        children: [
          // ===================================================
          // TOP CARD
          // ===================================================
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Container(
                width: context.getScreenWidth(20),

                height: context.getScreenWidth(20),

                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),

                  color: const Color(0xFFF5EFE7),
                ),

                child: Icon(
                  Icons.shopping_bag_rounded,
                  color: AppColors.primaryGold,
                  size: context.getScreenWidth(9),
                ),
              ),

              SizedBox(width: context.getScreenWidth(4)),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      "Order #${order.id.substring(0, 8)}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                        fontSize: context.getScreenWidth(4.5),
                      ),
                    ),

                    SizedBox(height: context.getScreenHeight(0.5)),

                    Text(
                      DateFormat(
                        "dd MMM yyyy • hh:mm a",
                      ).format(order.createdAt.toLocal()),

                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: context.getScreenWidth(3.4),
                      ),
                    ),

                    SizedBox(height: context.getScreenHeight(0.8)),

                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.getScreenWidth(3),
                        vertical: context.getScreenHeight(0.5),
                      ),

                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4E5),

                        borderRadius: BorderRadius.circular(100),
                      ),

                      child: Text(
                        order.status,
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w700,
                          fontSize: context.getScreenWidth(3.2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              GestureDetector(
                onTap: () {
                  setState(() {
                    expanded = !expanded;
                  });
                },

                child: AnimatedRotation(
                  turns: expanded ? 0.5 : 0,

                  duration: const Duration(milliseconds: 250),

                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: context.getScreenWidth(7),
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),

          // ===================================================
          // EXPANDED
          // ===================================================
          if (expanded) ...[
            SizedBox(height: context.getScreenHeight(1.8)),

            Divider(color: Colors.grey.shade300),

            SizedBox(height: context.getScreenHeight(1)),

            ...List.generate(order.items.length, (index) {
              final item = order.items[index];

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Text(
                          item.product.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                            fontSize: context.getScreenWidth(3.8),
                          ),
                        ),
                      ),

                      Expanded(
                        child: Text(
                          "x${item.quantity}",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: context.getScreenWidth(3.5),
                          ),
                        ),
                      ),

                      Expanded(
                        child: Text(
                          "₹${item.price.toStringAsFixed(0)}",
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            color: AppColors.primaryGold,
                            fontWeight: FontWeight.w700,
                            fontSize: context.getScreenWidth(3.7),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: context.getScreenHeight(1)),

                  if (index != order.items.length - 1)
                    Divider(color: Colors.grey.shade200),

                  SizedBox(height: context.getScreenHeight(1)),
                ],
              );
            }),

            Divider(color: Colors.grey.shade300),

            SizedBox(height: context.getScreenHeight(1)),

            Row(
              children: [
                Container(
                  width: context.getScreenWidth(9),
                  height: context.getScreenWidth(9),

                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F8EC),
                    shape: BoxShape.circle,
                  ),

                  child: Icon(
                    Icons.whatshot_rounded,
                    color: Colors.green,
                    size: context.getScreenWidth(4.5),
                  ),
                ),

                SizedBox(width: context.getScreenWidth(3)),

                Expanded(
                  child: Text(
                    "Contact on WhatsApp for query",
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                      fontSize: context.getScreenWidth(3.7),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
