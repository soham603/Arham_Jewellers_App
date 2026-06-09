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
            margin: const EdgeInsets.only(top: 6),
            width: 32,
            height: 3,
            decoration: BoxDecoration(
              color: context.colorPalette.goldDark.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
            child: Row(
              children: [
                Icon(
                  Icons.grid_view_rounded,
                  size: 16,
                  color: context.colorPalette.goldDark,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Select Categories',
                    style: TextStyle(
                      fontSize: 14,
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
                        fontSize: 12,
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
                          size: 36,
                          color: context.colorPalette.goldDark,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'No categories found',
                          style: TextStyle(
                            fontSize: 12,
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
            margin: const EdgeInsets.only(bottom: 2),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                      width: 28,
                      height: 28,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: context.colorPalette.goldLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.diamond_outlined,
                          color: context.colorPalette.goldDark,
                          size: 14,
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
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: context.colorPalette.goldDeep,
                    ),
                  ),
                ),
                if (level3.isNotEmpty && selectedCount > 0)
                  _buildCountBadge(context, selectedCount),
                if (isLoading)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  )
                else
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      size: 16,
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
              margin: const EdgeInsets.only(left: 18, top: 2, bottom: 2),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: context.colorPalette.goldDeep,
                      ),
                    ),
                  ),
                  Icon(
                    level3.every((c) => _isSelected(c.id))
                        ? Icons.check_box
                        : Icons.select_all_rounded,
                    size: 12,
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
        margin: const EdgeInsets.only(left: 18, top: 2, bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
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
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? context.colorPalette.goldDeep
                      : context.colorPalette.textColor,
                ),
              ),
            ),
            if (selected)
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.colorPalette.gold,
                ),
                child: const Icon(
                  Icons.check,
                  size: 9,
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
      padding: const EdgeInsets.only(right: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: context.colorPalette.gold,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '$count',
          style: const TextStyle(
            fontSize: 9,
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
