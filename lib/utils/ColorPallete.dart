import 'package:flutter/material.dart';

class ColorPalette {
  final bool isDarkMode;

  ColorPalette(this.isDarkMode);

  Color get backgroundColor =>
      isDarkMode ? const Color(0xFFFFFFFF) : const Color(0xFFFFFFFF);

  Color get primaryColor =>
      isDarkMode ? const Color(0xFFC6F224) : const Color(0xFFC6F224);

  Color get boxColor =>
      isDarkMode ? const Color(0xffF2F7FE) : const Color(0xffF2F7FE);

  Color get onlyAccentColor => const Color(0xffFFFDD00);

  Color get reversedAccentColor =>
      isDarkMode ? const Color(0xff94368E) : const Color(0xfffffdd00);

  Color get buttonColor =>
      isDarkMode ? const Color(0xff000000) : const Color(0xff000000);

  Color get textColor =>
      isDarkMode ? const Color(0xff000000) : const Color(0xff000000);

  Color get reverseTextColor =>
      isDarkMode ? const Color(0xffFFFFFF) : const Color(0xffFFFFFF);

  Color get lightBackgroundColor =>
      isDarkMode ? const Color(0xFF999999) : const Color(0xFF999999);

  Color get pageBackgroundColor =>
      isDarkMode ? const Color(0xFFF6F6F6) : const Color(0xFFF6F6F6);

  Color get subTitleColor =>
      isDarkMode ? const Color(0xFF767C8F) : const Color(0xFF767C8F);

  Color get shimmerBaseColor => Colors.grey[300]!;

  Color get shimmerHighLightColor => Colors.grey[100]!;

  Color get winnerColor => const Color(0xFFF8FFBF);

  Color get referralColor =>
      isDarkMode ? const Color(0xFFC6F224) : const Color(0xFFC6F224);

  Color get likeColor =>
      isDarkMode ? const Color(0xFFC6F224) : const Color(0xFFC6F224);

  Color get secondaryColor =>
      isDarkMode ? const Color(0xFFE1FC80) : const Color(0xFFE1FC80);

  Color get gold => const Color(0xFFD4AF37);

  Color get goldLight => const Color(0xFFF4EED8);

  Color get goldDark => const Color(0xFF8B6914);

  Color get goldDeep => const Color(0xFF5C4209);

  Color get cream => const Color(0xFFFAF6EE);

  Color get border => const Color(0xFFE8DFCC);

  Color get cardBg => const Color(0xFFFFFFFF);

  Color get chipBg => const Color(0xFFF0E8D0);

  Color get level3Bg => const Color(0xFFF9F4E8);

  Color get productBg => const Color(0xFFFFFBF2);

  Color get k18Accent => const Color(0xFFFFD700);

  Color get k20Accent => const Color(0xFFEAC117);

  Color get k22Accent => const Color(0xFFCFAF34);
}
