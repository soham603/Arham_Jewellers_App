import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

/// Downloads a network image to a temporary local [File].
/// Returns `null` if the download fails.
Future<File?> downloadNetworkImageToFile(String imageUrl) async {
  try {
    final dio = Dio();
    final dir = await getTemporaryDirectory();
    final filePath =
        '${dir.path}/network_img_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final response = await dio.download(
      imageUrl,
      filePath,
      options: Options(receiveTimeout: const Duration(seconds: 15)),
    );

    if (response.statusCode == 200) {
      final file = File(filePath);
      if (await file.exists()) return file;
    }
    return null;
  } catch (_) {
    return null;
  }
}
