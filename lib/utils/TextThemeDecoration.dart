import 'package:flutter/material.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';

class TextThemeDecoration {
  final bool isDarkMode;
  final BuildContext context;

  TextThemeDecoration(this.isDarkMode, this.context);

  static const String interFont = 'Inter';
  static const String instrumentSansFont = 'InstrumentSans';
  static const String generalSans = "GeneralSans";

  TextStyle get titleLarge => TextStyle(
    fontWeight: FontWeight.bold,
    fontFamily: interFont,
    color: context.colorPalette.textColor,
    fontSize: 20,
  );

  TextStyle get titleMedium => TextStyle(
    fontWeight: FontWeight.w500,
    fontFamily: interFont,
    color: context.colorPalette.textColor,
    fontSize: 18,
  );

  TextStyle get titleSmall => TextStyle(
    fontWeight: FontWeight.normal, // Regular
    fontFamily: interFont,
    color: context.colorPalette.textColor,
    fontSize: 16,
  );


  TextStyle get subTitleLarge => TextStyle(
    fontWeight: FontWeight.w700,
    fontFamily: instrumentSansFont,
    color: context.colorPalette.textColor,
    fontSize: 15,
  );

  TextStyle get subTitleMedium => TextStyle(
    fontWeight: FontWeight.w500,
    fontFamily: instrumentSansFont,
    color: context.colorPalette.textColor,
    fontSize: 14,
  );

  TextStyle get subTitleSmall => TextStyle(
    fontWeight: FontWeight.w400,
    fontFamily: instrumentSansFont,
    color: context.colorPalette.textColor,
    fontSize: 13,
  );

  TextStyle get paragraphLarge => TextStyle(
    fontWeight: FontWeight.w700,
    fontFamily: generalSans,
    color: context.colorPalette.textColor,
    fontSize: 12,
  );

  TextStyle get paragraphMedium => TextStyle(
    fontWeight: FontWeight.w400,
    fontFamily: generalSans,
    color: context.colorPalette.textColor,
    fontSize: 11,
  );

  TextStyle get paragraphSmall => TextStyle(
    fontWeight: FontWeight.w300,
    fontFamily: generalSans,
    color: context.colorPalette.textColor,
    fontSize: 10,
  );
}
