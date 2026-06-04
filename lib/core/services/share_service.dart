import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:ratnesh_gold_app/domain/entities/productModel.dart';
import 'package:ratnesh_gold_app/utils/Logger.dart';

class ShareService {
  static const String _brandName = 'SHREE ARHAM GOLD & RATNESH GOLD';
  static const String _brandSubtitle = 'Purity - Quality - Trust';

  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  static String buildFilterInfo({
    required List<String> selectedKarats,
    required List<String> selectedCategoryNames,
    required bool showAllStock,
    required double weightMin,
    required double weightMax,
  }) {
    final parts = <String>[];

    if (selectedKarats.isNotEmpty) {
      parts.add(selectedKarats.join(', '));
    }

    if (selectedCategoryNames.isNotEmpty) {
      parts.add(selectedCategoryNames.join(', '));
    }

    if (showAllStock) {
      parts.add('All Stock');
    }

    if (weightMin > 0 || weightMax < 500) {
      parts.add('${weightMin.round()}g – ${weightMax.round()}g');
    }

    return parts.isEmpty ? 'All Products' : parts.join(' | ');
  }

  static Future<Uint8List> _loadLogoBytes(String path) async {
    final data = await rootBundle.load(path);
    return data.buffer.asUint8List();
  }

  static String _buildShareText(String filterInfo) {
    return '$_brandName\n$_brandSubtitle\n\nFilters: $filterInfo';
  }

  static Future<Uint8List?> _downloadImage(String imageUrl) async {
    try {
      final response = await _dio.get<List<int>>(
        imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      if (response.statusCode == 200 && response.data != null) {
        return Uint8List.fromList(response.data!);
      }
    } catch (e) {
      Logger.error("ShareService", "Failed to download image: $imageUrl\n$e");
    }
    return null;
  }

  static Future<void> shareImagesDirectly({
    required List<ProductModel> products,
    required String filterInfo,
  }) async {
    final tempDir = await getTemporaryDirectory();

    final imageFutures = products.asMap().entries.map((entry) async {
      final i = entry.key;
      final product = entry.value;
      final imageUrl = product.displayImageUrl;
      if (imageUrl == null || imageUrl.isEmpty) return null;

      final bytes = await _downloadImage(imageUrl);
      if (bytes == null) return null;

      final fileName = 'product_${i + 1}_${product.id}.jpg';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes);
      return XFile(file.path, name: fileName);
    }).toList();

    final results = await Future.wait(imageFutures);
    final files = results.whereType<XFile>().toList();

    if (files.isEmpty) return;

    final shareText = _buildShareText(filterInfo);

    await Share.shareXFiles(
      files,
      subject: _brandName,
      text: shareText,
    );
  }

  static Future<void> shareAsPdf({
    required List<ProductModel> products,
    required String filterInfo,
    String? title,
  }) async {
    final arhamLogoBytes = await _loadLogoBytes('assets/images/arham-logo-gold.png');
    final ratneshLogoBytes = await _loadLogoBytes('assets/images/ratnesh-logo-gold.png');

    final imageFutures = products.map((product) async {
      final imageUrl = product.displayImageUrl;
      if (imageUrl == null || imageUrl.isEmpty) return null;
      return _downloadImage(imageUrl);
    }).toList();

    final imageBytesList = await Future.wait(imageFutures);

    final productDataList = products.asMap().entries.map((entry) {
      final i = entry.key;
      final product = entry.value;
      return {
        'index': i,
        'name': product.name,
        'categoryName': product.category?.name,
        'fineWeight': product.fineWeight,
        'touch': product.touch,
      };
    }).toList();

    final pdfBytes = await compute(_buildPdfInIsolate, {
      'arhamLogoBytes': arhamLogoBytes,
      'ratneshLogoBytes': ratneshLogoBytes,
      'imageBytesList': imageBytesList,
      'productDataList': productDataList,
      'title': title,
      'totalProducts': products.length,
    });

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${tempDir.path}/${_brandName.replaceAll(' ', '')}_Products_$timestamp.pdf');
    await file.writeAsBytes(pdfBytes);

    await Share.shareXFiles(
      [XFile(file.path, name: '$_brandName Products.pdf')],
      subject: '$_brandName - Product Catalog',
      text: _buildShareText(filterInfo),
    );
  }
}

Future<List<int>> _buildPdfInIsolate(Map<String, dynamic> params) async {
  final arhamLogoBytes = params['arhamLogoBytes'] as Uint8List;
  final ratneshLogoBytes = params['ratneshLogoBytes'] as Uint8List;
  final imageBytesList = params['imageBytesList'] as List<Uint8List?>;
  final productDataList = params['productDataList'] as List<Map<String, dynamic>>;
  final title = params['title'] as String?;
  final totalProducts = params['totalProducts'] as int;

  final brandName = 'SHREE ARHAM GOLD & RATNESH GOLD';
  final brandSubtitle = 'Purity - Quality - Trust';

  final pdf = pw.Document();

  final brandFont = pw.Font.helvetica();
  final regularFont = pw.Font.helvetica();
  final lightFont = pw.Font.helvetica();

  final arhamLogo = pw.MemoryImage(arhamLogoBytes);
  final ratneshLogo = pw.MemoryImage(ratneshLogoBytes);

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
        style: pw.TextStyle(
          font: brandFont,
          fontSize: 24,
          color: PdfColor.fromHex('#A57A36'),
        ),
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        brandSubtitle,
        style: pw.TextStyle(
          font: lightFont,
          fontSize: 10,
          color: PdfColor.fromHex('#7E756C'),
        ),
      ),
      pw.SizedBox(height: 12),
      pw.Divider(color: PdfColor.fromHex('#A57A36'), thickness: 1),
      pw.SizedBox(height: 12),
      if (title != null) ...[
        pw.Text(
          title,
          style: pw.TextStyle(
            font: brandFont,
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#2D2118'),
          ),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 8),
      ],
      pw.Text(
        'Total Products: $totalProducts',
        style: pw.TextStyle(
          font: regularFont,
          fontSize: 11,
          color: PdfColor.fromHex('#7E756C'),
        ),
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
          child: pw.Center(child: headerContent),
        ),
      ],
    ),
  );

  final productWidgets = <pw.Widget>[];

  for (var i = 0; i < productDataList.length; i++) {
    final data = productDataList[i];
    final imageBytes = imageBytesList[i];

    pw.MemoryImage? image;
    if (imageBytes != null) {
      image = pw.MemoryImage(imageBytes);
    }

    final productWidget = pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromHex('#E3DDD5'), width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (image != null)
            pw.Container(
              width: 80,
              height: 80,
              decoration: pw.BoxDecoration(
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.ClipRRect(
                horizontalRadius: 4,
                verticalRadius: 4,
                child: pw.Image(image, fit: pw.BoxFit.cover),
              ),
            ),
          if (image != null) pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  (data['name'] as String).isNotEmpty
                      ? data['name'] as String
                      : 'Product ${i + 1}',
                  style: pw.TextStyle(
                    font: brandFont,
                    fontSize: 12,
                    color: PdfColor.fromHex('#2D2118'),
                  ),
                ),
                if (data['categoryName'] != null) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    data['categoryName'] as String,
                    style: pw.TextStyle(
                      font: regularFont,
                      fontSize: 10,
                      color: PdfColor.fromHex('#7E756C'),
                    ),
                  ),
                ],
                pw.SizedBox(height: 6),
                pw.Row(
                  children: [
                    _infoChip(
                      'Weight',
                      data['fineWeight'] != null
                          ? '${(data['fineWeight'] as double).toStringAsFixed(1)}g'
                          : '-',
                      regularFont,
                      brandFont,
                    ),
                    pw.SizedBox(width: 12),
                    _infoChip(
                      'Touch',
                      (data['touch'] as String?) ?? '-',
                      regularFont,
                      brandFont,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    productWidgets.add(productWidget);
  }

  for (int page = 0; page < totalProducts; page++) {
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (context) => [productWidgets[page]],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${page + 2} of ${totalProducts + 1}',
            style: pw.TextStyle(
              font: lightFont,
              fontSize: 8,
              color: PdfColor.fromHex('#7E756C'),
            ),
          ),
        ),
      ),
    );
  }

  return await pdf.save();
}

pw.Widget _infoChip(String label, String value, pw.Font regularFont, pw.Font boldFont) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: pw.BoxDecoration(
      color: PdfColor.fromHex('#F1EEE9'),
      borderRadius: pw.BorderRadius.circular(3),
    ),
    child: pw.RichText(
      text: pw.TextSpan(
        children: [
          pw.TextSpan(
            text: '$label: ',
            style: pw.TextStyle(
              font: regularFont,
              fontSize: 9,
              color: PdfColor.fromHex('#7E756C'),
            ),
          ),
          pw.TextSpan(
            text: value,
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 9,
              color: PdfColor.fromHex('#2D2118'),
            ),
          ),
        ],
      ),
    ),
  );
}
