import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:ratnesh_gold_app/domain/entities/admin/adminAccessModel.dart';
import 'package:ratnesh_gold_app/presentation/controllers/admin/AdminUserController.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';

import '../../../core/theme/app_colors.dart';

class ApproveUsersScreen extends StatefulWidget {
  const ApproveUsersScreen({super.key});

  @override
  State<ApproveUsersScreen> createState() => _ApproveUsersScreenState();
}

class _ApproveUsersScreenState extends State<ApproveUsersScreen> {
  final AdminUserController controller = Get.put(AdminUserController());
  final ScrollController _scroll = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  static const _filters = ['PENDING', 'APPROVED', 'REJECTED'];

  // Store selected user info for display
  UserSearchModel? _selectedUser;

  @override
  void initState() {
    super.initState();
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
      backgroundColor: context.colorPalette.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.colorPalette.backgroundColor,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Access Requests',
          style: TextStyle(
            fontSize: context.getScreenWidth(5.5),
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
                  color: _filterColor(
                    controller.activeFilter,
                  ).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${controller.total} total',
                  style: TextStyle(
                    fontSize: context.getScreenWidth(3.2),
                    fontWeight: FontWeight.w600,
                    color: _filterColor(controller.activeFilter),
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(context.getScreenHeight(14)),
          child: Column(
            children: [
              _searchBar(context),
              _filterBar(context),
            ],
          ),
        ),
      ),
      body: Obx(() {
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
              context.getScreenHeight(2),
              context.getScreenWidth(4),
              context.getScreenHeight(3),
            ),
            itemCount: list.length + 1,
            separatorBuilder: (_, _) =>
                SizedBox(height: context.getScreenHeight(1.5)),
            itemBuilder: (context, index) {
              if (index == list.length) return _listFooter(context);
              return _RequestCard(
                request: list[index],
                controller: controller,
                onApprove: () => _showDatePicker(context, list[index]),
                onReject: () => _confirmReject(context, list[index]),
              );
            },
          ),
        );
      }),
    );
  }

  // ── Search Bar ────────────────────────────────────────────────────────────
  Widget _searchBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        context.getScreenWidth(4),
        context.getScreenHeight(1),
        context.getScreenWidth(4),
        context.getScreenHeight(1),
      ),
      child: Obx(() {
        // Show selected user chip if in USER mode and user selected
        if (controller.searchMode == SearchMode.USER && controller.selectedUserId != null && _selectedUser != null) {
          return Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.getScreenWidth(3),
              vertical: context.getScreenHeight(0.8),
            ),
            decoration: BoxDecoration(
              color: context.colorPalette.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: context.colorPalette.primaryColor.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: context.getScreenWidth(4),
                  backgroundColor: context.colorPalette.primaryColor,
                  child: Text(
                    _selectedUser!.name.isNotEmpty
                        ? _selectedUser!.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: context.getScreenWidth(3.5),
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: context.getScreenWidth(3)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedUser!.name,
                        style: TextStyle(
                          fontSize: context.getScreenWidth(3.8),
                          fontWeight: FontWeight.w700,
                          color: context.colorPalette.textColor,
                        ),
                      ),
                      Text(
                        _selectedUser!.phoneNumber,
                        style: TextStyle(
                          fontSize: context.getScreenWidth(3),
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
                color: context.colorPalette.boxColor,
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
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: (value) {
                        controller.onSearchTextChanged(value);
                      },
                      decoration: InputDecoration(
                        hintText: controller.searchMode == SearchMode.PHONE
                            ? 'Search by phone number...'
                            : 'Search by user name...',
                        hintStyle: TextStyle(
                          fontSize: context.getScreenWidth(3.5),
                          color: context.colorPalette.subTitleColor,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: context.colorPalette.subTitleColor,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: context.getScreenWidth(4),
                          vertical: context.getScreenHeight(1.5),
                        ),
                      ),
                    ),
                  ),
                  // Mode toggle button (Circle)
                  GestureDetector(
                    onTap: () {
                      controller.toggleSearchMode();
                      _searchController.clear();
                      _selectedUser = null;
                    },
                    child: Container(
                      margin: EdgeInsets.only(right: context.getScreenWidth(2)),
                      padding: EdgeInsets.all(context.getScreenWidth(2.5)),
                      decoration: BoxDecoration(
                        color: controller.searchMode == SearchMode.USER
                            ? context.colorPalette.primaryColor
                            : context.colorPalette.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Obx(
                        () => Icon(
                          controller.searchMode == SearchMode.PHONE
                              ? Icons.phone_android_rounded
                              : Icons.person_rounded,
                          size: context.getScreenWidth(5),
                          color: controller.searchMode == SearchMode.USER
                              ? Colors.white
                              : context.colorPalette.primaryColor,
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
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
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
                fontSize: context.getScreenWidth(3.5),
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
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.symmetric(vertical: context.getScreenHeight(0.5)),
            itemCount: results.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: context.colorPalette.subTitleColor.withOpacity(0.2),
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
                      fontSize: context.getScreenWidth(3),
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
  ) async {
    final initialDate = req.approvedTill != null && req.status == 'APPROVED'
        ? req.approvedTill!
        : DateTime.now().add(const Duration(days: 30));
    
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: context.colorPalette.primaryColor,
            onPrimary: Colors.white,
            surface: context.colorPalette.backgroundColor,
            onSurface: context.colorPalette.textColor,
          ),
        ),
        child: child!,
      ),
    );

    if (picked == null || !context.mounted) return;

    _showApproveConfirm(context, req, picked);
  }

  void _showApproveConfirm(
    BuildContext context,
    AccessRequestModel req,
    DateTime date,
  ) {
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
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 20,
              ),
            ),
            SizedBox(width: context.getScreenWidth(2)),
            Text(
              req.status == 'APPROVED' ? 'Extend Access' : 'Approve Access',
              style: TextStyle(
                fontSize: context.getScreenWidth(4.5),
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
                fontSize: context.getScreenWidth(3.8),
                color: context.colorPalette.textColor,
              ),
            ),
            SizedBox(height: context.getScreenHeight(1)),
            Container(
              padding: EdgeInsets.all(context.getScreenWidth(3)),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    color: Colors.green,
                    size: 16,
                  ),
                  SizedBox(width: context.getScreenWidth(2)),
                  Text(
                    DateFormat('dd MMM yyyy').format(date),
                    style: TextStyle(
                      fontSize: context.getScreenWidth(3.5),
                      fontWeight: FontWeight.w700,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
            if (req.approvedTill != null && req.status == 'APPROVED')
              Padding(
                padding: EdgeInsets.only(top: context.getScreenHeight(1)),
                child: Text(
                  'Current access until: ${DateFormat('dd MMM yyyy').format(req.approvedTill!.toLocal())}',
                  style: TextStyle(
                    fontSize: context.getScreenWidth(3),
                    color: context.colorPalette.subTitleColor,
                  ),
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
              onPressed: controller.actionState == CurrentAppState.LOADING
                  ? null
                  : () async {
                      final ok = await controller.approveRequest(
                        requestId: req.id,
                        approvedTillDate: date,
                      );
                      if (context.mounted) {
                        Get.back();
                        _snack(
                          context,
                          ok ? 'Access ${req.status == 'APPROVED' ? 'extended' : 'approved'} ✅' : controller.error,
                          isError: !ok,
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
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
                  : Text(
                      req.status == 'APPROVED' ? 'Extend' : 'Approve',
                      style: const TextStyle(
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

  void _confirmReject(BuildContext context, AccessRequestModel req) {
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
              req.status == 'APPROVED' ? 'Revoke Access' : 'Reject Request',
              style: TextStyle(
                fontSize: context.getScreenWidth(4.5),
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
            fontSize: context.getScreenWidth(3.8),
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
              onPressed: controller.actionState == CurrentAppState.LOADING
                  ? null
                  : () async {
                      final ok = await controller.rejectRequest(
                        requestId: req.id,
                      );
                      if (context.mounted) {
                        Get.back();
                        _snack(
                          context,
                          ok
                              ? req.status == 'APPROVED'
                                  ? 'Access revoked'
                                  : 'Request rejected'
                              : controller.error,
                          isError: !ok,
                        );
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
                fontSize: context.getScreenWidth(3.2),
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
              fontSize: context.getScreenWidth(4.5),
              fontWeight: FontWeight.w600,
              color: context.colorPalette.textColor,
            ),
          ),
          SizedBox(height: context.getScreenHeight(0.5)),
          Text(
            controller.error,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: context.getScreenWidth(3.2),
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
            controller.searchMode == SearchMode.PHONE && controller.searchQuery.isNotEmpty
                ? 'No ${controller.activeFilter.toLowerCase()} requests for this phone number'
                : controller.selectedUserId != null
                    ? 'No ${controller.activeFilter.toLowerCase()} requests for this user'
                    : 'No ${controller.activeFilter.toLowerCase()} requests',
            style: TextStyle(
              fontSize: context.getScreenWidth(4.5),
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
        return const Color(0xFFD4AF37);
    }
  }

  void _snack(BuildContext context, String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ── Request Card Widget ──────────────────────────────────────────────────────
class _RequestCard extends StatefulWidget {
  final AccessRequestModel request;
  final AdminUserController controller;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _RequestCard({
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

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    final user = req.user;
    final statusColor = _statusColor(req.status);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: context.colorPalette.boxColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.25)),
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
                  // Avatar
                  Container(
                    width: context.getScreenWidth(11),
                    height: context.getScreenWidth(11),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        (user?.name?.isNotEmpty == true ? user!.name![0] : '?')
                            .toUpperCase(),
                        style: TextStyle(
                          fontSize: context.getScreenWidth(5),
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: context.getScreenWidth(3)),

                  // Name + phone
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Unknown User',
                          style: TextStyle(
                            fontSize: context.getScreenWidth(4.2),
                            fontWeight: FontWeight.w700,
                            color: context.colorPalette.textColor,
                          ),
                        ),
                        SizedBox(height: context.getScreenHeight(0.3)),
                        Text(
                          user?.phoneNumber ?? user?.email ?? '—',
                          style: TextStyle(
                            fontSize: context.getScreenWidth(3.2),
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
                            fontSize: context.getScreenWidth(2.8),
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
                      padding: EdgeInsets.all(context.getScreenWidth(3)),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.verified_rounded,
                            color: Colors.green,
                            size: 18,
                          ),
                          SizedBox(width: context.getScreenWidth(2)),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Access approved until',
                                style: TextStyle(
                                  fontSize: context.getScreenWidth(3),
                                  color: context.colorPalette.subTitleColor,
                                ),
                              ),
                              Text(
                                DateFormat(
                                  'dd MMMM yyyy',
                                ).format(req.approvedTill!.toLocal()),
                                style: TextStyle(
                                  fontSize: context.getScreenWidth(3.8),
                                  fontWeight: FontWeight.w700,
                                  color: Colors.green.shade700,
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
                                      fontSize: context.getScreenWidth(2.8),
                                      color: remaining > 0
                                          ? Colors.green
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
                              color: Colors.green,
                              isLoading: isLoading,
                              onTap: widget.onApprove,
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
                          onTap: widget.onApprove,
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
                          color: Colors.green,
                          isLoading: isLoading,
                          onTap: widget.onApprove,
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
                      fontSize: context.getScreenWidth(3.5),
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
        padding: EdgeInsets.all(context.getScreenWidth(3)),
        child: Row(
          children: [
            CircleAvatar(
              radius: context.getScreenWidth(4.5),
              backgroundColor: context.colorPalette.primaryColor.withOpacity(0.1),
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: context.getScreenWidth(3.5),
                  fontWeight: FontWeight.w700,
                  color: context.colorPalette.primaryColor,
                ),
              ),
            ),
            SizedBox(width: context.getScreenWidth(3)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: TextStyle(
                      fontSize: context.getScreenWidth(3.8),
                      fontWeight: FontWeight.w600,
                      color: context.colorPalette.textColor,
                    ),
                  ),
                  Text(
                    user.phoneNumber,
                    style: TextStyle(
                      fontSize: context.getScreenWidth(3),
                      color: context.colorPalette.subTitleColor,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.getScreenWidth(2),
                vertical: context.getScreenHeight(0.3),
              ),
              decoration: BoxDecoration(
                color: _getStatusColor(user.accountStatus).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                user.accountStatus,
                style: TextStyle(
                  fontSize: context.getScreenWidth(2.5),
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
        return const Color(0xFFD4AF37);
    }
  }
}