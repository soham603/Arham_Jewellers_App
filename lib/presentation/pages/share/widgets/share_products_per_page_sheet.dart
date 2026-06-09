import 'package:flutter/material.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';

class ShareProductsPerPageSheet extends StatefulWidget {
  final Function(int productsPerPage) onSelected;

  const ShareProductsPerPageSheet({super.key, required this.onSelected});

  @override
  State<ShareProductsPerPageSheet> createState() => _ShareProductsPerPageSheetState();
}

class _ShareProductsPerPageSheetState extends State<ShareProductsPerPageSheet> {
  int _selectedValue = 1;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: context.getScreenHeight(2)),
          Text(
            'Products per Page',
            style: TextStyle(
              fontSize: context.getFontSize(4.5),
              fontWeight: FontWeight.w700,
              color: context.colorPalette.textColor,
            ),
          ),
          SizedBox(height: context.getScreenHeight(0.5)),
          Text(
            'Select how many products to show on each page',
            style: TextStyle(
              fontSize: context.getFontSize(3),
              color: context.colorPalette.subTitleColor,
            ),
          ),
          SizedBox(height: context.getScreenHeight(2)),
          _buildOption(context, 1, '1 product per page', 'Full-size images'),
          _buildOption(context, 4, '4 products per page', 'Grid layout'),
          SizedBox(height: context.getScreenHeight(2)),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onSelected(_selectedValue),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colorPalette.gold,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(
                  vertical: context.getScreenHeight(1.2),
                ),
              ),
              child: Text(
                'Generate PDF',
                style: TextStyle(
                  fontSize: context.getFontSize(3.8),
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(height: context.getScreenHeight(0.5)),
        ],
      ),
    );
  }

  Widget _buildOption(BuildContext context, int value, String title, String subtitle) {
    final isSelected = _selectedValue == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedValue = value),
      child: Container(
        margin: EdgeInsets.only(bottom: context.getScreenHeight(0.8)),
        padding: EdgeInsets.all(context.getScreenWidth(3.5)),
        decoration: BoxDecoration(
          color: isSelected
              ? context.colorPalette.gold.withOpacity(0.08)
              : context.colorPalette.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? context.colorPalette.gold
                : context.colorPalette.border,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: context.getScreenWidth(5),
              height: context.getScreenWidth(5),
              decoration: BoxDecoration(
                color: isSelected
                    ? context.colorPalette.gold
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? context.colorPalette.gold
                      : context.colorPalette.border,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      size: context.getFontSize(2.5),
                      color: Colors.white,
                    )
                  : null,
            ),
            SizedBox(width: context.getScreenWidth(3)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: context.getFontSize(3.5),
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? context.colorPalette.goldDeep
                          : context.colorPalette.textColor,
                    ),
                  ),
                  SizedBox(height: context.getScreenHeight(0.2)),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: context.getFontSize(2.8),
                      color: context.colorPalette.subTitleColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
