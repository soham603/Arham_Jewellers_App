import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:ratnesh_gold_app/core/constants/admin_constants.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/core/widgets/ratnesh_fallback.dart';
import 'package:ratnesh_gold_app/presentation/controllers/userOrderController.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/routes/app_routes.dart';

class OrderSuccessPage extends StatefulWidget {
  const OrderSuccessPage({super.key});

  @override
  State<OrderSuccessPage> createState() => _OrderSuccessPageState();
}

class _OrderSuccessPageState extends State<OrderSuccessPage>
    with TickerProviderStateMixin {
  late final AnimationController _heroController;
  late final AnimationController _contentController;

  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;

  @override
  void initState() {
    super.initState();

    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _contentFade = CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOut,
    );

    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOutCubic,
    ));

    _heroController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _contentController.forward();
    });
  }

  @override
  void dispose() {
    _heroController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final UserOrderController orderController =
        Get.isRegistered<UserOrderController>()
            ? Get.find<UserOrderController>()
            : Get.put(UserOrderController());

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Get.offAllNamed(AppRoutes.home);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.pageBg,
        body: SafeArea(
          child: Column(
            children: [
              Container(height: 4, color: AppColors.primaryGold),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: context.getScreenWidth(5),
                  ),
                  child: Obx(() {
                    final orderId = orderController.createdOrderId;
                    final message = orderController.orderMessage;

                    return Column(
                      children: [
                        SizedBox(height: context.getScreenHeight(4)),

                        // ── Hero: Animated success icon with gradient bg ──
                        _AnimatedHero(controller: _heroController),

                        SizedBox(height: context.getScreenHeight(2.5)),

                        Text(
                          'Booking Confirmed!',
                          style: TextStyle(
                            fontSize: context.getFontSize(6),
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                            letterSpacing: -0.3,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        SizedBox(height: context.getScreenHeight(1)),

                        Text(
                          message.isNotEmpty
                              ? message
                              : 'Your booking has been received.\nOur team will contact you shortly.',
                          style: TextStyle(
                            fontSize: context.getFontSize(3.8),
                            color: AppColors.textMuted,
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        SizedBox(height: context.getScreenHeight(3)),

                        // ── Content: Slide-up animated sections ──
                        FadeTransition(
                          opacity: _contentFade,
                          child: SlideTransition(
                            position: _contentSlide,
                            child: Column(
                              children: [
                                _OrderDetailCard(
                                  orderId: orderId,
                                  images: orderController.lastOrderImages,
                                  itemNames:
                                      orderController.lastOrderItemNames,
                                  itemQuantities: orderController
                                      .lastOrderItemQuantities,
                                  itemPrices:
                                      orderController.lastOrderItemPrices,
                                  total: orderController.lastOrderTotal,
                                  createdAt:
                                      orderController.lastOrderCreatedAt,
                                ),
                                SizedBox(height: context.getScreenHeight(2.5)),
                                _NextStepsCard(),
                                SizedBox(height: context.getScreenHeight(2.5)),
                                _ContactAdminCard(orderId: orderId),
                                SizedBox(height: context.getScreenHeight(3)),
                                _PrimaryButton(
                                  label: 'View My Orders',
                                  onPressed: () =>
                                      Get.offAllNamed(AppRoutes.myOrders),
                                ),
                                SizedBox(
                                    height: context.getScreenHeight(1.5)),
                                _SecondaryButton(
                                  label: 'Continue Shopping',
                                  onPressed: () =>
                                      Get.offAllNamed(AppRoutes.home),
                                ),
                                SizedBox(height: context.getScreenHeight(2)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Animated Hero Section ──────────────────────────────────────────────────

class _AnimatedHero extends StatelessWidget {
  final AnimationController controller;
  const _AnimatedHero({required this.controller});

  @override
  Widget build(BuildContext context) {
    final scale = CurvedAnimation(
      parent: controller,
      curve: Curves.elasticOut,
    );
    final fade = CurvedAnimation(
      parent: controller,
      curve: const Interval(0, 0.5, curve: Curves.easeIn),
    );

    return FadeTransition(
      opacity: fade,
      child: ScaleTransition(
        scale: scale,
        child: Container(
          width: context.getScreenWidth(22),
          height: context.getScreenWidth(22),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.success.withOpacity(0.15),
                AppColors.success.withOpacity(0.05),
              ],
            ),
            border: Border.all(
              color: AppColors.success.withOpacity(0.25),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.success.withOpacity(0.12),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: context.getScreenWidth(12),
              height: context.getScreenWidth(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.success,
                    const Color(0xFF248C4B),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: context.getScreenWidth(6),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Order Detail Card ──────────────────────────────────────────────────────

class _OrderDetailCard extends StatelessWidget {
  final String orderId;
  final List<String> images;
  final List<String> itemNames;
  final List<int> itemQuantities;
  final List<double> itemPrices;
  final double total;
  final DateTime createdAt;

  const _OrderDetailCard({
    required this.orderId,
    required this.images,
    required this.itemNames,
    required this.itemQuantities,
    required this.itemPrices,
    required this.total,
    required this.createdAt,
  });

  @override
  Widget build(BuildContext context) {
    return _CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildThumbnail(context),
              SizedBox(width: context.getScreenWidth(4)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Booking Received',
                      style: TextStyle(
                        fontSize: context.getFontSize(4.8),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: context.getScreenHeight(0.5)),
                    Text(
                      'Your booking has been received',
                      style: TextStyle(
                        fontSize: context.getFontSize(3.4),
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (orderId.isNotEmpty) ...[
            SizedBox(height: context.getScreenHeight(2.5)),
            _Divider(),
            SizedBox(height: context.getScreenHeight(2.5)),

            _infoRow(
              context,
              label: 'Order ID',
              valueWidget: _CopyableOrderId(orderId: orderId),
            ),
          ],

          SizedBox(height: context.getScreenHeight(1.5)),

          _infoRow(
            context,
            label: 'Status',
            valueWidget: _StatusBadge(
              label: 'Pending',
              color: const Color(0xFFF5A623),
              bgColor: const Color(0xFFFFF4E0),
            ),
          ),

          SizedBox(height: context.getScreenHeight(1.5)),

          _infoRow(
            context,
            label: 'Expected Contact',
            value: 'Within 24 hours',
          ),

          if (itemNames.isNotEmpty) ...[
            SizedBox(height: context.getScreenHeight(2.5)),
            _Divider(),
            SizedBox(height: context.getScreenHeight(2.5)),

            for (int i = 0; i < itemNames.length; i++) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${itemNames[i]}  x${itemQuantities[i]}',
                      style: TextStyle(
                        fontSize: context.getFontSize(3.6),
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '₹${itemPrices[i].toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: context.getFontSize(3.6),
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (i < itemNames.length - 1)
                SizedBox(height: context.getScreenHeight(1)),
            ],

            SizedBox(height: context.getScreenHeight(2)),
            _Divider(),
            SizedBox(height: context.getScreenHeight(2)),

            Row(
              children: [
                Text(
                  'Total',
                  style: TextStyle(
                    fontSize: context.getFontSize(4.5),
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const Spacer(),
                Text(
                  '₹${total.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: context.getFontSize(4.5),
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryGold,
                  ),
                ),
              ],
            ),
          ],

          SizedBox(height: context.getScreenHeight(2)),
          _Divider(),
          SizedBox(height: context.getScreenHeight(2)),

          _infoRow(
            context,
            label: 'Booked On',
            value: DateFormat('dd MMM yyyy • hh:mm a')
                .format(createdAt.toLocal()),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    final size = context.getScreenWidth(18);
    final displayImages = images.take(3).toList();

    if (displayImages.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.tileBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Icon(
            Icons.shopping_bag_outlined,
            color: AppColors.primaryGold,
            size: context.getScreenWidth(9),
          ),
        ),
      );
    }

    if (displayImages.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: size,
          height: size,
          child: CachedNetworkImage(
            imageUrl: displayImages[0],
            fit: BoxFit.cover,
            placeholder: (_, _) => Container(
              color: AppColors.tileBg,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (_, _, _) => RatneshFallback.s(),
          ),
        ),
      );
    }

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
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: displayImages[i],
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(
                      color: AppColors.tileBg,
                      child: const Center(
                        child:
                            CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (_, _, _) => RatneshFallback.s(),
                  ),
                ),
              ),
            ),
          if (images.length > displayImages.length)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  "+${images.length - displayImages.length}",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: context.getFontSize(2.5),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(
    BuildContext context, {
    required String label,
    String? value,
    Widget? valueWidget,
    Color? valueColor,
    bool bold = false,
  }) {
    final valueChild = valueWidget ??
        Text(
          value ?? '',
          style: TextStyle(
            fontSize: context.getFontSize(3.8),
            color: valueColor ?? AppColors.textDark,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: context.getFontSize(3.8),
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(child: valueChild),
      ],
    );
  }
}

// ── Copyable Order ID ────────────────────────────────────────────────────────

class _CopyableOrderId extends StatefulWidget {
  final String orderId;
  const _CopyableOrderId({required this.orderId});

  @override
  State<_CopyableOrderId> createState() => _CopyableOrderIdState();
}

class _CopyableOrderIdState extends State<_CopyableOrderId> {
  bool _copied = false;

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.orderId));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _copy,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _copied
              ? Colors.green.withOpacity(0.08)
              : AppColors.primaryGold.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _copied
                ? Colors.green.withOpacity(0.2)
                : AppColors.primaryGold.withOpacity(0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _copied ? Icons.check_circle : Icons.copy_rounded,
                key: ValueKey(_copied),
                size: context.getScreenWidth(3.8),
                color: _copied ? Colors.green : AppColors.textMuted,
              ),
            ),
            SizedBox(width: context.getScreenWidth(1.5)),
            Flexible(
              child: Text(
                '#${widget.orderId}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: context.getFontSize(3.8),
                  color: AppColors.primaryGold,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Next Steps Card ─────────────────────────────────────────────────────────

class _NextStepsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final steps = [
      (Icons.phone_in_talk_rounded, 'Team will call you',
          'Our team will contact you within 24 hours'),
      (Icons.verified_outlined, 'Booking verification',
          'We confirm stock availability and pricing'),
      (Icons.store_outlined, 'Visit Showroom',
          'Visit our showroom to complete your purchase'),
    ];

    return _CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "What happens next?",
            style: TextStyle(
              fontSize: context.getFontSize(4.8),
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: context.getScreenHeight(2.5)),
          ...steps.asMap().entries.map((entry) {
            final idx = entry.key;
            final (icon, title, subtitle) = entry.value;
            final isLast = idx == steps.length - 1;
            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Numbered step circle
                    Column(
                      children: [
                        Container(
                          width: context.getScreenWidth(9),
                          height: context.getScreenWidth(9),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primaryGold,
                                AppColors.primaryGoldDark,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.primaryGold.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '${idx + 1}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: context.getFontSize(3.8),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        if (!isLast)
                          Container(
                            width: 1.5,
                            height: context.getScreenHeight(3.5),
                            margin: EdgeInsets.symmetric(
                                vertical: context.getScreenHeight(0.6)),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppColors.primaryGold.withOpacity(0.3),
                                  AppColors.primaryGold.withOpacity(0.08),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(width: context.getScreenWidth(3)),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                            top: context.getScreenHeight(0.3)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: context.getFontSize(4.2),
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                            SizedBox(
                                height: context.getScreenHeight(0.5)),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: context.getFontSize(3.3),
                                color: AppColors.textMuted,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ── Contact Admin Card ─────────────────────────────────────────────────────

class _ContactAdminCard extends StatelessWidget {
  final String orderId;

  const _ContactAdminCard({required this.orderId});

  Future<void> _launchCall() async {
    final uri =
        Uri(scheme: 'tel', path: AdminConstants.adminPhone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchWhatsApp() async {
    final phone = AdminConstants.adminPhone.replaceAll('+', '');
    final message = Uri.encodeComponent(
      'Hi, I need help with my order #$orderId',
    );
    final uri = Uri.parse('https://wa.me/$phone?text=$message');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: context.getScreenWidth(10),
                height: context.getScreenWidth(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryGold.withOpacity(0.15),
                      AppColors.primaryGold.withOpacity(0.05),
                    ],
                  ),
                ),
                child: Icon(
                  Icons.headset_mic_rounded,
                  color: AppColors.primaryGold,
                  size: context.getScreenWidth(5),
                ),
              ),
              SizedBox(width: context.getScreenWidth(3)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Need Help?',
                      style: TextStyle(
                        fontSize: context.getFontSize(4.8),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: context.getScreenHeight(0.4)),
                    Text(
                      'Have questions about your order?',
                      style: TextStyle(
                        fontSize: context.getFontSize(3.3),
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: context.getScreenHeight(2.5)),
          Row(
            children: [
              Expanded(
                child: _ContactButton(
                  icon: Icon(Icons.phone_rounded,
                      color: AppColors.primaryGold,
                      size: context.getScreenWidth(4.5)),
                  label: 'Call Us',
                  color: AppColors.primaryGold,
                  onTap: _launchCall,
                ),
              ),
              SizedBox(width: context.getScreenWidth(3)),
              Expanded(
                child: _ContactButton(
                  icon: FaIcon(FontAwesomeIcons.whatsapp,
                      color: const Color(0xFF25D366)),
                  label: 'WhatsApp',
                  color: const Color(0xFF25D366),
                  onTap: _launchWhatsApp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Reusable Contact Button ─────────────────────────────────────────────────

class _ContactButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ContactButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withOpacity(0.2),
            ),
          ),
          padding: EdgeInsets.symmetric(
            vertical: context.getScreenHeight(1.6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              SizedBox(width: context.getScreenWidth(2)),
              Text(
                label,
                style: TextStyle(
                  fontSize: context.getFontSize(3.8),
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Primary Button ──────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _PrimaryButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: context.getScreenHeight(6.5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryGold,
                  AppColors.primaryGoldDark,
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGold.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: context.getFontSize(4.5),
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Secondary Button ────────────────────────────────────────────────────────

class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _SecondaryButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: context.getScreenHeight(6.5),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: AppColors.primaryGold.withOpacity(0.4),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          foregroundColor: AppColors.primaryGold,
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: TextStyle(
            fontSize: context.getFontSize(4.5),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ── Shared Card Container ───────────────────────────────────────────────────

class _CardContainer extends StatelessWidget {
  final Widget child;

  const _CardContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.getScreenWidth(5)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7DED2).withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: AppColors.primaryGold.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ── Shared Divider ──────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.divider.withOpacity(0),
            AppColors.divider,
            AppColors.divider.withOpacity(0),
          ],
        ),
      ),
    );
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: context.getFontSize(3.2),
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
