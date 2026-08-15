import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class DominantColor {
  static const Color _fallbackColor = Color(0xFFE0E0E0);

  static final Map<String, Color> _cache = {};
  static final Map<String, Future<Color?>> _inflight = {};

  static Future<Color?> forUrl(String url) async {
    final cached = _cache[url];
    if (cached != null) return cached;
    final inFlight = _inflight[url];
    if (inFlight != null) return inFlight;

    final future = _compute(url);
    _inflight[url] = future;
    try {
      final color = await future;
      if (color != null) _cache[url] = color;
      return color;
    } finally {
      _inflight.remove(url);
    }
  }

  static Future<Color?> _compute(String url) async {
    try {
      final file = await DefaultCacheManager().getSingleFile(url);
      final bytes = await file.readAsBytes();
      return _dominantColor(bytes);
    } catch (_) {
      return null;
    }
  }

  static Future<Color?> _dominantColor(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: 48,
      targetHeight: 48,
    );
    final frame = await codec.getNextFrame();
    final image = frame.image;
    try {
      final data =
          await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
      if (data == null) return null;
      return _extract(data, image.width, image.height);
    } finally {
      image.dispose();
      codec.dispose();
    }
  }

	static Color _extract(ByteData data, int width, int height) {
	  final counts = <int, int>{};
	  final rs = <int, int>{};
	  final gs = <int, int>{};
	  final bs = <int, int>{};

	  for (int i = 0; i < width * height; i++) {
	    final offset = i * 4;
	    if (data.getUint8(offset + 3) < 128) continue;

	    final r = data.getUint8(offset);
	    final g = data.getUint8(offset + 1);
	    final b = data.getUint8(offset + 2);

	    // Quantize to reduce noise and map size
	    final key = (r & 0xF0) << 16 | (g & 0xF0) << 8 | (b & 0xF0);
	    counts[key] = (counts[key] ?? 0) + 1;
	    rs[key] = (rs[key] ?? 0) + r;
	    gs[key] = (gs[key] ?? 0) + g;
	    bs[key] = (bs[key] ?? 0) + b;
	  }

	  if (counts.isEmpty) return _fallbackColor;

	  int bestKey = 0;
	  double bestScore = -1;
	  for (final MapEntry<int, int> entry in counts.entries) {
	    final key = entry.key;
	    final count = entry.value;

	    final r = (key >> 16) & 0xFF;
	    final g = (key >> 8) & 0xFF;
	    final b = key & 0xFF;

	    final maxC = r >= g ? (r >= b ? r : b) : (g >= b ? g : b);
	    final minC = r <= g ? (r <= b ? r : b) : (g <= b ? g : b);
	    final luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
	    final saturation = maxC == 0 ? 0.0 : (maxC - minC) / maxC;

	    // Gray/black buckets get a smaller vote so small dark regions
	    // (shadows, black bars) can't beat large colorful gradients.
	    final darknessPenalty = luminance < 0.08 ? 0.2 : 1.0;
	    final score = count * (0.25 + 0.75 * saturation) * darknessPenalty;

	    if (score > bestScore) {
	      bestScore = score;
	      bestKey = key;
	    }
	  }

	  final n = counts[bestKey]!;
	  return Color.fromARGB(
	    255,
	    (rs[bestKey]! / n).round(),
	    (gs[bestKey]! / n).round(),
	    (bs[bestKey]! / n).round(),
	  );
	}
}
