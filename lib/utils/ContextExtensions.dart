import 'package:flutter/material.dart';
import 'package:ratnesh_gold_app/utils/ColorPallete.dart';
import 'package:ratnesh_gold_app/utils/TextThemeDecoration.dart';

extension AppContextExtensions on BuildContext {
  ColorPalette get colorPalette => ColorPalette(Theme.of(this).brightness == Brightness.dark);

  TextThemeDecoration get textThemeDecoration =>
      TextThemeDecoration(Theme.of(this).brightness == Brightness.dark, this);

  double getScreenWidth(double percentage) => MediaQuery.of(this).size.width * (percentage / 100);

  double getScreenHeight(double percentage) => MediaQuery.of(this).size.height * (percentage / 100);

  double get maxContentWidth => 600.0;

  double responsiveWidth(double phoneVal, {double? tabletVal}) =>
      _isTablet ? (tabletVal ?? phoneVal * 1.15) : phoneVal;

  double responsiveFont(double baseSize, {double tabletMultiplier = 1.1}) =>
      _isTablet ? baseSize * tabletMultiplier : baseSize;

  int gridColumns({int phone = 2, int tablet = 3}) =>
      _isTablet ? tablet : phone;

  bool get _isTablet => MediaQuery.of(this).size.width >= 600;

  TargetPlatform get platform => Theme.of(this).platform;
  bool get isIOS => platform == TargetPlatform.iOS;
  bool get isAndroid => platform == TargetPlatform.android;
  bool get isMacOS => platform == TargetPlatform.macOS;
  bool get isWindows => platform == TargetPlatform.windows;
  bool get isWeb => platform == TargetPlatform.fuchsia;
}
