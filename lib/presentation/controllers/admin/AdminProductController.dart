import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide MultipartFile, FormData;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ratnesh_gold_app/core/utils/dio_error_helper.dart';
import 'package:ratnesh_gold_app/data/repositories/product_repository.dart';
import 'package:ratnesh_gold_app/utils/Logger.dart';
import 'package:ratnesh_gold_app/utils/image_crop_helper.dart';

class ProductImageMeta {
  File originalFile;
  CropResult lastResult;
  ProductImageMeta({required this.originalFile, required this.lastResult});
}

Uint8List _compressBytes(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return bytes;

  final longest = decoded.width > decoded.height ? decoded.width : decoded.height;
  final maxEdge = 1200;

  final img.Image resized;
  if (longest > maxEdge) {
    resized = img.copyResize(
      decoded,
      width: decoded.width >= decoded.height ? maxEdge : null,
      height: decoded.height > decoded.width ? maxEdge : null,
      interpolation: img.Interpolation.linear,
    );
  } else {
    resized = decoded;
  }

  return Uint8List.fromList(img.encodeJpg(resized, quality: 80));
}

class AdminProductController extends GetxController {
  static AdminProductController get instance =>
      Get.isRegistered<AdminProductController>()
          ? Get.find<AdminProductController>()
          : Get.put(AdminProductController());

  final _productRepo = ProductRepository();

  final _saving = false.obs;
  bool get saving => _saving.value;

  final _pickedImage = Rxn<File>();
  File? get pickedImage => _pickedImage.value;
  ProductImageMeta? _imageMeta;
  ProductImageMeta? get imageMeta => _imageMeta;

  static Future<File> _compressImageFile(File file) async {
    final bytes = await file.readAsBytes();
    final compressedBytes = await compute(_compressBytes, bytes);
    final tempDir = await getTemporaryDirectory();
    final compressedFile = File(
      '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await compressedFile.writeAsBytes(compressedBytes);
    return compressedFile;
  }

  Future<void> pickImage(BuildContext context) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;
    if (!context.mounted) return;
    final result = await cropImage(context, imageFile: File(picked.path));
    if (result != null) {
      _pickedImage.value = result.file;
      _imageMeta = ProductImageMeta(
        originalFile: File(picked.path),
        lastResult: result,
      );
    }
  }

  void clearPickedImage() {
    _pickedImage.value = null;
    _imageMeta = null;
  }

  void setPickedImage(File file, {ProductImageMeta? meta}) {
    _pickedImage.value = file;
    _imageMeta = meta;
  }

  /// Updates a product via PATCH multipart form-data.
  /// Returns true on success, false on failure.
  Future<bool> updateProduct({
    required String id,
    String? name,
    String? karat,
    String? categoryId,
    bool deleteCurrentImage = false,
    Map<String, dynamic>? rawDataPatch,
  }) async {
    _saving.value = true;

    try {
      final Map<String, dynamic> data = {
        if (name != null && name.trim().isNotEmpty) "name": name.trim(),
        if (karat != null && karat.isNotEmpty) "karat": karat,
        if (categoryId != null && categoryId.isNotEmpty) "categoryId": categoryId,
        if (deleteCurrentImage) "deleteImage": "true",
        if (rawDataPatch != null) "rawDataPatch": jsonEncode(rawDataPatch),
      };

      if (_pickedImage.value != null) {
        data["image"] = await MultipartFile.fromFile(
          (await _compressImageFile(_pickedImage.value!)).path,
          filename: _pickedImage.value!.path.split('/').last,
        );
      }

      final formData = FormData.fromMap(data);

      await _productRepo.updateProduct(
        id: id,
        data: formData,
      );

      _pickedImage.value = null;
      Logger.info("AdminProductController", "Product $id updated");
      return true;
    } catch (e) {
      Logger.error("AdminProductController", "updateProduct error: $e");
      return false;
    } finally {
      _saving.value = false;
    }
  }
}
