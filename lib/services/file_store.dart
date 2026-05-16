import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:office_toolspro/models/file_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FileStore {
  FileStore._();
  static const _prefsKey = 'file_store_items_v1';
  static final ValueNotifier<List<FileItem>> files =
      ValueNotifier<List<FileItem>>([]);

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      final list = <FileItem>[];
      for (final e in decoded) {
        if (e is! Map) continue;
        final m = Map<String, dynamic>.from(e);
        final item = FileItem.fromJson(m);
        if (item.path != null && item.path!.isNotEmpty) {
          if (!await File(item.path!).exists()) continue;
        }
        if (item.thumbnailPath != null && item.thumbnailPath!.isNotEmpty) {
          if (!await File(item.thumbnailPath!).exists()) {
            list.add(
              FileItem(
                id: item.id,
                name: item.name,
                type: item.type,
                date: item.date,
                content: item.content,
                path: item.path,
                thumbnailPath: null,
              ),
            );
            continue;
          }
        }
        list.add(item);
      }
      files.value = list;
    } catch (_) {
      // Corrupt or incompatible cache — ignore.
      debugPrint('[file_store] load failed (ignored)');
    }
  }

  static Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = jsonEncode(files.value.map((f) => f.toJson()).toList());
      await prefs.setString(_prefsKey, payload);
    } catch (_) {
      // Storage full or prefs unavailable — non-fatal.
      debugPrint('[file_store] save failed (ignored)');
    }
  }

  static void addFile(FileItem file) {
    files.value = [file, ...files.value];
    _save();
  }

  static void removeById(String id) {
    files.value = files.value.where((f) => f.id != id).toList(growable: false);
    _save();
  }

  static void restore(FileItem file, {int index = 0}) {
    final list = List<FileItem>.from(files.value);
    final safeIndex = index.clamp(0, list.length).toInt();
    list.insert(safeIndex, file);
    files.value = list;
    _save();
  }

  static void renameById(String id, String newName) {
    updateById(id: id, newName: newName);
  }

  static void updateById({
    required String id,
    String? newName,
    String? newPath,
    String? newThumbnailPath,
  }) {
    final trimmed = newName?.trim() ?? '';
    if (newName != null && trimmed.isEmpty) return;
    files.value = files.value
        .map(
          (f) => f.id == id
              ? FileItem(
                  id: f.id,
                  name: newName == null ? f.name : trimmed,
                  type: f.type,
                  date: f.date,
                  content: f.content,
                  path: newPath ?? f.path,
                  thumbnailPath: newThumbnailPath ?? f.thumbnailPath,
                )
              : f,
        )
        .toList(growable: false);
    _save();
  }
}
