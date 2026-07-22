import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/core/widgets/search_bar_widget.dart';
import 'package:ratnesh_gold_app/core/widgets/stat_card.dart';
import 'package:ratnesh_gold_app/domain/entities/craftsmanModel.dart';
import 'package:ratnesh_gold_app/presentation/controllers/admin/AdminCraftsmanController.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:ratnesh_gold_app/utils/ToastUtil.dart';

enum CraftsmanFilter { active, inactive, deleted }

class CraftsmanManagerScreen extends StatefulWidget {
  const CraftsmanManagerScreen({super.key});

  @override
  State<CraftsmanManagerScreen> createState() => _CraftsmanManagerScreenState();
}

class _CraftsmanManagerScreenState extends State<CraftsmanManagerScreen>
    with SingleTickerProviderStateMixin {
  final AdminCraftsmanController ctrl = Get.isRegistered<AdminCraftsmanController>()
      ? Get.find<AdminCraftsmanController>()
      : Get.put(AdminCraftsmanController(), permanent: true);

  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    ctrl.update();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ctrl.search(value);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.pageBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Manage Karigar',
          style: TextStyle(
            fontSize: context.getResponsiveSize(5),
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.upload_file_rounded, color: AppColors.primaryGold),
            onPressed: () => _showImportFlow(context),
          ),
        ],
      ),
      body: Obx(() {
        final allCraftsmen = ctrl.filteredCraftsmen;
        final activeCount = ctrl.craftsmen.where((c) => c.isActive && c.deletedAt == null).length;
        final inactiveCount = ctrl.craftsmen.where((c) => !c.isActive && c.deletedAt == null).length;
        final totalCount = ctrl.craftsmen.length;

        return Column(
          children: [
            SizedBox(height: context.heightPercent(1.5)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.getResponsiveSize(4)),
              child: Row(
                children: [
                  Expanded(child: StatCard(data: StatData(icon: Icons.people_rounded, label: 'Total', value: '$totalCount', color: AppColors.primaryGold))),
                  SizedBox(width: context.getResponsiveSize(2)),
                  Expanded(child: StatCard(data: StatData(icon: Icons.check_circle_rounded, label: 'Active', value: '$activeCount', color: AppColors.success))),
                  SizedBox(width: context.getResponsiveSize(2)),
                  Expanded(child: StatCard(data: StatData(icon: Icons.cancel_rounded, label: 'Inactive', value: '$inactiveCount', color: AppColors.danger))),
                ],
              ),
            ),
            SizedBox(height: context.heightPercent(1.5)),
            Padding(
              padding: EdgeInsets.only(
                left: context.getResponsiveSize(4),
                right: context.getResponsiveSize(4),
                bottom: context.heightPercent(1.5),
              ),
              child: SearchBarWidget(
                controller: _searchController,
                hintText: 'Search by name, phone, area...',
                outerBackgroundColor: Colors.transparent,
                barBackgroundColor: AppColors.white,
                onChanged: _onSearchChanged,
                onClear: () {
                  _searchController.clear();
                  ctrl.search('');
                },
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border(bottom: BorderSide(color: AppColors.divider)),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primaryGold,
                unselectedLabelColor: AppColors.textMuted,
                indicatorColor: AppColors.primaryGold,
                indicatorWeight: 3,
                dividerColor: Colors.transparent,
                labelStyle: TextStyle(fontSize: context.getResponsiveSize(3.5), fontWeight: FontWeight.w600),
                unselectedLabelStyle: TextStyle(fontSize: context.getResponsiveSize(3.5), fontWeight: FontWeight.w400),
                tabs: [
                  const Tab(text: 'Active'),
                  const Tab(text: 'Inactive'),
                  const Tab(text: 'Deleted'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _CraftsmanList(craftsmen: allCraftsmen, filter: CraftsmanFilter.active, onDelete: (c) => _confirmDelete(context, c), onRefresh: () => ctrl.fetchCraftsmen(), onImport: () => _showImportFlow(context), actionLoadingId: ctrl.actionLoadingId),
                  _CraftsmanList(craftsmen: allCraftsmen, filter: CraftsmanFilter.inactive, onDelete: (c) => _confirmDelete(context, c), onRefresh: () => ctrl.fetchCraftsmen(), onImport: () => _showImportFlow(context), actionLoadingId: ctrl.actionLoadingId),
                  _CraftsmanList(craftsmen: allCraftsmen, filter: CraftsmanFilter.deleted, onRestore: (c) => _confirmRestore(context, c), onRefresh: () => ctrl.fetchCraftsmen(), actionLoadingId: ctrl.actionLoadingId),
                ],
              ),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showImportFlow(context),
        backgroundColor: AppColors.primaryGold,
        child: const Icon(Icons.upload_file_rounded, color: Colors.white),
      ),
    );
  }

  void _confirmDelete(BuildContext context, CraftsmanModel craftsman) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.colorPalette.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete "${craftsman.name}"?', style: TextStyle(fontSize: context.getResponsiveSize(4.5), fontWeight: FontWeight.w700, color: context.colorPalette.textColor)),
        content: Text('You can restore it later from Trash.', style: TextStyle(fontSize: context.getResponsiveSize(3.5), color: context.colorPalette.subTitleColor)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: context.colorPalette.subTitleColor))),
          Obx(() => TextButton(
            onPressed: ctrl.actionLoadingId == craftsman.id ? null : () async {
              Navigator.pop(context);
              final (error, successMsg) = await ctrl.deleteCraftsman(craftsman.id);
              if (error == null) {
                ToastUtils.showSuccess(successMsg ?? '"${craftsman.name}" deleted');
              } else {
                ToastUtils.showError(error);
              }
            },
            child: ctrl.actionLoadingId == craftsman.id
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red))
                : const Text('Delete', style: TextStyle(color: Colors.red)),
          )),
        ],
      ),
    );
  }

  void _confirmRestore(BuildContext context, CraftsmanModel craftsman) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.colorPalette.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Restore "${craftsman.name}"?', style: TextStyle(fontSize: context.getResponsiveSize(4.5), fontWeight: FontWeight.w700, color: context.colorPalette.textColor)),
        content: Text('Move back to active list.', style: TextStyle(fontSize: context.getResponsiveSize(3.5), color: context.colorPalette.subTitleColor)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: context.colorPalette.subTitleColor))),
          Obx(() => TextButton(
            onPressed: ctrl.actionLoadingId == craftsman.id ? null : () async {
              Navigator.pop(context);
              final (error, successMsg) = await ctrl.restoreCraftsman(craftsman.id);
              if (error == null) {
                ToastUtils.showSuccess(successMsg ?? '"${craftsman.name}" restored');
              } else {
                ToastUtils.showError(error);
              }
            },
            child: ctrl.actionLoadingId == craftsman.id
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green))
                : const Text('Restore', style: TextStyle(color: Colors.green)),
          )),
        ],
      ),
    );
  }

  Future<void> _showImportFlow(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv', 'json'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return;

    final path = result.files.single.path;
    if (path == null) {
      ToastUtils.showError('Unable to read file. Please try again.');
      return;
    }

    final file = File(path);
    final fileName = result.files.single.name;

    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.colorPalette.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Import Karigar Data?', style: TextStyle(fontSize: context.getResponsiveSize(4.5), fontWeight: FontWeight.w700, color: context.colorPalette.textColor)),
        content: Text('File: $fileName\n\nThis will create new karigar entries and update existing ones.', style: TextStyle(fontSize: context.getResponsiveSize(3.5), color: context.colorPalette.subTitleColor)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: TextStyle(color: context.colorPalette.subTitleColor))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Import', style: TextStyle(color: AppColors.primaryGold, fontWeight: FontWeight.w600))),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: context.colorPalette.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          children: [
            const CircularProgressIndicator(color: AppColors.primaryGold),
            SizedBox(width: context.getResponsiveSize(4)),
            Text('Importing...', style: TextStyle(fontSize: context.getResponsiveSize(4), color: context.colorPalette.textColor)),
          ],
        ),
      ),
    );

    final (error, successMessage) = await ctrl.importCraftsmen(file);

    if (!context.mounted) return;
    Navigator.pop(context);

    if (error == null) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: context.colorPalette.backgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Import Complete', style: TextStyle(fontSize: context.getResponsiveSize(4.5), fontWeight: FontWeight.w700, color: context.colorPalette.textColor)),
          content: Text(successMessage ?? 'Import completed successfully.', style: TextStyle(fontSize: context.getResponsiveSize(3.5), color: context.colorPalette.subTitleColor)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK', style: TextStyle(color: AppColors.primaryGold, fontWeight: FontWeight.w600))),
          ],
        ),
      );
    } else {
      ToastUtils.showError(error);
    }
  }
}

class _CraftsmanList extends StatelessWidget {
  final List<CraftsmanModel> craftsmen;
  final CraftsmanFilter filter;
  final void Function(CraftsmanModel)? onDelete;
  final void Function(CraftsmanModel)? onRestore;
  final VoidCallback onRefresh;
  final VoidCallback? onImport;
  final String? actionLoadingId;

  const _CraftsmanList({
    required this.craftsmen,
    required this.filter,
    this.onDelete,
    this.onRestore,
    required this.onRefresh,
    this.onImport,
    this.actionLoadingId,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = craftsmen.where((c) {
      switch (filter) {
        case CraftsmanFilter.active:
          return c.deletedAt == null && c.isActive;
        case CraftsmanFilter.inactive:
          return c.deletedAt == null && !c.isActive;
        case CraftsmanFilter.deleted:
          return c.deletedAt != null;
      }
    }).toList();

    if (filtered.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: AppColors.primaryGold,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(context.getResponsiveSize(4), context.heightPercent(1), context.getResponsiveSize(4), context.heightPercent(2)),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final craftsman = filtered[index];
          return _CraftsmanCard(
            craftsman: craftsman,
            filter: filter,
            isLoading: actionLoadingId == craftsman.id,
            onDelete: onDelete != null ? () => onDelete!(craftsman) : null,
            onRestore: onRestore != null ? () => onRestore!(craftsman) : null,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDeletedFilter = filter == CraftsmanFilter.deleted;
    final showImportButton = filter != CraftsmanFilter.deleted;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isDeletedFilter ? Icons.delete_outline_rounded : Icons.people_outline_rounded,
            size: context.getResponsiveSize(16),
            color: context.colorPalette.subTitleColor.withValues(alpha: 0.4),
          ),
          SizedBox(height: context.heightPercent(2)),
          Text(
            filter == CraftsmanFilter.active
                ? 'No active karigar found'
                : filter == CraftsmanFilter.inactive
                    ? 'No inactive karigar found'
                    : 'No karigar in trash',
            style: TextStyle(
              fontSize: context.getResponsiveSize(4.5),
              fontWeight: FontWeight.w600,
              color: context.colorPalette.subTitleColor,
            ),
          ),
          SizedBox(height: context.heightPercent(1)),
          if (showImportButton)
            SizedBox(height: context.heightPercent(2)),
          if (showImportButton)
            ElevatedButton.icon(
              onPressed: onImport,
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('Import Karigar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: context.getResponsiveSize(6), vertical: context.heightPercent(1.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
        ],
      ),
    );
  }

}

class _CraftsmanCard extends StatelessWidget {
  final CraftsmanModel craftsman;
  final CraftsmanFilter filter;
  final bool isLoading;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;

  const _CraftsmanCard({
    required this.craftsman,
    required this.filter,
    required this.isLoading,
    this.onDelete,
    this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = [craftsman.accountName, craftsman.areaName]
        .where((s) => s != null && s.isNotEmpty && s != craftsman.name)
        .join(' · ');
    return Container(
      margin: EdgeInsets.only(bottom: context.heightPercent(1.5)),
      padding: EdgeInsets.all(context.getResponsiveSize(4)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      craftsman.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.getResponsiveSize(4.2),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      SizedBox(height: context.heightPercent(0.3)),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: context.getResponsiveSize(3.2),
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _buildStatusBadge(context),
            ],
          ),
          SizedBox(height: context.heightPercent(1.2)),
          Wrap(
            spacing: context.getResponsiveSize(3),
            runSpacing: context.heightPercent(0.5),
            children: [
              if (craftsman.phoneNumber.isNotEmpty)
                _buildInfoChip(context, Icons.phone_rounded, craftsman.phoneNumber),
              if (craftsman.emailId != null && craftsman.emailId!.isNotEmpty)
                _buildInfoChip(context, Icons.email_rounded, craftsman.emailId!),
              if (craftsman.state != null && craftsman.state!.isNotEmpty)
                _buildInfoChip(context, Icons.location_on_rounded, [craftsman.state, craftsman.cityName].where((s) => s != null && s.isNotEmpty).join(', ')),
            ],
          ),
          SizedBox(height: context.heightPercent(1.2)),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (filter == CraftsmanFilter.deleted && onRestore != null)
                _buildActionButton(
                  context,
                  icon: Icons.restore_rounded,
                  label: 'Restore',
                  color: AppColors.success,
                  isLoading: isLoading,
                  onTap: onRestore,
                ),
              if (filter != CraftsmanFilter.deleted && onDelete != null)
                _buildActionButton(
                  context,
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete',
                  color: AppColors.danger,
                  isLoading: isLoading,
                  onTap: onDelete,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final isActive = craftsman.isActive && craftsman.deletedAt == null;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.getResponsiveSize(2.5), vertical: context.heightPercent(0.4)),
      decoration: BoxDecoration(
        color: isActive ? AppColors.success.withValues(alpha: 0.1) : AppColors.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          fontSize: context.getResponsiveSize(2.8),
          fontWeight: FontWeight.w600,
          color: isActive ? AppColors.success : AppColors.danger,
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: context.getResponsiveSize(3.5), color: AppColors.textMuted),
        SizedBox(width: context.getResponsiveSize(1)),
        Text(
          text,
          style: TextStyle(
            fontSize: context.getResponsiveSize(3),
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required bool isLoading,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: context.getResponsiveSize(3), vertical: context.heightPercent(0.8)),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: isLoading
            ? SizedBox(
                width: context.getResponsiveSize(4),
                height: context.getResponsiveSize(4),
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: context.getResponsiveSize(3.5), color: color),
                  SizedBox(width: context.getResponsiveSize(1.5)),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: context.getResponsiveSize(3),
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
