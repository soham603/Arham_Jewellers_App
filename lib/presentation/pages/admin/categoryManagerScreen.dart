import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ratnesh_gold_app/domain/entities/category_model.dart';
import 'package:ratnesh_gold_app/utils/image_crop_helper.dart';
import 'package:ratnesh_gold_app/presentation/controllers/admin/AdminCategoryController.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/utils/ToastUtil.dart';
import 'package:ratnesh_gold_app/utils/network_image_to_file.dart';
import 'package:ratnesh_gold_app/core/widgets/image_action_sheet.dart';

class _CategoryImageMeta {
  File originalFile;
  CropResult lastResult;
  _CategoryImageMeta({required this.originalFile, required this.lastResult});
}

class CategoryManagerScreen extends StatefulWidget {
  const CategoryManagerScreen({super.key});

  @override
  State<CategoryManagerScreen> createState() => _CategoryManagerScreenState();
}

class _CategoryManagerScreenState extends State<CategoryManagerScreen>
    with SingleTickerProviderStateMixin {
  late final CategoryManagerController ctrl;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    ctrl = Get.isRegistered<CategoryManagerController>()
        ? Get.find<CategoryManagerController>()
        : Get.put(CategoryManagerController());
    ctrl.fetchAll();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    if (Get.isRegistered<CategoryManagerController>()) {
      Get.delete<CategoryManagerController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorPalette.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.colorPalette.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.colorPalette.textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Categories',
          style: TextStyle(
            fontSize: context.getResponsiveSize(5),
            fontWeight: FontWeight.w700,
            color: context.colorPalette.textColor,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight + 1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TabBar(
                controller: _tabController,
                labelColor: context.colorPalette.primaryColor,
                unselectedLabelColor: context.colorPalette.subTitleColor,
                indicatorColor: context.colorPalette.primaryColor,
                dividerColor: Colors.transparent,
                indicatorWeight: 3,
                labelStyle: TextStyle(fontSize: context.getResponsiveSize(3.5), fontWeight: FontWeight.w600),
                unselectedLabelStyle: TextStyle(fontSize: context.getResponsiveSize(3.5), fontWeight: FontWeight.w400),
                tabs: const [
                  Tab(text: 'Level 2'),
                  Tab(text: 'Level 3'),
                ],
              ),
              Container(height: 1, color: AppColors.divider),
            ],
          ),
        ),
      ),
      body: Obx(() {
        if (ctrl.loading && ctrl.allCategories.isEmpty) {
          return _shimmer();
        }
        return TabBarView(
          controller: _tabController,
          children: [
            _Level2Tab(ctrl: ctrl),
            _Level3Tab(ctrl: ctrl),
          ],
        );
      }),
    );
  }
}

class _Level2Tab extends StatefulWidget {
  final CategoryManagerController ctrl;
  const _Level2Tab({required this.ctrl});

  @override
  State<_Level2Tab> createState() => _Level2TabState();
}

class _Level2TabState extends State<_Level2Tab> {
  CategoryModel? _selectedL1;

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.ctrl;

    if (_selectedL1 == null) {
      return Obx(() {
        final parents = ctrl.level1Grouped;
        if (parents.isEmpty) return _empty('No Level 1 categories.', null);
        return _ParentPickerList(parents: parents, onSelect: (p) => setState(() => _selectedL1 = p));
      });
    }

    return Obx(() {
      final items = ctrl.level2ForGroup(_selectedL1!.name);
      return _DrillDownList(
        breadcrumb: _selectedL1!.name,
        onBack: () => setState(() => _selectedL1 = null),
        items: items,
        emptyMsg: 'No Level 2 under ${_selectedL1!.name}.',
        onRefresh: () => ctrl.fetchAll(force: true),
        onAddNew: () => _showCreateSheet(context, ctrl, level: 2, parentId: _selectedL1!.id),
        onEdit: (cat) => _showEditSheet(context, ctrl, cat),
        onDelete: (cat) => _confirmDelete(context, ctrl, cat),
        onRestore: (cat) => _confirmRestore(context, ctrl, cat),
        ctrl: ctrl,
      );
    });
  }
}

class _Level3Tab extends StatefulWidget {
  final CategoryManagerController ctrl;
  const _Level3Tab({required this.ctrl});

  @override
  State<_Level3Tab> createState() => _Level3TabState();
}

class _Level3TabState extends State<_Level3Tab> {
  CategoryModel? _selectedL1;
  CategoryModel? _selectedL2;

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.ctrl;

    if (_selectedL1 == null) {
      return Obx(() {
        final parents = ctrl.level1Grouped;
        if (parents.isEmpty) return _empty('No Level 1 categories.', null);
        return _ParentPickerList(parents: parents, onSelect: (p) => setState(() => _selectedL1 = p));
      });
    }

    if (_selectedL2 == null) {
      return Obx(() {
        final items = ctrl.level2ForGroup(_selectedL1!.name);
        return _DrillDownList(
          breadcrumb: _selectedL1!.name,
          onBack: () => setState(() { _selectedL1 = null; _selectedL2 = null; }),
          items: items,
          emptyMsg: 'No Level 2 under ${_selectedL1!.name}.',
          onRefresh: () => ctrl.fetchAll(force: true),
          isParentPicker: true,
          onSelectParent: (p) => setState(() => _selectedL2 = p),
          ctrl: ctrl,
        );
      });
    }

    return Obx(() {
      final items = ctrl.level3For(_selectedL2!.id);
      final availableL2 = ctrl.level2All;
      return _DrillDownList(
        breadcrumb: '${_selectedL1!.name} → ${_selectedL2!.name}',
        onBack: () => setState(() { _selectedL2 = null; }),
        items: items,
        emptyMsg: 'No Level 3 under ${_selectedL2!.name}.',
        onRefresh: () => ctrl.fetchAll(force: true),
        onAddNew: () => _showCreateSheet(context, ctrl, level: 3, parentId: _selectedL2!.id),
        onEdit: (cat) => _showEditSheet(context, ctrl, cat, availableParents: availableL2),
        onDelete: (cat) => _confirmDelete(context, ctrl, cat),
        onRestore: (cat) => _confirmRestore(context, ctrl, cat),
        ctrl: ctrl,
      );
    });
  }
}

class _ParentPickerList extends StatelessWidget {
  final List<CategoryModel> parents;
  final ValueChanged<CategoryModel> onSelect;
  const _ParentPickerList({required this.parents, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => Get.find<CategoryManagerController>().fetchAll(),
      color: context.colorPalette.primaryColor,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(
          context.getResponsiveSize(4), context.heightPercent(1),
          context.getResponsiveSize(4), context.heightPercent(8),
        ),
        itemCount: parents.length,
        itemBuilder: (_, i) => _ParentTile(cat: parents[i], onTap: () => onSelect(parents[i])),
      ),
    );
  }
}

class _DrillDownList extends StatelessWidget {
  final String breadcrumb;
  final VoidCallback onBack;
  final List<CategoryModel> items;
  final String emptyMsg;
  final Future<void> Function() onRefresh;
  final VoidCallback? onAddNew;
  final void Function(CategoryModel)? onEdit;
  final void Function(CategoryModel)? onDelete;
  final void Function(CategoryModel)? onRestore;
  final void Function(CategoryModel)? onSelectParent;
  final bool isParentPicker;
  final CategoryManagerController ctrl;

  const _DrillDownList({
    required this.breadcrumb,
    required this.onBack,
    required this.items,
    required this.emptyMsg,
    required this.onRefresh,
    this.onAddNew,
    this.onEdit,
    this.onDelete,
    this.onRestore,
    this.onSelectParent,
    this.isParentPicker = false,
    required this.ctrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: context.getResponsiveSize(4),
            vertical: context.heightPercent(1),
          ),
          color: context.colorPalette.boxColor.withValues(alpha: 0.4),
          child: Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back_ios_rounded, size: context.getResponsiveSize(3.5), color: context.colorPalette.primaryColor),
                    SizedBox(width: context.getResponsiveSize(1)),
                    Text('Back', style: TextStyle(fontSize: context.getResponsiveSize(3.3), color: context.colorPalette.primaryColor, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              SizedBox(width: context.getResponsiveSize(3)),
              Icon(Icons.chevron_right_rounded, size: context.getResponsiveSize(4), color: context.colorPalette.subTitleColor),
              SizedBox(width: context.getResponsiveSize(1.5)),
              Expanded(
                child: Text(
                  breadcrumb, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: context.getResponsiveSize(3.5), fontWeight: FontWeight.w600, color: context.colorPalette.textColor),
                ),
              ),
              if (onAddNew != null)
                GestureDetector(
                  onTap: onAddNew,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: context.getResponsiveSize(2.5), vertical: context.heightPercent(0.6)),
                    decoration: BoxDecoration(color: context.colorPalette.primaryColor, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, color: Colors.white, size: context.getResponsiveSize(3.5)),
                        SizedBox(width: context.getResponsiveSize(1)),
                        Text('New', style: TextStyle(color: Colors.white, fontSize: context.getResponsiveSize(3), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        Divider(height: 1, color: context.colorPalette.boxColor),
        Expanded(
          child: items.isEmpty
              ? _empty(emptyMsg, onBack)
              : RefreshIndicator(
                  onRefresh: onRefresh,
                  color: context.colorPalette.primaryColor,
                  child: ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                      context.getResponsiveSize(4), context.heightPercent(1),
                      context.getResponsiveSize(4), context.heightPercent(8),
                    ),
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final cat = items[i];
                      if (isParentPicker && onSelectParent != null) {
                        return _ParentTile(cat: cat, onTap: () => onSelectParent!(cat));
                      }
                      return _CategoryTile(
                        cat: cat,
                        onEdit: onEdit != null ? () => onEdit!(cat) : null,
                        onDelete: onDelete != null ? () => onDelete!(cat) : null,
                        onRestore: onRestore != null ? () => onRestore!(cat) : null,
                        ctrl: ctrl,
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}


class _ParentTile extends StatelessWidget {
  final CategoryModel cat;
  final VoidCallback onTap;
  const _ParentTile({required this.cat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: context.heightPercent(0.8)),
        padding: EdgeInsets.all(context.getResponsiveSize(3)),
        decoration: BoxDecoration(
          color: context.colorPalette.boxColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _Thumb(cat: cat, size: 12),
            SizedBox(width: context.getResponsiveSize(3)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cat.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: context.getResponsiveSize(3.8), fontWeight: FontWeight.w600, color: context.colorPalette.textColor)),
                  if (cat.nameSlug.isNotEmpty) ...[
                    SizedBox(height: 2),
                    Text(cat.nameSlug, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: context.getResponsiveSize(2.8), color: context.colorPalette.subTitleColor)),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: context.colorPalette.subTitleColor, size: context.getResponsiveSize(5)),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final CategoryModel cat;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final CategoryManagerController ctrl;

  const _CategoryTile({
    required this.cat,
    this.onEdit,
    this.onDelete,
    this.onRestore,
    required this.ctrl,
  });

  Color _levelColor(int? level) {
    switch (level) {
      case 1: return const Color(0xFFD4AF37);
      case 2: return const Color(0xFF8B6914);
      case 3: return const Color(0xFF5C4A1E);
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDeleted = cat.isDeleted;
    final isInactive = !cat.isActive;
    final levelColor = _levelColor(cat.level);

    return Container(
      margin: EdgeInsets.only(bottom: context.heightPercent(0.8)),
      decoration: BoxDecoration(
        color: context.colorPalette.boxColor,
        borderRadius: BorderRadius.circular(12),
        border: isDeleted
            ? Border.all(color: Colors.red.withValues(alpha: 0.25))
            : isInactive
                ? Border.all(color: Colors.orange.withValues(alpha: 0.3))
                : null,
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: isDeleted
                    ? Colors.red
                    : isInactive
                        ? Colors.orange
                        : levelColor,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(context.getResponsiveSize(2.5)),
              child: _Thumb(cat: cat),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: context.heightPercent(1)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Wrap(
                      spacing: context.getResponsiveSize(1.5),
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _LevelBadge(level: cat.level, color: levelColor),
                        if (isDeleted)
                          _StatusPill(
                            label: 'Deleted',
                            color: Colors.red,
                          )
                        else if (isInactive)
                          _StatusPill(
                            label: 'Inactive',
                            color: Colors.orange,
                          )
                        else
                          _StatusPill(
                            label: 'Active',
                            color: Colors.green,
                          ),
                      ],
                    ),
                    SizedBox(height: context.heightPercent(0.3)),
                    Text(
                      cat.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.getResponsiveSize(3.6), fontWeight: FontWeight.w600,
                        color: context.colorPalette.textColor,
                        decoration: isDeleted ? TextDecoration.lineThrough : null,
                        height: 1.3,
                      ),
                    ),
                    if (cat.nameSlug.isNotEmpty) ...[
                      SizedBox(height: 2),
                      Text(cat.nameSlug, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: context.getResponsiveSize(2.6), color: context.colorPalette.subTitleColor)),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(right: context.getResponsiveSize(2), top: context.heightPercent(0.8), bottom: context.heightPercent(0.8)),
              child: Obx(() {
                final isLoading = ctrl.actionLoadingId == cat.id;
                if (isLoading) {
                  return SizedBox(width: context.getResponsiveSize(5), height: context.getResponsiveSize(5),
                    child: CircularProgressIndicator(strokeWidth: 2, color: context.colorPalette.primaryColor));
                }
                if (isDeleted && onRestore != null) {
                  return _CircleBtn(icon: Icons.restore_rounded, color: Colors.green, onTap: onRestore!);
                }
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (onEdit != null) _CircleBtn(icon: Icons.edit_rounded, color: context.colorPalette.primaryColor, onTap: onEdit!),
                    if (onEdit != null && onDelete != null) SizedBox(height: context.heightPercent(0.5)),
                    if (onDelete != null) _CircleBtn(icon: Icons.delete_rounded, color: Colors.red, onTap: onDelete!),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final CategoryModel cat;
  final double size;
  const _Thumb({required this.cat, this.size = 13});

  @override
  Widget build(BuildContext context) {
    final s = context.getResponsiveSize(size);
    return Container(
      width: s, height: s,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: context.colorPalette.backgroundColor),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: cat.imageUrl.isNotEmpty
            ? Opacity(
                opacity: cat.isDeleted ? 0.5 : 1.0,
                child: CachedNetworkImage(
                  imageUrl: cat.imageUrl, fit: BoxFit.cover,
                  placeholder: (_, _) => Container(color: context.colorPalette.shimmerBaseColor),
                  errorWidget: (_, _, _) => _noImg(context),
                ),
              )
            : _noImg(context),
      ),
    );
  }

  Widget _noImg(BuildContext context) {
    return Container(
      color: context.colorPalette.backgroundColor,
      child: Icon(Icons.category_outlined, size: context.getResponsiveSize(5), color: context.colorPalette.subTitleColor),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  final int? level;
  final Color color;
  const _LevelBadge({required this.level, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.getResponsiveSize(2), vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
      child: Text('L${level ?? "?"}', style: TextStyle(fontSize: context.getResponsiveSize(2.5), color: color, fontWeight: FontWeight.w700)),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.getResponsiveSize(2), vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: context.getResponsiveSize(1.2)),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: context.getResponsiveSize(2.5),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(context.getResponsiveSize(1.5)),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(icon, size: context.getResponsiveSize(3.5), color: color),
      ),
    );
  }
}

Widget _shimmer() {
  return ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: 5,
    itemBuilder: (_, _) => Container(
      margin: const EdgeInsets.only(bottom: 10),
      height: 72,
      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
    ),
  );
}

Widget _empty(String msg, VoidCallback? onBack) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.category_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(msg, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
          if (onBack != null) ...[
            const SizedBox(height: 16),
            TextButton(onPressed: onBack, child: const Text('Go Back')),
          ],
        ],
      ),
    ),
  );
}

void _showCreateSheet(BuildContext context, CategoryManagerController ctrl, {required int level, String? parentId}) {
  _showFormSheet(context, ctrl, isCreate: true, level: level, parentId: parentId);
}

void _showEditSheet(BuildContext context, CategoryManagerController ctrl, CategoryModel cat, {List<CategoryModel>? availableParents}) {
  _showFormSheet(context, ctrl, isCreate: false, existing: cat, availableParents: availableParents);
}

void _showFormSheet(BuildContext context, CategoryManagerController ctrl, {
  required bool isCreate,
  CategoryModel? existing,
  int? level,
  String? parentId,
  List<CategoryModel>? availableParents,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CategoryFormSheet(
      isCreate: isCreate,
      existing: existing,
      level: level ?? existing?.level ?? 1,
      parentId: parentId ?? existing?.parentId,
      ctrl: ctrl,
      availableParents: availableParents,
    ),
  );
}

class _CategoryFormSheet extends StatefulWidget {
  final bool isCreate;
  final CategoryModel? existing;
  final int level;
  final String? parentId;
  final CategoryManagerController ctrl;
  final List<CategoryModel>? availableParents;

  const _CategoryFormSheet({
    required this.isCreate,
    this.existing,
    required this.level,
    this.parentId,
    required this.ctrl,
    this.availableParents,
  });

  @override
  State<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<_CategoryFormSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  File? _pickedImage;
  _CategoryImageMeta? _imageMeta;
  bool _isDeleteImage = false;
  bool _isActive = true;
  bool _submitting = false;
  bool _fromServerEdit = false;
  String? _selectedParentId;

  bool get isEditing => !widget.isCreate;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameCtrl.text = widget.existing!.name;
      _descCtrl.text = widget.existing!.description ?? '';
      _isActive = widget.existing!.isActive;
      _selectedParentId = widget.existing!.parentId;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    if (!mounted) return;
    final result = await cropImage(context, imageFile: File(picked.path), aspectRatio: 1);
    if (result != null) {
      setState(() {
        _pickedImage = result.file;
        _isDeleteImage = false;
        _fromServerEdit = false;
        _imageMeta = _CategoryImageMeta(
          originalFile: File(picked.path),
          lastResult: result,
        );
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final (error, successMsg) = isEditing
        ? await widget.ctrl.editCategory(
            id: widget.existing!.id,
            name: _nameCtrl.text.trim(),
            parentId: _selectedParentId,
            imageFile: _pickedImage,
            isDeleteImage: _isDeleteImage,
            isActive: _isActive,
            skipCompression: _fromServerEdit,
          )
        : await widget.ctrl.createCategory(
            name: _nameCtrl.text.trim(),
            boxName: _nameCtrl.text.trim(),
            description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
            level: widget.level,
            parentId: widget.parentId,
            imageFile: _pickedImage,
          );

    if (error == null && mounted) {
      ToastUtils.showSuccess(successMsg ?? (isEditing ? 'Updated' : 'Created'));
      Navigator.of(context).pop();
    } else if (mounted) {
      ToastUtils.showError(error ?? 'Something went wrong');
    }
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: context.colorPalette.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollCtrl) {
          return Form(
            key: _formKey,
            child: ListView(
              controller: scrollCtrl,
              padding: EdgeInsets.fromLTRB(
                context.getResponsiveSize(5), context.heightPercent(1.5),
                context.getResponsiveSize(5), context.heightPercent(3),
              ),
              children: [
                Center(child: Container(width: context.getResponsiveSize(10), height: 4,
                  decoration: BoxDecoration(color: context.colorPalette.boxColor, borderRadius: BorderRadius.circular(2)))),
                SizedBox(height: context.heightPercent(2)),
                Text(
                  isEditing ? 'Edit Category' : 'New Level ${widget.level} Category',
                  style: TextStyle(fontSize: context.getResponsiveSize(5), fontWeight: FontWeight.w700, color: context.colorPalette.textColor),
                ),
                SizedBox(height: context.heightPercent(2.5)),

                _label('Name'),
                SizedBox(height: context.heightPercent(0.6)),
                TextFormField(
                  controller: _nameCtrl,
                  style: TextStyle(fontSize: context.getResponsiveSize(3.8), color: context.colorPalette.textColor),
                  decoration: _inputDec(context, 'Enter name'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                SizedBox(height: context.heightPercent(2)),

                if (isEditing) ...[
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.getResponsiveSize(3),
                      vertical: context.heightPercent(1.2),
                    ),
                    decoration: BoxDecoration(
                      color: _isActive
                          ? Colors.green.withValues(alpha: 0.08)
                          : Colors.orange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isActive
                            ? Colors.green.withValues(alpha: 0.35)
                            : Colors.orange.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isActive ? Icons.check_circle_rounded : Icons.pause_circle_rounded,
                          color: _isActive ? Colors.green : Colors.orange,
                          size: context.getResponsiveSize(5),
                        ),
                        SizedBox(width: context.getResponsiveSize(3)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isActive ? 'Active' : 'Inactive',
                                style: TextStyle(
                                  fontSize: context.getResponsiveSize(3.6),
                                  fontWeight: FontWeight.w700,
                                  color: context.colorPalette.textColor,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                _isActive
                                    ? 'Visible to users. All products in this category remain active.'
                                    : 'Hidden from users. All products in this category become inactive.',
                                style: TextStyle(
                                  fontSize: context.getResponsiveSize(2.6),
                                  color: context.colorPalette.subTitleColor,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: context.getResponsiveSize(2)),
                        Switch(
                          value: _isActive,
                          activeThumbColor: Colors.green,
                          inactiveTrackColor: Colors.orange.withValues(alpha: 0.5),
                          onChanged: (v) => setState(() => _isActive = v),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: context.heightPercent(2)),
                ],

                if (!isEditing) ...[
                  _label('Description (optional)'),
                  SizedBox(height: context.heightPercent(0.6)),
                  TextFormField(
                    controller: _descCtrl,
                    style: TextStyle(fontSize: context.getResponsiveSize(3.8), color: context.colorPalette.textColor),
                    maxLines: 3,
                    decoration: _inputDec(context, 'Brief description...'),
                  ),
                  SizedBox(height: context.heightPercent(2)),
                ],

                if (isEditing && widget.availableParents != null && widget.availableParents!.isNotEmpty) ...[
                  _label('Move to Category'),
                  SizedBox(height: context.heightPercent(0.6)),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.getResponsiveSize(3),
                      vertical: context.heightPercent(0.3),
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: context.colorPalette.boxColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedParentId,
                        hint: Text(
                          'Select parent category',
                          style: TextStyle(
                            fontSize: context.getResponsiveSize(3.5),
                            color: context.colorPalette.subTitleColor,
                          ),
                        ),
                        items: widget.availableParents!.map((cat) {
                          return DropdownMenuItem<String>(
                            value: cat.id,
                            child: Text(
                              cat.name,
                              style: TextStyle(
                                fontSize: context.getResponsiveSize(3.5),
                                color: context.colorPalette.textColor,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _selectedParentId = v),
                      ),
                    ),
                  ),
                  SizedBox(height: context.heightPercent(2)),
                ],

                _label('Image (optional)'),
                SizedBox(height: context.heightPercent(0.8)),
                Center(
                  child: SizedBox(
                    width: context.heightPercent(14),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: GestureDetector(
                        onTap: () {
                          final hasExistingImage = isEditing &&
                              widget.existing!.imageUrl.isNotEmpty;
                          final hasPickedImage = _pickedImage != null;
                          final hasAnyImage = hasPickedImage || hasExistingImage;

                          if (hasAnyImage) {
                            showImageActionSheet(
                              context,
                              onEdit: () async {
                                if (hasPickedImage) {
                                  final meta = _imageMeta;
                                  final originalFile = meta?.originalFile ?? _pickedImage!;
                                  final initialState = meta != null
                                      ? CropInitialState(
                                          rotationDegrees: meta.lastResult.rotationDegrees,
                                          flipY: meta.lastResult.flipY,
                                        )
                                      : null;
                                  final result = await cropImage(
                                    context,
                                    imageFile: originalFile,
                                    aspectRatio: 1,
                                    initialState: initialState,
                                  );
                                  if (result != null) {
                                    setState(() {
                                      _pickedImage = result.file;
                                      _isDeleteImage = false;
                                      _imageMeta = _CategoryImageMeta(
                                        originalFile: originalFile,
                                        lastResult: result,
                                      );
                                    });
                                  }
                                } else if (hasExistingImage) {
                                  final localFile =
                                      await downloadNetworkImageToFile(
                                          widget.existing!.imageUrl);
                                  if (localFile != null && context.mounted) {
                                    final result = await cropImage(
                                      context,
                                      imageFile: localFile,
                                      aspectRatio: 1,
                                    );
                                    if (result != null) {
                                      setState(() {
                                        _pickedImage = result.file;
                                        _isDeleteImage = false;
                                        _fromServerEdit = true;
                                        _imageMeta = _CategoryImageMeta(
                                          originalFile: localFile,
                                          lastResult: result,
                                        );
                                      });
                                    }
                                  }
                                }
                              },
                              onUpload: _pickImage,
                              onRemove: () {
                                setState(() {
                                  _pickedImage = null;
                                  _isDeleteImage = true;
                                });
                              },
                            );
                          } else {
                            _pickImage();
                          }
                        },
                        child: Container(
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _pickedImage != null ? context.colorPalette.primaryColor : context.colorPalette.boxColor,
                              width: _pickedImage != null ? 2 : 1,
                            ),
                            color: context.colorPalette.boxColor.withValues(alpha: 0.4),
                          ),
                          child: _pickedImage != null
                              ? Image.file(_pickedImage!, fit: BoxFit.cover)
                              : _imagePlaceholder(context),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: context.heightPercent(3)),

                SizedBox(
                  width: double.infinity, height: context.heightPercent(6),
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colorPalette.primaryColor,
                      disabledBackgroundColor: context.colorPalette.primaryColor.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _submitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(isEditing ? 'Save' : 'Create',
                            style: TextStyle(fontSize: context.getResponsiveSize(4), fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _label(String text) {
    return Text(text, style: TextStyle(fontSize: context.getResponsiveSize(3.3), fontWeight: FontWeight.w600, color: context.colorPalette.textColor));
  }

  Widget _imagePlaceholder(BuildContext context) {
    if (isEditing && !_isDeleteImage && widget.existing!.imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(fit: StackFit.expand, children: [
          CachedNetworkImage(
            imageUrl: widget.existing!.imageUrl,
            fit: BoxFit.cover,
            errorWidget: (_, _, _) => Container(
              color: context.colorPalette.backgroundColor,
              child: Icon(Icons.broken_image_outlined, size: context.getResponsiveSize(6), color: context.colorPalette.subTitleColor),
            ),
          ),
          Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.black.withValues(alpha: 0.35))),
          Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.camera_alt_rounded, color: Colors.white, size: context.getResponsiveSize(6)),
            SizedBox(height: context.heightPercent(0.3)),
            Text('Tap to change', style: TextStyle(color: Colors.white, fontSize: context.getResponsiveSize(3))),
          ])),
        ]),
      );
    }
    return Center(
      child: Icon(Icons.add_photo_alternate_outlined, size: context.getResponsiveSize(6), color: context.colorPalette.subTitleColor),
    );
  }
}

InputDecoration _inputDec(BuildContext context, String hint) {
  return InputDecoration(
    isDense: true,
    contentPadding: EdgeInsets.symmetric(horizontal: context.getResponsiveSize(3.5), vertical: context.heightPercent(1.3)),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.colorPalette.boxColor)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.colorPalette.boxColor)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.colorPalette.primaryColor)),
    hintText: hint,
    hintStyle: TextStyle(fontSize: context.getResponsiveSize(3.3), color: context.colorPalette.subTitleColor),
  );
}

void _confirmDelete(BuildContext context, CategoryManagerController ctrl, CategoryModel cat) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: context.colorPalette.backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Delete "${cat.name}"?', style: TextStyle(fontSize: context.getResponsiveSize(4.5), fontWeight: FontWeight.w700, color: context.colorPalette.textColor)),
      content: Text('You can restore it later.', style: TextStyle(fontSize: context.getResponsiveSize(3.5), color: context.colorPalette.subTitleColor)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: context.colorPalette.subTitleColor))),
        Obx(() => TextButton(
          onPressed: ctrl.actionLoadingId == cat.id ? null : () async {
            Navigator.pop(context);
            final (error, successMsg) = await ctrl.deleteCategory(cat.id);
            if (error == null) {
              ToastUtils.showSuccess(successMsg ?? '"${cat.name}" deleted');
            } else {
              ToastUtils.showError(error);
            }
          },
          child: ctrl.actionLoadingId == cat.id
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red))
              : const Text('Delete', style: TextStyle(color: Colors.red)),
        )),
      ],
    ),
  );
}

void _confirmRestore(BuildContext context, CategoryManagerController ctrl, CategoryModel cat) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: context.colorPalette.backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Restore "${cat.name}"?', style: TextStyle(fontSize: context.getResponsiveSize(4.5), fontWeight: FontWeight.w700, color: context.colorPalette.textColor)),
      content: Text('Move back to active.', style: TextStyle(fontSize: context.getResponsiveSize(3.5), color: context.colorPalette.subTitleColor)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: context.colorPalette.subTitleColor))),
        TextButton(
          onPressed: ctrl.actionLoadingId == cat.id ? null : () async {
            Navigator.pop(context);
            final (error, successMsg) = await ctrl.restoreCategory(cat.id);
            if (error == null) {
              ToastUtils.showSuccess(successMsg ?? '"${cat.name}" restored');
            } else {
              ToastUtils.showError(error);
            }
          },
          child: const Text('Restore', style: TextStyle(color: Colors.green)),
        ),
      ],
    ),
  );
}
