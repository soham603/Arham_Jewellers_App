import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/core/widgets/image_action_sheet.dart';
import 'package:ratnesh_gold_app/domain/entities/category_model.dart';
import 'package:ratnesh_gold_app/domain/entities/productModel.dart';
import 'package:ratnesh_gold_app/presentation/controllers/admin/AdminProductController.dart';
import 'package:ratnesh_gold_app/presentation/controllers/CategoryController.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:ratnesh_gold_app/utils/ToastUtil.dart';
import 'package:ratnesh_gold_app/utils/image_crop_helper.dart';
import 'package:ratnesh_gold_app/utils/network_image_to_file.dart';
import 'package:ratnesh_gold_app/presentation/pages/admin/raw_data_page.dart';

class ProductEditPage extends StatefulWidget {
  final ProductModel product;

  const ProductEditPage({super.key, required this.product});

  @override
  State<ProductEditPage> createState() => _ProductEditPageState();
}

class _ProductEditPageState extends State<ProductEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late String _selectedKarat;
  late bool _isActive;
  String? _selectedLevel2Id;
  String? _selectedCategoryId;
  bool _isDeleteImage = false;

  late final AdminProductController _adminCtrl;
  Map<String, dynamic>? _rawDataPatch;

  CategoryController get _catCtrl => CategoryController.instance;

  bool get _hasExistingImage =>
      widget.product.imageUrl != null && widget.product.imageUrl!.isNotEmpty;

  List<CategoryModel> get _level2Categories {
    switch (_selectedKarat) {
      case '0K':
        return _catCtrl.k0Categories;
      case '18K':
        return _catCtrl.k18Categories;
      case '20K':
        return _catCtrl.k20Categories;
      case '22K':
        return _catCtrl.k22Categories;
      default:
        return [];
    }
  }

  List<CategoryModel> get _level3Categories {
    if (_selectedLevel2Id == null) return [];
    return _catCtrl.level3Cache[_selectedLevel2Id] ?? [];
  }

  List<String> get _availableKarats {
    final karats = <String>{};
    if (_catCtrl.k0Categories.isNotEmpty) karats.add('0K');
    if (_catCtrl.k18Categories.isNotEmpty) karats.add('18K');
    if (_catCtrl.k20Categories.isNotEmpty) karats.add('20K');
    if (_catCtrl.k22Categories.isNotEmpty) karats.add('22K');
    if (karats.isEmpty) {
      karats.addAll(['18K', '20K', '22K']);
    }
    return karats.toList()..sort();
  }

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.product.name);
    _selectedKarat = widget.product.karat ?? '22K';
    _isActive = widget.product.isActive;

    _adminCtrl = Get.isRegistered<AdminProductController>()
        ? Get.find<AdminProductController>()
        : Get.put(AdminProductController());

    _initCategorySelections();
  }

  void _initCategorySelections() {
    final productCategory = widget.product.category;
    if (productCategory == null) return;

    _selectedCategoryId = productCategory.id;

    // Find parent level2 from the cached tree instead of relying on productCategory.parentId
    _selectedLevel2Id = _catCtrl.getParentLevel2Id(productCategory.id);

    // Determine karat from the category hierarchy
    final karatFromCategory = _catCtrl.getLevel3Karat(productCategory.id);
    if (karatFromCategory != null) {
      _selectedKarat = karatFromCategory.toUpperCase();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    if (Get.isRegistered<AdminProductController>()) {
      Get.delete<AdminProductController>();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    await _adminCtrl.pickImage(context);
    if (_adminCtrl.pickedImage != null) {
      setState(() {
        _isDeleteImage = false;
      });
    }
  }

  void _showImageAction() {
    final hasPicked = _adminCtrl.pickedImage != null;
    final hasAny = hasPicked || _hasExistingImage;

    if (hasAny) {
      showImageActionSheet(
        context,
        onEdit: () async {
          if (hasPicked) {
            final originalFile = _adminCtrl.imageMeta?.originalFile ?? _adminCtrl.pickedImage!;
            final initialState = _adminCtrl.imageMeta != null
                ? CropInitialState(
                    rotationDegrees: _adminCtrl.imageMeta!.lastResult.rotationDegrees,
                    flipY: _adminCtrl.imageMeta!.lastResult.flipY,
                  )
                : null;
            final result = await cropImage(
              context,
              imageFile: originalFile,
              initialState: initialState,
            );
            if (result != null) {
              final newMeta = ProductImageMeta(
                originalFile: originalFile,
                lastResult: result,
              );
              _adminCtrl.clearPickedImage();
              _adminCtrl.setPickedImage(result.file, meta: newMeta);
              setState(() {
                _isDeleteImage = false;
              });
            }
          } else if (_hasExistingImage) {
            final localFile = await downloadNetworkImageToFile(
              widget.product.imageUrl!,
            );
            if (localFile != null && context.mounted) {
              final result = await cropImage(
                context,
                imageFile: localFile,
              );
              if (result != null) {
                final newMeta = ProductImageMeta(
                  originalFile: localFile,
                  lastResult: result,
                );
                _adminCtrl.setPickedImage(result.file, meta: newMeta);
                setState(() {
                  _isDeleteImage = false;
                });
              }
            }
          }
        },
        onUpload: _pickImage,
        onRemove: () {
          setState(() {
            _isDeleteImage = true;
          });
          _adminCtrl.clearPickedImage();
        },
      );
    } else {
      _pickImage();
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final (error, successMsg) = await _adminCtrl.updateProduct(
      id: widget.product.id,
      name: _nameCtrl.text.trim(),
      karat: _selectedKarat,
      categoryId: _selectedCategoryId,
      isActive: _isActive,
      deleteCurrentImage: _isDeleteImage,
      rawDataPatch: _rawDataPatch,
    );

    if (error == null && mounted) {
      widget.product.isActive = _isActive;
      ToastUtils.showSuccess(successMsg ?? 'Product updated');
      Navigator.of(context).pop(true);
    } else if (mounted) {
      ToastUtils.showError(error ?? 'Something went wrong');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        title: const Text('Edit Product'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  context.getResponsiveSize(5),
                  context.heightPercent(2),
                  context.getResponsiveSize(5),
                  context.heightPercent(1),
                ),
                children: [
                  // Image Section
                  _label('Product Image'),
                  SizedBox(height: context.heightPercent(0.8)),
                  Center(
                    child: SizedBox(
                      width: context.heightPercent(18),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: GestureDetector(
                          onTap: _showImageAction,
                            child: Container(
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _adminCtrl.pickedImage != null
                                      ? AppColors.primaryGold
                                      : Colors.grey.shade300,
                                  width: _adminCtrl.pickedImage != null ? 2 : 1,
                                ),
                              color: Colors.grey.shade100,
                            ),
                            child: _buildImagePreview(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: context.heightPercent(2.5)),

                  // Name
                  _label('Name'),
                  SizedBox(height: context.heightPercent(0.6)),
                  TextFormField(
                    controller: _nameCtrl,
                    style: TextStyle(
                      fontSize: context.getResponsiveSize(3.8),
                      color: AppColors.textDark,
                    ),
                    decoration: _inputDec('Enter product name'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  SizedBox(height: context.heightPercent(2)),

                  // Karat
                  _label('Karat'),
                  SizedBox(height: context.heightPercent(0.6)),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedKarat,
                    decoration: _inputDec('Select karat'),
                    items: _availableKarats.map((k) {
                      return DropdownMenuItem(value: k, child: Text(k));
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          _selectedKarat = v;
                          _selectedLevel2Id = null;
                          _selectedCategoryId = null;
                        });
                      }
                    },
                  ),
                  SizedBox(height: context.heightPercent(2)),

                  // Collection (Level 2)
                  _label('Collection'),
                  SizedBox(height: context.heightPercent(0.6)),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedLevel2Id,
                    decoration: _inputDec(
                      _level2Categories.isEmpty
                          ? 'No collections for $_selectedKarat'
                          : 'Select collection',
                    ),
                    isExpanded: true,
                    items: _level2Categories.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat.id,
                        child: Text(cat.name, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: _level2Categories.isEmpty
                        ? null
                        : (v) {
                            setState(() {
                              _selectedLevel2Id = v;
                              _selectedCategoryId = null;
                            });
                          },
                    validator: (v) {
                      if (_selectedLevel2Id == null && _level2Categories.isNotEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: context.heightPercent(2)),

                  // Style (Level 3)
                  _label('Style'),
                  SizedBox(height: context.heightPercent(0.6)),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategoryId,
                    decoration: _inputDec(
                      _level3Categories.isEmpty && _selectedLevel2Id != null
                          ? 'No styles available'
                          : 'Select style',
                    ),
                    isExpanded: true,
                    items: _level3Categories.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat.id,
                        child: Text(cat.name, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: _level3Categories.isEmpty
                        ? null
                        : (v) => setState(() => _selectedCategoryId = v),
                    validator: (v) {
                      if (_selectedCategoryId == null) {
                        return _level3Categories.isEmpty
                            ? 'No styles available for this collection'
                            : 'Required';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: context.heightPercent(2)),

                  // Active Status
                  _label('Status'),
                  SizedBox(height: context.heightPercent(0.6)),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.getResponsiveSize(4),
                      vertical: context.heightPercent(0.8),
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade300),
                      color: Colors.white,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isActive ? Icons.check_circle : Icons.cancel,
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
                                  fontSize: context.getResponsiveSize(3.5),
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                ),
                              ),
                              Text(
                                _isActive ? 'Product is visible to users' : 'Product is hidden from users',
                                style: TextStyle(
                                  fontSize: context.getResponsiveSize(2.5),
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
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

                  // Raw Data
                  GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push<Map<String, dynamic>>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RawDataPage(
                            rawData: widget.product.rawData ?? {},
                          ),
                        ),
                      );
                      if (result != null && result.isNotEmpty) {
                        _rawDataPatch = result;
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.getResponsiveSize(4),
                        vertical: context.heightPercent(1.2),
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.4)),
                        color: AppColors.primaryGold.withValues(alpha: 0.06),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.table_chart_outlined,
                            size: context.getResponsiveSize(4.5),
                            color: AppColors.primaryGold,
                          ),
                          SizedBox(width: context.getResponsiveSize(2)),
                          Text(
                            'View All Raw Data',
                            style: TextStyle(
                              fontSize: context.getResponsiveSize(3.5),
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryGold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: context.heightPercent(1)),
                ],
              ),
            ),

            // Save Button - fixed at bottom
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.getResponsiveSize(5),
                0,
                context.getResponsiveSize(5),
                context.heightPercent(2),
              ),
              child: Obx(() => SizedBox(
                width: double.infinity,
                height: context.heightPercent(6.5),
                child: ElevatedButton(
                  onPressed: _adminCtrl.saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppColors.primaryGold.withValues(alpha: 0.5),
                    elevation: 3,
                    shadowColor: AppColors.primaryGold.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _adminCtrl.saving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: context.getResponsiveSize(4),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_adminCtrl.pickedImage != null) {
      return Image.file(_adminCtrl.pickedImage!, fit: BoxFit.cover);
    }
    if (_hasExistingImage) {
      return CachedNetworkImage(
        imageUrl: widget.product.imageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryGold,
            strokeWidth: 2,
          ),
        ),
        errorWidget: (context, url, error) => _imagePlaceholder(),
      );
    }
    return _imagePlaceholder();
  }

  Widget _imagePlaceholder() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: context.getResponsiveSize(10),
            color: Colors.grey.shade400,
          ),
          SizedBox(height: context.heightPercent(0.5)),
          Text(
            'Tap to add image',
            style: TextStyle(
              fontSize: context.getResponsiveSize(2.8),
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: context.getResponsiveSize(3.2),
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
      ),
    );
  }

  InputDecoration _inputDec(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(
        horizontal: context.getResponsiveSize(4),
        vertical: context.heightPercent(1.2),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primaryGold, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}
