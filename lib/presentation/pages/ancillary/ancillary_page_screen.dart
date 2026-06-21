import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/presentation/controllers/admin/AncillaryController.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';
import 'package:url_launcher/url_launcher.dart';

class AncillaryPageScreen extends StatefulWidget {
  const AncillaryPageScreen({super.key});

  @override
  State<AncillaryPageScreen> createState() => _AncillaryPageScreenState();
}

class _AncillaryPageScreenState extends State<AncillaryPageScreen> {
  late final AncillaryController controller;
  late final String pageKey;
  bool _fetched = false;

  @override
  void initState() {
    super.initState();
    pageKey = Get.arguments as String? ?? 'TERMS';
    if (Get.isRegistered<AncillaryController>()) {
      controller = Get.find<AncillaryController>();
    } else {
      controller = Get.put(AncillaryController());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_fetched) {
      _fetched = true;
      controller.fetchPage(pageKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = AncillaryController.pageLabels[pageKey] ?? pageKey;

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.pageBg,
        elevation: 0,
        centerTitle: false,
        title: Text(
          label,
          style: TextStyle(
            fontSize: context.getResponsiveSize(5.5),
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
      ),
      body: Obx(() {
        final state = controller.state;
        final page = controller.getPage(pageKey);

        if (state == CurrentAppState.LOADING && page == null) {
          return Center(
            child: SizedBox(
              width: context.getResponsiveSize(8),
              height: context.getResponsiveSize(8),
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primaryGold,
              ),
            ),
          );
        }

        if (state == CurrentAppState.ERROR && page == null) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(context.getResponsiveSize(8)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: context.getResponsiveSize(14),
                    color: Colors.red.shade300,
                  ),
                  SizedBox(height: context.heightPercent(2)),
                  Text(
                    controller.error.isNotEmpty
                        ? controller.error
                        : 'Failed to load content',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: context.getResponsiveSize(3.8),
                      color: Colors.red.shade400,
                    ),
                  ),
                  SizedBox(height: context.heightPercent(2)),
                  ElevatedButton(
                    onPressed: () => controller.fetchPage(pageKey),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Retry',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (page == null || page.content.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.article_outlined,
                  size: context.getResponsiveSize(14),
                  color: AppColors.textMuted.withValues(alpha: 0.4),
                ),
                SizedBox(height: context.heightPercent(1)),
                Text(
                  'No content available',
                  style: TextStyle(
                    fontSize: context.getResponsiveSize(4),
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: context.getResponsiveSize(4),
            vertical: context.heightPercent(2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Html(
                data: page.content,
                style: {
                  'body': Style(
                    fontSize: FontSize(context.getResponsiveSize(3.8)),
                    color: AppColors.textDark,
                    lineHeight: LineHeight.em(1.6),
                  ),
                  'h1': Style(
                    fontSize: FontSize(context.getResponsiveSize(5.5)),
                    fontWeight: FontWeight.w700,
                  ),
                  'h2': Style(
                    fontSize: FontSize(context.getResponsiveSize(5)),
                    fontWeight: FontWeight.w700,
                  ),
                  'h3': Style(
                    fontSize: FontSize(context.getResponsiveSize(4.5)),
                    fontWeight: FontWeight.w600,
                  ),
                  'p': Style(margin: Margins.only(bottom: 12)),
                  'a': Style(
                    color: AppColors.primaryGold,
                    textDecoration: TextDecoration.underline,
                  ),
                },
                onLinkTap: (url, attributes, element) {
                  if (url != null) {
                    launchUrl(Uri.parse(url));
                  }
                },
              ),
            ],
          ),
        );
      }),
    );
  }
}
