import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart' show Color;
import 'package:http/http.dart' as http;

class CutoutResult {
  final Uint8List bytes;
  final bool removed;
  const CutoutResult(this.bytes, this.removed);
}

/// Background removal + colour detection for clothing photos.
///
/// * If you pass a remove.bg key (`flutter run --dart-define=REMOVE_BG_KEY=xxxx`)
///   the photo is cut out by remove.bg (best quality, works on any background).
/// * Otherwise a built-in, offline cutout is used. It works best when the
///   garment is laid flat on a plain surface (bed, floor, wall, white sheet).
class ImageService {
  static const String _removeBgKey = String.fromEnvironment('REMOVE_BG_KEY');

  static Future<CutoutResult> removeBackground(Uint8List original) async {
    if (_removeBgKey.isNotEmpty) {
      try {
        final r = await _removeBg(original);
        return CutoutResult(r, true);
      } catch (_) {
        // fall through to the local cutout
      }
    }
    try {
      return await _local(original);
    } catch (_) {
      return CutoutResult(original, false);
    }
  }

  static Future<Uint8List> _removeBg(Uint8List bytes) async {
    final req = http.MultipartRequest(
        'POST', Uri.parse('https://api.remove.bg/v1.0/removebg'))
      ..headers['X-Api-Key'] = _removeBgKey
      ..fields['size'] = 'auto'
      ..fields['crop'] = 'true'
      ..files.add(http.MultipartFile.fromBytes('image_file', bytes,
          filename: 'item.jpg'));
    final res = await req.send().timeout(const Duration(seconds: 40));
    final body = await res.stream.toBytes();
    if (res.statusCode != 200) throw Exception('remove.bg ${res.statusCode}');
    return body;
  }

  /// Flood-fills the background from the photo's edges, makes it transparent
  /// and crops to the garment.
  static Future<CutoutResult> _local(Uint8List original) async {
    final codec = await ui.instantiateImageCodec(original, targetWidth: 640);
    final frame = await codec.getNextFrame();
    final img = frame.image;
    final w = img.width, h = img.height;
    final data = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (data == null) return CutoutResult(original, false);
    final px = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

    // Background colour = median colour along the photo border.
    final rs = <int>[], gs = <int>[], bs = <int>[];
    void sample(int x, int y) {
      final i = (y * w + x) * 4;
      rs.add(px[i]);
      gs.add(px[i + 1]);
      bs.add(px[i + 2]);
    }

    for (var x = 0; x < w; x += 3) {
      sample(x, 0);
      sample(x, h - 1);
    }
    for (var y = 0; y < h; y += 3) {
      sample(0, y);
      sample(w - 1, y);
    }
    int med(List<int> l) {
      l.sort();
      return l[l.length ~/ 2];
    }

    final br = med(rs), bg = med(gs), bb = med(bs);
    const tol = 52;
    const tol2 = tol * tol;

    bool isBg(int idx) {
      final i = idx * 4;
      final dr = px[i] - br, dg = px[i + 1] - bg, db = px[i + 2] - bb;
      return dr * dr + dg * dg + db * db < tol2;
    }

    final mask = Uint8List(w * h); // 1 = background
    final queue = Int32List(w * h);
    var head = 0, tail = 0;
    void push(int idx) {
      if (mask[idx] == 0 && isBg(idx)) {
        mask[idx] = 1;
        queue[tail++] = idx;
      }
    }

    for (var x = 0; x < w; x++) {
      push(x);
      push((h - 1) * w + x);
    }
    for (var y = 0; y < h; y++) {
      push(y * w);
      push(y * w + w - 1);
    }
    while (head < tail) {
      final idx = queue[head++];
      final x = idx % w, y = idx ~/ w;
      if (x > 0) push(idx - 1);
      if (x < w - 1) push(idx + 1);
      if (y > 0) push(idx - w);
      if (y < h - 1) push(idx + w);
    }

    var minX = w, minY = h, maxX = -1, maxY = -1, fg = 0;
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        if (mask[y * w + x] == 0) {
          fg++;
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }
    }
    final frac = fg / (w * h);
    if (maxX < 0 || frac < 0.02 || frac > 0.92)
      return CutoutResult(original, false);

    const pad = 14;
    final x0 = max(0, minX - pad), y0 = max(0, minY - pad);
    final x1 = min(w - 1, maxX + pad), y1 = min(h - 1, maxY + pad);
    final cw = x1 - x0 + 1, ch = y1 - y0 + 1;
    final out = Uint8List(cw * ch * 4);

    bool bgAt(int x, int y) =>
        x < 0 || y < 0 || x >= w || y >= h || mask[y * w + x] == 1;

    for (var y = y0; y <= y1; y++) {
      for (var x = x0; x <= x1; x++) {
        if (mask[y * w + x] == 1) continue;
        final s = (y * w + x) * 4;
        final d = ((y - y0) * cw + (x - x0)) * 4;
        out[d] = px[s];
        out[d + 1] = px[s + 1];
        out[d + 2] = px[s + 2];
        final edge = bgAt(x - 1, y) ||
            bgAt(x + 1, y) ||
            bgAt(x, y - 1) ||
            bgAt(x, y + 1);
        out[d + 3] = edge ? 150 : 255;
      }
    }

    final c = Completer<ui.Image>();
    ui.decodeImageFromPixels(out, cw, ch, ui.PixelFormat.rgba8888, c.complete);
    final outImg = await c.future;
    final png = await outImg.toByteData(format: ui.ImageByteFormat.png);
    if (png == null) return CutoutResult(original, false);
    return CutoutResult(png.buffer.asUint8List(), true);
  }

  /// Estimates the dominant garment colour, ignoring transparent / studio-white pixels.
  static Future<Color?> dominantColor(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 48);
      final frame = await codec.getNextFrame();
      final data =
          await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (data == null) return null;
      double r = 0, g = 0, b = 0;
      var n = 0;
      for (var i = 0; i + 3 < data.lengthInBytes; i += 4) {
        final pr = data.getUint8(i),
            pg = data.getUint8(i + 1),
            pb = data.getUint8(i + 2),
            pa = data.getUint8(i + 3);
        if (pa < 128) continue;
        if (pr > 238 && pg > 238 && pb > 238) continue;
        r += pr;
        g += pg;
        b += pb;
        n++;
      }
      if (n < 20) return const Color(0xFFFFFFFF);
      return Color.fromARGB(
          255, (r / n).round(), (g / n).round(), (b / n).round());
    } catch (_) {
      return null;
    }
  }
}
