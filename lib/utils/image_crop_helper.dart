import 'dart:io';
import 'dart:ui' as ui;

import 'package:croppy/croppy.dart';
import 'package:flutter/material.dart';

/// Opens a Material-style crop/rotate/flip editor and returns the edited
/// [File], or `null` if the user cancelled.
Future<File?> cropImage(
  BuildContext context, {
  required File imageFile,
  double? aspectRatio,
  bool circleUi = false,
}) async {
  final allowedAspectRatios = aspectRatio != null
      ? [
          CropAspectRatio(width: aspectRatio.round(), height: 1),
          CropAspectRatio(width: 1, height: aspectRatio.round()),
        ]
      : null;

  final result = await showMaterialImageCropper(
    context,
    imageProvider: FileImage(imageFile),
    allowedAspectRatios: allowedAspectRatios,
  );

  if (result == null) return null;

  final byteData = await result.uiImage.toByteData(
    format: ui.ImageByteFormat.png,
  );
  if (byteData == null) return null;

  return File.fromRawPath(byteData.buffer.asUint8List());
}
