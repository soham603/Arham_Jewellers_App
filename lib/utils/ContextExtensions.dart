import 'package:flutter/material.dart';
import 'package:ratnesh_gold_app/utils/ColorPallete.dart';
import 'package:ratnesh_gold_app/utils/TextThemeDecoration.dart';

extension ContextExtensions on BuildContext {
  // Get the current theme
  ThemeData get theme => Theme.of(this);

  bool get isDarkMode => theme.brightness == Brightness.dark;

  ColorPalette get colorPalette => ColorPalette(isDarkMode);

  TextThemeDecoration get textThemeDecoration => TextThemeDecoration(isDarkMode, this);

  double getScreenWidth(double percentage) => MediaQuery.of(this).size.width * (percentage / 100);

  double getScreenHeight(double percentage) => MediaQuery.of(this).size.height * (percentage / 100);

  Orientation get orientation => MediaQuery.of(this).orientation;

  bool get isLandscape => orientation == Orientation.landscape;
  bool get isPortrait => orientation == Orientation.portrait;

  TargetPlatform get platform => theme.platform;
  bool get isIOS => platform == TargetPlatform.iOS;
  bool get isAndroid => platform == TargetPlatform.android;
  bool get isMacOS => platform == TargetPlatform.macOS;
  bool get isWindows => platform == TargetPlatform.windows;
  bool get isWeb => platform == TargetPlatform.fuchsia;
}
