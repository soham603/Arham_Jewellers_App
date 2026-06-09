import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/core/widgets/search_bar_widget.dart';
import 'package:ratnesh_gold_app/domain/entities/admin/handsetChangeModel.dart';
import 'package:ratnesh_gold_app/presentation/controllers/admin/HandsetChangeController.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';

class HandsetChangeScreen extends StatefulWidget {
  const HandsetChangeScreen({super.key});

  @override
  State<HandsetChangeScreen> createState() => _HandsetChangeScreenState();
}

class _HandsetChangeScreenState extends State<HandsetChangeScreen> {
  final HandsetChangeController controller = Get.put(HandsetChangeController());
  final ScrollController _scroll = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  static const _filters = ['PENDING', 'APPROVED', 'REJECTED'];

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
        controller.loadMore();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchRequests();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.pageBg,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Handset Changes',
          style: TextStyle(
            fontSize: context.getFontSize(5.5),
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        actions: [
          Obx(
            () => Padding(
              padding: EdgeInsets.only(right: context.getScreenWidth(4)),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.getScreenWidth(3),
                  vertical: context.getScreenHeight(0.5),
                ),
                decoration: BoxDecoration(
                  color: _filterColor(controller.activeFilter).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${controller.total} total',
                  style: TextStyle(
                    fontSize: context.getFontSize(3.2),
                    fontWeight: FontWeight.w600,
                    color: _filterColor(controller.activeFilter),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.getScreenWidth(4),
              context.getScreenHeight(1),
              context.getScreenWidth(4),
              0,
            ),
            child: SearchBarWidget(
              controller: _searchController,
              onChanged: controller.onSearchChanged,
              onClear: () {
                _searchController.clear();
                controller.clearSearch();
              },
              hintText: 'Search by name or phone...',
              outerBackgroundColor: Colors.transparent,
            ),
          ),
          SizedBox(height: context.getScreenHeight(0.5)),
          _filterBar(context),
          Expanded(
            child: Obx(() {
              final state = controller.state;
              final list = controller.requests;

              if (state == CurrentAppState.LOADING && list.isEmpty) {
                return _shimmerList(context);
              }

              if (state == CurrentAppState.ERROR && list.isEmpty) {
                return _errorView(context);
              }

              if (state == CurrentAppState.SUCCESS && list.isEmpty) {
                return _emptyView(context);
              }

              return RefreshIndicator(
                onRefresh: controller.refresh,
                color: context.colorPalette.primaryColor,
                child: ListView.separated(
                  controller: _scroll,
                  padding: EdgeInsets.fromLTRB(
                    context.getScreenWidth(4),
                    context.getScreenHeight(1.5),
                    context.getScreenWidth(4),
                    context.getScreenHeight(3),
                  ),
                  itemCount: list.length + 1,
                  separatorBuilder: (_, _) =>
                      SizedBox(height: context.getScreenHeight(1.5)),
                  itemBuilder: (context, index) {
                    if (index == list.length) return _listFooter(context);
                    return _RequestCard(
                      key: ValueKey(list[index].id),
                      request: list[index],
                      controller: controller,
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Filter Bar ────────────────────────────────────────────────────────────
  Widget _filterBar(BuildContext context) {
    return Obx(
      () => Container(
        padding: EdgeInsets.fromLTRB(
          context.getScreenWidth(4),
          context.getScreenHeight(0.5),
          context.getScreenWidth(4),
          context.getScreenHeight(1),
        ),
        child: Row(
          children: _filters.map((f) {
            final isActive = controller.activeFilter == f;
            final color = _filterColor(f);
            return Expanded(
              child: GestureDetector(
                onTap: () => controller.setFilter(f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.symmetric(
                    horizontal: context.getScreenWidth(1),
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: context.getScreenHeight(0.8),
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? color : color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    f,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: context.getFontSize(3),
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : color,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── List Footer ───────────────────────────────────────────────────────────
  Widget _listFooter(BuildContext context) {
    return Obx(() {
      if (controller.state == CurrentAppState.LOADING &&
          controller.requests.isNotEmpty) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: context.getScreenHeight(2)),
          child: Center(
            child: SizedBox(
              width: context.getScreenWidth(6),
              height: context.getScreenWidth(6),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: context.colorPalette.primaryColor,
              ),
            ),
          ),
        );
      }
      if (!controller.hasMore) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: context.getScreenHeight(2)),
          child: Center(
            child: Text(
              'All requests loaded',
              style: TextStyle(
                fontSize: context.getFontSize(3.2),
                color: context.colorPalette.subTitleColor,
              ),
            ),
          ),
        );
      }
      return const SizedBox.shrink();
    });
  }

  // ── Shimmer ───────────────────────────────────────────────────────────────
  Widget _shimmerList(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.all(context.getScreenWidth(4)),
      itemCount: 5,
      separatorBuilder: (_, __) =>
          SizedBox(height: context.getScreenHeight(1.5)),
      itemBuilder: (_, __) => _shimmerCard(context),
    );
  }

  Widget _shimmerCard(BuildContext context) {
    return Container(
      height: context.getScreenHeight(14),
      decoration: BoxDecoration(
        color: context.colorPalette.shimmerBaseColor,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsets.all(context.getScreenWidth(4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: context.getScreenWidth(10),
                height: context.getScreenWidth(10),
                decoration: BoxDecoration(
                  color: context.colorPalette.shimmerHighLightColor,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: context.getScreenWidth(3)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: context.getScreenWidth(35),
                    height: context.getScreenHeight(1.5),
                    decoration: BoxDecoration(
                      color: context.colorPalette.shimmerHighLightColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(height: context.getScreenHeight(0.6)),
                  Container(
                    width: context.getScreenWidth(25),
                    height: context.getScreenHeight(1.2),
                    decoration: BoxDecoration(
                      color: context.colorPalette.shimmerHighLightColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Error / Empty ─────────────────────────────────────────────────────────
  Widget _errorView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_off_rounded,
            size: context.getScreenWidth(14),
            color: context.colorPalette.subTitleColor,
          ),
          SizedBox(height: context.getScreenHeight(1.5)),
          Text(
            'Failed to load',
            style: TextStyle(
              fontSize: context.getFontSize(4.5),
              fontWeight: FontWeight.w600,
              color: context.colorPalette.textColor,
            ),
          ),
          SizedBox(height: context.getScreenHeight(0.5)),
          Text(
            controller.error,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: context.getFontSize(3.2),
              color: context.colorPalette.subTitleColor,
            ),
          ),
          SizedBox(height: context.getScreenHeight(2)),
          ElevatedButton(
            onPressed: controller.refresh,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colorPalette.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _emptyView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_rounded,
            size: context.getScreenWidth(16),
            color: context.colorPalette.subTitleColor,
          ),
          SizedBox(height: context.getScreenHeight(1.5)),
          Text(
            controller.searchQuery.isNotEmpty
                ? 'No ${controller.activeFilter.toLowerCase()} requests found'
                : 'No ${controller.activeFilter.toLowerCase()} requests',
            style: TextStyle(
              fontSize: context.getFontSize(4.5),
              fontWeight: FontWeight.w600,
              color: context.colorPalette.textColor,
            ),
          ),
          if (controller.searchQuery.isNotEmpty)
            TextButton(
              onPressed: () {
                _searchController.clear();
                controller.clearSearch();
              },
              child: Text(
                'Clear search',
                style: TextStyle(
                  color: context.colorPalette.primaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _filterColor(String filter) {
    switch (filter) {
      case 'APPROVED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      default:
        return const Color(0xFFD4AF37);
    }
  }
}

// ── Request Card ──────────────────────────────────────────────────────────────
class _RequestCard extends StatefulWidget {
  final HandsetChangeRequestModel request;
  final HandsetChangeController controller;

  const _RequestCard({
    super.key,
    required this.request,
    required this.controller,
  });

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    final statusColor = _statusColor(req.status);
    final cardColor = AppColors.primaryGold;
    final userName = req.userName ?? 'Unknown';
    final userPhone = req.userPhoneNumber ?? '—';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: context.colorPalette.boxColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardColor.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header row (always visible) ─────────────────────────────────
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: EdgeInsets.all(context.getScreenWidth(4)),
              child: Row(
                children: [
                  Container(
                    width: context.getScreenWidth(11),
                    height: context.getScreenWidth(11),
                    decoration: BoxDecoration(
                      color: cardColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        (userName.isNotEmpty ? userName[0] : '?')
                            .toUpperCase(),
                        style: TextStyle(
                          fontSize: context.getFontSize(5),
                          fontWeight: FontWeight.w700,
                          color: cardColor,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: context.getScreenWidth(3)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: TextStyle(
                            fontSize: context.getFontSize(4.2),
                            fontWeight: FontWeight.w700,
                            color: context.colorPalette.textColor,
                          ),
                        ),
                        SizedBox(height: context.getScreenHeight(0.3)),
                        Text(
                          userPhone,
                          style: TextStyle(
                            fontSize: context.getFontSize(3.2),
                            color: context.colorPalette.subTitleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.getScreenWidth(2.5),
                          vertical: context.getScreenHeight(0.4),
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          req.status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: context.getFontSize(2.8),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      SizedBox(height: context.getScreenHeight(0.5)),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: context.colorPalette.subTitleColor,
                        size: context.getScreenWidth(5),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded detail ─────────────────────────────────────────────
          if (_expanded) ...[
            Divider(
              height: 1,
              color: context.colorPalette.boxColor,
              indent: context.getScreenWidth(4),
              endIndent: context.getScreenWidth(4),
            ),
            Padding(
              padding: EdgeInsets.all(context.getScreenWidth(4)),
              child: Column(
                children: [
                  if (req.oldDeviceName != null || req.oldDeviceId != null)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(context.getScreenWidth(3)),
                      decoration: BoxDecoration(
                        color: context.colorPalette.gold.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: context.colorPalette.gold.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Old device
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Old Device',
                                  style: TextStyle(
                                    fontSize: context.getFontSize(2.8),
                                    color: context.colorPalette.subTitleColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: context.getScreenHeight(0.3)),
                                Text(
                                  req.oldDeviceName ?? '—',
                                  style: TextStyle(
                                    fontSize: context.getFontSize(3.5),
                                    fontWeight: FontWeight.w700,
                                    color: context.colorPalette.textColor,
                                  ),
                                ),
                                SizedBox(height: context.getScreenHeight(0.2)),
                                Text(
                                  req.oldDeviceId ?? '—',
                                  style: TextStyle(
                                    fontSize: context.getFontSize(2.6),
                                    color: context.colorPalette.subTitleColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Arrow
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.getScreenWidth(2),
                            ),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              color: context.colorPalette.gold,
                              size: context.getScreenWidth(5),
                            ),
                          ),
                          // New device
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'New Device',
                                  style: TextStyle(
                                    fontSize: context.getFontSize(2.8),
                                    color: context.colorPalette.subTitleColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: context.getScreenHeight(0.3)),
                                Text(
                                  req.newDeviceName,
                                  style: TextStyle(
                                    fontSize: context.getFontSize(3.5),
                                    fontWeight: FontWeight.w700,
                                    color: context.colorPalette.textColor,
                                  ),
                                  textAlign: TextAlign.end,
                                ),
                                SizedBox(height: context.getScreenHeight(0.2)),
                                Text(
                                  req.newDeviceId,
                                  style: TextStyle(
                                    fontSize: context.getFontSize(2.6),
                                    color: context.colorPalette.subTitleColor,
                                  ),
                                  textAlign: TextAlign.end,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    _infoRow(
                      context,
                      Icons.phone_android_rounded,
                      'Device',
                      req.newDeviceName,
                    ),
                    SizedBox(height: context.getScreenHeight(0.8)),
                    _infoRow(
                      context,
                      Icons.disc_full_rounded,
                      'Device ID',
                      req.newDeviceId,
                    ),
                  ],
                  SizedBox(height: context.getScreenHeight(0.8)),
                  _infoRow(
                    context,
                    Icons.access_time_rounded,
                    'Requested',
                    DateFormat('dd MMM yyyy, hh:mm a')
                        .format(req.createdAt.toLocal()),
                  ),

                  if (req.rejectionReason != null &&
                      req.rejectionReason!.isNotEmpty) ...[
                    SizedBox(height: context.getScreenHeight(1)),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(context.getScreenWidth(3)),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.withOpacity(0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: Colors.red,
                            size: context.getScreenWidth(4),
                          ),
                          SizedBox(width: context.getScreenWidth(2)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Rejection Reason',
                                  style: TextStyle(
                                    fontSize: context.getFontSize(3),
                                    color: context.colorPalette.subTitleColor,
                                  ),
                                ),
                                SizedBox(height: context.getScreenHeight(0.3)),
                                Text(
                                  req.rejectionReason!,
                                  style: TextStyle(
                                    fontSize: context.getFontSize(3.5),
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (req.status == 'PENDING') ...[
                    SizedBox(height: context.getScreenHeight(1.5)),
                    Obx(() {
                      final isLoading =
                          widget.controller.actionState ==
                                  CurrentAppState.LOADING &&
                              widget.controller.actioningId == req.id;

                      return Row(
                        children: [
                          Expanded(
                            child: _actionButton(
                              context,
                              label: 'Approve',
                              icon: Icons.check_circle_rounded,
                              color: AppColors.primaryGold,
                              isLoading: isLoading,
                              onTap: () => _showApproveConfirm(context, req),
                            ),
                          ),
                          SizedBox(width: context.getScreenWidth(3)),
                          Expanded(
                            child: _actionButton(
                              context,
                              label: 'Reject',
                              icon: Icons.cancel_rounded,
                              color: Colors.red,
                              isLoading: isLoading,
                              onTap: () => _showRejectDialog(context, req),
                              outlined: true,
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showApproveConfirm(
      BuildContext context, HandsetChangeRequestModel req) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.colorPalette.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primaryGold,
                size: 20,
              ),
            ),
            SizedBox(width: context.getScreenWidth(2)),
            Text(
              'Approve Request',
              style: TextStyle(
                fontSize: context.getFontSize(4.5),
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        content: Text(
          'Allow ${req.userName ?? 'this user'} to change their handset to ${req.newDeviceName}?',
          style: TextStyle(
            fontSize: context.getFontSize(3.8),
            color: context.colorPalette.textColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.colorPalette.subTitleColor),
            ),
          ),
          Obx(
            () => ElevatedButton(
              onPressed: widget.controller.actionState ==
                      CurrentAppState.LOADING
                  ? null
                  : () async {
                      final ok = await widget.controller.approveRequest(
                        requestId: req.id,
                        context: context,
                      );
                      if (context.mounted) {
                        Get.back();
                        if (ok) {
                          _snack(context, 'Request approved', isError: false);
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: widget.controller.actionState == CurrentAppState.LOADING
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Approve',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(
      BuildContext context, HandsetChangeRequestModel req) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.colorPalette.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.cancel_rounded,
                color: Colors.red,
                size: 20,
              ),
            ),
            SizedBox(width: context.getScreenWidth(2)),
            Text(
              'Reject Request',
              style: TextStyle(
                fontSize: context.getFontSize(4.5),
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reject handset change request from ${req.userName ?? 'this user'}?',
              style: TextStyle(
                fontSize: context.getFontSize(3.8),
                color: context.colorPalette.textColor,
              ),
            ),
            SizedBox(height: context.getScreenHeight(1.5)),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter rejection reason...',
                hintStyle: TextStyle(
                  fontSize: context.getFontSize(3.5),
                  color: context.colorPalette.subTitleColor,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: context.colorPalette.subTitleColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: Colors.red, width: 1.5),
                ),
                contentPadding: EdgeInsets.all(context.getScreenWidth(3)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.colorPalette.subTitleColor),
            ),
          ),
          Obx(
            () => ElevatedButton(
              onPressed: widget.controller.actionState ==
                      CurrentAppState.LOADING
                  ? null
                  : () async {
                      if (reasonController.text.trim().isEmpty) {
                        _snack(context, 'Please enter a reason',
                            isError: true);
                        return;
                      }
                      final ok = await widget.controller.rejectRequest(
                        requestId: req.id,
                        rejectionReason: reasonController.text.trim(),
                        context: context,
                      );
                      if (context.mounted) {
                        Get.back();
                        if (ok) {
                          _snack(context, 'Request rejected', isError: false);
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: widget.controller.actionState == CurrentAppState.LOADING
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Reject',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
      BuildContext ctx, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: ctx.getScreenWidth(4),
          color: ctx.colorPalette.subTitleColor,
        ),
        SizedBox(width: ctx.getScreenWidth(2)),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: ctx.getScreenWidth(3.2),
            color: ctx.colorPalette.subTitleColor,
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: ctx.getScreenWidth(3.2),
              fontWeight: FontWeight.w600,
              color: ctx.colorPalette.textColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isLoading,
    bool outlined = false,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: context.getScreenHeight(1.2)),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : color,
          borderRadius: BorderRadius.circular(10),
          border: outlined ? Border.all(color: color) : null,
        ),
        child: isLoading
            ? Center(
                child: SizedBox(
                  width: context.getScreenWidth(4.5),
                  height: context.getScreenWidth(4.5),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: outlined ? color : Colors.white,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: outlined ? color : Colors.white,
                    size: context.getScreenWidth(4),
                  ),
                  SizedBox(width: context.getScreenWidth(1.5)),
                  Text(
                    label,
                    style: TextStyle(
                      color: outlined ? color : Colors.white,
                      fontSize: context.getFontSize(3.5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'APPROVED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      default:
        return const Color(0xFFD4AF37);
    }
  }

  void _snack(BuildContext context, String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : AppColors.primaryGold,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
