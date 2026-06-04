import 'package:flutter/material.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';

class TextThemeDecoration {
  final bool isDarkMode;
  final BuildContext context;

  TextThemeDecoration(this.isDarkMode, this.context);

  double _scale(double size) => context.responsiveFont(size, tabletMultiplier: 1.1);

  static const String interFont = 'Inter';
  static const String instrumentSansFont = 'InstrumentSans';
  static const String generalSans = "GeneralSans";

  TextStyle get titleLarge => TextStyle(
    fontWeight: FontWeight.bold,
    fontFamily: interFont,
    color: context.colorPalette.textColor,
    fontSize: _scale(20),
  );

  TextStyle get titleMedium => TextStyle(
    fontWeight: FontWeight.w500,
    fontFamily: interFont,
    color: context.colorPalette.textColor,
    fontSize: _scale(18),
  );

  TextStyle get titleSmall => TextStyle(
    fontWeight: FontWeight.normal,
    fontFamily: interFont,
    color: context.colorPalette.textColor,
    fontSize: _scale(16),
  );


  TextStyle get subTitleLarge => TextStyle(
    fontWeight: FontWeight.w700,
    fontFamily: instrumentSansFont,
    color: context.colorPalette.textColor,
    fontSize: _scale(15),
  );

  TextStyle get subTitleMedium => TextStyle(
    fontWeight: FontWeight.w500,
    fontFamily: instrumentSansFont,
    color: context.colorPalette.textColor,
    fontSize: _scale(14),
  );

  TextStyle get subTitleSmall => TextStyle(
    fontWeight: FontWeight.w400,
    fontFamily: instrumentSansFont,
    color: context.colorPalette.textColor,
    fontSize: _scale(13),
  );

  TextStyle get paragraphLarge => TextStyle(
    fontWeight: FontWeight.w700,
    fontFamily: generalSans,
    color: context.colorPalette.textColor,
    fontSize: _scale(12),
  );

  TextStyle get paragraphMedium => TextStyle(
    fontWeight: FontWeight.w400,
    fontFamily: generalSans,
    color: context.colorPalette.textColor,
    fontSize: _scale(11),
  );

  TextStyle get paragraphSmall => TextStyle(
    fontWeight: FontWeight.w300,
    fontFamily: generalSans,
    color: context.colorPalette.textColor,
    fontSize: _scale(10),
  );
}
