import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ratnesh_gold_app/utils/crop_editor_page.dart';

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
