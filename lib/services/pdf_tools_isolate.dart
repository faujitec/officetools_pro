import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui';

import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'package:office_toolspro/services/pdf_tools_service.dart';

/// Runs heavy Syncfusion PDF work off the UI isolate.
class PdfToolsIsolate {
  PdfToolsIsolate._();

  static Future<Uint8List> merge(List<Uint8List> inputs) =>
      Isolate.run(() => const PdfToolsService().merge(inputs));

  static Future<Uint8List> splitExtract(
          Uint8List input, Set<int> pagesToKeep) =>
      Isolate.run(
          () => const PdfToolsService().splitExtract(input, pagesToKeep));

  static Future<Uint8List> deletePages(
          Uint8List input, Set<int> pagesToDelete) =>
      Isolate.run(
          () => const PdfToolsService().deletePages(input, pagesToDelete));

  static Future<Uint8List> rearrange(Uint8List input, List<int> newOrder) =>
      Isolate.run(() => const PdfToolsService().rearrange(input, newOrder));

  static Future<Uint8List> rotateAll(
          Uint8List input, PdfPageRotateAngle angle) =>
      Isolate.run(() => const PdfToolsService().rotateAll(input, angle));

  static Future<Uint8List> rotateSelected(
    Uint8List input,
    PdfPageRotateAngle angle,
    Set<int> pagesToRotate,
  ) =>
      Isolate.run(
        () => const PdfToolsService().rotateSelected(
          input,
          angle,
          pagesToRotate,
        ),
      );

  static Future<Uint8List> compress(
          Uint8List input, PdfCompressionLevel level) =>
      Isolate.run(() => const PdfToolsService().compress(input, level));

  static Future<Uint8List> passwordProtect(Uint8List input, String password) =>
      Isolate.run(
          () => const PdfToolsService().passwordProtect(input, password));

  static Future<Uint8List> textPdf(String text) => Isolate.run(() {
        final doc = PdfDocument();
        try {
          final page = doc.pages.add();
          final font = PdfStandardFont(PdfFontFamily.helvetica, 11);
          page.graphics.drawString(
            text.trim().isEmpty ? ' ' : text,
            font,
            bounds: Rect.fromLTWH(0, 0, page.size.width, page.size.height),
          );
          return Uint8List.fromList(doc.saveSync());
        } finally {
          doc.dispose();
        }
      });
}
