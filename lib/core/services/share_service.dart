import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:ratnesh_gold_app/domain/entities/productModel.dart';
import 'package:ratnesh_gold_app/services/Dependencies.dart';
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

  static String _buildShareText(String filterInfo, {String? title}) {
    if (title != null && title.isNotEmpty) {
      return '$_brandName\n$_brandSubtitle\n\n$title';
    }
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
    String? title,
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

    final shareText = _buildShareText(filterInfo, title: title);

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
        'fineWeight': product.netWeight ?? product.fineWeight,
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

    await Share.shareXFiles(
      [XFile(file.path, name: shareFileName)],
      subject: '$_brandName - Product Catalog',
      text: _buildShareText(filterInfo, title: title),
    );
  }

  /// Fetches products for the given category IDs, deduplicates, and shares as images.
  static Future<void> shareImagesFromCategories({
    required List<String> categoryIds,
    required String filterInfo,
    String? title,
  }) async {
    final products = await _fetchProductsForCategories(categoryIds);
    if (products.isEmpty) return;
    await shareImagesDirectly(products: products, filterInfo: filterInfo, title: title);
  }

  /// Fetches products for the given category IDs, deduplicates, and shares as PDF.
  static Future<void> sharePdfFromCategories({
    required List<String> categoryIds,
    required String filterInfo,
    String? title,
  }) async {
    final products = await _fetchProductsForCategories(categoryIds);
    if (products.isEmpty) return;
    await shareAsPdf(products: products, filterInfo: filterInfo, title: title);
  }

  /// Fetches products for multiple category IDs (one request per category) and deduplicates.
  static Future<List<ProductModel>> _fetchProductsForCategories(List<String> categoryIds) async {
    final allProducts = <ProductModel>[];
    final seen = <String>{};

    for (final categoryId in categoryIds) {
      try {
        final response = await httpClient.get(
          "/api/v1/products/get-all",
          queryParameters: {
            "categoryId": categoryId,
            "page": 1,
            "limit": 500,
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
        }
      } catch (e) {
        Logger.error("ShareService", "Failed to fetch products for category $categoryId: $e");
      }
    }

    return allProducts;
  }

  static Future<File> shareCartEnquiryPdf({
    required List<ProductModel> products,
    required List<int> quantities,
  }) async {
    final arhamLogoBytes = await _loadLogoBytes('assets/images/arham-logo-gold.png');
    final ratneshLogoBytes = await _loadLogoBytes('assets/images/ratnesh-logo-gold.png');

    final imageFutures = products.map((p) async {
      final url = p.displayImageUrl;
      if (url == null || url.isEmpty) return null;
      return _downloadImage(url);
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
        'netWt': p.netWeight ?? p.fineWeight,
        'qty': quantities[i],
      });
    }

    final pdfBytes = await compute(_buildCartEnquiryPdfInIsolate, {
      'arhamLogoBytes': arhamLogoBytes,
      'ratneshLogoBytes': ratneshLogoBytes,
      'rows': rows,
      'imageBytesList': imageBytesList,
    });

    final tempDir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'Cart_Enquiry_$timestamp.pdf';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(pdfBytes);

    return file;
  }

  static Future<File> shareOrderDetailsPdf({
    required String orderId,
    int? orderToken,
    required String status,
    required DateTime createdAt,
    required List<Map<String, dynamic>> items,
    double? totalAmount,
  }) async {
    final arhamLogoBytes = await _loadLogoBytes('assets/images/arham-logo-gold.png');
    final ratneshLogoBytes = await _loadLogoBytes('assets/images/ratnesh-logo-gold.png');

    final imageFutures = items.map((item) async {
      final url = item['imageUrl'] as String?;
      if (url == null || url.isEmpty) return null;
      return _downloadImage(url);
    }).toList();
    final imageBytesList = await Future.wait(imageFutures);

    final pdfBytes = await compute(_buildOrderDetailsPdfInIsolate, {
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

    final tempDir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final displayId = orderToken != null ? '$orderToken' : orderId.substring(0, 8).toUpperCase();
    final fileName = 'Order_${displayId}_$timestamp.pdf';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(pdfBytes);

    return file;
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

    final availableWidth = PdfPageFormat.a4.width - 60;
    final maxImageHeight = 580.0;
    double imageDisplayHeight = maxImageHeight;
    if (image != null) {
      final imgW = image.width?.toDouble() ?? availableWidth;
      final imgH = image.height?.toDouble() ?? maxImageHeight;
      final aspectRatio = imgH / imgW;
      imageDisplayHeight = availableWidth * aspectRatio;
      if (imageDisplayHeight > maxImageHeight) {
        imageDisplayHeight = maxImageHeight;
      }
    }

    final productWidget = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (image != null)
          pw.Container(
            width: availableWidth,
            height: imageDisplayHeight,
            decoration: pw.BoxDecoration(
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.ClipRRect(
              horizontalRadius: 4,
              verticalRadius: 4,
              child: pw.Image(image, fit: pw.BoxFit.contain),
            ),
          ),
        pw.SizedBox(height: 14),
        pw.Text(
          (data['name'] as String).isNotEmpty
              ? data['name'] as String
              : 'Product ${i + 1}',
          style: pw.TextStyle(
            font: brandFont,
            fontSize: 14,
            color: PdfColor.fromHex('#2D2118'),
          ),
        ),
        pw.SizedBox(height: 4),
        if (data['categoryName'] != null)
          pw.Text(
            data['categoryName'] as String,
            style: pw.TextStyle(
              font: regularFont,
              fontSize: 11,
              color: PdfColor.fromHex('#7E756C'),
            ),
          ),
        pw.SizedBox(height: 8),
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

  // Column widths for A4 (usable width ≈ 523 pts with 30pt margins)
  // Image(40) + #(28) + Name(155) + Category(95) + Karat(70) + NetWt(68) + Qty(42) ≈ 498
  final colWidths = <double>[40, 28, 155, 95, 70, 68, 42];

  final tableHeaderStyle = pw.TextStyle(font: boldFont, fontSize: 9, color: PdfColor.fromHex('#FFFFFF'));
  final tableCellStyle = pw.TextStyle(font: regularFont, fontSize: 8.5, color: darkColor);

  pw.TableRow buildRow(List<String> cells, {bool isHeader = false, pw.MemoryImage? image}) {
    final children = <pw.Widget>[];

    // Image cell
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
                '${cells[0]}',
                style: pw.TextStyle(font: regularFont, fontSize: 8, color: mutedColor),
              ),
            ),
          ),
        ),
      );
    }

    // Text cells
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
        r['netWt'] != null ? '${(r['netWt'] as double).toStringAsFixed(2)}' : '-',
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

  final colWidths = <double>[40, 200, 60, 100, 80];

  final tableHeaderStyle = pw.TextStyle(font: boldFont, fontSize: 9, color: PdfColors.white);
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
    buildRow(['', 'Item', 'Qty', 'Price', 'Status'], isHeader: true),
    ...items.asMap().entries.map((entry) {
      final ci = entry.key;
      final item = entry.value;
      final imgBytes = ci < imageBytesList.length ? imageBytesList[ci] : null;
      final img = imgBytes != null ? pw.MemoryImage(imgBytes) : null;
      final itemStatus = item['isRejected'] == true ? 'Rejected' : 'Confirmed';
      return buildRow([
        item['name'] as String? ?? '-',
        '${item['quantity'] ?? 0}',
        '₹${(item['price'] as double? ?? 0).toStringAsFixed(2)}',
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
                '₹${totalAmount.toStringAsFixed(2)}',
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
