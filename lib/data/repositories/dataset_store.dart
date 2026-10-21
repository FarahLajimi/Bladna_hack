import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/labeled_photo.dart';

/// Keeps the Litter Lens photos in the app's private documents folder, so
/// they survive restarts (the image picker's own files are temporary).
/// Nothing is uploaded anywhere.
class DatasetStore {
  static Future<Directory> _dir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/litter_lens');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Copies a picked image into the dataset folder and returns its new path.
  static Future<String> importPhoto(String sourcePath, String id) async {
    final dir = await _dir();
    final dot = sourcePath.lastIndexOf('.');
    final ext = dot >= 0 && sourcePath.length - dot <= 5 ? sourcePath.substring(dot) : '.jpg';
    final target = File('${dir.path}/$id$ext');
    await File(sourcePath).copy(target.path);
    return target.path;
  }

  static Future<void> deletePhoto(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {
      // Already gone — nothing to do.
    }
  }

  static Future<void> clearAll() async {
    try {
      final dir = await _dir();
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {
      // Ignore: reset must never crash.
    }
  }

  /// Writes labels.json next to the photos — a simple manifest a training
  /// script can read (file name + label + time).
  static Future<String> exportManifest(List<LabeledPhoto> photos) async {
    final dir = await _dir();
    final file = File('${dir.path}/labels.json');
    final data = {
      'format': 'bladna-litter-lens-v1',
      'note': 'Labels chosen by the player. Game categories, not official municipal streams.',
      'items': [
        for (final p in photos)
          {
            'file': p.path.split('/').last,
            'label': p.categoryId,
            'created': p.timestamp.toIso8601String(),
          },
      ],
    };
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
    return file.path;
  }
}
