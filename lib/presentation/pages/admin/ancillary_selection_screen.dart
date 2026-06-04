import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'ancillary_editor_screen.dart';

class AncillarySelectionScreen extends StatelessWidget {
  const AncillarySelectionScreen({super.key});

  final List<String> categories = const [
    "TERMS",
    "ABOUT",
    "CONTACT",
    "PRIVACY",
    "REFUND",
    "CITY_POLICY",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.pageBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textDark,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "Edit Ancillary Data",
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
            fontSize: context.getScreenWidth(4.5),
          ),
        ),
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(context.getScreenWidth(4)),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return Card(
            elevation: 0,
            margin: EdgeInsets.only(bottom: context.getScreenHeight(1.5)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(
                horizontal: context.getScreenWidth(4),
                vertical: context.getScreenHeight(0.5),
              ),
              title: Text(
                category.replaceAll('_', ' '),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                  fontSize: context.getScreenWidth(4),
                ),
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: AppColors.primaryGold,
              ),
              onTap: () {
                Get.to(() => AncillaryEditorScreen(category: category));
              },
            ),
          );
        },
      ),
    );
  }
}
