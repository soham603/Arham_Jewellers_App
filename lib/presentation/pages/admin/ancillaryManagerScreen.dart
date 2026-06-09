import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/presentation/controllers/admin/AncillaryController.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';

class AncillaryManagerScreen extends StatefulWidget {
  const AncillaryManagerScreen({super.key});

  @override
  State<AncillaryManagerScreen> createState() => _AncillaryManagerScreenState();
}

class _AncillaryManagerScreenState extends State<AncillaryManagerScreen> {
  final AncillaryController controller = Get.put(AncillaryController());

  @override
  void initState() {
    super.initState();
    controller.fetchAllPages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.pageBg,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Ancillary Pages',
          style: TextStyle(
            fontSize: context.getResponsiveSize(5.5),
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        actions: [
          IconButton(
            onPressed: controller.fetchAllPages,
            icon: Icon(
              Icons.refresh_rounded,
              color: AppColors.textDark,
              size: context.getResponsiveSize(6),
            ),
          ),
        ],
      ),
      body: Obx(() {
        final state = controller.state;

        if (state == CurrentAppState.LOADING && controller.pages.isEmpty) {
          return _buildLoading(context);
        }

        if (state == CurrentAppState.ERROR && controller.pages.isEmpty) {
          return _buildError(context);
        }

        return _buildPageList(context);
      }),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: context.getResponsiveSize(8),
            height: context.getResponsiveSize(8),
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primaryGold,
            ),
          ),
          SizedBox(height: context.getScreenHeight(2)),
          Text(
            'Loading pages...',
            style: TextStyle(
              fontSize: context.getResponsiveSize(3.8),
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.getScreenWidth(8)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: context.getResponsiveSize(14),
              color: Colors.red.shade300,
            ),
            SizedBox(height: context.getScreenHeight(2)),
            Text(
              controller.error.isNotEmpty ? controller.error : 'Failed to load pages',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.getResponsiveSize(3.8),
                color: Colors.red.shade400,
              ),
            ),
            SizedBox(height: context.getScreenHeight(2)),
            ElevatedButton(
              onPressed: controller.fetchAllPages,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageList(BuildContext context) {
    final pages = AncillaryController.pageKeys;
    final labels = AncillaryController.pageLabels;

    return RefreshIndicator(
      onRefresh: controller.fetchAllPages,
      color: AppColors.primaryGold,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(
          horizontal: context.getScreenWidth(4),
          vertical: context.getScreenHeight(2),
        ),
        itemCount: pages.length,
        separatorBuilder: (_, __) => SizedBox(height: context.getScreenHeight(1.5)),
        itemBuilder: (context, index) {
          final key = pages[index];
          final label = labels[key] ?? key;
          final pageData = controller.getPage(key);
          final hasContent = pageData != null && pageData.content.isNotEmpty;

          return GestureDetector(
            onTap: () => _openPageDetail(context, key, label),
            child: Container(
              padding: EdgeInsets.all(context.getScreenWidth(4)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: hasContent
                      ? AppColors.primaryGold.withOpacity(0.3)
                      : const Color(0xFFE7DED2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: context.getResponsiveSize(12),
                    height: context.getResponsiveSize(12),
                    decoration: BoxDecoration(
                      color: hasContent
                          ? AppColors.primaryGold.withOpacity(0.12)
                          : const Color(0xFFF5EFE7),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getPageIcon(key),
                      color: hasContent ? AppColors.primaryGold : AppColors.textMuted,
                      size: context.getResponsiveSize(6),
                    ),
                  ),
                  SizedBox(width: context.getScreenWidth(4)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: context.getResponsiveSize(4.2),
                            color: AppColors.textDark,
                          ),
                        ),
                        SizedBox(height: context.getScreenHeight(0.3)),
                        Text(
                          hasContent
                              ? pageData.title.isNotEmpty
                                  ? pageData.title
                                  : 'Content available'
                              : 'No content yet',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: context.getResponsiveSize(3),
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted,
                    size: context.getResponsiveSize(6),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openPageDetail(BuildContext context, String pageKey, String label) {
    final pageData = controller.getPage(pageKey);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PageDetailSheet(
        pageKey: pageKey,
        label: label,
        existingTitle: pageData?.title ?? '',
        existingContent: pageData?.content ?? '',
      ),
    );
  }

  IconData _getPageIcon(String key) {
    switch (key) {
      case 'TERMS':
        return Icons.description_rounded;
      case 'ABOUT':
        return Icons.info_outline_rounded;
      case 'CONTACT':
        return Icons.contact_mail_rounded;
      case 'PRIVACY':
        return Icons.privacy_tip_rounded;
      case 'REFUND':
        return Icons.replay_rounded;
      case 'CITY_POLICY':
        return Icons.location_city_rounded;
      default:
        return Icons.article_rounded;
    }
  }
}

class _PageDetailSheet extends StatefulWidget {
  final String pageKey;
  final String label;
  final String existingTitle;
  final String existingContent;

  const _PageDetailSheet({
    required this.pageKey,
    required this.label,
    required this.existingTitle,
    required this.existingContent,
  });

  @override
  State<_PageDetailSheet> createState() => _PageDetailSheetState();
}

class _PageDetailSheetState extends State<_PageDetailSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  final AncillaryController controller = Get.find<AncillaryController>();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existingTitle);
    _contentController = TextEditingController(text: widget.existingContent);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: EdgeInsets.fromLTRB(
          context.getScreenWidth(5),
          context.getScreenHeight(2),
          context.getScreenWidth(5),
          context.getScreenHeight(3),
        ),
        decoration: BoxDecoration(
          color: AppColors.pageBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: context.getScreenWidth(10),
                height: context.getScreenHeight(0.5),
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            SizedBox(height: context.getScreenHeight(2)),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Edit ${widget.label}',
                    style: TextStyle(
                      fontSize: context.getResponsiveSize(5),
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: Icon(
                    Icons.close_rounded,
                    color: AppColors.textMuted,
                    size: context.getResponsiveSize(6),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.getScreenHeight(2)),
            TextField(
              controller: _titleController,
              style: TextStyle(
                fontSize: context.getResponsiveSize(4),
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
              decoration: InputDecoration(
                labelText: 'Title',
                labelStyle: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: context.getResponsiveSize(3.5),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.primaryGold,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            SizedBox(height: context.getScreenHeight(1.5)),
            Expanded(
              child: TextField(
                controller: _contentController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: TextStyle(
                  fontSize: context.getResponsiveSize(3.5),
                  color: AppColors.textDark,
                  fontFamily: 'monospace',
                ),
                decoration: InputDecoration(
                  labelText: 'HTML Content',
                  labelStyle: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: context.getResponsiveSize(3.5),
                  ),
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.primaryGold,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: context.getScreenHeight(2)),
            Obx(() {
              final isLoading = controller.updateState == CurrentAppState.LOADING;

              return GestureDetector(
                onTap: isLoading ? null : _save,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: context.getScreenHeight(1.5),
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryGold.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: isLoading
                      ? Center(
                          child: SizedBox(
                            width: context.getScreenWidth(5),
                            height: context.getScreenWidth(5),
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          'Save Changes',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: context.getResponsiveSize(4.2),
                          ),
                        ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _save() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty) {
      Get.snackbar('Required', 'Please enter a title');
      return;
    }

    controller.updatePage(
      pageKey: widget.pageKey,
      title: title,
      content: content,
    );
  }
}
