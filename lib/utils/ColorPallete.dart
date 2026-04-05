import 'package:flutter/material.dart';

class ColorPalette {
  final bool isDarkMode;

  ColorPalette(this.isDarkMode);

  Color get backgroundColor => isDarkMode ? Color(0xFFFFFFFF) : Color(0xFFFFFFFF);

  Color get primaryColor => isDarkMode ? Color(0xFFC6F224) : Color(0xFFC6F224);

  Color get boxColor => isDarkMode ? const Color(0xffF2F7FE) : const Color(0xffF2F7FE);

  Color get onlyAccentColor => const Color(0xffFFFDD00);

  Color get reversedAccentColor => isDarkMode ? const Color(0xff94368E) : const Color(0xfffffdd00);

  Color get buttonColor => isDarkMode ? const Color(0xff000000) : const Color(0xff000000);

  Color get textColor => isDarkMode ? const Color(0xff000000) : const Color(0xff000000);

  Color get reverseTextColor => isDarkMode ? const Color(0xffFFFFFF) : const Color(0xffFFFFFF);

  Color get lightBackgroundColor => isDarkMode ? Color(0xFF999999) : Color(0xFF999999);

  Color get pageBackgroundColor => isDarkMode ? Color(0xFFF6F6F6) : Color(0xFFF6F6F6);

  Color get subTitleColor => isDarkMode ? Color(0xFF767C8F) : Color(0xFF767C8F);

  Color get shimmerBaseColor => Colors.grey[300]!;

  Color get shimmerHighLightColor => Colors.grey[100]!;

  Color get winnerColor => Color(0xFFF8FFBF);

  Color get referralColor => isDarkMode ? Color(0xFFC6F224) : Color(0xFFC6F224);

  Color get likeColor => isDarkMode ? Color(0xFFC6F224) : Color(0xFFC6F224) ;

  Color get secondaryColor => isDarkMode ? Color(0xFFE1FC80) : Color(0xFFE1FC80) ;

}