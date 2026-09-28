import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/data/repositories/product_repository.dart';
import 'package:ratnesh_gold_app/domain/entities/category_model.dart';
import 'package:ratnesh_gold_app/domain/entities/productModel.dart';
import 'package:ratnesh_gold_app/presentation/controllers/CategoryController.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';

class LinkTargetSelection {
  final String linkType;
  final String? linkId;
  final String? linkName;

  const LinkTargetSelection({
    required this.linkType,
    this.linkId,
    this.linkName,
  });
}

class LinkTargetPicker extends StatefulWidget {
  final String? initialLinkType;
  final String? initialLinkId;
  final String? initialLinkName;
  final bool enabled;
  final ValueChanged<LinkTargetSelection> onChanged;

  const LinkTargetPicker({
    super.key,
    this.initialLinkType,
    this.initialLinkId,
    this.initialLinkName,
    this.enabled = true,
    required this.onChanged,
  });

  @override
  State<LinkTargetPicker> createState() => _LinkTargetPickerState();
}

class _LinkTargetPickerState extends State<LinkTargetPicker> {
  final _productRepo = ProductRepository();
  final _productSearchController = TextEditingController();

  late String _linkType;
  ProductModel? _linkProduct;
  CategoryModel? _linkCategory;

  final _productResults = <ProductModel>[];
  CurrentAppState _productSearchState = CurrentAppState.INITIAL;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialLinkType?.toLowerCase();
    _linkType = (initial == 'product' || initial == 'category')
        ? initial!
        : 'none';
    if (_linkType == 'product' && widget.initialLinkName != null) {
      _linkProduct = ProductModel(
        id: widget.initialLinkId ?? '',
        name: widget.initialLinkName!,
        isActive: true,
      );
    }
    if (_linkType == 'category' && widget.initialLinkName != null) {
      _linkCategory = CategoryModel(
        id: widget.initialLinkId ?? '',
        name: widget.initialLinkName!,
        nameSlug: '',
        imageUrl: '',
        isDeleted: false,
      );
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _productSearchController.dispose();
    super.dispose();
  }

  void _selectType(String value) {
    if (!widget.enabled || _linkType == value) return;
    setState(() {
      _linkType = value;
      if (value != 'product') {
        _productResults.clear();
        _productSearchState = CurrentAppState.INITIAL;
        _linkProduct = null;
        _productSearchController.clear();
      }
      if (value != 'category') {
        _linkCategory = null;
      }
    });

    if (value == 'none') {
      widget.onChanged(
        const LinkTargetSelection(linkType: 'none'),
      );
    }
  }

  void _onProductSearchChanged(String query) {
    _debounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _productResults.clear();
        _productSearchState = CurrentAppState.INITIAL;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _searchProducts(trimmed);
    });
  }

  Future<void> _searchProducts(String query) async {
    if (!mounted) return;
    setState(() => _productSearchState = CurrentAppState.LOADING);
    try {
      final result = await _productRepo.searchProducts(query: query);
      if (!mounted || _linkType != 'product') return;
      setState(() {
        _productResults
          ..clear()
          ..addAll(result.items);
        _productSearchState = CurrentAppState.SUCCESS;
      });
    } catch (_) {
      if (!mounted || _linkType != 'product') return;
      setState(() {
        _productResults.clear();
        _productSearchState = CurrentAppState.ERROR;
      });
    }
  }

  void _selectProduct(ProductModel product) {
    setState(() {
      _linkProduct = product;
      _linkCategory = null;
    });
    widget.onChanged(
      LinkTargetSelection(
        linkType: 'product',
        linkId: product.id,
        linkName: product.name,
      ),
    );
  }

  Future<void> _openCategoryPicker() async {
    if (!widget.enabled) return;

    final selected = await showModalBottomSheet<CategoryModel>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _CategoryPickerSheet(),
    );

    if (selected == null || !mounted) return;
    setState(() {
      _linkCategory = selected;
      _linkProduct = null;
    });
    widget.onChanged(
      LinkTargetSelection(
        linkType: 'category',
        linkId: selected.id,
        linkName: selected.name,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final options = [
      {'value': 'none', 'label': 'None', 'icon': Icons.block_rounded},
      {
        'value': 'product',
        'label': 'Product',
        'icon': Icons.shopping_bag_rounded,
      },
      {
        'value': 'category',
        'label': 'Category',
        'icon': Icons.category_rounded,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Link to (optional)',
          style: TextStyle(
            fontSize: context.getResponsiveSize(3.5),
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        SizedBox(height: context.heightPercent(0.3)),
        Text(
          'Tapping the video opens the linked product or collection.',
          style: TextStyle(
            fontSize: context.getResponsiveSize(2.8),
            color: AppColors.textMuted,
          ),
        ),
        SizedBox(height: context.heightPercent(0.8)),
        Row(
          children: options.map((opt) {
            final isSelected = _linkType == opt['value'];
            return Expanded(
              child: GestureDetector(
                onTap: () => _selectType(opt['value'] as String),
                child: Container(
                  margin: EdgeInsets.only(
                    right: opt != options.last
                        ? context.getResponsiveSize(2)
                        : 0,
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: context.heightPercent(1),
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryGold.withValues(alpha: 0.1)
                        : context.colorPalette.boxColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryGold
                          : context.colorPalette.subTitleColor.withValues(
                              alpha: 0.15,
                            ),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        opt['icon'] as IconData,
                        color: isSelected
                            ? AppColors.primaryGold
                            : AppColors.textMuted,
                        size: context.getResponsiveSize(5),
                      ),
                      SizedBox(height: context.heightPercent(0.3)),
                      Text(
                        opt['label'] as String,
                        style: TextStyle(
                          fontSize: context.getResponsiveSize(2.8),
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppColors.primaryGold
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (_linkType == 'product')
          Padding(
            padding: EdgeInsets.only(top: context.heightPercent(1)),
            child: _buildProductPicker(context),
          ),
        if (_linkType == 'category')
          Padding(
            padding: EdgeInsets.only(top: context.heightPercent(1)),
            child: _buildCategoryPicker(context),
          ),
      ],
    );
  }

  Widget _buildProductPicker(BuildContext context) {
    final product = _linkProduct;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (product != null && product.name.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: context.heightPercent(1)),
            child: Chip(
              label: Text(
                product.name,
                style: TextStyle(
                  fontSize: context.getResponsiveSize(3),
                  color: AppColors.textDark,
                ),
              ),
              backgroundColor: AppColors.primaryGold.withValues(alpha: 0.1),
              onDeleted: widget.enabled
                  ? () => setState(() {
                        _linkProduct = null;
                        widget.onChanged(
                          const LinkTargetSelection(linkType: 'none'),
                        );
                      })
                  : null,
              deleteIcon: const Icon(Icons.close_rounded, size: 16),
            ),
          ),
        TextField(
          controller: _productSearchController,
          enabled: widget.enabled,
          onChanged: _onProductSearchChanged,
          style: TextStyle(
            fontSize: context.getResponsiveSize(3.4),
            color: AppColors.textDark,
          ),
          decoration: InputDecoration(
            hintText: 'Search by product name or tag number',
            hintStyle: TextStyle(
              fontSize: context.getResponsiveSize(3.2),
              color: AppColors.textMuted,
            ),
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            filled: true,
            fillColor: context.colorPalette.boxColor,
            contentPadding: EdgeInsets.symmetric(
              horizontal: context.getResponsiveSize(3),
              vertical: context.heightPercent(1.4),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: context.colorPalette.subTitleColor.withValues(
                  alpha: 0.15,
                ),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: context.colorPalette.subTitleColor.withValues(
                  alpha: 0.15,
                ),
              ),
            ),
          ),
        ),
        if (_linkProduct == null) _buildProductResults(context),
      ],
    );
  }

  Widget _buildProductResults(BuildContext context) {
    if (_productSearchState == CurrentAppState.LOADING &&
        _productResults.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: context.heightPercent(1.5)),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_productResults.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.only(top: context.heightPercent(0.8)),
      constraints: BoxConstraints(maxHeight: context.heightPercent(28)),
      decoration: BoxDecoration(
        color: context.colorPalette.boxColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.colorPalette.subTitleColor.withValues(alpha: 0.15),
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: _productResults.length,
        separatorBuilder: (_, _) => Divider(
          height: 1,
          color: context.colorPalette.subTitleColor.withValues(alpha: 0.1),
        ),
        itemBuilder: (context, index) {
          final product = _productResults[index];
          return ListTile(
            dense: true,
            title: Text(
              product.name,
              style: TextStyle(
                fontSize: context.getResponsiveSize(3.4),
                color: AppColors.textDark,
              ),
            ),
            subtitle: (product.tagNo != null && product.tagNo!.isNotEmpty)
                ? Text(
                    'Tag ${product.tagNo}',
                    style: TextStyle(
                      fontSize: context.getResponsiveSize(2.8),
                      color: AppColors.textMuted,
                    ),
                  )
                : null,
            onTap: () => _selectProduct(product),
          );
        },
      ),
    );
  }

  Widget _buildCategoryPicker(BuildContext context) {
    final category = _linkCategory;
    return GestureDetector(
      onTap: _openCategoryPicker,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: context.getResponsiveSize(4),
          vertical: context.heightPercent(1.4),
        ),
        decoration: BoxDecoration(
          color: context.colorPalette.boxColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: context.colorPalette.subTitleColor.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                (category != null && category.name.isNotEmpty)
                    ? category.name
                    : 'Select a level-3 category',
                style: TextStyle(
                  fontSize: context.getResponsiveSize(3.5),
                  color: (category == null || category.name.isEmpty)
                      ? context.colorPalette.subTitleColor.withValues(
                          alpha: 0.6,
                        )
                      : AppColors.textDark,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryPickerSheet extends StatefulWidget {
  @override
  State<_CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<_CategoryPickerSheet> {
  late final Future<List<CategoryModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadCategories();
  }

  Future<List<CategoryModel>> _loadCategories() async {
    if (!Get.isRegistered<CategoryController>()) return const [];
    final controller = Get.find<CategoryController>();
    if (controller.allLevel3Categories.isNotEmpty) {
      return controller.allLevel3Categories;
    }
    try {
      await controller.fetchCategoryTree();
    } catch (_) {}
    return controller.allLevel3Categories;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: FutureBuilder<List<CategoryModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final categories = snapshot.data ?? const <CategoryModel>[];
          if (categories.isEmpty) {
            return Center(
              child: Text(
                'No categories available',
                style: TextStyle(
                  fontSize: context.getResponsiveSize(3.6),
                  color: AppColors.textMuted,
                ),
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: EdgeInsets.all(context.getResponsiveSize(4)),
                child: Text(
                  'Select a category',
                  style: TextStyle(
                    fontSize: context.getResponsiveSize(4.2),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  itemCount: categories.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (itemContext, index) {
                    final category = categories[index];
                    return ListTile(
                      title: Text(
                        category.name,
                        style: TextStyle(
                          fontSize: itemContext.getResponsiveSize(3.6),
                          color: AppColors.textDark,
                        ),
                      ),
                      onTap: () =>
                          Navigator.of(itemContext).pop(category),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
