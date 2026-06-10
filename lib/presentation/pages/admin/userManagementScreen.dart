import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/core/widgets/search_bar_widget.dart';
import 'package:ratnesh_gold_app/presentation/controllers/admin/AdminUserManagementController.dart';
import 'package:ratnesh_gold_app/presentation/controllers/admin/AdminUserController.dart';
import 'package:ratnesh_gold_app/presentation/controllers/AuthController.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  late final AdminUserManagementController controller;
  final ScrollController _scroll = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  static const _roleFilters = ['ALL', 'ADMIN', 'USER'];

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<AdminUserManagementController>()
        ? Get.find<AdminUserManagementController>()
        : Get.put(AdminUserManagementController());
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
          'User Management',
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
                  color: AppColors.primaryGold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${controller.total} total',
                  style: TextStyle(
                    fontSize: context.getResponsiveSize(3.2),
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGold,
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
              final list = controller.filteredUsers;

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
                      SizedBox(height: context.getScreenHeight(1.2)),
                  itemBuilder: (context, index) {
                    if (index == list.length) return _listFooter(context);
                    return _UserCard(
                      key: ValueKey(list[index].id),
                      user: list[index],
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

  // ── Search Bar ────────────────────────────────────────────────────────────
  Widget _searchBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.getResponsiveSize(4),
        context.getScreenHeight(1),
        context.getResponsiveSize(4),
        context.getScreenHeight(0.5),
      ),
      child: Column(
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
                    onChanged: controller.onSearchChanged,
                    hintText: _searchHintText(),
                    outerBackgroundColor: Colors.transparent,
                    showShadow: false,
                  ),
                ),
                SizedBox(width: context.getResponsiveSize(1.5)),
                GestureDetector(
                  onTap: () {
                    controller.toggleSearchMode();
                    _searchController.clear();
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
                        _searchModeIcon(controller.searchMode),
                        size: context.getResponsiveSize(5),
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: context.getScreenHeight(0.5)),
          Obx(
            () => Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Search by: ${controller.searchMode.name}',
                style: TextStyle(
                  fontSize: context.getResponsiveSize(2.8),
                  color: context.colorPalette.subTitleColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _searchHintText() {
    switch (controller.searchMode) {
      case UserSearchMode.NAME:
        return 'Search by name...';
      case UserSearchMode.EMAIL:
        return 'Search by email...';
      case UserSearchMode.PHONE:
        return 'Search by phone number...';
    }
  }

  IconData _searchModeIcon(UserSearchMode mode) {
    switch (mode) {
      case UserSearchMode.NAME:
        return Icons.person_rounded;
      case UserSearchMode.EMAIL:
        return Icons.email_rounded;
      case UserSearchMode.PHONE:
        return Icons.phone_android_rounded;
    }
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
          children: _roleFilters.map((f) {
            final isActive = controller.activeFilter == f;
            final color = _roleColor(f);
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

  Color _roleColor(String role) {
    switch (role) {
      case 'ADMIN':
        return AppColors.primaryGold;
      case 'USER':
        return const Color(0xFF2D9D59);
      default:
        return context.colorPalette.subTitleColor;
    }
  }

  // ── List Footer ───────────────────────────────────────────────────────────
  Widget _listFooter(BuildContext context) {
    return Obx(() {
      final isLoading = controller.state == CurrentAppState.LOADING &&
          controller.users.isNotEmpty;

      if (isLoading) {
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
              'All users loaded',
              style: TextStyle(
                fontSize: context.getResponsiveSize(3.2),
                color: context.colorPalette.subTitleColor,
              ),
            ),
          ),
        );
      }

      return Padding(
        padding: EdgeInsets.symmetric(
          vertical: context.getScreenHeight(1.5),
          horizontal: context.getResponsiveSize(12),
        ),
        child: ElevatedButton(
          onPressed: controller.loadMore,
          style: ElevatedButton.styleFrom(
            backgroundColor: context.colorPalette.primaryColor,
            padding: EdgeInsets.symmetric(vertical: context.getScreenHeight(1.2)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: Text(
            'Load More',
            style: TextStyle(
              fontSize: context.getResponsiveSize(3.8),
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      );
    });
  }

  // ── Shimmer ───────────────────────────────────────────────────────────────
  Widget _shimmerList(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.all(context.getResponsiveSize(4)),
      itemCount: 5,
      separatorBuilder: (_, _) =>
          SizedBox(height: context.getScreenHeight(1.2)),
      itemBuilder: (_, _) => _shimmerCard(context),
    );
  }

  Widget _shimmerCard(BuildContext context) {
    return Container(
      height: context.getScreenHeight(10),
      decoration: BoxDecoration(
        color: context.colorPalette.shimmerBaseColor,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsets.all(context.getResponsiveSize(4)),
      child: Row(
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
            Icons.people_outline_rounded,
            size: context.getResponsiveSize(16),
            color: context.colorPalette.subTitleColor,
          ),
          SizedBox(height: context.getScreenHeight(1.5)),
          Text(
            controller.searchQuery.isNotEmpty
                ? 'No users found'
                : 'No users available',
            style: TextStyle(
              fontSize: context.getResponsiveSize(4.5),
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
}

// ── User Card ───────────────────────────────────────────────────────────────
class _UserCard extends StatelessWidget {
  final UserSearchModel user;
  final AdminUserManagementController controller;

  const _UserCard({
    super.key,
    required this.user,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = user.userActivationStatus == 'ACTIVE';

    return GestureDetector(
      onTap: () => _showUserDetailSheet(context),
      child: Container(
        padding: EdgeInsets.all(context.getResponsiveSize(4)),
        decoration: BoxDecoration(
          color: context.colorPalette.boxColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? AppColors.primaryGold.withValues(alpha: 0.2)
                : Colors.red.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: context.getResponsiveSize(11),
              height: context.getResponsiveSize(11),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primaryGold.withValues(alpha: 0.12)
                    : Colors.red.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  (user.name.isNotEmpty ? user.name[0] : '?').toUpperCase(),
                  style: TextStyle(
                    fontSize: context.getResponsiveSize(5),
                    fontWeight: FontWeight.w700,
                    color: isActive ? AppColors.primaryGold : Colors.red,
                  ),
                ),
              ),
            ),
            SizedBox(width: context.getResponsiveSize(3)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: context.getResponsiveSize(4),
                            fontWeight: FontWeight.w700,
                            color: context.colorPalette.textColor,
                          ),
                        ),
                      ),
                      if (user.role == 'ADMIN' || user.role == 'SUPERADMIN') ...[
                        SizedBox(width: context.getResponsiveSize(1.5)),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.getResponsiveSize(1.5),
                            vertical: context.getScreenHeight(0.2),
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGold.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            user.role,
                            style: TextStyle(
                              fontSize: context.getResponsiveSize(2.2),
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryGold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: context.getScreenHeight(0.3)),
                  Text(
                    user.phoneNumber,
                    style: TextStyle(
                      fontSize: context.getResponsiveSize(3.2),
                      color: context.colorPalette.subTitleColor,
                    ),
                  ),
                  if (user.companyName != null &&
                      user.companyName!.isNotEmpty) ...[
                    SizedBox(height: context.getScreenHeight(0.2)),
                    Text(
                      user.companyName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.getResponsiveSize(2.8),
                        color: context.colorPalette.subTitleColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.getResponsiveSize(2.5),
                    vertical: context.getScreenHeight(0.4),
                  ),
                  decoration: BoxDecoration(
                    color: (isActive ? Colors.green : Colors.red)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isActive ? 'ACTIVE' : 'INACTIVE',
                    style: TextStyle(
                      color: isActive ? Colors.green : Colors.red,
                      fontSize: context.getResponsiveSize(2.5),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (user.forgotPasswordStatus == 'PENDING') ...[
                  SizedBox(height: context.getScreenHeight(0.5)),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.getResponsiveSize(2.5),
                      vertical: context.getScreenHeight(0.4),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'PASSWORD PENDING',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: context.getResponsiveSize(2),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
                SizedBox(height: context.getScreenHeight(0.5)),
                Icon(
                  Icons.chevron_right_rounded,
                  color: context.colorPalette.subTitleColor,
                  size: context.getResponsiveSize(5),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Detail Sheet ──────────────────────────────────────────────────────────
  void _showUserDetailSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserDetailSheet(
        user: user,
        controller: controller,
      ),
    );
  }
}

// ── Detail Bottom Sheet ─────────────────────────────────────────────────────
class _UserDetailSheet extends StatefulWidget {
  final UserSearchModel user;
  final AdminUserManagementController controller;

  const _UserDetailSheet({
    required this.user,
    required this.controller,
  });

  @override
  State<_UserDetailSheet> createState() => _UserDetailSheetState();
}

class _UserDetailSheetState extends State<_UserDetailSheet> {
  late bool _isRetailer;
  late bool _isStaff;
  final _newPasswordController = TextEditingController();
  bool _obscureNewPassword = true;

  @override
  void initState() {
    super.initState();
    _isRetailer = widget.user.isRetailer ?? false;
    _isStaff = widget.user.role == 'ADMIN' || widget.user.role == 'SUPERADMIN';
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final isActive = user.userActivationStatus == 'ACTIVE';
    final accessExpired = user.enableAccessTill != null &&
        user.enableAccessTill!.isBefore(DateTime.now());

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.colorPalette.backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              _handleBar(context),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(
                    context.getResponsiveSize(5),
                    0,
                    context.getResponsiveSize(5),
                    context.getScreenHeight(3),
                  ),
                  children: [
                    _header(context, user, isActive),
                    SizedBox(height: context.getScreenHeight(2.5)),
                    _sectionTitle(context, 'Profile Information'),
                    _detailCard(
                      context,
                      children: [
                        _detailRow(context, Icons.person_outline, 'Name', user.name),
                        _divider(context),
                        _detailRow(context, Icons.email_outlined, 'Email', user.email),
                        _divider(context),
                        _detailRow(context, Icons.phone_outlined, 'Phone', user.phoneNumber),
                        if (user.companyName != null && user.companyName!.isNotEmpty) ...[
                          _divider(context),
                          _detailRow(context, Icons.business_outlined, 'Company', user.companyName!),
                        ],
                        if (user.area != null && user.area!.isNotEmpty) ...[
                          _divider(context),
                          _detailRow(context, Icons.location_on_outlined, 'Area', user.area!),
                        ],
                        if (user.city != null && user.city!.isNotEmpty) ...[
                          _divider(context),
                          _detailRow(context, Icons.location_city_outlined, 'City', user.city!),
                        ],
                      ],
                    ),
                    SizedBox(height: context.getScreenHeight(2)),
                    _sectionTitle(context, 'Account Details'),
                    _detailCard(
                      context,
                      children: [
                        _detailRow(context, Icons.badge_outlined, 'Role', user.role),
                        _divider(context),
                        _detailRow(
                          context,
                          Icons.verified_user_outlined,
                          'Account Status',
                          user.accountStatus,
                        ),
                        _divider(context),
                        _detailRow(
                          context,
                          Icons.toggle_on_outlined,
                          'Activation',
                          user.userActivationStatus,
                        ),
                        _divider(context),
                        _detailRow(
                          context,
                          Icons.access_time_outlined,
                          'Joined',
                          DateFormat('dd MMM yyyy').format(user.createdAt),
                        ),
                        if (user.enableAccessTill != null) ...[
                          _divider(context),
                          _detailRow(
                            context,
                            Icons.calendar_today_outlined,
                            'Access Until',
                            DateFormat('dd MMM yyyy').format(user.enableAccessTill!),
                            valueColor: accessExpired ? Colors.red : null,
                          ),
                        ],
                        if (user.accessRequests != null && user.accessRequests!.isNotEmpty) ...[
                          _divider(context),
                          _detailRow(
                            context,
                            Icons.history_outlined,
                            'Access Requests',
                            '${user.accessRequests!.length} total',
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: context.getScreenHeight(2)),
                    _sectionTitle(context, 'Device Information'),
                    _detailCard(
                      context,
                      children: [
                        _detailRow(
                          context,
                          Icons.phone_android_outlined,
                          'Device',
                          user.deviceName ?? 'Not registered',
                        ),
                        if (user.deviceId != null && user.deviceId!.isNotEmpty) ...[
                          _divider(context),
                          _detailRow(
                            context,
                            Icons.disc_full_outlined,
                            'Device ID',
                            user.deviceId!,
                            maxLines: 2,
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: context.getScreenHeight(2.5)),
                    _sectionTitle(context, 'Actions'),
                    _actionCard(context, isActive),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _handleBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: context.getScreenHeight(1)),
      child: Column(
        children: [
          Container(
            width: context.getResponsiveSize(10),
            height: context.getScreenHeight(0.5),
            decoration: BoxDecoration(
              color: context.colorPalette.subTitleColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, UserSearchModel user, bool isActive) {
    return Column(
      children: [
        _handleBar(context),
        SizedBox(height: context.getScreenHeight(2)),
        Container(
          width: context.getResponsiveSize(18),
          height: context.getResponsiveSize(18),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primaryGold.withValues(alpha: 0.12)
                : Colors.red.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              (user.name.isNotEmpty ? user.name[0] : '?').toUpperCase(),
              style: TextStyle(
                fontSize: context.getResponsiveSize(8),
                fontWeight: FontWeight.w700,
                color: isActive ? AppColors.primaryGold : Colors.red,
              ),
            ),
          ),
        ),
        SizedBox(height: context.getScreenHeight(1)),
        Text(
          user.name,
          style: TextStyle(
            fontSize: context.getResponsiveSize(5.5),
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        SizedBox(height: context.getScreenHeight(0.3)),
        Text(
          user.email,
          style: TextStyle(
            fontSize: context.getResponsiveSize(3.5),
            color: context.colorPalette.subTitleColor,
          ),
        ),
        SizedBox(height: context.getScreenHeight(1)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _badge(
              context,
              label: user.role,
              color: _roleBadgeColor(user.role),
            ),
            SizedBox(width: context.getResponsiveSize(2)),
            _badge(
              context,
              label: isActive ? 'Active' : 'Inactive',
              color: isActive ? Colors.green : Colors.red,
            ),
            if (user.isRetailer == true) ...[
              SizedBox(width: context.getResponsiveSize(2)),
              _badge(
                context,
                label: 'Retailer',
                color: const Color(0xFFD4AF37),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _badge(BuildContext context, {required String label, required Color color}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.getResponsiveSize(2.5),
        vertical: context.getScreenHeight(0.4),
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: context.getResponsiveSize(2.5),
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.getScreenHeight(1)),
      child: Text(
        title,
        style: TextStyle(
          fontSize: context.getResponsiveSize(4),
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Widget _detailCard(BuildContext context, {required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: context.getResponsiveSize(4),
        vertical: context.getScreenHeight(1.5),
      ),
      decoration: BoxDecoration(
        color: context.colorPalette.boxColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: context.colorPalette.subTitleColor.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _detailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
    int maxLines = 1,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.getScreenHeight(0.5)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: context.getResponsiveSize(4.2),
            color: context.colorPalette.subTitleColor,
          ),
          SizedBox(width: context.getResponsiveSize(2.5)),
          SizedBox(
            width: context.getResponsiveSize(28),
            child: Text(
              label,
              style: TextStyle(
                fontSize: context.getResponsiveSize(3.2),
                color: context.colorPalette.subTitleColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: context.getResponsiveSize(3.5),
                fontWeight: FontWeight.w600,
                color: valueColor ?? context.colorPalette.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(BuildContext context) {
    return Divider(
      height: 1,
      color: context.colorPalette.subTitleColor.withValues(alpha: 0.1),
    );
  }

  Color _roleBadgeColor(String? role) {
    switch (role) {
      case 'SUPERADMIN':
        return Colors.purple;
      case 'ADMIN':
        return AppColors.primaryGold;
      default:
        return const Color(0xFF2D9D59);
    }
  }

  // ── Action Card ───────────────────────────────────────────────────────────
  Widget _actionCard(BuildContext context, bool isActive) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: context.getResponsiveSize(4),
        vertical: context.getScreenHeight(1.5),
      ),
      decoration: BoxDecoration(
        color: context.colorPalette.boxColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: context.colorPalette.subTitleColor.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        children: [
          // Staff Toggle — visible only to SUPERADMIN
          if (Get.find<AuthController>().user?.role == 'SUPERADMIN') ...[
            _toggleRow(
              context,
              icon: Icons.admin_panel_settings_outlined,
              title: 'Staff Access',
              subtitle: 'Grant admin privileges',
              value: _isStaff,
              activeColor: AppColors.primaryGold,
              isLoading: widget.controller.actionState == CurrentAppState.LOADING &&
                  widget.controller.actioningId == widget.user.id,
              onChanged: (val) => _confirmStaffToggle(context, val),
            ),
            _sheetDivider(context),
          ],

          // Retailer Toggle
          _toggleRow(
            context,
            icon: Icons.store_outlined,
            title: 'Retailer Status',
            subtitle: 'Mark as retailer',
            value: _isRetailer,
            activeColor: const Color(0xFFD4AF37),
            isLoading: widget.controller.actionState == CurrentAppState.LOADING &&
                widget.controller.actioningId == widget.user.id,
            onChanged: (val) => _confirmRetailerToggle(context, val),
          ),
          _sheetDivider(context),

          // Deactivate / Reactivate
          _actionRow(
            context,
            icon: isActive
                ? Icons.block_outlined
                : Icons.check_circle_outline_rounded,
            title: isActive ? 'Deactivate User' : 'Reactivate User',
            subtitle: isActive
                ? 'Disable this user account'
                : 'Re-enable this user account',
            color: isActive ? Colors.red : Colors.green,
            isLoading: widget.controller.actionState == CurrentAppState.LOADING &&
                widget.controller.actioningId == widget.user.id,
            onTap: isActive
                ? () => _confirmDeactivate(context)
                : () => _confirmReactivate(context),
          ),

          // Reset Password — visible only when forgotPasswordStatus is PENDING
          if (widget.user.forgotPasswordStatus == 'PENDING') ...[
            _sheetDivider(context),
            _actionRow(
              context,
              icon: Icons.lock_reset_rounded,
              title: 'Reset Password',
              subtitle: 'Set a new password for this user',
              color: Colors.orange,
              isLoading: widget.controller.actionState == CurrentAppState.LOADING &&
                  widget.controller.actioningId == widget.user.id,
              onTap: () => _showResetPasswordDialog(context),
            ),
          ],
        ],
      ),
    );
  }

  Widget _toggleRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Color activeColor,
    required bool isLoading,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.getScreenHeight(0.8)),
      child: Row(
        children: [
          Container(
            width: context.getResponsiveSize(10),
            height: context.getResponsiveSize(10),
            decoration: BoxDecoration(
              color: value ? activeColor.withValues(alpha: 0.12) : context.colorPalette.boxColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: context.getResponsiveSize(5),
              color: value ? activeColor : context.colorPalette.subTitleColor,
            ),
          ),
          SizedBox(width: context.getResponsiveSize(3)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: context.getResponsiveSize(3.8),
                    fontWeight: FontWeight.w600,
                    color: context.colorPalette.textColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: context.getResponsiveSize(2.8),
                    color: context.colorPalette.subTitleColor,
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            SizedBox(
              width: context.getResponsiveSize(5),
              height: context.getResponsiveSize(5),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: activeColor,
              ),
            )
          else
            Transform.scale(
              scale: 0.7,
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: activeColor,
                activeTrackColor: activeColor.withValues(alpha: 0.3),
              ),
            ),
        ],
      ),
    );
  }

  Widget _actionRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.getScreenHeight(0.8)),
        child: Row(
          children: [
            Container(
              width: context.getResponsiveSize(10),
              height: context.getResponsiveSize(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: context.getResponsiveSize(5),
                color: color,
              ),
            ),
            SizedBox(width: context.getResponsiveSize(3)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: context.getResponsiveSize(3.8),
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: context.getResponsiveSize(2.8),
                      color: context.colorPalette.subTitleColor,
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading)
              SizedBox(
                width: context.getResponsiveSize(5),
                height: context.getResponsiveSize(5),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: color,
                ),
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                color: context.colorPalette.subTitleColor,
                size: context.getResponsiveSize(5),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sheetDivider(BuildContext context) {
    return Divider(
      height: 1,
      color: context.colorPalette.subTitleColor.withValues(alpha: 0.1),
    );
  }

  // ── Confirmation Dialogs ──────────────────────────────────────────────────
  void _confirmDeactivate(BuildContext context) {
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
              child: const Icon(Icons.block_rounded, color: Colors.red, size: 20),
            ),
            SizedBox(width: context.getResponsiveSize(2)),
            Text(
              'Deactivate User',
              style: TextStyle(
                fontSize: context.getResponsiveSize(4.5),
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to deactivate ${widget.user.name}? They will no longer be able to access the app.',
          style: TextStyle(
            fontSize: context.getResponsiveSize(3.8),
            color: context.colorPalette.textColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Cancel', style: TextStyle(color: context.colorPalette.subTitleColor)),
          ),
          Obx(
            () => ElevatedButton(
              onPressed: widget.controller.actionState == CurrentAppState.LOADING
                  ? null
                  : () async {
                      Navigator.of(dialogContext).pop();
                      await widget.controller.deactivateUser(widget.user.id);
                      if (context.mounted) Navigator.of(context).pop();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: widget.controller.actionState == CurrentAppState.LOADING
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Deactivate', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmReactivate(BuildContext context) {
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
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
            ),
            SizedBox(width: context.getResponsiveSize(2)),
            Text(
              'Reactivate User',
              style: TextStyle(
                fontSize: context.getResponsiveSize(4.5),
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        content: Text(
          'Reactivate ${widget.user.name}\'s account? They will regain access to the app.',
          style: TextStyle(
            fontSize: context.getResponsiveSize(3.8),
            color: context.colorPalette.textColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Cancel', style: TextStyle(color: context.colorPalette.subTitleColor)),
          ),
          Obx(
            () => ElevatedButton(
              onPressed: widget.controller.actionState == CurrentAppState.LOADING
                  ? null
                  : () async {
                      Navigator.of(dialogContext).pop();
                      await widget.controller.reactivateUser(widget.user.id);
                      if (context.mounted) Navigator.of(context).pop();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: widget.controller.actionState == CurrentAppState.LOADING
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Reactivate', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmStaffToggle(BuildContext context, bool newValue) {
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
                color: AppColors.primaryGold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.primaryGold, size: 20),
            ),
            SizedBox(width: context.getResponsiveSize(2)),
            Text(
              newValue ? 'Grant Staff Access' : 'Remove Staff Access',
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
              ? 'Grant staff privileges to ${widget.user.name}?'
              : 'Remove staff privileges from ${widget.user.name}?',
          style: TextStyle(
            fontSize: context.getResponsiveSize(3.8),
            color: context.colorPalette.textColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Cancel', style: TextStyle(color: context.colorPalette.subTitleColor)),
          ),
          Obx(
            () => ElevatedButton(
              onPressed: widget.controller.actionState == CurrentAppState.LOADING
                  ? null
                  : () async {
                      Navigator.of(dialogContext).pop();
                      final ok = await widget.controller.toggleStaff(
                        userId: widget.user.id,
                        isStaff: newValue,
                      );
                      if (ok) setState(() => _isStaff = newValue);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: widget.controller.actionState == CurrentAppState.LOADING
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Confirm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmRetailerToggle(BuildContext context, bool newValue) {
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
                color: const Color(0xFFD4AF37).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.store_rounded, color: Color(0xFFD4AF37), size: 20),
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
              ? 'Grant retailer privileges to ${widget.user.name}?'
              : 'Remove retailer privileges from ${widget.user.name}?',
          style: TextStyle(
            fontSize: context.getResponsiveSize(3.8),
            color: context.colorPalette.textColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Cancel', style: TextStyle(color: context.colorPalette.subTitleColor)),
          ),
          Obx(
            () => ElevatedButton(
              onPressed: widget.controller.actionState == CurrentAppState.LOADING
                  ? null
                  : () async {
                      Navigator.of(dialogContext).pop();
                      final ok = await widget.controller.toggleRetailer(
                        userId: widget.user.id,
                        isRetailer: newValue,
                      );
                      if (ok) setState(() => _isRetailer = newValue);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: widget.controller.actionState == CurrentAppState.LOADING
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Confirm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  void _showResetPasswordDialog(BuildContext context) {
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
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    color: Colors.orange,
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
                  'Set a new password for ${widget.user.name}',
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
                        color: Colors.orange,
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
              Obx(
                () => ElevatedButton(
                  onPressed: hasPassword && widget.controller.actionState != CurrentAppState.LOADING
                      ? () async {
                          final password = _newPasswordController.text.trim();
                          Navigator.of(dialogContext).pop();
                          await widget.controller.adminResetPassword(
                            userId: widget.user.id,
                            newPassword: password,
                          );
                          if (context.mounted) Navigator.of(context).pop();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    disabledBackgroundColor: Colors.orange.withValues(alpha: 0.35),
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
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'Reset Password',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: context.getResponsiveSize(3.2),
                          ),
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
