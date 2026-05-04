import 'dart:ui';
import 'dart:typed_data';

import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfToolsService {
  const PdfToolsService();

  Uint8List merge(List<Uint8List> inputs) {
    final output = PdfDocument();
    final opened = <PdfDocument>[];
    try {
      for (final bytes in inputs) {
        final src = PdfDocument(inputBytes: bytes);
        opened.add(src);
        for (int i = 0; i < src.pages.count; i++) {
          _copyPage(src.pages[i], output);
        }
      }
      return Uint8List.fromList(output.saveSync());
    } finally {
      for (final doc in opened) {
        doc.dispose();
      }
      output.dispose();
    }
  }

  Uint8List splitExtract(Uint8List input, Set<int> pagesToKeep) {
    final src = PdfDocument(inputBytes: input);
    final out = PdfDocument();
    try {
      for (final oneBased in pagesToKeep.toList()..sort()) {
        if (oneBased > 0 && oneBased <= src.pages.count) {
          _copyPage(src.pages[oneBased - 1], out);
        }
      }
      return Uint8List.fromList(out.saveSync());
    } finally {
      src.dispose();
      out.dispose();
    }
  }

  Uint8List deletePages(Uint8List input, Set<int> pagesToDelete) {
    final src = PdfDocument(inputBytes: input);
    final out = PdfDocument();
    try {
      for (int i = 1; i <= src.pages.count; i++) {
        if (!pagesToDelete.contains(i)) {
          _copyPage(src.pages[i - 1], out);
        }
      }
      return Uint8List.fromList(out.saveSync());
    } finally {
      src.dispose();
      out.dispose();
    }
  }

  Uint8List rearrange(Uint8List input, List<int> newOrder) {
    final src = PdfDocument(inputBytes: input);
    final out = PdfDocument();
    try {
      for (final oneBased in newOrder) {
        if (oneBased > 0 && oneBased <= src.pages.count) {
          _copyPage(src.pages[oneBased - 1], out);
        }
      }
      return Uint8List.fromList(out.saveSync());
    } finally {
      src.dispose();
      out.dispose();
    }
  }

  Uint8List rotateAll(Uint8List input, PdfPageRotateAngle angle) {
    final doc = PdfDocument(inputBytes: input);
    try {
      for (int i = 0; i < doc.pages.count; i++) {
        doc.pages[i].rotation = angle;
      }
      return Uint8List.fromList(doc.saveSync());
    } finally {
      doc.dispose();
    }
  }

  Uint8List rotateSelected(Uint8List input, PdfPageRotateAngle angle, Set<int> pagesToRotate) {
    final doc = PdfDocument(inputBytes: input);
    try {
      for (int i = 0; i < doc.pages.count; i++) {
        final oneBased = i + 1;
        if (pagesToRotate.contains(oneBased)) {
          doc.pages[i].rotation = angle;
        }
      }
      return Uint8List.fromList(doc.saveSync());
    } finally {
      doc.dispose();
    }
  }

  Uint8List compress(Uint8List input, PdfCompressionLevel level) {
    final doc = PdfDocument(inputBytes: input);
    try {
      doc.compressionLevel = level;
      return Uint8List.fromList(doc.saveSync());
    } finally {
      doc.dispose();
    }
  }

  Uint8List passwordProtect(Uint8List input, String password) {
    final doc = PdfDocument(inputBytes: input);
    try {
      doc.security.userPassword = password;
      doc.security.ownerPassword = password;
      return Uint8List.fromList(doc.saveSync());
    } finally {
      doc.dispose();
    }
  }

  int pageCount(Uint8List input) {
    final doc = PdfDocument(inputBytes: input);
    try {
      return doc.pages.count;
    } finally {
      doc.dispose();
    }
  }

  void _copyPage(PdfPage source, PdfDocument target) {
    final page = target.pages.add();
    page.graphics.drawPdfTemplate(
      source.createTemplate(),
      const Offset(0, 0),
      source.size,
    );
  }
}
