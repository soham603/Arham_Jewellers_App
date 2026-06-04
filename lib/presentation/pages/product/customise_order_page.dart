import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart'; // 🔥 Added Image Picker
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/domain/entities/productModel.dart';
import 'package:ratnesh_gold_app/presentation/controllers/AuthController.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';

class CustomiseOrderPage extends StatefulWidget {
  final ProductModel? product;

  const CustomiseOrderPage({super.key, this.product});

  @override
  State<CustomiseOrderPage> createState() => _CustomiseOrderPageState();
}

class _CustomiseOrderPageState extends State<CustomiseOrderPage> {
  // State variables for visually selectable chips
  String selectedCarat = '22K (92%)';
  String selectedMarking = 'HUID';
  String selectedStyle = 'Bhungdi';

  static const _caratOptions = [
    '9K  (37%)',
    '14K (58%)',
    '18K (75%)',
    '20K (83%)',
    '22K (92%)',
    '24K (100%)',
  ];

  // Image Picker Variables
  List<File?> referenceImages = [null, null, null, null];
  bool _networkImageFailed = false;
  final ImagePicker _picker = ImagePicker();

  // Form Controllers
  final TextEditingController partyNameCtrl = TextEditingController();
  final TextEditingController partyCodeCtrl = TextEditingController();
  final TextEditingController areaCtrl = TextEditingController();
  final TextEditingController contactCtrl = TextEditingController();
  final TextEditingController itemNameCtrl = TextEditingController();
  final TextEditingController weightCtrl = TextEditingController();
  final TextEditingController noOfPcCtrl = TextEditingController();
  final TextEditingController sizeCtrl = TextEditingController();
  final TextEditingController lengthBroadnessCtrl = TextEditingController();
  final TextEditingController productDescriptionCtrl = TextEditingController();

  bool _isValid(String? value) =>
      value != null && value.trim().isNotEmpty && value.trim().toLowerCase() != 'nan';

  @override
  void initState() {
    super.initState();

    // ── Pre-fill from logged-in user ──
    if (Get.isRegistered<AuthController>()) {
      final user = Get.find<AuthController>().user;
      if (user != null) {
        partyCodeCtrl.text = user.id;
        final partyName = _isValid(user.companyName)
            ? user.companyName!
            : _isValid(user.name)
                ? user.name
                : '';
        partyNameCtrl.text = partyName;
        if (_isValid(user.area)) {
          areaCtrl.text = user.area!;
        }
        if (user.phoneNumber.isNotEmpty) {
          contactCtrl.text = user.phoneNumber;
        }
      }
    }

    // ── Pre-fill from product ──
    if (widget.product != null) {
      final p = widget.product!;

      if (p.grossWeight != null && p.grossWeight! > 0) {
        weightCtrl.text = p.grossWeight!.toStringAsFixed(2);
      } else if (p.rawData != null && p.rawData!['GrossWt'] != null) {
        weightCtrl.text = p.rawData!['GrossWt'].toString();
      }

      if (p.size != null && p.size!.isNotEmpty) {
        sizeCtrl.text = p.size!;
      }

      if (p.karat != null) {
        final karatNum = RegExp(r'(\d+)').firstMatch(p.karat!)?.group(1);
        if (karatNum != null) {
          final match = _caratOptions.where((c) => c.startsWith('${karatNum}K'));
          if (match.isNotEmpty) {
            selectedCarat = match.first;
          }
        }
      }
    }
  }

  @override
  void dispose() {
    partyNameCtrl.dispose();
    partyCodeCtrl.dispose();
    areaCtrl.dispose();
    contactCtrl.dispose();
    itemNameCtrl.dispose();
    weightCtrl.dispose();
    noOfPcCtrl.dispose();
    sizeCtrl.dispose();
    lengthBroadnessCtrl.dispose();
    productDescriptionCtrl.dispose();
    super.dispose();
  }

  // --- Image Picking Logic ---
  void _showImageSourceActionSheet(BuildContext context, int index) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt, color: AppColors.primaryGold),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera, index);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: AppColors.primaryGold),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery, index);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source, int index) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          referenceImages[index] = File(image.path);
        });
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to pick image",
        backgroundColor: Colors.red.shade50,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.pageBg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textDark,
            size: 20,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "Customise Order",
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w800,
            fontSize: context.getScreenWidth(5),
            letterSpacing: 0.5,
          ),
        ),
      ),

      // =====================================================
      // BOTTOM ACTION BAR
      // =====================================================
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: EdgeInsets.fromLTRB(
            context.getScreenWidth(4),
            context.getScreenHeight(1.2),
            context.getScreenWidth(4),
            context.getScreenHeight(1.2),
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGold.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "By continuing you agree to our Terms & Privacy Policy",
                style: TextStyle(
                  fontSize: context.getScreenWidth(2.8),
                  color: AppColors.textMuted,
                ),
              ),
              SizedBox(height: context.getScreenHeight(1.5)),
              SizedBox(
                width: double.infinity,
                height: context.getScreenHeight(6),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 6,
                    shadowColor: AppColors.primaryGold.withOpacity(0.4),
                    backgroundColor: AppColors.primaryGold,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Get.back();
                    Get.snackbar(
                      "Success",
                      "Custom order submitted successfully!",
                      backgroundColor: Colors.green.shade50,
                      colorText: Colors.green.shade800,
                    );
                  },
                  child: Text(
                    'Confirm Custom Order',
                    style: TextStyle(
                      fontSize: context.getScreenWidth(4.2),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: context.getScreenWidth(4),
            vertical: context.getScreenHeight(1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =====================================================
              // 1. CUSTOMER INFORMATION
              // =====================================================
              _buildSectionHeader("Customer Information"),
              _buildCard(
                child: Column(
                  children: [
                    _buildInfoTile("Party Code", partyCodeCtrl.text),
                    _buildInfoDivider(),
                    _buildInfoTile("Party Name", partyNameCtrl.text),
                    _buildInfoDivider(),
                    _buildInfoTile("Area", areaCtrl.text),
                    _buildInfoDivider(),
                    _buildInfoTile("Contact", contactCtrl.text),
                  ],
                ),
              ),

              SizedBox(height: context.getScreenHeight(0.5)),

              // =====================================================
              // 2. PRODUCT SPECIFICATIONS
              // =====================================================
              _buildSectionHeader("Product Specifications"),
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.product?.imageUrl != null &&
                        !_networkImageFailed) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 100,
                            width: 100,
                            decoration: BoxDecoration(
                              color: AppColors.pageBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color:
                                    AppColors.primaryGold.withOpacity(0.25),
                                width: 1.5,
                              ),
                            ),
                            child: _buildMainImageDisplay(),
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: _buildTextField(
                              "Item Name",
                              controller: itemNameCtrl,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 14),
                    ] else
                      _buildTextField(
                        "Item Name",
                        controller: itemNameCtrl,
                      ),
                    SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildTextField(
                            "Weight (g)",
                            controller: weightCtrl,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: _buildTextField(
                            "No. of PC",
                            controller: noOfPcCtrl,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildTextField(
                            "Size",
                            controller: sizeCtrl,
                          ),
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: _buildTextField(
                            "Length/Broad (in)",
                            controller: lengthBroadnessCtrl,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 14),
                    _buildTextField(
                      "Product Description & Requirements",
                      controller: productDescriptionCtrl,
                      maxLines: 3,
                    ),
                    SizedBox(height: 18),

                    // Upload Reference Images
                    _buildLabel("Upload Reference Images (Max 4)"),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _buildImageUploadBox(context, 0)),
                        SizedBox(width: 10),
                        Expanded(child: _buildImageUploadBox(context, 1)),
                        SizedBox(width: 10),
                        Expanded(child: _buildImageUploadBox(context, 2)),
                        SizedBox(width: 10),
                        Expanded(child: _buildImageUploadBox(context, 3)),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: context.getScreenHeight(0.5)),

              // =====================================================
              // 3. CUSTOMIZATION OPTIONS
              // =====================================================
              _buildSectionHeader("Customization Options"),
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Purity"),
                    SizedBox(height: 10),
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildChip("9K  (37%)", selectedCarat,
                                  (val) => setState(() => selectedCarat = val)),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: _buildChip("14K (58%)", selectedCarat,
                                  (val) => setState(() => selectedCarat = val)),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: _buildChip("18K (75%)", selectedCarat,
                                  (val) => setState(() => selectedCarat = val)),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildChip("20K (83%)", selectedCarat,
                                  (val) => setState(() => selectedCarat = val)),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: _buildChip("22K (92%)", selectedCarat,
                                  (val) => setState(() => selectedCarat = val)),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: _buildChip("24K (100%)", selectedCarat,
                                  (val) => setState(() => selectedCarat = val)),
                            ),
                          ],
                        ),
                      ],
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Divider(height: 1, color: AppColors.divider),
                    ),

                    _buildLabel("Style"),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildChip("Bhungdi", selectedStyle,
                              (val) => setState(() => selectedStyle = val)),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildChip("English (Pech)", selectedStyle,
                              (val) => setState(() => selectedStyle = val)),
                        ),
                      ],
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Divider(height: 1, color: AppColors.divider),
                    ),

                    _buildLabel("Marking"),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildChip("No Marking", selectedMarking,
                              (val) => setState(() => selectedMarking = val)),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _buildChip("Hallmark", selectedMarking,
                              (val) => setState(() => selectedMarking = val)),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _buildChip("HUID", selectedMarking,
                              (val) => setState(() => selectedMarking = val)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: context.getScreenHeight(0.5)),

              SizedBox(height: context.getScreenHeight(3)),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI HELPER METHODS ---

  Widget _buildMainImageDisplay() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(13),
      child: CachedNetworkImage(
        imageUrl: widget.product!.imageUrl!,
        fit: BoxFit.cover,
        errorWidget: (context, url, error) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_networkImageFailed) {
              setState(() => _networkImageFailed = true);
            }
          });
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10, top: 14),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.primaryGold,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: context.getScreenWidth(4),
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryGold.withOpacity(0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGold.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: context.getScreenWidth(28),
            child: Text(
              label,
              style: TextStyle(
                fontSize: context.getScreenWidth(3),
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '—',
              style: TextStyle(
                fontSize: context.getScreenWidth(3.3),
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoDivider() {
    return Divider(height: 1, color: AppColors.divider);
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: context.getScreenWidth(3.2),
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
      ),
    );
  }

  Widget _buildTextField(
    String label, {
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool readOnly = false,
  }) {
    if (readOnly) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel(label),
          SizedBox(height: 4),
          Text(
            controller.text,
            style: TextStyle(
              fontSize: context.getScreenWidth(3.5),
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: TextStyle(
            fontSize: context.getScreenWidth(3.3),
            color: AppColors.textDark,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: AppColors.pageBg,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: AppColors.primaryGold,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageUploadBox(BuildContext context, int index) {
    bool hasImage = referenceImages[index] != null;
    return AspectRatio(
      aspectRatio: 1,
      child: GestureDetector(
        onTap: () => _showImageSourceActionSheet(context, index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: hasImage ? Colors.transparent : AppColors.pageBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasImage
                  ? AppColors.primaryGold.withOpacity(0.4)
                  : AppColors.divider,
              width: hasImage ? 1.5 : 1,
            ),
          ),
          child: hasImage
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(referenceImages[index]!, fit: BoxFit.cover),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() => referenceImages[index] = null);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      color: AppColors.primaryGold.withOpacity(0.6),
                      size: 24,
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Add",
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildChip(
    String label,
    String groupValue,
    Function(String) onSelected,
  ) {
    bool isSelected = label == groupValue;
    return GestureDetector(
      onTap: () => onSelected(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGold : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryGold
                : AppColors.divider,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryGold.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textMuted,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: context.getScreenWidth(3.2),
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
