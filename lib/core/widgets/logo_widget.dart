import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

class LogoWidget extends StatelessWidget {
  const LogoWidget({
    super.key,
    this.logoSize = 44,
    this.showIcon = true,
    this.showName = true,
    this.showSubtitle = true,
    this.iconColor,
    this.nameColor,
    this.subtitleColor,
    this.nameFontSize,
    this.subtitleFontSize,
    this.nameLetterSpacing = 2,
    this.iconNameSpacing = 8,
    this.nameSubtitleSpacing = 4,
  });

  final double logoSize;
  final bool showIcon;
  final bool showName;
  final bool showSubtitle;
  final Color? iconColor;
  final Color? nameColor;
  final Color? subtitleColor;
  final double? nameFontSize;
  final double? subtitleFontSize;
  final double nameLetterSpacing;
  final double iconNameSpacing;
  final double nameSubtitleSpacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcon)
          Image.asset(
            'assets/images/ratnesh-logo.png',
            height: logoSize,
            fit: BoxFit.contain,
            color: iconColor ?? AppColors.primaryGold,
            colorBlendMode: BlendMode.srcIn,
          ),
        if (showIcon && showName) SizedBox(height: iconNameSpacing),
        if (showName)
          Text(
            'RATNESHGOLD',
            style: GoogleFonts.bodoniModa(
              fontSize: nameFontSize ?? 16,
              fontWeight: FontWeight.w900,
              letterSpacing: nameLetterSpacing,
              color: nameColor ?? AppColors.textDark,
            ),
          ),
        if (showName && showSubtitle) SizedBox(height: nameSubtitleSpacing),
        if (showSubtitle)
          Text(
            'Purity • Quality • Trust',
            style: TextStyle(
              fontSize: subtitleFontSize ?? 11,
              color: subtitleColor ?? AppColors.textMuted,
              letterSpacing: 0.3,
            ),
          ),
      ],
    );
  }
}
