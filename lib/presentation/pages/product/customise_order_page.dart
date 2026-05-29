import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart'; // 🔥 Added Image Picker
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/domain/entities/productModel.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';

class CustomiseOrderPage extends StatefulWidget {
  final ProductModel? product;

  const CustomiseOrderPage({super.key, this.product});

  @override
  State<CustomiseOrderPage> createState() => _CustomiseOrderPageState();
}

class _CustomiseOrderPageState extends State<CustomiseOrderPage> {
  // State variables for visually selectable chips
  String selectedCarat = '22K';
  String selectedMarking = 'HUID';
  String selectedStyle = 'Bhungdi';
  DateTime? deliveryDate;

  // 🔥 Image Picker Variables
  File? mainUploadedImage;
  List<File?> referenceImages = [null, null, null, null];
  final ImagePicker _picker = ImagePicker();

  // Form Controllers
  final TextEditingController partyNameCtrl = TextEditingController();
  final TextEditingController partyCodeCtrl = TextEditingController();
  final TextEditingController areaCtrl = TextEditingController();
  final TextEditingController contactCtrl = TextEditingController();
  final TextEditingController itemNameCtrl = TextEditingController();
  final TextEditingController weightCtrl = TextEditingController();
  final TextEditingController noOfPcCtrl = TextEditingController();
  final TextEditingController noOfItemsCtrl = TextEditingController();
  final TextEditingController sizeCtrl = TextEditingController();
  final TextEditingController lengthBroadnessCtrl = TextEditingController();
  final TextEditingController productDescriptionCtrl = TextEditingController();
  final TextEditingController staffNameCtrl = TextEditingController();
  final TextEditingController orderRemarksCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      itemNameCtrl.text = widget.product!.name;
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
    noOfItemsCtrl.dispose();
    sizeCtrl.dispose();
    lengthBroadnessCtrl.dispose();
    productDescriptionCtrl.dispose();
    staffNameCtrl.dispose();
    orderRemarksCtrl.dispose();
    super.dispose();
  }

  // --- Image Picking Logic ---
  void _showImageSourceActionSheet(
    BuildContext context,
    bool isMain, {
    int index = 0,
  }) {
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
                _pickImage(ImageSource.camera, isMain, index: index);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: AppColors.primaryGold),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery, isMain, index: index);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(
    ImageSource source,
    bool isMain, {
    int index = 0,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          if (isMain) {
            mainUploadedImage = File(image.path);
          } else {
            referenceImages[index] = File(image.path);
          }
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryGold,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != deliveryDate) {
      setState(() {
        deliveryDate = picked;
      });
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
      // PREMIUM BOTTOM ACTION BAR
      // =====================================================
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: EdgeInsets.fromLTRB(
            context.getScreenWidth(5),
            context.getScreenHeight(1.5),
            context.getScreenWidth(5),
            context.getScreenHeight(1.5),
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, -5),
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
                  color: Colors.grey.shade500,
                ),
              ),
              SizedBox(height: context.getScreenHeight(1.5)),
              SizedBox(
                width: double.infinity,
                height: context.getScreenHeight(6.2),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 4,
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
              // 1. CUSTOMER & PRODUCT IMAGE
              // =====================================================
              _buildSectionHeader("Customer Information"),
              _buildModernCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () =>
                                _showImageSourceActionSheet(context, true),
                            child: Container(
                              height: 120,
                              width: 120,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9F6F0),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primaryGold.withOpacity(0.2),
                                ),
                              ),
                              child: _buildMainImageDisplay(),
                            ),
                          ),
                          SizedBox(height: 16),
                          _buildModernTextField(
                            "Party Code",
                            controller: partyCodeCtrl,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildModernTextField(
                            "Party Name",
                            controller: partyNameCtrl,
                          ),
                          SizedBox(height: 16),
                          _buildModernTextField("Area", controller: areaCtrl),
                          SizedBox(height: 16),
                          _buildModernTextField(
                            "Contact Number",
                            controller: contactCtrl,
                            keyboardType: TextInputType.phone,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // =====================================================
              // 2. PRODUCT SPECIFICATIONS
              // =====================================================
              _buildSectionHeader("Product Specifications"),
              _buildModernCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildModernTextField(
                            "Item Name",
                            controller: itemNameCtrl,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: _buildModernTextField(
                            "Weight (g)",
                            controller: weightCtrl,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildModernTextField(
                            "No. of PC",
                            controller: noOfPcCtrl,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildModernTextField(
                            "No. of Items",
                            controller: noOfItemsCtrl,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildModernTextField(
                            "Size",
                            controller: sizeCtrl,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildModernTextField(
                            "Length/Broad (in)",
                            controller: lengthBroadnessCtrl,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    _buildModernTextField(
                      "Product Description & Requirements",
                      controller: productDescriptionCtrl,
                      maxLines: 3,
                    ),

                    SizedBox(height: 20),

                    // Upload Reference Images Box
                    Text(
                      "Upload Reference Images (Max 4)",
                      style: _labelStyle(),
                    ),
                    SizedBox(height: 8),
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

              // =====================================================
              // 3. CUSTOMIZATION OPTIONS
              // =====================================================
              _buildSectionHeader("Customization Options"),
              _buildModernCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Melting Carat", style: _labelStyle()),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildChoiceChip(
                            "18K",
                            selectedCarat,
                            (val) => setState(() => selectedCarat = val),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _buildChoiceChip(
                            "20K",
                            selectedCarat,
                            (val) => setState(() => selectedCarat = val),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _buildChoiceChip(
                            "22K",
                            selectedCarat,
                            (val) => setState(() => selectedCarat = val),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _buildChoiceChip(
                            "24K",
                            selectedCarat,
                            (val) => setState(() => selectedCarat = val),
                          ),
                        ),
                      ],
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Divider(height: 1, color: Colors.grey.shade200),
                    ),

                    Text("Style", style: _labelStyle()),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildChoiceChip(
                            "Bhungdi",
                            selectedStyle,
                            (val) => setState(() => selectedStyle = val),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildChoiceChip(
                            "English",
                            selectedStyle,
                            (val) => setState(() => selectedStyle = val),
                          ),
                        ),
                      ],
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Divider(height: 1, color: Colors.grey.shade200),
                    ),

                    Text("Marking", style: _labelStyle()),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildChoiceChip(
                            "No Marking",
                            selectedMarking,
                            (val) => setState(() => selectedMarking = val),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _buildChoiceChip(
                            "Hallmark",
                            selectedMarking,
                            (val) => setState(() => selectedMarking = val),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _buildChoiceChip(
                            "HUID",
                            selectedMarking,
                            (val) => setState(() => selectedMarking = val),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // =====================================================
              // 4. ORDER DETAILS & REMARKS
              // =====================================================
              _buildSectionHeader("Order Administration"),
              _buildModernCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Delivery Date", style: _labelStyle()),
                    SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F9F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              deliveryDate == null
                                  ? "Select Date"
                                  : "${deliveryDate!.day}/${deliveryDate!.month}/${deliveryDate!.year}",
                              style: TextStyle(
                                color: deliveryDate == null
                                    ? Colors.grey.shade400
                                    : AppColors.textDark,
                                fontSize: context.getScreenWidth(3.5),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Icon(
                              Icons.calendar_month_outlined,
                              color: AppColors.primaryGold,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 16),
                    _buildModernTextField(
                      "Order Confirmed By (Staff Name)",
                      controller: staffNameCtrl,
                    ),

                    SizedBox(height: 16),
                    _buildModernTextField(
                      "Administration Remarks",
                      controller: orderRemarksCtrl,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),

              SizedBox(height: context.getScreenHeight(2)),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI HELPER METHODS ---

  // Displays the correct main image (User Uploaded > Product Image > Placeholder)
  Widget _buildMainImageDisplay() {
    if (mainUploadedImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(mainUploadedImage!, fit: BoxFit.cover),
      );
    } else if (widget.product?.imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: widget.product!.imageUrl!,
          fit: BoxFit.cover,
        ),
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_a_photo_outlined,
            color: AppColors.primaryGold.withOpacity(0.5),
          ),
          SizedBox(height: 4),
          Text(
            "Add Image",
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
        ],
      );
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12, top: 16),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.primaryGold,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: context.getScreenWidth(4.2),
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernCard({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryGold.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildModernTextField(
    String label, {
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle()),
        SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: TextStyle(
            fontSize: context.getScreenWidth(3.5),
            color: AppColors.textDark,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF9F9F9),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primaryGold, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  TextStyle _labelStyle() {
    return TextStyle(
      fontSize: context.getScreenWidth(3.2),
      fontWeight: FontWeight.w700,
      color: Colors.grey.shade600,
    );
  }

  Widget _buildImageUploadBox(BuildContext context, int index) {
    bool hasImage = referenceImages[index] != null;
    return AspectRatio(
      aspectRatio: 1,
      child: GestureDetector(
        onTap: () => _showImageSourceActionSheet(context, false, index: index),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: hasImage
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(referenceImages[index]!, fit: BoxFit.cover),
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
                        color: Colors.grey.shade500,
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

  Widget _buildChoiceChip(
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
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryGold : Colors.grey.shade200,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryGold.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade600,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: context.getScreenWidth(3.2),
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
