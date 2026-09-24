import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';

import 'package:ratnesh_gold_app/presentation/controllers/admin/AncillaryController.dart';

class AncillaryEditorScreen extends StatefulWidget {
  final String category;

  const AncillaryEditorScreen({super.key, required this.category});

  @override
  State<AncillaryEditorScreen> createState() => _AncillaryEditorScreenState();
}

class _AncillaryEditorScreenState extends State<AncillaryEditorScreen> {
  static const String _adminContactKey = 'ADMIN_CONTACT';

  final HtmlEditorController controller = HtmlEditorController();
  final TextEditingController _phoneController = TextEditingController();

  late final AncillaryController apiController;

  bool isLoading = true;
  bool isSaving = false;
  String? _phoneError;

  bool get _isPhonePage => widget.category == _adminContactKey;

  @override
  void initState() {
    super.initState();
    apiController = Get.isRegistered<AncillaryController>()
        ? Get.find<AncillaryController>()
        : Get.put(AncillaryController(), permanent: true);
    _loadInitialHtml();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  static String _toNational(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 12 && digits.startsWith('91')) return digits.substring(2);
    if (digits.length == 11 && digits.startsWith('0')) return digits.substring(1);
    return digits.length > 10 ? digits.substring(0, 10) : digits;
  }

  static bool _isValidPhone(String national) =>
      RegExp(r'^[6-9]\d{9}$').hasMatch(national);

  Future<void> _loadInitialHtml() async {
    if (apiController.getPage(widget.category) == null) {
      await apiController.fetchPage(widget.category);
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }

    final page = apiController.getPage(widget.category);
    if (_isPhonePage) {
      _phoneController.text = _toNational(page?.content ?? '');
      return;
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      controller.setText(page?.content ?? "");
    });
  }

  Future<void> _save() async {
    String content;
    if (_isPhonePage) {
      final national = _toNational(_phoneController.text);
      if (!_isValidPhone(national)) {
        setState(() => _phoneError = 'Enter a valid 10-digit mobile number (starting with 6-9).');
        return;
      }
      content = '+91$national';
    } else {
      content = await controller.getText();
    }

    setState(() {
      isSaving = true;
      _phoneError = null;
    });

    final page = apiController.getPage(widget.category);
    final success = await apiController.updatePage(
      pageKey: widget.category,
      title: page?.title ?? widget.category,
      content: content,
    );

    setState(() => isSaving = false);

    if (success) {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textDark,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          _isPhonePage
              ? "Support contact number"
              : "Editing ${widget.category}",
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
            fontSize: context.getResponsiveSize(4.5),
          ),
        ),
        actions: [
          if (isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: Text(
                "Save",
                style: TextStyle(
                  color: AppColors.primaryGold,
                  fontWeight: FontWeight.w800,
                  fontSize: context.getResponsiveSize(4),
                ),
              ),
            ),
        ],
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.primaryGold),
            )
          : _isPhonePage
              ? _buildPhoneForm(context)
              : HtmlEditor(
                  controller: controller,
                  htmlEditorOptions: const HtmlEditorOptions(
                    hint: "Type your HTML content here...",
                    shouldEnsureVisible: true,
                  ),
                  htmlToolbarOptions: const HtmlToolbarOptions(
                    toolbarPosition: ToolbarPosition.aboveEditor,
                    toolbarType: ToolbarType.nativeScrollable,
                  ),
                  otherOptions: const OtherOptions(height: 500),
                ),
    );
  }

  Widget _buildPhoneForm(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(context.getResponsiveSize(4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This number is shown to customers and used in order notifications.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: context.getResponsiveSize(3.6),
            ),
          ),
          SizedBox(height: context.heightPercent(2)),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            onChanged: (_) {
              if (_phoneError != null) setState(() => _phoneError = null);
            },
            style: TextStyle(fontSize: context.getResponsiveSize(4)),
            decoration: InputDecoration(
              labelText: 'Support mobile number',
              hintText: '98765 43210',
              prefixText: '+91 ',
              errorText: _phoneError,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
