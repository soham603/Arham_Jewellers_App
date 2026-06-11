import 'package:flutter/material.dart';
import 'package:ratnesh_gold_app/utils/ColorPallete.dart';

extension AppContextExtensions on BuildContext {
  ColorPalette get colorPalette => ColorPalette();

  double getScreenWidth(double percentage) => MediaQuery.of(this).size.width * (percentage / 100);

  double getScreenHeight(double percentage) => MediaQuery.of(this).size.height * (percentage / 100);

  double getResponsiveSize(double percentage, {double maxWidth = 800, double minSize = 12.0}) {
    final screenWidth = MediaQuery.of(this).size.width;
    final effectiveWidth = screenWidth.clamp(0.0, maxWidth);
    final size = effectiveWidth * (percentage / 100);
    return size < minSize ? minSize : size;
  }

  double responsiveWidth(double phoneVal, {double? tabletVal, double? largeTabletVal}) {
    if (!_isTablet) return phoneVal;
    if (largeTabletVal != null && _isLargeTablet) return largeTabletVal;
    return tabletVal ?? phoneVal * 1.2;
  }

  double responsiveFont(double baseSize, {double? tabletMultiplier, double? largeTabletMultiplier}) {
    if (!_isTablet) return baseSize;
    if (largeTabletMultiplier != null && _isLargeTablet) return baseSize * largeTabletMultiplier;
    final screenWidth = MediaQuery.of(this).size.width;
    final autoScale = (screenWidth / 600).clamp(1.0, 1.5);
    return baseSize * (tabletMultiplier ?? autoScale);
  }

  int gridColumns({int phone = 2, int tablet = 3}) {
    if (!_isTablet) return phone;
    final width = MediaQuery.of(this).size.width;
    if (width >= 1200) return 5;
    if (width >= 900) return 4;
    return tablet;
  }

  bool get _isTablet => MediaQuery.of(this).size.width >= 600;
  bool get _isLargeTablet => MediaQuery.of(this).size.width >= 1000;
}
