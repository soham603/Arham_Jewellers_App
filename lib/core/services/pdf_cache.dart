import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

class PdfCache {
  static const String _cacheSubdir = 'shared_pdfs/cache';
  static const String _manifestFile = 'manifest.json';
  static const Duration defaultTtl = Duration(hours: 24);

  static Completer<void>? _manifestLock;

  static Future<T> _withManifestLock<T>(Future<T> Function() body) async {
    while (_manifestLock != null) {
      await _manifestLock!.future;
    }
    _manifestLock = Completer<void>();
    try {
      return await body();
    } finally {
      _manifestLock!.complete();
      _manifestLock = null;
    }
  }

  static Future<Directory> _getCacheDir() async {
    final tempDir = await getTemporaryDirectory();
    final cacheDir = Directory('${tempDir.path}/$_cacheSubdir');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  static Future<File> _getManifestFile() async {
    final cacheDir = await _getCacheDir();
    return File('${cacheDir.path}/$_manifestFile');
  }

  static Future<List<Map<String, dynamic>>> _readManifest() async {
    final manifestFile = await _getManifestFile();
    if (!await manifestFile.exists()) {
      return [];
    }
    try {
      final content = await manifestFile.readAsString();
      if (content.isEmpty) return [];
      final List<dynamic> data = jsonDecode(content);
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  static Future<void> _writeManifest(List<Map<String, dynamic>> entries) async {
    final manifestFile = await _getManifestFile();
    final content = jsonEncode(entries);
    await manifestFile.writeAsString(content);
  }

  static String _hashKey(String key) {
    final bytes = utf8.encode(key);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static Future<File?> get(String key) async {
    return _withManifestLock(() async {
      final manifest = await _readManifest();
      final hashedKey = _hashKey(key);

      final entry = manifest.firstWhere(
        (e) => e['key'] == hashedKey,
        orElse: () => <String, dynamic>{},
      );

      if (entry.isEmpty) return null;

      final path = entry['path'] as String;
      final file = File(path);

      if (!await file.exists()) {
        await invalidate(key);
        return null;
      }

      return file;
    });
  }

  static Future<File> put(String key, List<int> bytes) async {
    return _withManifestLock(() async {
      final cacheDir = await _getCacheDir();
      final hashedKey = _hashKey(key);
      final fileName = '$hashedKey.pdf';
      final filePath = '${cacheDir.path}/$fileName';
      final file = File(filePath);

      await file.writeAsBytes(bytes);
      final stat = await file.stat();

      final manifest = await _readManifest();
      manifest.removeWhere((e) => e['key'] == hashedKey);

      manifest.add({
        'key': hashedKey,
        'path': filePath,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'size': stat.size,
      });

      await _writeManifest(manifest);
      return file;
    });
  }

  static Future<void> invalidate(String key) async {
    return _withManifestLock(() async {
      final hashedKey = _hashKey(key);
      final manifest = await _readManifest();

      final entry = manifest.firstWhere(
        (e) => e['key'] == hashedKey,
        orElse: () => <String, dynamic>{},
      );

      if (entry.isNotEmpty) {
        final path = entry['path'] as String;
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }

      manifest.removeWhere((e) => e['key'] == hashedKey);
      await _writeManifest(manifest);
    });
  }

  static Future<void> clearStale({Duration ttl = defaultTtl}) async {
    return _withManifestLock(() async {
      final manifest = await _readManifest();
      final now = DateTime.now().millisecondsSinceEpoch;
      final cutoff = now - ttl.inMilliseconds;

      final staleEntries = manifest.where((e) {
        final timestamp = e['timestamp'] as int;
        return timestamp < cutoff;
      }).toList();

      for (final entry in staleEntries) {
        final path = entry['path'] as String;
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }

      manifest.removeWhere((e) {
        final timestamp = e['timestamp'] as int;
        return timestamp < cutoff;
      });

      await _writeManifest(manifest);
    });
  }

  static Future<void> clearAll() async {
    final cacheDir = await _getCacheDir();
    if (await cacheDir.exists()) {
      await cacheDir.delete(recursive: true);
    }
    await _getCacheDir();
  }
}
