import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:ratnesh_gold_app/utils/ToastUtil.dart';

import 'package:ratnesh_gold_app/presentation/controllers/admin/AncillaryController.dart';

class AncillaryEditorScreen extends StatefulWidget {
  final String category;

  const AncillaryEditorScreen({super.key, required this.category});

  @override
  State<AncillaryEditorScreen> createState() => _AncillaryEditorScreenState();
}

class _AncillaryEditorScreenState extends State<AncillaryEditorScreen> {
  final HtmlEditorController controller = HtmlEditorController();

  final AncillaryController apiController = Get.put(AncillaryController());

  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadInitialHtml();
  }

  Future<void> _loadInitialHtml() async {
    await apiController.fetchPage(widget.category);

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }

    final page = apiController.getPage(widget.category);
    Future.delayed(const Duration(milliseconds: 500), () {
      controller.setText(page?.content ?? "");
    });
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
          "Editing ${widget.category}",
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
              onPressed: () async {
                setState(() => isSaving = true);

                final htmlText = await controller.getText();
                final page = apiController.getPage(widget.category);
                final success = await apiController.updatePage(
                  pageKey: widget.category,
                  title: page?.title ?? widget.category,
                  content: htmlText,
                );

                setState(() => isSaving = false);

                if (success) {
                  ToastUtils.showSuccess(
                    context,
                    "Successfully updated ${widget.category}",
                  );
                  Get.back();
                } else {
                  ToastUtils.showError(
                    context,
                    "Failed to save ${widget.category}",
                  );
                }
              },
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
}
