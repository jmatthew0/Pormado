import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Saves the wardrobe on the phone: one JSON file plus one PNG per clothing photo.
class Storage {
  static Directory? _root;

  static Future<Directory?> _dir() async {
    if (kIsWeb) return null;
    if (_root != null) return _root;
    try {
      final docs = await getApplicationDocumentsDirectory();
      final root = Directory('${docs.path}/pormado');
      if (!await root.exists()) await root.create(recursive: true);
      final photos = Directory('${root.path}/photos');
      if (!await photos.exists()) await photos.create();
      _root = root;
      return root;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> readJson() async {
    final d = await _dir();
    if (d == null) return null;
    final f = File('${d.path}/wardrobe.json');
    if (!await f.exists()) return null;
    try {
      return jsonDecode(await f.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> writeJson(Map<String, dynamic> json) async {
    final d = await _dir();
    if (d == null) return;
    final tmp = File('${d.path}/wardrobe.json.tmp');
    await tmp.writeAsString(jsonEncode(json), flush: true);
    await tmp.rename('${d.path}/wardrobe.json');
  }

  static Future<Uint8List?> readPhoto(String id) async {
    final d = await _dir();
    if (d == null) return null;
    final f = File('${d.path}/photos/$id.png');
    return await f.exists() ? await f.readAsBytes() : null;
  }

  static Future<void> writePhoto(String id, Uint8List bytes) async {
    final d = await _dir();
    if (d == null) return;
    await File('${d.path}/photos/$id.png').writeAsBytes(bytes, flush: true);
  }

  static Future<void> deletePhoto(String id) async {
    final d = await _dir();
    if (d == null) return;
    final f = File('${d.path}/photos/$id.png');
    if (await f.exists()) await f.delete();
  }
}
