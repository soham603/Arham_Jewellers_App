import 'package:flutter/material.dart';
import 'package:ratnesh_gold_app/utils/ColorPallete.dart';

extension AppContextExtensions on BuildContext {
  ColorPalette get colorPalette => ColorPalette();

  double getScreenWidth(double percentage) => MediaQuery.of(this).size.width * (percentage / 100);

  double getScreenHeight(double percentage) => MediaQuery.of(this).size.height * (percentage / 100);

  double getResponsiveSize(double percentage, {double maxTabletWidth = 600, double minSize = 12.0}) {
    final effectiveWidth = MediaQuery.of(this).size.width.clamp(0.0, maxTabletWidth);
    final size = effectiveWidth * (percentage / 100);
    return size < minSize ? minSize : size;
  }

  double responsiveWidth(double phoneVal, {double? tabletVal}) =>
      _isTablet ? (tabletVal ?? phoneVal * 1.15) : phoneVal;

  double responsiveFont(double baseSize, {double tabletMultiplier = 1.1}) =>
      _isTablet ? baseSize * tabletMultiplier : baseSize;

  int gridColumns({int phone = 2, int tablet = 3}) =>
      _isTablet ? tablet : phone;

  bool get _isTablet => MediaQuery.of(this).size.width >= 600;
}
