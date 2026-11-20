import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Hooks for photo processing when digitizing a clothing item.
class ImageService {
  /// Flip to true once a real background-removal backend is wired into
  /// [processPhoto] (e.g. an ML Kit subject-segmentation plugin or the
  /// remove.bg API). The UI badge adapts automatically.
  static const bool removesBackground = false;

  /// Returns the path of the processed photo. Currently a pass-through.
  static Future<String> processPhoto(String path) async => path;

  /// Estimates the dominant garment colour from a local photo by sampling
  /// pixels and ignoring transparent / near-white studio backgrounds.
  static Future<Color?> dominantColor(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 48);
      final frame = await codec.getNextFrame();
      final data = await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (data == null) return null;
      double r = 0, g = 0, b = 0;
      var n = 0;
      for (var i = 0; i + 3 < data.lengthInBytes; i += 4) {
        final pr = data.getUint8(i), pg = data.getUint8(i + 1), pb = data.getUint8(i + 2), pa = data.getUint8(i + 3);
        if (pa < 128) continue;
        if (pr > 238 && pg > 238 && pb > 238) continue; // studio white
        r += pr;
        g += pg;
        b += pb;
        n++;
      }
      if (n < 20) return const Color(0xFFFFFFFF);
      return Color.fromARGB(255, (r / n).round(), (g / n).round(), (b / n).round());
    } catch (_) {
      return null;
    }
  }
}
