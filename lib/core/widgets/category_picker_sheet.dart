import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/domain/entities/category_model.dart';
import 'package:ratnesh_gold_app/presentation/controllers/CategoryController.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';

/// A single selected-category entry so IDs and names never go out of sync.
class SelectedCategory {
  final String id;
  final String displayName;

  const SelectedCategory({required this.id, required this.displayName});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectedCategory &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// A reusable bottom sheet for picking categories with expandable level-3 subcategories.
class CategoryPickerSheet extends StatefulWidget {
  final List<CategoryModel> categories;
  final Map<String, List<CategoryModel>> categoryVariants;
  final CategoryController categoryController;
  final Set<SelectedCategory> selectedCategories;
  final String Function(String) cleanName;
  final ValueChanged<Set<SelectedCategory>> onSelectionChanged;
  final VoidCallback onClear;

  const CategoryPickerSheet({
    super.key,
    required this.categories,
    required this.categoryVariants,
    required this.categoryController,
    required this.selectedCategories,
    required this.cleanName,
    required this.onSelectionChanged,
    required this.onClear,
  });

  static Future<void> show(
    BuildContext context, {
    required List<CategoryModel> categories,
    required Map<String, List<CategoryModel>> categoryVariants,
    required CategoryController categoryController,
    required Set<SelectedCategory> selectedCategories,
    required String Function(String) cleanName,
    required ValueChanged<Set<SelectedCategory>> onSelectionChanged,
    required VoidCallback onClear,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => CategoryPickerSheet(
        categories: categories,
        categoryVariants: categoryVariants,
        categoryController: categoryController,
        selectedCategories: selectedCategories,
        cleanName: cleanName,
        onSelectionChanged: onSelectionChanged,
        onClear: onClear,
      ),
    );
  }

  @override
  State<CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<CategoryPickerSheet> {
  late Set<SelectedCategory> _localSelection;

  @override
  void initState() {
    super.initState();
    _localSelection = Set<SelectedCategory>.from(widget.selectedCategories);
  }

  List<CategoryModel> _mergedLevel3(CategoryModel parent) {
    final key = parent.name.toLowerCase().trim();
    final variants = widget.categoryVariants[key] ?? [parent];
    final seen = <String>{};
    final result = <CategoryModel>[];
    for (final variant in variants) {
      for (final child
          in widget.categoryController.level3Cache[variant.id] ?? []) {
        if (seen.add(child.id)) {
          result.add(child);
        }
      }
    }
    return result;
  }

  bool _isSelected(String id) {
    return _localSelection.any((c) => c.id == id);
  }

  void _notifyParent() {
    widget.onSelectionChanged(Set<SelectedCategory>.from(_localSelection));
  }

  void _toggleSingle(CategoryModel cat) {
    final cleanedName = widget.cleanName(cat.name);
    setState(() {
      final existing = _localSelection.firstWhereOrNull((c) => c.id == cat.id);
      if (existing != null) {
        _localSelection.remove(existing);
      } else {
        _localSelection.add(
          SelectedCategory(id: cat.id, displayName: cleanedName),
        );
      }
    });
    _notifyParent();
  }

  void _toggleAllForParent(CategoryModel parent) {
    final children = _mergedLevel3(parent);
    if (children.isEmpty) return;

    final allSelected = children.every((c) => _isSelected(c.id));

    setState(() {
      if (allSelected) {
        final childIds = children.map((c) => c.id).toSet();
        _localSelection.removeWhere((c) => childIds.contains(c.id));
      } else {
        for (final child in children) {
          if (!_isSelected(child.id)) {
            _localSelection.add(SelectedCategory(
              id: child.id,
              displayName: widget.cleanName(child.name),
            ));
          }
        }
      }
    });
    _notifyParent();
  }

  void _clearAll() {
    setState(() => _localSelection.clear());
    widget.onClear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.width >= 600
          ? MediaQuery.of(context).size.height * 0.5
          : MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: context.colorPalette.cream,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(
            context.responsiveWidth(14, tabletVal: 16),
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: context.responsiveWidth(6)),
            width: context.responsiveWidth(32),
            height: context.responsiveWidth(3, tabletVal: 4),
            decoration: BoxDecoration(
              color: context.colorPalette.goldDark.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.responsiveWidth(12),
              context.responsiveWidth(6),
              context.responsiveWidth(12),
              context.responsiveWidth(6),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.grid_view_rounded,
                  size: context.responsiveWidth(16, tabletVal: 18),
                  color: context.colorPalette.goldDark,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Select Categories',
                    style: TextStyle(
                      fontSize: context.responsiveFont(14),
                      fontWeight: FontWeight.w700,
                      color: context.colorPalette.goldDeep,
                    ),
                  ),
                ),
                if (_localSelection.isNotEmpty)
                  TextButton(
                    onPressed: _clearAll,
                    child: Text(
                      'Clear',
                      style: TextStyle(
                        fontSize: context.responsiveFont(12),
                        color: context.colorPalette.goldDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: context.colorPalette.border),
          Expanded(
            child: widget.categories.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.category_outlined,
                          size: context.responsiveWidth(36, tabletVal: 40),
                          color: context.colorPalette.goldDark,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'No categories found',
                          style: TextStyle(
                            fontSize: context.responsiveFont(12),
                            color: context.colorPalette.goldDark,
                          ),
                        ),
                      ],
                    ),
                  )
                : Obx(() {
                    final expandedId =
                        widget.categoryController.expandedCategoryId;
                    return ListView.builder(
                      padding: EdgeInsets.all(
                        context.responsiveWidth(10, tabletVal: 12),
                      ),
                      itemCount: widget.categories.length,
                      itemBuilder: (_, index) {
                        final cat = widget.categories[index];
                        return _buildCategoryTile(context, cat, expandedId);
                      },
                    );
                  }),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(
    BuildContext context,
    CategoryModel cat,
    dynamic expandedId,
  ) {
    final isExpanded = expandedId == cat.id;
    final level3 = _mergedLevel3(cat);
    final isLoading = widget.categoryController.isLevel3Loading(cat.id);
    final selectedCount =
        level3.where((sub) => _isSelected(sub.id)).length;

    return Column(
      children: [
        GestureDetector(
          onTap: () => widget.categoryController.toggleExpand(cat),
          child: Container(
            margin: EdgeInsets.only(bottom: context.responsiveWidth(2)),
            padding: EdgeInsets.symmetric(
              horizontal: context.responsiveWidth(10, tabletVal: 12),
              vertical: context.responsiveWidth(6),
            ),
            decoration: BoxDecoration(
              color: context.colorPalette.cardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isExpanded
                    ? context.colorPalette.gold
                    : context.colorPalette.border,
                width: isExpanded ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                if (cat.imageUrl.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      cat.imageUrl,
                      width: context.responsiveWidth(28, tabletVal: 32),
                      height: context.responsiveWidth(28, tabletVal: 32),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: context.responsiveWidth(28, tabletVal: 32),
                        height: context.responsiveWidth(28, tabletVal: 32),
                        decoration: BoxDecoration(
                          color: context.colorPalette.goldLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.diamond_outlined,
                          color: context.colorPalette.goldDark,
                          size: context.responsiveWidth(14, tabletVal: 16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    widget.cleanName(cat.name),
                    style: TextStyle(
                      fontSize: context.responsiveFont(11),
                      fontWeight: FontWeight.w600,
                      color: context.colorPalette.goldDeep,
                    ),
                  ),
                ),
                if (level3.isNotEmpty && selectedCount > 0)
                  _buildCountBadge(context, selectedCount),
                if (isLoading)
                  SizedBox(
                    width: context.responsiveWidth(14, tabletVal: 16),
                    height: context.responsiveWidth(14, tabletVal: 16),
                    child: const CircularProgressIndicator(strokeWidth: 1.5),
                  )
                else
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      size: context.responsiveWidth(16, tabletVal: 18),
                      color: context.colorPalette.goldDark,
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (isExpanded && level3.isNotEmpty) ...[
          GestureDetector(
            onTap: () => _toggleAllForParent(cat),
            child: Container(
              margin: EdgeInsets.only(
                left: context.responsiveWidth(18, tabletVal: 20),
                top: context.responsiveWidth(2),
                bottom: context.responsiveWidth(2),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: context.responsiveWidth(8, tabletVal: 10),
                vertical: context.responsiveWidth(4),
              ),
              decoration: BoxDecoration(
                color: context.colorPalette.cardBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.colorPalette.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'All',
                      style: TextStyle(
                        fontSize: context.responsiveFont(10),
                        fontWeight: FontWeight.w700,
                        color: context.colorPalette.goldDeep,
                      ),
                    ),
                  ),
                  Icon(
                    level3.every((c) => _isSelected(c.id))
                        ? Icons.check_box
                        : Icons.select_all_rounded,
                    size: context.responsiveWidth(12, tabletVal: 14),
                    color: context.colorPalette.goldDark,
                  ),
                ],
              ),
            ),
          ),
          ...level3.map((sub) => _buildSubCategoryTile(context, sub)),
        ],
      ],
    );
  }

  Widget _buildSubCategoryTile(BuildContext context, CategoryModel sub) {
    final selected = _isSelected(sub.id);
    final cleanedName = widget.cleanName(sub.name);

    return GestureDetector(
      onTap: () => _toggleSingle(sub),
      child: Container(
        margin: EdgeInsets.only(
          left: context.responsiveWidth(18, tabletVal: 20),
          top: context.responsiveWidth(2),
          bottom: context.responsiveWidth(2),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: context.responsiveWidth(8, tabletVal: 10),
          vertical: context.responsiveWidth(5),
        ),
        decoration: BoxDecoration(
          color: selected
              ? context.colorPalette.goldLight
              : context.colorPalette.backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? context.colorPalette.gold
                : context.colorPalette.border,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                cleanedName,
                style: TextStyle(
                  fontSize: context.responsiveFont(10),
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? context.colorPalette.goldDeep
                      : context.colorPalette.textColor,
                ),
              ),
            ),
            if (selected)
              Container(
                width: context.responsiveWidth(14, tabletVal: 16),
                height: context.responsiveWidth(14, tabletVal: 16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.colorPalette.gold,
                ),
                child: Icon(
                  Icons.check,
                  size: context.responsiveWidth(9, tabletVal: 11),
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountBadge(BuildContext context, int count) {
    return Padding(
      padding: EdgeInsets.only(right: context.responsiveWidth(4)),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.responsiveWidth(4),
          vertical: context.responsiveWidth(1),
        ),
        decoration: BoxDecoration(
          color: context.colorPalette.gold,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '$count',
          style: TextStyle(
            fontSize: context.responsiveFont(9),
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

extension _IterableExt<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}


