import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:ratnesh_gold_app/domain/entities/productModel.dart';
import 'package:ratnesh_gold_app/utils/Logger.dart';

class ShareService {
  static const String _brandName = 'ARHAM JEWELLERS';
  static const String _brandSubtitle = 'Purity • Quality • Trust';

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

  static String _buildShareText(String filterInfo) {
    return '$_brandName\n$_brandSubtitle\n\nFilters: $filterInfo';
  }

  static Future<void> shareImagesDirectly({
    required List<ProductModel> products,
    required String filterInfo,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final files = <XFile>[];
    final dio = Dio();

    for (var i = 0; i < products.length; i++) {
      final product = products[i];
      final imageUrl = product.displayImageUrl;
      if (imageUrl == null || imageUrl.isEmpty) continue;

      try {
        final response = await dio.get<List<int>>(
          imageUrl,
          options: Options(responseType: ResponseType.bytes),
        );
        if (response.statusCode == 200 && response.data != null) {
          final fileName = 'product_${i + 1}_${product.id}.jpg';
          final file = File('${tempDir.path}/$fileName');
          await file.writeAsBytes(response.data!);
          files.add(XFile(file.path, name: fileName));
        }
      } catch (e) {
        Logger.error("ShareService", "Failed to download image for product ${product.id}: $imageUrl\n$e");
      }
    }

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
  }) async {
    final pdf = pw.Document();

    // Use built-in fonts
    final brandFont = pw.Font.helvetica();
    final regularFont = pw.Font.helvetica();
    final lightFont = pw.Font.helvetica();

    // Header section
    final headerSection = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          _brandName,
          style: pw.TextStyle(
            font: brandFont,
            fontSize: 24,
            color: PdfColor.fromHex('#A57A36'),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          _brandSubtitle,
          style: pw.TextStyle(
            font: lightFont,
            fontSize: 10,
            color: PdfColor.fromHex('#7E756C'),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Divider(color: PdfColor.fromHex('#A57A36'), thickness: 1),
        pw.SizedBox(height: 8),
        pw.Text(
          'Filters: $filterInfo',
          style: pw.TextStyle(
            font: regularFont,
            fontSize: 11,
            color: PdfColor.fromHex('#2D2118'),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Total Products: ${products.length}',
          style: pw.TextStyle(
            font: regularFont,
            fontSize: 10,
            color: PdfColor.fromHex('#7E756C'),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Divider(color: PdfColor.fromHex('#E3DDD5'), thickness: 0.5),
      ],
    );

    // Download images and build product entries
    final productWidgets = <pw.Widget>[];
    final dio = Dio();

    for (var i = 0; i < products.length; i++) {
      final product = products[i];
      final imageUrl = product.displayImageUrl;

      pw.MemoryImage? image;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          final response = await dio.get<List<int>>(
            imageUrl,
            options: Options(responseType: ResponseType.bytes),
          );
          if (response.statusCode == 200 && response.data != null) {
            image = pw.MemoryImage(Uint8List.fromList(response.data!));
          }
        } catch (e) {
          Logger.error("ShareService", "Failed to download image for PDF: product ${product.id}: $imageUrl\n$e");
        }
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
                    product.name.isNotEmpty ? product.name : 'Product ${i + 1}',
                    style: pw.TextStyle(
                      font: brandFont,
                      fontSize: 12,
                      color: PdfColor.fromHex('#2D2118'),
                    ),
                  ),
                  if (product.category?.name != null) ...[
                    pw.SizedBox(height: 4),
                    pw.Text(
                      product.category!.name,
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
                      _infoChip('Weight', product.fineWeight != null ? '${product.fineWeight!.toStringAsFixed(1)}g' : '-', regularFont, brandFont),
                      pw.SizedBox(width: 12),
                      _infoChip('Touch', product.touch ?? '-', regularFont, brandFont),
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

    // Build PDF pages (split into chunks of 4 products per page)
    final int totalCount = products.length;
    final int perPage = 4;
    final int totalPages = (totalCount / perPage).ceil();

    for (int page = 0; page < totalPages; page++) {
      final int start = page * perPage;
      final int end = (start + perPage < totalCount) ? start + perPage : totalCount;
      final pageProducts = productWidgets.sublist(start, end);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(30),
          header: (context) => page == 0 ? headerSection : pw.SizedBox(),
          build: (context) => pageProducts,
          footer: (context) => pw.Container(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Page ${page + 1} of $totalPages',
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

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${tempDir.path}/${_brandName.replaceAll(' ', '')}_Products_$timestamp.pdf');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles(
      [XFile(file.path, name: '$_brandName Products.pdf')],
      subject: '$_brandName - Product Catalog',
      text: _buildShareText(filterInfo),
    );
  }

  static pw.Widget _infoChip(String label, String value, pw.Font regularFont, pw.Font boldFont) {
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
}
