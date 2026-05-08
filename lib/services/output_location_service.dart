import 'dart:io';

import 'package:path_provider/path_provider.dart';

class OutputLocationService {
  OutputLocationService._();

  static const String folderName = 'OfficeTools Pro';

  static Future<Directory> resolveOutputDirectory() async {
    Directory? base;
    try {
      base = await getDownloadsDirectory();
    } catch (_) {
      base = null;
    }
    if (Platform.isAndroid) {
      const candidates = [
        '/storage/emulated/0/Download',
        '/sdcard/Download',
      ];
      for (final path in candidates) {
        final d = Directory(path);
        try {
          if (await d.exists()) {
            base = d;
            break;
          }
        } catch (_) {
          // Try next candidate.
        }
      }
    }
    base ??= await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/$folderName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}
