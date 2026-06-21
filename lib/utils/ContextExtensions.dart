import 'package:flutter/material.dart';
import 'package:ratnesh_gold_app/utils/ColorPallete.dart';

class Breakpoints {
  Breakpoints._();

  static const double tabletWidth = 600;
  static const double largeTabletWidth = 1000;
  static const double desktopWidth = 1200;
  static const double wideTabletWidth = 900;
  static const double clampMaxWidth = 800;
  static const double minResponsiveSize = 12.0;
  static const double defaultPhoneScale = 1.2;
}

extension AppContextExtensions on BuildContext {
  ColorPalette get colorPalette => const ColorPalette();

  double widthPercent(double percentage) => MediaQuery.sizeOf(this).width * (percentage / 100);

  double heightPercent(double percentage) => MediaQuery.sizeOf(this).height * (percentage / 100);

  double getResponsiveSize(double percentage, {double maxWidth = Breakpoints.clampMaxWidth, double minSize = Breakpoints.minResponsiveSize}) {
    final screenWidth = MediaQuery.sizeOf(this).width;
    final effectiveWidth = screenWidth.clamp(0.0, maxWidth);
    final size = effectiveWidth * (percentage / 100);
    return size < minSize ? minSize : size;
  }

  double responsiveWidth(double phoneVal, {double? tabletVal, double? largeTabletVal}) {
    final width = MediaQuery.sizeOf(this).width;
    if (!_checkTablet(width)) return phoneVal;
    if (largeTabletVal != null && _checkLargeTablet(width)) return largeTabletVal;
    return tabletVal ?? phoneVal * Breakpoints.defaultPhoneScale;
  }

  double responsiveFont(double baseSize, {double? tabletMultiplier, double? largeTabletMultiplier}) {
    final textScaler = MediaQuery.textScalerOf(this);
    final width = MediaQuery.sizeOf(this).width;
    if (!_checkTablet(width)) return textScaler.scale(baseSize);
    if (largeTabletMultiplier != null && _checkLargeTablet(width)) return textScaler.scale(baseSize * largeTabletMultiplier);
    final autoScale = (width / Breakpoints.tabletWidth).clamp(1.0, 1.5);
    return textScaler.scale(baseSize * (tabletMultiplier ?? autoScale));
  }

  int gridColumns({int phone = 2, int tablet = 3}) {
    final width = MediaQuery.sizeOf(this).width;
    if (!_checkTablet(width)) return phone;
    if (width >= Breakpoints.desktopWidth) return 5;
    if (width >= Breakpoints.wideTabletWidth) return 4;
    return tablet;
  }

  bool _checkTablet(double width) => width >= Breakpoints.tabletWidth;
  bool _checkLargeTablet(double width) => width >= Breakpoints.largeTabletWidth;
}
