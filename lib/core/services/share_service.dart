import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:ratnesh_gold_app/domain/entities/productModel.dart';
import 'package:ratnesh_gold_app/domain/entities/admin/adminOrderModel.dart';
import 'package:ratnesh_gold_app/services/Dependencies.dart';
import 'package:ratnesh_gold_app/core/constants/ApiUrlConstants.dart';
import 'package:ratnesh_gold_app/core/constants/image_constants.dart';
import 'package:ratnesh_gold_app/core/services/pdf_cache.dart';

class ShareToWhatsAppResult {
  final bool success;
  final String? filePath;
  final String? fileName;

  const ShareToWhatsAppResult({
    required this.success,
    this.filePath,
    this.fileName,
  });
}

class ShareService {
  static const String _brandName = 'SHREE ARHAM GOLD & RATNESH GOLD';
  static const String _brandSubtitle = 'Purity - Quality - Trust';

  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  static Future<Uint8List> _loadLogoBytes(String path) async {
    final data = await rootBundle.load(path);
    return data.buffer.asUint8List();
  }

  static String _buildShareText(String filterInfo, {String? title}) {
    if (title != null && title.isNotEmpty) {
      return '$_brandName\n$_brandSubtitle\n\n$title';
    }
    return '$_brandName\n$_brandSubtitle\n\n$filterInfo';
  }

  static Future<Uint8List?> _downloadAndCompressImage(
    String imageUrl, {
    int? maxLongestEdge,
    int quality = ImageCompressionConstants.shareQuality,
  }) async {
    try {
      final response = await _dio.get<List<int>>(
        imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      if (response.statusCode == 200 && response.data != null) {
        final bytes = Uint8List.fromList(response.data!);
        if (maxLongestEdge == null) return bytes;
        return _compressImage(bytes, maxLongestEdge: maxLongestEdge, quality: quality);
      }
    } catch (e) {
    }
    return null;
  }

  static Uint8List? _compressImage(
    Uint8List bytes, {
    int maxLongestEdge = ImageCompressionConstants.shareMaxEdge,
    int quality = ImageCompressionConstants.shareQuality,
  }) {
    final decoded = img.decodeJpg(bytes);
    if (decoded == null) return bytes;

    final longest = decoded.width > decoded.height ? decoded.width : decoded.height;
    if (longest <= maxLongestEdge) return bytes;

    final resized = img.copyResize(
      decoded,
      width: decoded.width >= decoded.height ? maxLongestEdge : null,
      height: decoded.height > decoded.width ? maxLongestEdge : null,
      interpolation: img.Interpolation.linear,
    );

    return Uint8List.fromList(img.encodeJpg(resized, quality: quality));
  }

  static Future<List<Uint8List?>> _downloadImageUrls({
    required List<String?> urls,
    ValueNotifier<double>? progress,
    ValueNotifier<bool>? cancelled,
    double rangeStart = 0.0,
    double rangeEnd = 1.0,
  }) async {
    const batchSize = 12;
    final result = <Uint8List?>[];
    final total = urls.length;

    if (total == 0) return result;

    for (int i = 0; i < total; i += batchSize) {
      if (cancelled?.value == true) return result;

      final batchEnd = (i + batchSize).clamp(0, total);
      final batch = urls.sublist(i, batchEnd);

      final downloadFutures = batch.map((url) async {
        if (url == null || url.isEmpty) return null;
        try {
          final response = await _dio.get<List<int>>(
            url,
            options: Options(responseType: ResponseType.bytes),
          );
          if (response.statusCode == 200 && response.data != null) {
            return Uint8List.fromList(response.data!);
          }
        } catch (e) {
        }
        return null;
      }).toList();

      final rawBytes = await Future.wait(downloadFutures);
      result.addAll(rawBytes);

      final fraction = batchEnd / total;
      progress?.value = rangeStart + (rangeEnd - rangeStart) * fraction;
    }

    return result;
  }

  static Future<List<Uint8List?>> _downloadAndCompressAllImages({
    required List<ProductModel> products,
    required int maxLongestEdge,
    required int quality,
    bool compressImages = true,
    ValueNotifier<bool>? cancelled,
    ValueNotifier<double>? progress,
  }) async {
    const batchSize = 12;
    final imageBytesList = <Uint8List?>[];

    for (int i = 0; i < products.length; i += batchSize) {
      if (cancelled?.value == true) return imageBytesList;

      final batch = products.skip(i).take(batchSize);
      final batchCount = batch.length;

      final downloadFutures = batch.map((product) async {
        final imageUrl = product.displayImageUrl;
        if (imageUrl == null || imageUrl.isEmpty) return null;
        try {
          final response = await _dio.get<List<int>>(
            imageUrl,
            options: Options(responseType: ResponseType.bytes),
          );
          if (response.statusCode == 200 && response.data != null) {
            return Uint8List.fromList(response.data!);
          }
        } catch (e) {
        }
        return null;
      }).toList();

      final rawBytesList = await Future.wait(downloadFutures);

      if (cancelled?.value == true) return imageBytesList;

      if (compressImages) {
        final compressedBatch = await compute(_compressImageBatchInIsolate, {
          'imageBytes': rawBytesList,
          'maxLongestEdge': maxLongestEdge,
          'quality': quality,
        });

        imageBytesList.addAll(compressedBatch);

        final compressProgress = (i + batchCount) / products.length;
        progress?.value = compressProgress;
      } else {
        imageBytesList.addAll(rawBytesList);

        final downloadProgress = (i + batchCount) / products.length;
        progress?.value = downloadProgress;
      }

    }

    return imageBytesList;
  }

  static Future<void> shareImagesDirectly({
    required List<ProductModel> products,
    required String filterInfo,
    String? title,
    bool compressImages = true,
    ValueNotifier<bool>? cancelled,
    ValueNotifier<double>? progress,
  }) async {
    final imageBytesList = await _downloadAndCompressAllImages(
      products: products,
      maxLongestEdge: ImageCompressionConstants.shareMaxEdge,
      quality: ImageCompressionConstants.shareQuality,
      compressImages: compressImages,
      cancelled: cancelled,
      progress: progress,
    );

    if (cancelled?.value == true) return;

    final files = <XFile>[];
    final tempDir = await getTemporaryDirectory();

    try {
      for (int i = 0; i < imageBytesList.length; i++) {
        final bytes = imageBytesList[i];
        if (bytes == null) continue;

        final product = products[i];
        final fileName = 'product_${i + 1}_${product.id}.jpg';
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(bytes);
        files.add(XFile(file.path, name: fileName));
      }

      if (files.isEmpty) return;

      final shareText = _buildShareText(filterInfo, title: title);

      await Share.shareXFiles(
        files,
        subject: _brandName,
        text: shareText,
      );
    } finally {
      for (final file in files) {
        try {
          await File(file.path).delete();
        } catch (_) {}
      }
    }
  }

  static Future<void> shareAsPdf({
    required List<ProductModel> products,
    required String filterInfo,
    String? title,
    int productsPerPage = 1,
    bool compressImages = true,
    ValueNotifier<bool>? cancelled,
    ValueNotifier<double>? progress,
  }) async {
    final imageBytesList = await _downloadAndCompressAllImages(
      products: products,
      maxLongestEdge: ImageCompressionConstants.pdfProductMaxEdge,
      quality: ImageCompressionConstants.pdfProductQuality,
      compressImages: compressImages,
      cancelled: cancelled,
      progress: progress,
    );

    if (cancelled?.value == true) return;

    final arhamLogoBytes = await _loadLogoBytes('assets/images/arham-logo-gold.png');
    final ratneshLogoBytes = await _loadLogoBytes('assets/images/ratnesh-logo-gold.png');

    progress?.value = 0.95;

    final pdfBytes = await compute(_buildPdfInIsolate, {
      'arhamLogoBytes': arhamLogoBytes,
      'ratneshLogoBytes': ratneshLogoBytes,
      'imageBytesList': imageBytesList,
      'filterInfo': filterInfo,
      'totalProducts': products.length,
      'productsPerPage': productsPerPage,
    });

    if (cancelled?.value == true) return;

    progress?.value = 1.0;

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeTitle = title != null && title.isNotEmpty
        ? title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        : null;
    final fileName = safeTitle != null
        ? '${safeTitle}_Products_$timestamp.pdf'
        : '${_brandName.replaceAll(' ', '')}_Products_$timestamp.pdf';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(pdfBytes);

    final shareFileName = safeTitle != null
        ? '$safeTitle Products.pdf'
        : '$_brandName Products.pdf';

    try {
      if (cancelled?.value == true) return;

      await Share.shareXFiles(
        [XFile(file.path, name: shareFileName)],
        subject: '$_brandName - Product Catalog',
        text: _buildShareText(filterInfo, title: title),
      );
    } finally {
      try {
        await file.delete();
      } catch (_) {}
    }
  }

  static Future<void> shareImagesFromCategories({
    required List<String> categoryIds,
    required String filterInfo,
    String? title,
    bool compressImages = true,
    ValueNotifier<bool>? cancelled,
    ValueNotifier<double>? progress,
  }) async {
    final products = await fetchProductsForCategories(categoryIds);
    if (products.isEmpty) return;
    if (cancelled?.value == true) return;
    await shareImagesDirectly(
      products: products,
      filterInfo: filterInfo,
      title: title,
      compressImages: compressImages,
      cancelled: cancelled,
      progress: progress,
    );
  }

  static Future<void> sharePdfFromCategories({
    required List<String> categoryIds,
    required String filterInfo,
    String? title,
    int productsPerPage = 1,
    bool compressImages = true,
    ValueNotifier<bool>? cancelled,
    ValueNotifier<double>? progress,
  }) async {
    final products = await fetchProductsForCategories(categoryIds);
    if (products.isEmpty) return;
    if (cancelled?.value == true) return;
    await shareAsPdf(
      products: products,
      filterInfo: filterInfo,
      title: title,
      productsPerPage: productsPerPage,
      compressImages: compressImages,
      cancelled: cancelled,
      progress: progress,
    );
  }

  static Future<int> fetchProductCount(List<String> categoryIds) async {
    int totalCount = 0;

    for (final categoryId in categoryIds) {
      try {
        final response = await httpClient.get(
          ApiUrlConstants.PRODUCTS_GET_ALL,
          queryParameters: {
            "categoryId": categoryId,
            "page": 1,
            "limit": 1,
            "showReverse": true,
          },
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = response.data['data'];
          totalCount += (data['totalCount'] ?? 0) as int;
        }
      } catch (e) {
      }
    }

    return totalCount;
  }

  static Future<List<ProductModel>> fetchProductsForCategories(List<String> categoryIds) async {
    final allProducts = <ProductModel>[];
    final seen = <String>{};

    for (final categoryId in categoryIds) {
      try {
        int page = 1;
        const int limit = 50;
        bool hasMore = true;

        while (hasMore) {
          final response = await httpClient.get(
            ApiUrlConstants.PRODUCTS_GET_ALL,
            queryParameters: {
              "categoryId": categoryId,
              "page": page,
              "limit": limit,
              "showReverse": true,
            },
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            final data = response.data['data'];
            final List raw = data['data'] is List ? data['data'] : [];
            for (final item in raw) {
              final product = ProductModel.fromJson(item);
              if (seen.add(product.id)) {
                allProducts.add(product);
              }
            }
            hasMore = raw.length >= limit;
            page++;
          } else {
            hasMore = false;
          }
        }
      } catch (e) {
      }
    }

    return allProducts;
  }

  static const MethodChannel _channel = MethodChannel('com.shreearhamgold.ratneshgold/file_saver');

  static Future<List<String>> getAvailableWhatsAppPackages() async {
    try {
      final result = await _channel.invokeMethod('getAvailableWhatsAppPackages');
      if (result is List) {
        return result.map((e) => e.toString()).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<String?> _saveBytesToDownloads({
    required List<int> bytes,
    required String fileName,
  }) async {
    try {
      final result = await _channel.invokeMethod<String>('saveToDownloads', {
        'bytes': bytes,
        'fileName': fileName,
      });
      return result;
    } on PlatformException catch (e) {
      return null;
    }
  }

  static Future<ShareToWhatsAppResult> shareOrderPdfToWhatsApp({
    required String orderId,
    int? orderToken,
    required String status,
    required DateTime createdAt,
    DateTime? updatedAt,
    required List<Map<String, dynamic>> items,
    double? totalAmount,
    required String message,
    required String phone,
    String? packageName,
    ValueNotifier<double>? progress,
    ValueNotifier<bool>? cancelled,
  }) async {
    progress?.value = 0.0;

    final ts = (updatedAt ?? createdAt).millisecondsSinceEpoch;
    final cacheKey = 'order:$orderId:$status:$ts';
    final cachedFile = await PdfCache.get(cacheKey);
    
    List<int> pdfBytes;
    
    if (cachedFile != null) {
      pdfBytes = await cachedFile.readAsBytes();
      progress?.value = 1.0;
    } else {
      final imageUrls = items.map((item) {
        final url = item['imageUrl'] as String?;
        return (url != null && url.isNotEmpty) ? url : null;
      }).toList();

      final rawBytesList = await _downloadImageUrls(
        urls: imageUrls,
        progress: progress,
        cancelled: cancelled,
        rangeStart: 0.0,
        rangeEnd: 0.4,
      );

      if (cancelled?.value == true) return const ShareToWhatsAppResult(success: false);

      final imageBytesList = await compute(_compressImageBatchInIsolate, {
        'imageBytes': rawBytesList,
        'maxLongestEdge': ImageCompressionConstants.pdfThumbnailMaxEdge,
        'quality': ImageCompressionConstants.pdfThumbnailQuality,
      });

      progress?.value = 0.5;
      if (cancelled?.value == true) return const ShareToWhatsAppResult(success: false);

      final arhamLogoBytes = await _loadLogoBytes('assets/images/arham-logo-gold.png');
      final ratneshLogoBytes = await _loadLogoBytes('assets/images/ratnesh-logo-gold.png');

      pdfBytes = await compute(_buildOrderDetailsPdfInIsolate, {
        'arhamLogoBytes': arhamLogoBytes,
        'ratneshLogoBytes': ratneshLogoBytes,
        'orderId': orderId,
        'orderToken': orderToken,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
        'items': items,
        'totalAmount': totalAmount,
        'imageBytesList': imageBytesList,
      });

      progress?.value = 0.8;
      if (cancelled?.value == true) return const ShareToWhatsAppResult(success: false);

      await PdfCache.put(cacheKey, pdfBytes);
    }

    final tempDir = await getTemporaryDirectory();
    final sharedDir = Directory('${tempDir.path}/shared_pdfs');
    if (!await sharedDir.exists()) {
      await sharedDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final displayId = orderToken != null ? '$orderToken' : orderId.substring(0, 8).toUpperCase();
    final fileName = 'Order_${displayId}_$timestamp.pdf';
    final file = File('${sharedDir.path}/$fileName');
    await file.writeAsBytes(pdfBytes);

    progress?.value = 0.95;
    if (cancelled?.value == true) {
      try { await file.delete(); } catch (_) {}
      return const ShareToWhatsAppResult(success: false);
    }

    try {
      if (Platform.isAndroid) {
        final result = await _channel.invokeMethod<bool>('shareToWhatsApp', {
          'filePath': file.path,
          'message': message,
          'phone': phone,
          'packageName': packageName,
        });
        progress?.value = 1.0;
        if (result == true) {
          return const ShareToWhatsAppResult(success: true);
        }
        return ShareToWhatsAppResult(
          success: false,
          filePath: file.path,
          fileName: fileName,
        );
      } else {
        await Share.shareXFiles(
          [XFile(file.path, name: fileName)],
          text: message,
        );
        progress?.value = 1.0;
        return const ShareToWhatsAppResult(success: true);
      }
    } catch (e) {
      return ShareToWhatsAppResult(
        success: false,
        filePath: file.path,
        fileName: fileName,
      );
    } finally {
      Future.delayed(const Duration(seconds: 30), () async {
        try { await file.delete(); } catch (_) {}
      });
    }
  }

  static Future<Uint8List> generateCartEnquiryPdfBytes({
    required List<ProductModel> products,
    required List<int> quantities,
  }) async {
    final arhamLogoBytes = await _loadLogoBytes('assets/images/arham-logo-gold.png');
    final ratneshLogoBytes = await _loadLogoBytes('assets/images/ratnesh-logo-gold.png');

    final imageFutures = products.map((p) async {
      final url = p.displayImageUrl;
      if (url == null || url.isEmpty) return null;
      return _downloadAndCompressImage(
        url,
        maxLongestEdge: ImageCompressionConstants.pdfThumbnailMaxEdge,
        quality: ImageCompressionConstants.pdfThumbnailQuality,
      );
    }).toList();
    final imageBytesList = await Future.wait(imageFutures);

    final rows = <Map<String, dynamic>>[];
    for (var i = 0; i < products.length; i++) {
      final p = products[i];
      rows.add({
        'index': i + 1,
        'name': p.name,
        'category': p.category?.name ?? '-',
        'karat': p.touch ?? p.karat ?? '-',
        'netWt': p.karigarNetWt,
        'qty': quantities[i],
      });
    }

    final pdfBytes = await compute(_buildCartEnquiryPdfInIsolate, {
      'arhamLogoBytes': arhamLogoBytes,
      'ratneshLogoBytes': ratneshLogoBytes,
      'rows': rows,
      'imageBytesList': imageBytesList,
    });

    return Uint8List.fromList(pdfBytes);
  }

  static Future<String?> saveCartEnquiryPdfToDownloads({
    required List<ProductModel> products,
    required List<int> quantities,
  }) async {
    final pdfBytes = await generateCartEnquiryPdfBytes(
      products: products,
      quantities: quantities,
    );

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'Cart_Enquiry_$timestamp.pdf';

    return _saveBytesToDownloads(bytes: pdfBytes, fileName: fileName);
  }

  static Future<ShareToWhatsAppResult> shareCartEnquiryPdfToWhatsApp({
    required List<ProductModel> products,
    required List<int> quantities,
    required String message,
    required String phone,
    String? packageName,
    ValueNotifier<double>? progress,
    ValueNotifier<bool>? cancelled,
  }) async {
    progress?.value = 0.0;

    final sortedPairs = <String>[];
    for (var i = 0; i < products.length; i++) {
      final p = products[i];
      sortedPairs.add('${p.id}:${quantities[i]}:${p.name}:${p.displayImageUrl ?? ''}');
    }
    sortedPairs.sort();
    final cacheKey = 'cart:${sortedPairs.join('|')}';
    
    final cachedFile = await PdfCache.get(cacheKey);
    
    List<int> pdfBytes;
    
    if (cachedFile != null) {
      pdfBytes = await cachedFile.readAsBytes();
      progress?.value = 1.0;
    } else {
      final imageUrls = products.map((p) {
        final url = p.displayImageUrl;
        return (url != null && url.isNotEmpty) ? url : null;
      }).toList();

      final rawBytesList = await _downloadImageUrls(
        urls: imageUrls,
        progress: progress,
        cancelled: cancelled,
        rangeStart: 0.0,
        rangeEnd: 0.4,
      );

      if (cancelled?.value == true) return const ShareToWhatsAppResult(success: false);

      final imageBytesList = await compute(_compressImageBatchInIsolate, {
        'imageBytes': rawBytesList,
        'maxLongestEdge': ImageCompressionConstants.pdfThumbnailMaxEdge,
        'quality': ImageCompressionConstants.pdfThumbnailQuality,
      });

      progress?.value = 0.5;
      if (cancelled?.value == true) return const ShareToWhatsAppResult(success: false);

      final rows = <Map<String, dynamic>>[];
      for (var i = 0; i < products.length; i++) {
        final p = products[i];
        rows.add({
          'index': i + 1,
          'name': p.name,
          'category': p.category?.name ?? '-',
          'karat': p.touch ?? p.karat ?? '-',
          'netWt': p.karigarNetWt,
          'qty': quantities[i],
        });
      }

      final arhamLogoBytes = await _loadLogoBytes('assets/images/arham-logo-gold.png');
      final ratneshLogoBytes = await _loadLogoBytes('assets/images/ratnesh-logo-gold.png');

      pdfBytes = await compute(_buildCartEnquiryPdfInIsolate, {
        'arhamLogoBytes': arhamLogoBytes,
        'ratneshLogoBytes': ratneshLogoBytes,
        'rows': rows,
        'imageBytesList': imageBytesList,
      });

      progress?.value = 0.8;
      if (cancelled?.value == true) return const ShareToWhatsAppResult(success: false);

      await PdfCache.put(cacheKey, pdfBytes);
    }

    final tempDir = await getTemporaryDirectory();
    final sharedDir = Directory('${tempDir.path}/shared_pdfs');
    if (!await sharedDir.exists()) {
      await sharedDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'Cart_Enquiry_$timestamp.pdf';
    final file = File('${sharedDir.path}/$fileName');
    await file.writeAsBytes(pdfBytes);

    progress?.value = 0.95;
    if (cancelled?.value == true) {
      try { await file.delete(); } catch (_) {}
      return const ShareToWhatsAppResult(success: false);
    }

    try {
      if (Platform.isAndroid) {
        final result = await _channel.invokeMethod<bool>('shareToWhatsApp', {
          'filePath': file.path,
          'message': message,
          'phone': phone,
          'packageName': packageName,
        });
        progress?.value = 1.0;
        if (result == true) {
          return const ShareToWhatsAppResult(success: true);
        }
        return ShareToWhatsAppResult(
          success: false,
          filePath: file.path,
          fileName: fileName,
        );
      } else {
        await Share.shareXFiles(
          [XFile(file.path, name: fileName)],
          text: message,
        );
        progress?.value = 1.0;
        return const ShareToWhatsAppResult(success: true);
      }
    } catch (e) {
      return ShareToWhatsAppResult(
        success: false,
        filePath: file.path,
        fileName: fileName,
      );
    } finally {
      Future.delayed(const Duration(seconds: 30), () async {
        try { await file.delete(); } catch (_) {}
      });
    }
  }

  static Future<bool?> shareCustomOrderAsPdf({
    required AdminOrderModel order,
    ValueNotifier<double>? progress,
  }) async {
    try {
    final cacheKey = 'custom_order:${order.id}:${order.updatedAt.millisecondsSinceEpoch}';
    final cachedFile = await PdfCache.get(cacheKey);
    
    List<int> pdfBytes;
    final displayId = order.id.substring(0, 8).toUpperCase();
    
    if (cachedFile != null) {
      pdfBytes = await cachedFile.readAsBytes();
      progress?.value = 1.0;
    } else {
      final arhamLogoBytes = await _loadLogoBytes('assets/images/arham-logo-gold.png');
      final ratneshLogoBytes = await _loadLogoBytes('assets/images/ratnesh-logo-gold.png');

      progress?.value = 0.1;

      final refImageFutures = order.referenceImages.map((url) {
        if (url.isEmpty) return Future<Uint8List?>.value(null);
        return _downloadAndCompressImage(
          url,
          maxLongestEdge: ImageCompressionConstants.pdfCustomOrderImageMaxEdge,
          quality: ImageCompressionConstants.pdfCustomOrderImageQuality,
        );
      }).toList();

      final productImageFutures = order.orderItems.map((item) {
        final url = item.product.displayImageUrl;
        if (url == null || url.isEmpty) return Future<Uint8List?>.value(null);
        return _downloadAndCompressImage(
          url,
          maxLongestEdge: ImageCompressionConstants.pdfCustomOrderImageMaxEdge,
          quality: ImageCompressionConstants.pdfCustomOrderImageQuality,
        );
      }).toList();

      final List<Uint8List?> refImageBytesList;
      final List<Uint8List?> productImageBytesList;
      final results = await Future.wait([
        Future.wait(refImageFutures),
        Future.wait(productImageFutures),
      ]);
      refImageBytesList = List<Uint8List?>.from(results[0]);
      productImageBytesList = List<Uint8List?>.from(results[1]);

      progress?.value = 0.6;

      pdfBytes = await compute(_buildCustomOrderPdfInIsolate, {
        'arhamLogoBytes': arhamLogoBytes,
        'ratneshLogoBytes': ratneshLogoBytes,
        'orderId': displayId,
        'itemName': order.itemName ?? '-',
        'weight': order.weight ?? '-',
        'purity': order.purity ?? '-',
        'pieces': order.noOfPieces ?? '-',
        'marking': order.marking ?? '-',
        'deliveryDate': order.deliveryDate ?? '-',
        'refImageBytesList': refImageBytesList,
        'productImageBytesList': productImageBytesList,
      });

      progress?.value = 0.9;

      await PdfCache.put(cacheKey, pdfBytes);
    }

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'CustomOrder_${displayId}_$timestamp.pdf';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(pdfBytes);

    progress?.value = 0.95;

    try {
      await Share.shareXFiles(
        [XFile(file.path, name: 'Custom Order $displayId.pdf')],
        subject: '$_brandName - Custom Order $displayId',
        text: '$_brandName\n$_brandSubtitle\n\nCustom Order #$displayId',
      );
      progress?.value = 1.0;
      return true;
    } finally {
      try {
        await file.delete();
      } catch (_) {}
    }
    } catch (e) {
      return false;
    }
  }

  static Future<bool?> shareCustomOrderAsImages({
    required AdminOrderModel order,
    ValueNotifier<double>? progress,
  }) async {
    try {
    progress?.value = 0.1;

    final refImageFutures = order.referenceImages.map((url) {
      if (url.isEmpty) return Future<Uint8List?>.value(null);
      return _downloadAndCompressImage(
        url,
        maxLongestEdge: ImageCompressionConstants.shareMaxEdge,
        quality: ImageCompressionConstants.shareQuality,
      );
    }).toList();

    final productImageFutures = order.orderItems.map((item) {
      final url = item.product.displayImageUrl;
      if (url == null || url.isEmpty) return Future<Uint8List?>.value(null);
      return _downloadAndCompressImage(
        url,
        maxLongestEdge: ImageCompressionConstants.shareMaxEdge,
        quality: ImageCompressionConstants.shareQuality,
      );
    }).toList();

    final List<Uint8List?> refImageBytesList;
    final List<Uint8List?> productImageBytesList;
    final results = await Future.wait([
      Future.wait(refImageFutures),
      Future.wait(productImageFutures),
    ]);
    refImageBytesList = List<Uint8List?>.from(results[0]);
    productImageBytesList = List<Uint8List?>.from(results[1]);

    progress?.value = 0.6;

    final allBytes = [...refImageBytesList, ...productImageBytesList]
        .whereType<Uint8List>()
        .toList();

    if (allBytes.isEmpty) return null;

    final tempDir = await getTemporaryDirectory();
    final files = <XFile>[];

    try {
      for (int i = 0; i < refImageBytesList.length; i++) {
        final bytes = refImageBytesList[i];
        if (bytes == null) continue;
        final fileName = 'ref_image_${i + 1}.jpg';
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(bytes);
        files.add(XFile(file.path, name: fileName));
      }

      for (int i = 0; i < productImageBytesList.length; i++) {
        final bytes = productImageBytesList[i];
        if (bytes == null) continue;
        final fileName = 'product_image_${i + 1}.jpg';
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(bytes);
        files.add(XFile(file.path, name: fileName));
      }

      if (files.isEmpty) return null;

      progress?.value = 0.8;

      final itemName = order.itemName ?? '-';
      final weight = order.weight ?? '-';
      final purity = order.purity ?? '-';
      final noOfPieces = order.noOfPieces ?? '-';
      final marking = order.marking ?? '-';
      final deliveryDate = order.deliveryDate ?? '-';

      final shareText = 'Custom Order Details\n'
          '━━━━━━━━━━━━━━━━━━━━\n'
          'Item: $itemName\n'
          'Weight: ${weight == '-' ? '-' : '${weight}g'}\n'
          'Purity: $purity\n'
          'Pieces: $noOfPieces\n'
          'Hallmark/HUID: $marking\n'
          'Delivery Date: $deliveryDate\n'
          '━━━━━━━━━━━━━━━━━━━━\n'
          '$_brandName\n'
          '$_brandSubtitle';

      progress?.value = 0.95;

      await Share.shareXFiles(
        files,
        subject: '$_brandName - Custom Order',
        text: shareText,
      );
      progress?.value = 1.0;
      return true;
    } finally {
      for (final file in files) {
        try {
          await File(file.path).delete();
        } catch (_) {}
      }
    }
    } catch (e) {
      return false;
    }
  }
}

Future<List<Uint8List?>> _compressImageBatchInIsolate(Map<String, dynamic> params) async {
  final imageBytes = params['imageBytes'] as List<Uint8List?>;
  final maxLongestEdge = params['maxLongestEdge'] as int;
  final quality = params['quality'] as int;

  return imageBytes.map((bytes) {
    if (bytes == null) return null;
    
    final decoded = img.decodeJpg(bytes);
    if (decoded == null) return bytes;

    final longest = decoded.width > decoded.height ? decoded.width : decoded.height;
    if (longest <= maxLongestEdge) return bytes;

    final resized = img.copyResize(
      decoded,
      width: decoded.width >= decoded.height ? maxLongestEdge : null,
      height: decoded.height > decoded.width ? maxLongestEdge : null,
      interpolation: img.Interpolation.linear,
    );

    return Uint8List.fromList(img.encodeJpg(resized, quality: quality));
  }).toList();
}

Future<List<int>> _buildPdfInIsolate(Map<String, dynamic> params) async {
  final arhamLogoBytes = params['arhamLogoBytes'] as Uint8List;
  final ratneshLogoBytes = params['ratneshLogoBytes'] as Uint8List;
  final imageBytesList = params['imageBytesList'] as List<Uint8List?>;
  final filterInfo = params['filterInfo'] as String;
  final totalProducts = params['totalProducts'] as int;
  final productsPerPage = params['productsPerPage'] as int? ?? 1;

  final pdf = pw.Document();

  final brandFont = pw.Font.helvetica();
  final regularFont = pw.Font.helvetica();
  final lightFont = pw.Font.helvetica();

  final arhamLogo = pw.MemoryImage(arhamLogoBytes);
  final ratneshLogo = pw.MemoryImage(ratneshLogoBytes);

  final goldColor = PdfColor.fromHex('#A57A36');
  final darkColor = PdfColor.fromHex('#2D2118');

  final brandName = 'SHREE ARHAM GOLD & RATNESH GOLD';
  final brandSubtitle = 'Purity - Quality - Trust';

  final headerContent = pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    mainAxisAlignment: pw.MainAxisAlignment.center,
    children: [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Image(arhamLogo, width: 100, height: 40),
          pw.SizedBox(width: 20),
          pw.Image(ratneshLogo, width: 40, height: 40),
        ],
      ),
      pw.SizedBox(height: 8),
      pw.Text(
        brandName,
        style: pw.TextStyle(font: brandFont, fontSize: 24, color: goldColor),
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        brandSubtitle,
        style: pw.TextStyle(font: lightFont, fontSize: 10, color: PdfColors.white),
      ),
      pw.SizedBox(height: 12),
      pw.Divider(color: goldColor, thickness: 2),
      pw.SizedBox(height: 12),
      if (filterInfo.isNotEmpty) ...[
        pw.Text(
          filterInfo,
          style: pw.TextStyle(font: brandFont, fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 10),
      ],
      pw.Text(
        'Total Products: $totalProducts',
        style: pw.TextStyle(font: regularFont, fontSize: 11, color: PdfColor.fromHex('#BBBBBB')),
      ),
    ],
  );

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(30),
      build: (context) => [
        pw.Container(
          height: PdfPageFormat.a4.height - 60,
          decoration: pw.BoxDecoration(color: darkColor),
          padding: const pw.EdgeInsets.all(30),
          child: pw.Center(child: headerContent),
        ),
      ],
    ),
  );

  final totalPages = (totalProducts / productsPerPage).ceil();

  const double gap = 8;

  for (int page = 0; page < totalPages; page++) {
    final startIndex = page * productsPerPage;
    final endIndex = (startIndex + productsPerPage).clamp(0, totalProducts);
    final pageCount = endIndex - startIndex;

    if (productsPerPage == 4) {
      final rowHeight = (PdfPageFormat.a4.height - 60 - gap) / 2;
      final colWidth = (PdfPageFormat.a4.width - 60 - gap) / 2;

      final rows = <pw.Widget>[];
      for (int row = 0; row < 2; row++) {
        final rowStart = row * 2;
        final rowEnd = (rowStart + 2).clamp(0, pageCount);
        if (rowStart >= pageCount) break;

        final cols = <pw.Widget>[];
        for (int j = rowStart; j < rowEnd; j++) {
          final idx = startIndex + j;
          final imageBytes = imageBytesList[idx];
          if (imageBytes != null) {
            cols.add(
              pw.SizedBox(
                width: colWidth,
                height: rowHeight,
                child: pw.Image(pw.MemoryImage(imageBytes), fit: pw.BoxFit.contain),
              ),
            );
          } else {
            cols.add(pw.SizedBox(width: colWidth, height: rowHeight));
          }
          if (j < rowEnd - 1) cols.add(pw.SizedBox(width: gap));
        }
        rows.add(pw.Row(children: cols));
        if (row == 0 && rowEnd < pageCount) rows.add(pw.SizedBox(height: gap));
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(30),
          build: (context) => rows,
        ),
      );
    } else {
      final totalGaps = (pageCount - 1) * gap;
      final imageHeight = (PdfPageFormat.a4.height - 60 - totalGaps) / pageCount;

      final images = <pw.Widget>[];
      for (int j = 0; j < pageCount; j++) {
        final idx = startIndex + j;
        final imageBytes = imageBytesList[idx];
        if (imageBytes != null) {
          images.add(
            pw.Container(
              height: imageHeight,
              child: pw.Image(pw.MemoryImage(imageBytes), fit: pw.BoxFit.contain),
            ),
          );
        } else {
          images.add(pw.Container(height: imageHeight));
        }
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(30),
          build: (context) => [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                for (int i = 0; i < images.length; i++) ...[
                  if (i > 0) pw.SizedBox(height: gap),
                  images[i],
                ],
              ],
            ),
          ],
        ),
      );
    }
  }

  return await pdf.save();
}

Future<List<int>> _buildCartEnquiryPdfInIsolate(Map<String, dynamic> params) async {
  final arhamLogoBytes = params['arhamLogoBytes'] as Uint8List;
  final ratneshLogoBytes = params['ratneshLogoBytes'] as Uint8List;
  final rows = params['rows'] as List<Map<String, dynamic>>;
  final imageBytesList = params['imageBytesList'] as List<Uint8List?>;

  final brandName = 'SHREE ARHAM GOLD & RATNESH GOLD';
  final brandSubtitle = 'Purity - Quality - Trust';

  final pdf = pw.Document();

  final regularFont = pw.Font.helvetica();
  final boldFont = pw.Font.helveticaBold();

  final arhamLogo = pw.MemoryImage(arhamLogoBytes);
  final ratneshLogo = pw.MemoryImage(ratneshLogoBytes);

  final goldColor = PdfColor.fromHex('#A57A36');
  final darkColor = PdfColor.fromHex('#2D2118');
  final mutedColor = PdfColor.fromHex('#7E756C');
  final borderColor = PdfColor.fromHex('#D4C9B8');

  final header = pw.Container(
    padding: const pw.EdgeInsets.only(bottom: 16),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Image(arhamLogo, width: 90, height: 36),
            pw.SizedBox(width: 16),
            pw.Image(ratneshLogo, width: 36, height: 36),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          brandName,
          style: pw.TextStyle(font: boldFont, fontSize: 18, color: goldColor),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          brandSubtitle,
          style: pw.TextStyle(font: regularFont, fontSize: 9, color: mutedColor),
        ),
        pw.SizedBox(height: 10),
        pw.Divider(color: goldColor, thickness: 1),
        pw.SizedBox(height: 6),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Cart Enquiry',
              style: pw.TextStyle(font: boldFont, fontSize: 14, color: darkColor),
            ),
            pw.Text(
              'Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
              style: pw.TextStyle(font: regularFont, fontSize: 9, color: mutedColor),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Total Items: ${rows.length}',
          style: pw.TextStyle(font: regularFont, fontSize: 9, color: mutedColor),
        ),
      ],
    ),
  );

  final colWidths = <double>[40, 28, 155, 95, 70, 68, 42];

  final tableHeaderStyle = pw.TextStyle(font: boldFont, fontSize: 9, color: PdfColor.fromHex('#FFFFFF'));
  final tableCellStyle = pw.TextStyle(font: regularFont, fontSize: 8.5, color: darkColor);

  pw.TableRow buildRow(List<String> cells, {bool isHeader = false, pw.MemoryImage? image}) {
    final children = <pw.Widget>[];

    if (isHeader) {
      children.add(
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 7),
          alignment: pw.Alignment.center,
          child: pw.Text('', style: tableHeaderStyle),
        ),
      );
    } else if (image != null) {
      children.add(
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          alignment: pw.Alignment.center,
          child: pw.ClipRRect(
            horizontalRadius: 3,
            verticalRadius: 3,
            child: pw.Image(image, width: 32, height: 32, fit: pw.BoxFit.cover),
          ),
        ),
      );
    } else {
      children.add(
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          alignment: pw.Alignment.center,
          child: pw.Container(
            width: 32,
            height: 32,
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#F1EEE9'),
              borderRadius: pw.BorderRadius.circular(3),
            ),
            child: pw.Center(
              child: pw.Text(
                cells[0],
                style: pw.TextStyle(font: regularFont, fontSize: 8, color: mutedColor),
              ),
            ),
          ),
        ),
      );
    }

    for (var ci = 0; ci < cells.length; ci++) {
      children.add(
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
          alignment: ci == 0 ? pw.Alignment.center : pw.Alignment.centerLeft,
          child: pw.Text(
            cells[ci],
            style: isHeader ? tableHeaderStyle : tableCellStyle,
            maxLines: 2,
          ),
        ),
      );
    }

    return pw.TableRow(
      decoration: isHeader ? pw.BoxDecoration(color: goldColor) : null,
      children: children,
    );
  }

  final tableRows = <pw.TableRow>[
    buildRow(['#', 'Name', 'Category', 'Karat', 'Net Wt (g)', 'Qty'], isHeader: true),
    ...rows.asMap().entries.map((entry) {
      final ci = entry.key;
      final r = entry.value;
      final imgBytes = ci < imageBytesList.length ? imageBytesList[ci] : null;
      final img = imgBytes != null ? pw.MemoryImage(imgBytes) : null;
      return buildRow([
        '${r['index']}',
        r['name'] as String,
        r['category'] as String,
        r['karat'] as String,
        r['netWt'] != null ? (r['netWt'] as double).toStringAsFixed(2) : '-',
        '${r['qty']}',
      ], image: img);
    }),
  ];

  final table = pw.Table(
    columnWidths: {
      for (var i = 0; i < colWidths.length; i++) i: pw.FixedColumnWidth(colWidths[i]),
    },
    border: pw.TableBorder(
      horizontalInside: pw.BorderSide(color: borderColor, width: 0.5),
      verticalInside: pw.BorderSide(color: borderColor, width: 0.5),
    ),
    children: tableRows,
  );

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(30),
      build: (context) => [header, table],
      footer: (context) => pw.Container(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          'Page ${context.pageNumber} of ${context.pagesCount}',
          style: pw.TextStyle(font: regularFont, fontSize: 8, color: mutedColor),
        ),
      ),
    ),
  );

  return await pdf.save();
}

Future<List<int>> _buildOrderDetailsPdfInIsolate(Map<String, dynamic> params) async {
  final arhamLogoBytes = params['arhamLogoBytes'] as Uint8List;
  final ratneshLogoBytes = params['ratneshLogoBytes'] as Uint8List;
  final orderId = params['orderId'] as String;
  final orderToken = params['orderToken'] as int?;
  final status = params['status'] as String;
  final createdAt = DateTime.parse(params['createdAt'] as String);
  final items = params['items'] as List<Map<String, dynamic>>;
  final totalAmount = params['totalAmount'] as double?;
  final imageBytesList = params['imageBytesList'] as List<Uint8List?>;

  final brandName = 'SHREE ARHAM GOLD & RATNESH GOLD';
  final brandSubtitle = 'Purity - Quality - Trust';

  final pdf = pw.Document();

  final regularFont = pw.Font.helvetica();
  final boldFont = pw.Font.helveticaBold();

  final arhamLogo = pw.MemoryImage(arhamLogoBytes);
  final ratneshLogo = pw.MemoryImage(ratneshLogoBytes);

  final goldColor = PdfColor.fromHex('#A57A36');
  final darkColor = PdfColor.fromHex('#2D2118');
  final mutedColor = PdfColor.fromHex('#7E756C');
  final borderColor = PdfColor.fromHex('#D4C9B8');
  final greenColor = PdfColor.fromHex('#2D8C56');
  final redColor = PdfColor.fromHex('#DC2626');

  final displayId = orderToken != null ? '#$orderToken' : '#${orderId.substring(0, 8).toUpperCase()}';

  final header = pw.Container(
    padding: const pw.EdgeInsets.only(bottom: 16),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Image(arhamLogo, width: 90, height: 36),
            pw.SizedBox(width: 16),
            pw.Image(ratneshLogo, width: 36, height: 36),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          brandName,
          style: pw.TextStyle(font: boldFont, fontSize: 18, color: goldColor),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          brandSubtitle,
          style: pw.TextStyle(font: regularFont, fontSize: 9, color: mutedColor),
        ),
        pw.SizedBox(height: 10),
        pw.Divider(color: goldColor, thickness: 1),
        pw.SizedBox(height: 6),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Order Details',
              style: pw.TextStyle(font: boldFont, fontSize: 14, color: darkColor),
            ),
            pw.Text(
              'Date: ${createdAt.day}/${createdAt.month}/${createdAt.year}',
              style: pw.TextStyle(font: regularFont, fontSize: 9, color: mutedColor),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          children: [
            pw.Text(
              'Order: $displayId',
              style: pw.TextStyle(font: boldFont, fontSize: 10, color: darkColor),
            ),
            pw.SizedBox(width: 16),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: pw.BoxDecoration(
                color: status.toLowerCase() == 'rejected' ? redColor : greenColor,
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Text(
                '${status[0].toUpperCase()}${status.substring(1)}',
                style: pw.TextStyle(font: boldFont, fontSize: 8, color: PdfColors.white),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  final colWidths = <double>[36, 24, 140, 55, 34, 70, 65];

  final tableHeaderStyle = pw.TextStyle(font: boldFont, fontSize: 9, color: PdfColor.fromHex('#FFFFFF'));
  final tableCellStyle = pw.TextStyle(font: regularFont, fontSize: 8.5, color: darkColor);

  pw.TableRow buildRow(List<String> cells, {bool isHeader = false, pw.MemoryImage? image, String? itemStatus}) {
    final children = <pw.Widget>[];

    if (isHeader) {
      children.add(
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 7),
          alignment: pw.Alignment.center,
          child: pw.Text('', style: tableHeaderStyle),
        ),
      );
    } else if (image != null) {
      children.add(
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          alignment: pw.Alignment.center,
          child: pw.ClipRRect(
            horizontalRadius: 3,
            verticalRadius: 3,
            child: pw.Image(image, width: 32, height: 32, fit: pw.BoxFit.cover),
          ),
        ),
      );
    } else {
      children.add(
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          alignment: pw.Alignment.center,
          child: pw.Container(
            width: 32,
            height: 32,
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#F1EEE9'),
              borderRadius: pw.BorderRadius.circular(3),
            ),
          ),
        ),
      );
    }

    for (var ci = 0; ci < cells.length; ci++) {
      final isStatusCell = ci == cells.length - 1 && itemStatus != null;
      pw.TextStyle cellStyle;
      if (isHeader) {
        cellStyle = tableHeaderStyle;
      } else if (isStatusCell) {
        final isRejected = itemStatus.toLowerCase() == 'rejected';
        cellStyle = pw.TextStyle(
          font: boldFont,
          fontSize: 8,
          color: isRejected ? redColor : greenColor,
        );
      } else {
        cellStyle = tableCellStyle;
      }

      children.add(
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
          alignment: ci == 0 ? pw.Alignment.center : pw.Alignment.centerLeft,
          child: pw.Text(
            cells[ci],
            style: cellStyle,
            maxLines: 2,
          ),
        ),
      );
    }

    return pw.TableRow(
      decoration: isHeader ? pw.BoxDecoration(color: goldColor) : null,
      children: children,
    );
  }

  final tableRows = <pw.TableRow>[
    buildRow(['#', 'Name', 'Karat', 'Net Wt (g)', 'Qty', 'Status'], isHeader: true),
    ...items.asMap().entries.map((entry) {
      final ci = entry.key;
      final item = entry.value;
      final imgBytes = ci < imageBytesList.length ? imageBytesList[ci] : null;
      final img = imgBytes != null ? pw.MemoryImage(imgBytes) : null;
      final itemStatus = item['isRejected'] == true ? 'Rejected' : 'Confirmed';
      final netWt = item['netWeight'] as double?;
      return buildRow([
        '${ci + 1}',
        item['name'] as String? ?? '-',
        item['karat'] as String? ?? '-',
        netWt != null ? netWt.toStringAsFixed(2) : '-',
        '${item['quantity'] ?? 0}',
        itemStatus,
      ], image: img, itemStatus: itemStatus);
    }),
  ];

  final table = pw.Table(
    columnWidths: {
      for (var i = 0; i < colWidths.length; i++) i: pw.FixedColumnWidth(colWidths[i]),
    },
    border: pw.TableBorder(
      horizontalInside: pw.BorderSide(color: borderColor, width: 0.5),
      verticalInside: pw.BorderSide(color: borderColor, width: 0.5),
    ),
    children: tableRows,
  );

  final totalSection = totalAmount != null
      ? pw.Container(
          margin: const pw.EdgeInsets.only(top: 16),
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#F9F3E8'),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text(
                'Total: ',
                style: pw.TextStyle(font: regularFont, fontSize: 11, color: darkColor),
              ),
              pw.Text(
                'Rs. ${totalAmount.toStringAsFixed(2)}',
                style: pw.TextStyle(font: boldFont, fontSize: 14, color: goldColor),
              ),
            ],
          ),
        )
      : pw.SizedBox.shrink();

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(30),
      build: (context) => [header, table, totalSection],
      footer: (context) => pw.Container(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          'Page ${context.pageNumber} of ${context.pagesCount}',
          style: pw.TextStyle(font: regularFont, fontSize: 8, color: mutedColor),
        ),
      ),
    ),
  );

  return await pdf.save();
}

Future<List<int>> _buildCustomOrderPdfInIsolate(Map<String, dynamic> params) async {
  final arhamLogoBytes = params['arhamLogoBytes'] as Uint8List;
  final ratneshLogoBytes = params['ratneshLogoBytes'] as Uint8List;
  final orderId = params['orderId'] as String;
  final itemName = params['itemName'] as String;
  final weight = params['weight'] as String;
  final purity = params['purity'] as String;
  final pieces = params['pieces'] as String;
  final marking = params['marking'] as String;
  final deliveryDate = params['deliveryDate'] as String;
  final refImageBytesList = params['refImageBytesList'] as List<Uint8List?>;
  final productImageBytesList = params['productImageBytesList'] as List<Uint8List?>;

  final brandName = 'SHREE ARHAM GOLD & RATNESH GOLD';
  final brandSubtitle = 'Purity - Quality - Trust';

  final pdf = pw.Document();

  final regularFont = pw.Font.helvetica();
  final boldFont = pw.Font.helveticaBold();

  final arhamLogo = pw.MemoryImage(arhamLogoBytes);
  final ratneshLogo = pw.MemoryImage(ratneshLogoBytes);

  final goldColor = PdfColor.fromHex('#A57A36');
  final darkColor = PdfColor.fromHex('#2D2118');
  final mutedColor = PdfColor.fromHex('#7E756C');
  final borderColor = PdfColor.fromHex('#D4C9B8');
  final labelColor = PdfColor.fromHex('#5C534A');

  final header = pw.Container(
    padding: const pw.EdgeInsets.only(bottom: 16),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Image(arhamLogo, width: 90, height: 36),
            pw.SizedBox(width: 16),
            pw.Image(ratneshLogo, width: 36, height: 36),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          brandName,
          style: pw.TextStyle(font: boldFont, fontSize: 18, color: goldColor),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          brandSubtitle,
          style: pw.TextStyle(font: regularFont, fontSize: 9, color: mutedColor),
        ),
        pw.SizedBox(height: 10),
        pw.Divider(color: goldColor, thickness: 1),
        pw.SizedBox(height: 6),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              'Custom Order Details',
              style: pw.TextStyle(font: boldFont, fontSize: 14, color: darkColor),
            ),
          ],
        ),
      ],
    ),
  );

  final summaryRows = <Map<String, String>>[
    {'label': 'Order ID', 'value': '#$orderId'},
    {'label': 'Item Name', 'value': itemName},
    {'label': 'Weight', 'value': weight},
    {'label': 'Purity', 'value': purity},
    {'label': 'Pieces', 'value': pieces},
    {'label': 'Hallmark / HUID', 'value': marking},
    {'label': 'Delivery Date', 'value': deliveryDate},
  ];

  final summaryTable = pw.Table(
    columnWidths: const {
      0: pw.FixedColumnWidth(160),
      1: pw.FixedColumnWidth(360),
    },
    border: pw.TableBorder(
      top: pw.BorderSide(color: borderColor, width: 0.5),
      bottom: pw.BorderSide(color: borderColor, width: 0.5),
      left: pw.BorderSide(color: borderColor, width: 0.5),
      right: pw.BorderSide(color: borderColor, width: 0.5),
      horizontalInside: pw.BorderSide(color: borderColor, width: 0.5),
      verticalInside: pw.BorderSide(color: borderColor, width: 0.5),
    ),
    children: summaryRows.map((row) {
      return pw.TableRow(
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: pw.BoxDecoration(color: PdfColor.fromHex('#F9F3E8')),
            child: pw.Text(
              row['label']!,
              style: pw.TextStyle(font: boldFont, fontSize: 9.5, color: labelColor),
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: pw.Text(
              row['value']!,
              style: pw.TextStyle(font: regularFont, fontSize: 9.5, color: darkColor),
            ),
          ),
        ],
      );
    }).toList(),
  );

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(30),
      build: (context) => [header, pw.SizedBox(height: 8), summaryTable],
      footer: (context) => pw.Container(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          'Page ${context.pageNumber} of ${context.pagesCount}',
          style: pw.TextStyle(font: regularFont, fontSize: 8, color: mutedColor),
        ),
      ),
    ),
  );

  for (final imageBytes in refImageBytesList) {
    if (imageBytes == null) continue;
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (context) => pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: borderColor, width: 0.5),
          ),
          child: pw.Image(pw.MemoryImage(imageBytes), fit: pw.BoxFit.contain),
        ),
      ),
    );
  }

  for (final imageBytes in productImageBytesList) {
    if (imageBytes == null) continue;
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (context) => pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: borderColor, width: 0.5),
          ),
          child: pw.Image(pw.MemoryImage(imageBytes), fit: pw.BoxFit.contain),
        ),
      ),
    );
  }

  return await pdf.save();
}
