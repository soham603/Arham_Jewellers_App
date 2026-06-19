import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ratnesh_gold_app/utils/crop_editor_page.dart';

/// Initial state for the crop editor (rotation + flip).
/// Optionally carries an initial crop rect.
class CropInitialState {
  final double rotationDegrees;
  final bool flipY;
  final Rect? cropRect;

  const CropInitialState({
    this.rotationDegrees = 0,
    this.flipY = false,
    this.cropRect,
  });
}

/// Result returned by the crop editor: the edited file + edit state.
class CropResult {
  final File file;
  final double rotationDegrees;
  final bool flipY;

  const CropResult({
    required this.file,
    this.rotationDegrees = 0,
    this.flipY = false,
  });
}

/// Opens a crop/rotate/flip editor and returns the edited [CropResult],
/// or `null` if the user cancelled.
Future<CropResult?> cropImage(
  BuildContext context, {
  required File imageFile,
  double? aspectRatio,
  bool circleUi = false,
  CropInitialState? initialState,
}) async {
  final result = await Navigator.of(context).push<CropResult>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => CropEditorPage(
        imageFile: imageFile,
        aspectRatio: aspectRatio,
        initialState: initialState,
      ),
    ),
  );

  return result;
}
