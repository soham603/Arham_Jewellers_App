import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/core/widgets/search_bar_widget.dart';
import 'package:ratnesh_gold_app/domain/entities/admin/adminAccessModel.dart';
import 'package:ratnesh_gold_app/presentation/controllers/admin/AdminUserController.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';

class ApproveUsersScreen extends StatefulWidget {
  const ApproveUsersScreen({super.key});

  @override
  State<ApproveUsersScreen> createState() => _ApproveUsersScreenState();
}

class _ApproveUsersScreenState extends State<ApproveUsersScreen> {
  late final AdminUserController controller;
  final ScrollController _scroll = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  static const _filters = ['PENDING', 'APPROVED', 'REJECTED'];

  // Store selected user info for display
  UserSearchModel? _selectedUser;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<AdminUserController>()
        ? Get.find<AdminUserController>()
        : Get.put(AdminUserController());
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
        controller.loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
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
          'Access Requests',
          style: TextStyle(
            fontSize: context.getResponsiveSize(5.5),
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        actions: [
          Obx(
            () => Padding(
              padding: EdgeInsets.only(right: context.getResponsiveSize(4)),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.getResponsiveSize(3),
                  vertical: context.getScreenHeight(0.5),
                ),
                decoration: BoxDecoration(
                  color: _filterColor(
                    controller.activeFilter,
                  ).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${controller.total} total',
                  style: TextStyle(
                    fontSize: context.getResponsiveSize(3.2),
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
          _searchBar(context),
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
                    context.getResponsiveSize(4),
                    context.getScreenHeight(1.5),
                    context.getResponsiveSize(4),
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
                      onApprove: (isRetailer) => _showDatePicker(context, list[index], isRetailer),
                      onReject: () => _confirmReject(context, list[index]),
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

  // ── Search Bar ────────────────────────────────────────────────────────────
  Widget _searchBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        context.getResponsiveSize(4),
        context.getScreenHeight(1),
        context.getResponsiveSize(4),
        context.getScreenHeight(1),
      ),
      child: Obx(() {
        // Show selected user chip if in USER mode and user selected
        if (controller.searchMode == SearchMode.USER && controller.selectedUserId != null && _selectedUser != null) {
          return Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.getResponsiveSize(3),
              vertical: context.getScreenHeight(0.8),
            ),
            decoration: BoxDecoration(
              color: context.colorPalette.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: context.colorPalette.primaryColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: context.getResponsiveSize(4),
                  backgroundColor: context.colorPalette.primaryColor,
                  child: Text(
                    _selectedUser!.name.isNotEmpty
                        ? _selectedUser!.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: context.getResponsiveSize(3.5),
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: context.getResponsiveSize(3)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedUser!.name,
                        style: TextStyle(
                          fontSize: context.getResponsiveSize(3.8),
                          fontWeight: FontWeight.w700,
                          color: context.colorPalette.textColor,
                        ),
                      ),
                      Text(
                        _selectedUser!.phoneNumber,
                        style: TextStyle(
                          fontSize: context.getResponsiveSize(3),
                          color: context.colorPalette.subTitleColor,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    _selectedUser = null;
                    controller.clearSearch();
                    _searchController.clear();
                  },
                  icon: Icon(
                    Icons.close_rounded,
                    color: context.colorPalette.subTitleColor,
                  ),
                ),
              ],
            ),
          );
        }

        // Search input field
        return Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _searchFocusNode.hasFocus
                      ? context.colorPalette.primaryColor
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SearchBarWidget(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: controller.onSearchTextChanged,
                      hintText: controller.searchMode == SearchMode.PHONE
                          ? 'Search by phone number...'
                          : 'Search by user name...',
                      outerBackgroundColor: Colors.transparent,
                      showShadow: false,
                    ),
                  ),
                  SizedBox(width: context.getResponsiveSize(1.5)),
                  // Mode toggle button (Circle)
                  GestureDetector(
                    onTap: () {
                      controller.toggleSearchMode();
                      _searchController.clear();
                      _selectedUser = null;
                    },
                    child: Container(
                      margin: EdgeInsets.only(right: context.getResponsiveSize(2)),
                      padding: EdgeInsets.all(context.getResponsiveSize(2.5)),
                      decoration: BoxDecoration(
                        color: context.colorPalette.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Obx(
                        () => Icon(
                          controller.searchMode == SearchMode.PHONE
                              ? Icons.phone_android_rounded
                              : Icons.person_rounded,
                          size: context.getResponsiveSize(5),
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Search results dropdown (only in USER mode)
            if (controller.searchMode == SearchMode.USER && 
                _searchController.text.trim().isNotEmpty)
              _searchResultsDropdown(context),
          ],
        );
      }),
    );
  }

  Widget _searchResultsDropdown(BuildContext context) {
    return Obx(() {
      final state = controller.searchState;
      final results = controller.searchResults;

      if (state == CurrentAppState.LOADING) {
        return Container(
          margin: EdgeInsets.only(top: context.getScreenHeight(1)),
          padding: EdgeInsets.all(context.getScreenHeight(1.5)),
          decoration: BoxDecoration(
            color: context.colorPalette.boxColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: SizedBox(
              width: context.getResponsiveSize(6),
              height: context.getResponsiveSize(6),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: context.colorPalette.primaryColor,
              ),
            ),
          ),
        );
      }

      if (state == CurrentAppState.SUCCESS && results.isEmpty) {
        return Container(
          margin: EdgeInsets.only(top: context.getScreenHeight(1)),
          padding: EdgeInsets.all(context.getScreenHeight(2)),
          decoration: BoxDecoration(
            color: context.colorPalette.boxColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              'No users found',
              style: TextStyle(
                fontSize: context.getResponsiveSize(3.5),
                color: context.colorPalette.subTitleColor,
              ),
            ),
          ),
        );
      }

      if (results.isNotEmpty) {
        return Container(
          margin: EdgeInsets.only(top: context.getScreenHeight(1)),
          constraints: BoxConstraints(
            maxHeight: context.getScreenHeight(40),
          ),
          decoration: BoxDecoration(
            color: context.colorPalette.boxColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.symmetric(vertical: context.getScreenHeight(0.5)),
            itemCount: results.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              color: context.colorPalette.subTitleColor.withValues(alpha: 0.2),
            ),
            itemBuilder: (context, index) {
              final user = results[index];
              return _SearchResultTile(
                user: user,
                onTap: () {
                  setState(() {
                    _selectedUser = user;
                  });
                  _searchController.clear();
                  _searchFocusNode.unfocus();
                  controller.selectUser(user);
                },
              );
            },
          ),
        );
      }

      return const SizedBox.shrink();
    });
  }

  // ── Filter Bar ────────────────────────────────────────────────────────────
  Widget _filterBar(BuildContext context) {
    return Obx(
      () => Container(
        padding: EdgeInsets.fromLTRB(
          context.getResponsiveSize(4),
          context.getScreenHeight(0.5),
          context.getResponsiveSize(4),
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
                    horizontal: context.getResponsiveSize(1),
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: context.getScreenHeight(0.8),
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? color : color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    f,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: context.getResponsiveSize(3),
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

  // ── Date Picker for Approve ───────────────────────────────────────────────
  Future<void> _showDatePicker(
    BuildContext context,
    AccessRequestModel req,
    bool isRetailer,
  ) async {
    final initialDate = req.approvedTill != null && req.status == 'APPROVED'
        ? req.approvedTill!
        : DateTime.now().add(const Duration(days: 30));
    
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      helpText: req.status == 'APPROVED' ? 'EXTEND ACCESS UNTIL' : 'GRANT ACCESS UNTIL',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: context.colorPalette.primaryColor,
            onPrimary: Colors.white,
            surface: context.colorPalette.backgroundColor,
            onSurface: context.colorPalette.textColor,
          ),
          datePickerTheme: DatePickerThemeData(
            headerHeadlineStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            headerHelpStyle: const TextStyle(fontSize: 13),
            dayStyle: const TextStyle(fontSize: 14),
            weekdayStyle: const TextStyle(fontSize: 12),
            dayShape: WidgetStateProperty.all(const CircleBorder()),
          ),
        ),
        child: child!,
      ),
    );

    if (picked == null || !context.mounted) return;

    _showApproveConfirm(context, req, picked, isRetailer);
  }

  void _showApproveConfirm(
    BuildContext context,
    AccessRequestModel req,
    DateTime date,
    bool initialRetailer,
  ) {
    bool isRetailer = initialRetailer;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: context.colorPalette.backgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: EdgeInsets.fromLTRB(
            context.getResponsiveSize(5),
            context.getResponsiveSize(4),
            context.getResponsiveSize(5),
            0,
          ),
          actionsPadding: EdgeInsets.fromLTRB(
            context.getResponsiveSize(2),
            0,
            context.getResponsiveSize(3),
            context.getScreenHeight(1),
          ),
          titlePadding: EdgeInsets.fromLTRB(
            context.getResponsiveSize(5),
            context.getResponsiveSize(4),
            context.getResponsiveSize(5),
            context.getScreenHeight(1),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primaryGold,
                  size: 16,
                ),
              ),
              SizedBox(width: context.getResponsiveSize(2)),
              Text(
                req.status == 'APPROVED' ? 'Extend Access' : 'Approve Access',
                style: TextStyle(
                  fontSize: context.getResponsiveSize(4),
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
                req.status == 'APPROVED'
                    ? 'Extend access for ${req.user?.name ?? 'this user'} until:'
                    : 'Grant access to ${req.user?.name ?? 'this user'} until:',
                style: TextStyle(
                  fontSize: context.getResponsiveSize(3.4),
                  color: context.colorPalette.textColor,
                ),
              ),
              SizedBox(height: context.getScreenHeight(0.6)),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.getResponsiveSize(2.5),
                  vertical: context.getScreenHeight(0.5),
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      color: AppColors.primaryGold,
                      size: 13,
                    ),
                    SizedBox(width: context.getResponsiveSize(1.5)),
                    Text(
                      DateFormat('dd MMM yyyy').format(date),
                      style: TextStyle(
                        fontSize: context.getResponsiveSize(3),
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryGold,
                      ),
                    ),
                  ],
                ),
              ),
              if (req.approvedTill != null && req.status == 'APPROVED')
                Padding(
                  padding: EdgeInsets.only(top: context.getScreenHeight(0.5)),
                  child: Text(
                    'Current access until: ${DateFormat('dd MMM yyyy').format(req.approvedTill!.toLocal())}',
                    style: TextStyle(
                      fontSize: context.getResponsiveSize(2.6),
                      color: context.colorPalette.subTitleColor,
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.symmetric(
                  horizontal: context.getResponsiveSize(3),
                  vertical: context.getScreenHeight(0.6),
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: context.colorPalette.subTitleColor,
                  fontSize: context.getResponsiveSize(3.2),
                ),
              ),
            ),
            Obx(
              () => ElevatedButton(
                onPressed: controller.actionState == CurrentAppState.LOADING
                    ? null
                    : () async {
                        await controller.approveRequest(
                          requestId: req.id,
                          approvedTillDate: date,
                          isRetailer: isRetailer,
                        );
                        if (dialogContext.mounted) {
                          Navigator.of(dialogContext).pop();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.symmetric(
                    horizontal: context.getResponsiveSize(3),
                    vertical: context.getScreenHeight(0.6),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: controller.actionState == CurrentAppState.LOADING
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        req.status == 'APPROVED' ? 'Extend' : 'Approve',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: context.getResponsiveSize(3.2),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmReject(BuildContext context, AccessRequestModel req) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.colorPalette.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.cancel_rounded,
                color: Colors.red,
                size: 20,
              ),
            ),
            SizedBox(width: context.getResponsiveSize(2)),
            Text(
              req.status == 'APPROVED' ? 'Revoke Access' : 'Reject Request',
              style: TextStyle(
                fontSize: context.getResponsiveSize(4.5),
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        content: Text(
          req.status == 'APPROVED'
              ? 'Are you sure you want to revoke access for ${req.user?.name ?? "this user"}? This will immediately remove their access.'
              : 'Are you sure you want to reject ${req.user?.name ?? "this user"}\'s access request?',
          style: TextStyle(
            fontSize: context.getResponsiveSize(3.8),
            color: context.colorPalette.textColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.colorPalette.subTitleColor),
            ),
          ),
          Obx(
            () => ElevatedButton(
              onPressed: controller.actionState == CurrentAppState.LOADING
                  ? null
                  : () async {
                      await controller.rejectRequest(
                        requestId: req.id,
                      );
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: controller.actionState == CurrentAppState.LOADING
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Confirm',
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

  // ── Footer (load more / end) ──────────────────────────────────────────────
  Widget _listFooter(BuildContext context) {
    return Obx(() {
      if (controller.state == CurrentAppState.LOADING &&
          controller.requests.isNotEmpty) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: context.getScreenHeight(2)),
          child: Center(
            child: SizedBox(
              width: context.getResponsiveSize(6),
              height: context.getResponsiveSize(6),
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
                fontSize: context.getResponsiveSize(3.2),
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
      padding: EdgeInsets.all(context.getResponsiveSize(4)),
      itemCount: 5,
      separatorBuilder: (_, _) =>
          SizedBox(height: context.getScreenHeight(1.5)),
      itemBuilder: (_, _) => _shimmerCard(context),
    );
  }

  Widget _shimmerCard(BuildContext context) {
    return Container(
      height: context.getScreenHeight(14),
      decoration: BoxDecoration(
        color: context.colorPalette.shimmerBaseColor,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsets.all(context.getResponsiveSize(4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: context.getResponsiveSize(10),
                height: context.getResponsiveSize(10),
                decoration: BoxDecoration(
                  color: context.colorPalette.shimmerHighLightColor,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: context.getResponsiveSize(3)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: context.getResponsiveSize(35),
                    height: context.getScreenHeight(1.5),
                    decoration: BoxDecoration(
                      color: context.colorPalette.shimmerHighLightColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(height: context.getScreenHeight(0.6)),
                  Container(
                    width: context.getResponsiveSize(25),
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
            size: context.getResponsiveSize(14),
            color: context.colorPalette.subTitleColor,
          ),
          SizedBox(height: context.getScreenHeight(1.5)),
          Text(
            'Failed to load',
            style: TextStyle(
              fontSize: context.getResponsiveSize(4.5),
              fontWeight: FontWeight.w600,
              color: context.colorPalette.textColor,
            ),
          ),
          SizedBox(height: context.getScreenHeight(0.5)),
          Text(
            controller.error,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: context.getResponsiveSize(3.2),
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
            size: context.getResponsiveSize(16),
            color: context.colorPalette.subTitleColor,
          ),
          SizedBox(height: context.getScreenHeight(1.5)),
          Text(
            controller.searchMode == SearchMode.PHONE && controller.searchQuery.isNotEmpty
                ? 'No ${controller.activeFilter.toLowerCase()} requests for this phone number'
                : controller.selectedUserId != null
                    ? 'No ${controller.activeFilter.toLowerCase()} requests for this user'
                    : 'No ${controller.activeFilter.toLowerCase()} requests',
            style: TextStyle(
              fontSize: context.getResponsiveSize(4.5),
              fontWeight: FontWeight.w600,
              color: context.colorPalette.textColor,
            ),
          ),
          if (controller.searchQuery.isNotEmpty || controller.selectedUserId != null)
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedUser = null;
                });
                controller.clearSearch();
                _searchController.clear();
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
        return AppColors.primaryGold;
    }
  }
}

// ── Request Card Widget ──────────────────────────────────────────────────────
class _RequestCard extends StatefulWidget {
  final AccessRequestModel request;
  final AdminUserController controller;
  final ValueChanged<bool> onApprove;
  final VoidCallback onReject;

  const _RequestCard({
    super.key,
    required this.request,
    required this.controller,
    required this.onApprove,
    required this.onReject,
  });

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  bool _expanded = false;
  late bool _isRetailer;
  final TextEditingController _newPasswordController = TextEditingController();
  bool _obscureNewPassword = true;

  @override
  void initState() {
    super.initState();
    _isRetailer = widget.request.isRetailer;
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    final user = req.user;
    final statusColor = _statusColor(req.status);
    final cardColor = AppColors.primaryGold;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: context.colorPalette.boxColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardColor.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
              padding: EdgeInsets.all(context.getResponsiveSize(4)),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: context.getResponsiveSize(11),
                    height: context.getResponsiveSize(11),
                    decoration: BoxDecoration(
                      color: cardColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        (user?.name?.isNotEmpty == true ? user!.name![0] : '?')
                            .toUpperCase(),
                        style: TextStyle(
                          fontSize: context.getResponsiveSize(5),
                          fontWeight: FontWeight.w700,
                          color: cardColor,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: context.getResponsiveSize(3)),

                  // Name + phone
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Unknown User',
                          style: TextStyle(
                            fontSize: context.getResponsiveSize(4.2),
                            fontWeight: FontWeight.w700,
                            color: context.colorPalette.textColor,
                          ),
                        ),
                        SizedBox(height: context.getScreenHeight(0.3)),
                        Text(
                          user?.phoneNumber ?? user?.email ?? '—',
                          style: TextStyle(
                            fontSize: context.getResponsiveSize(3.2),
                            color: context.colorPalette.subTitleColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status badge + expand icon
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (req.isRetailer)
                            Container(
                              margin: EdgeInsets.only(right: context.getResponsiveSize(1.5)),
                              padding: EdgeInsets.all(context.getResponsiveSize(1.5)),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.store_rounded,
                                color: const Color(0xFFD4AF37),
                                size: context.getResponsiveSize(3.2),
                              ),
                            ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.getResponsiveSize(2.5),
                              vertical: context.getScreenHeight(0.4),
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              req.status,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: context.getResponsiveSize(2.8),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: context.getScreenHeight(0.5)),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: context.colorPalette.subTitleColor,
                        size: context.getResponsiveSize(5),
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
              indent: context.getResponsiveSize(4),
              endIndent: context.getResponsiveSize(4),
            ),
            Padding(
              padding: EdgeInsets.all(context.getResponsiveSize(4)),
              child: Column(
                children: [
                  // Info rows
                  _infoRow(
                    context,
                    Icons.email_rounded,
                    'Email',
                    user?.email ?? '—',
                  ),
                  SizedBox(height: context.getScreenHeight(0.8)),
                  _infoRow(
                    context,
                    Icons.phone_rounded,
                    'Phone',
                    user?.phoneNumber ?? '—',
                  ),
                  SizedBox(height: context.getScreenHeight(0.8)),
                  _infoRow(
                    context,
                    Icons.access_time_rounded,
                    'Requested',
                    DateFormat(
                      'dd MMM yyyy, hh:mm a',
                    ).format(req.requestedAt.toLocal()),
                  ),

                  // Approved till (if applicable)
                  if (req.approvedTill != null) ...[
                    SizedBox(height: context.getScreenHeight(0.8)),
                    Container(
                      padding: EdgeInsets.all(context.getResponsiveSize(3)),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGold.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.primaryGold.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.verified_rounded,
                            color: AppColors.primaryGold,
                            size: 18,
                          ),
                          SizedBox(width: context.getResponsiveSize(2)),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Access approved until',
                                style: TextStyle(
                                  fontSize: context.getResponsiveSize(3),
                                  color: context.colorPalette.subTitleColor,
                                ),
                              ),
                              Text(
                                DateFormat(
                                  'dd MMMM yyyy',
                                ).format(req.approvedTill!.toLocal()),
                                style: TextStyle(
                                  fontSize: context.getResponsiveSize(3.8),
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryGold,
                                ),
                              ),
                              // Days remaining
                              Builder(
                                builder: (_) {
                                  final remaining = req.approvedTill!
                                      .difference(DateTime.now())
                                      .inDays;
                                  return Text(
                                    remaining > 0
                                        ? '$remaining days remaining'
                                        : 'Expired',
                                    style: TextStyle(
                                      fontSize: context.getResponsiveSize(2.8),
                                      color: remaining > 0
                                          ? AppColors.primaryGold
                                          : Colors.red,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  SizedBox(height: context.getScreenHeight(1.5)),

                  if (req.status == 'PENDING' || req.status == 'APPROVED')
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.getResponsiveSize(3),
                        vertical: context.getScreenHeight(0.5),
                      ),
                      decoration: BoxDecoration(
                        color: _isRetailer
                            ? const Color(0xFFD4AF37).withValues(alpha: 0.1)
                            : context.colorPalette.boxColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _isRetailer
                              ? const Color(0xFFD4AF37).withValues(alpha: 0.4)
                              : context.colorPalette.subTitleColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.store_rounded,
                            color: _isRetailer ? const Color(0xFFD4AF37) : context.colorPalette.subTitleColor,
                            size: context.getResponsiveSize(5),
                          ),
                          SizedBox(width: context.getResponsiveSize(3)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mark as Retailer',
                                  style: TextStyle(
                                    fontSize: context.getResponsiveSize(3.5),
                                    fontWeight: FontWeight.w600,
                                    color: context.colorPalette.textColor,
                                  ),
                                ),
                                Text(
                                  'Grant retailer privileges',
                                  style: TextStyle(
                                    fontSize: context.getResponsiveSize(2.8),
                                    color: context.colorPalette.subTitleColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Transform.scale(
                            scale: 0.7,
                            child: Switch(
                              value: _isRetailer,
                              onChanged: (val) {
                                if (req.status == 'APPROVED') {
                                  _confirmRetailerToggle(context, req, val);
                                } else {
                                  setState(() => _isRetailer = val);
                                }
                              },
                              activeThumbColor: const Color(0xFFD4AF37),
                              activeTrackColor: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (req.status == 'PENDING' || req.status == 'APPROVED')
                    SizedBox(height: context.getScreenHeight(1.5)),

                  if (req.status == 'APPROVED')
                    GestureDetector(
                      onTap: () => _showResetPasswordDialog(context, req),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.getResponsiveSize(3),
                          vertical: context.getScreenHeight(1),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGold.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.primaryGold.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lock_reset_rounded,
                              color: AppColors.primaryGold,
                              size: context.getResponsiveSize(5),
                            ),
                            SizedBox(width: context.getResponsiveSize(3)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Reset Password',
                                    style: TextStyle(
                                      fontSize: context.getResponsiveSize(3.5),
                                      fontWeight: FontWeight.w600,
                                      color: context.colorPalette.textColor,
                                    ),
                                  ),
                                  Text(
                                    'Set a new password for this user',
                                    style: TextStyle(
                                      fontSize: context.getResponsiveSize(2.8),
                                      color: context.colorPalette.subTitleColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: context.colorPalette.subTitleColor,
                              size: context.getResponsiveSize(5),
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (req.status == 'APPROVED')
                    SizedBox(height: context.getScreenHeight(1.5)),

                  Obx(() {
                    final isLoading = widget.controller.actionState == CurrentAppState.LOADING && 
                                     widget.controller.actioningId == req.id;

                    if (req.status == 'PENDING') {
                      return Row(
                        children: [
                          Expanded(
                            child: _actionButton(
                              context,
                              label: 'Approve',
                              icon: Icons.check_circle_rounded,
                              color: AppColors.primaryGold,
                              isLoading: isLoading,
                              onTap: () => widget.onApprove(_isRetailer),
                            ),
                          ),
                          SizedBox(width: context.getResponsiveSize(3)),
                          Expanded(
                            child: _actionButton(
                              context,
                              label: 'Reject',
                              icon: Icons.cancel_rounded,
                              color: Colors.red,
                              isLoading: isLoading,
                              onTap: widget.onReject,
                              outlined: true,
                            ),
                          ),
                        ],
                      );
                    }

                    if (req.status == 'APPROVED') {
                      return SizedBox(
                        width: double.infinity,
                        child: _actionButton(
                          context,
                          label: 'Extend Access',
                          icon: Icons.date_range_rounded,
                          color: context.colorPalette.primaryColor,
                          isLoading: isLoading,
                          onTap: () => widget.onApprove(req.isRetailer),
                        ),
                      );
                    }

                    if (req.status == 'REJECTED') {
                      return SizedBox(
                        width: double.infinity,
                        child: _actionButton(
                          context,
                          label: 'Approve Now',
                          icon: Icons.check_circle_rounded,
                          color: AppColors.primaryGold,
                          isLoading: isLoading,
                          onTap: () => widget.onApprove(req.isRetailer),
                        ),
                      );
                    }

                    return const SizedBox.shrink();
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext ctx, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: ctx.getResponsiveSize(4),
          color: ctx.colorPalette.subTitleColor,
        ),
        SizedBox(width: ctx.getResponsiveSize(2)),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: ctx.getResponsiveSize(3.2),
            color: ctx.colorPalette.subTitleColor,
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: ctx.getResponsiveSize(3.2),
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
                  width: context.getResponsiveSize(4.5),
                  height: context.getResponsiveSize(4.5),
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
                    size: context.getResponsiveSize(4),
                  ),
                  SizedBox(width: context.getResponsiveSize(1.5)),
                  Text(
                    label,
                    style: TextStyle(
                      color: outlined ? color : Colors.white,
                      fontSize: context.getResponsiveSize(3.5),
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
        return AppColors.primaryGold;
    }
  }

  void _confirmRetailerToggle(BuildContext context, AccessRequestModel req, bool newValue) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.colorPalette.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.store_rounded,
                color: Color(0xFFD4AF37),
                size: 16,
              ),
            ),
            SizedBox(width: context.getResponsiveSize(2)),
            Text(
              newValue ? 'Enable Retailer' : 'Disable Retailer',
              style: TextStyle(
                fontSize: context.getResponsiveSize(4),
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        content: Text(
          newValue
              ? 'Grant retailer privileges to ${req.user?.name ?? 'this user'}?'
              : 'Remove retailer privileges from ${req.user?.name ?? 'this user'}?',
          style: TextStyle(
            fontSize: context.getResponsiveSize(3.4),
            color: context.colorPalette.textColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.symmetric(
                horizontal: context.getResponsiveSize(3),
                vertical: context.getScreenHeight(0.6),
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: context.colorPalette.subTitleColor,
                fontSize: context.getResponsiveSize(3.2),
              ),
            ),
          ),
          Obx(() {
            final isLoading = widget.controller.actionState == CurrentAppState.LOADING &&
                              widget.controller.actioningId == req.id;
            return ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      Navigator.of(dialogContext).pop();
                      final ok = await widget.controller.updateRetailer(
                        requestId: req.id,
                        isRetailer: newValue,
                        currentApprovedTill: req.approvedTill!,
                      );
                      if (ok) {
                        setState(() => _isRetailer = newValue);
                      }
                    },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.symmetric(
                horizontal: context.getResponsiveSize(3),
                vertical: context.getScreenHeight(0.6),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: widget.controller.actionState == CurrentAppState.LOADING
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Confirm',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: context.getResponsiveSize(3.2),
                    ),
                  ),
            );
          }),
        ],
      ),
    );
  }

  void _showResetPasswordDialog(BuildContext context, AccessRequestModel req) {
    _newPasswordController.clear();
    _obscureNewPassword = true;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final hasPassword = _newPasswordController.text.trim().isNotEmpty;

          return AlertDialog(
            backgroundColor: context.colorPalette.backgroundColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            contentPadding: EdgeInsets.fromLTRB(
              context.getResponsiveSize(5),
              context.getResponsiveSize(4),
              context.getResponsiveSize(5),
              0,
            ),
            actionsPadding: EdgeInsets.fromLTRB(
              context.getResponsiveSize(2),
              0,
              context.getResponsiveSize(3),
              context.getScreenHeight(1),
            ),
            titlePadding: EdgeInsets.fromLTRB(
              context.getResponsiveSize(5),
              context.getResponsiveSize(4),
              context.getResponsiveSize(5),
              context.getScreenHeight(1),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    color: AppColors.primaryGold,
                    size: 16,
                  ),
                ),
                SizedBox(width: context.getResponsiveSize(2)),
                Text(
                  'Reset Password',
                  style: TextStyle(
                    fontSize: context.getResponsiveSize(4),
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
                  'Set a new password for ${req.user?.name ?? 'this user'}',
                  style: TextStyle(
                    fontSize: context.getResponsiveSize(3.4),
                    color: context.colorPalette.textColor,
                  ),
                ),
                SizedBox(height: context.getScreenHeight(1.5)),
                TextField(
                  controller: _newPasswordController,
                  obscureText: _obscureNewPassword,
                  onChanged: (_) => setDialogState(() {}),
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: context.getResponsiveSize(3.5),
                  ),
                  decoration: InputDecoration(
                    hintText: 'New Password',
                    hintStyle: TextStyle(color: context.colorPalette.subTitleColor),
                    prefixIcon: Icon(
                      Icons.lock_outline_rounded,
                      color: context.colorPalette.subTitleColor,
                      size: context.getResponsiveSize(4.5),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNewPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.grey.shade500,
                        size: context.getResponsiveSize(4.5),
                      ),
                      onPressed: () {
                        setDialogState(() {
                          _obscureNewPassword = !_obscureNewPassword;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: context.colorPalette.boxColor,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: context.getResponsiveSize(3),
                      vertical: context.getScreenHeight(1.2),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: context.colorPalette.subTitleColor.withValues(alpha: 0.2),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: context.colorPalette.subTitleColor.withValues(alpha: 0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.primaryGold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: context.getScreenHeight(2)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.symmetric(
                    horizontal: context.getResponsiveSize(3),
                    vertical: context.getScreenHeight(0.6),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: context.colorPalette.subTitleColor,
                    fontSize: context.getResponsiveSize(3.2),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: hasPassword
                    ? () {
                        Navigator.of(dialogContext).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Password reset for ${req.user?.name ?? 'user'}',
                            ),
                            backgroundColor: AppColors.primaryGold,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  disabledBackgroundColor: AppColors.primaryGold.withValues(alpha: 0.35),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.symmetric(
                    horizontal: context.getResponsiveSize(3),
                    vertical: context.getScreenHeight(0.6),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Reset Password',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: context.getResponsiveSize(3.2),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Search Result Tile ──────────────────────────────────────────────────────
class _SearchResultTile extends StatelessWidget {
  final UserSearchModel user;
  final VoidCallback onTap;

  const _SearchResultTile({
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(context.getResponsiveSize(3)),
        child: Row(
          children: [
            CircleAvatar(
              radius: context.getResponsiveSize(4.5),
              backgroundColor: context.colorPalette.primaryColor.withValues(alpha: 0.1),
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: context.getResponsiveSize(3.5),
                  fontWeight: FontWeight.w700,
                  color: context.colorPalette.primaryColor,
                ),
              ),
            ),
            SizedBox(width: context.getResponsiveSize(3)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: TextStyle(
                      fontSize: context.getResponsiveSize(3.8),
                      fontWeight: FontWeight.w600,
                      color: context.colorPalette.textColor,
                    ),
                  ),
                  Text(
                    user.phoneNumber,
                    style: TextStyle(
                      fontSize: context.getResponsiveSize(3),
                      color: context.colorPalette.subTitleColor,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.getResponsiveSize(2),
                vertical: context.getScreenHeight(0.3),
              ),
              decoration: BoxDecoration(
                color: _getStatusColor(user.accountStatus).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                user.accountStatus,
                style: TextStyle(
                  fontSize: context.getResponsiveSize(2.5),
                  fontWeight: FontWeight.w600,
                  color: _getStatusColor(user.accountStatus),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'APPROVED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      default:
        return AppColors.primaryGold;
    }
  }
}