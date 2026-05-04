import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:office_toolspro/models/file_item.dart';
import 'package:office_toolspro/services/analytics_service.dart';
import 'package:office_toolspro/services/convert_service.dart';
import 'package:office_toolspro/services/compress_service.dart';
import 'package:office_toolspro/services/file_store.dart';
import 'package:office_toolspro/services/ocr_service.dart';
import 'package:office_toolspro/services/pdf_tools_service.dart';
import 'package:office_toolspro/services/selfie_segmentation_service.dart';
import 'package:office_toolspro/widgets/global_banner_ad.dart';
import 'package:office_toolspro/widgets/upload_drop_card.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class ToolOption {
  final String id;
  final String name;
  final IconData icon;
  final bool requiresInternet;
  final bool isBeta;

  const ToolOption({
    required this.id,
    required this.name,
    required this.icon,
    this.requiresInternet = false,
    this.isBeta = false,
  });
}

const List<ToolOption> imageTools = <ToolOption>[
  ToolOption(id: 'resize', name: 'Resize Image', icon: Icons.open_in_full_rounded),
  ToolOption(id: 'crop', name: 'Crop Image', icon: Icons.crop_rounded),
  ToolOption(
    id: 'remove-bg',
    name: 'Remove Background',
    icon: Icons.layers_outlined,
  ),
  ToolOption(id: 'compress-img', name: 'Compress Image', icon: Icons.file_download_outlined),
  ToolOption(id: 'convert-img', name: 'Convert Format', icon: Icons.sync_rounded),
];

const List<ToolOption> pdfTools = <ToolOption>[
  ToolOption(id: 'merge', name: 'Merge PDFs', icon: Icons.layers_outlined),
  ToolOption(id: 'split', name: 'Split PDF', icon: Icons.content_cut_rounded),
  ToolOption(id: 'rearrange', name: 'Rearrange Pages', icon: Icons.picture_as_pdf_outlined),
  ToolOption(id: 'delete', name: 'Delete Pages', icon: Icons.delete_outline_rounded),
  ToolOption(id: 'rotate', name: 'Rotate Pages', icon: Icons.rotate_right_rounded),
  ToolOption(id: 'compress-pdf', name: 'Compress PDF', icon: Icons.compress_rounded),
  ToolOption(id: 'password', name: 'Password Protect', icon: Icons.lock_outline_rounded),
  ToolOption(
    id: 'ocr',
    name: 'OCR (Extract Text)',
    icon: Icons.document_scanner_outlined,
    requiresInternet: true,
  ),
];

const List<ToolOption> convertTools = <ToolOption>[
  ToolOption(
    id: 'pdf-word',
    name: 'PDF to Word',
    icon: Icons.description_outlined,
    requiresInternet: true,
    isBeta: true,
  ),
  ToolOption(
    id: 'word-pdf',
    name: 'Word to PDF',
    icon: Icons.picture_as_pdf_outlined,
    requiresInternet: true,
    isBeta: true,
  ),
  ToolOption(id: 'img-pdf', name: 'Image to PDF', icon: Icons.image_outlined),
  ToolOption(id: 'img-convert', name: 'Image Format', icon: Icons.photo_size_select_large_outlined),
  ToolOption(id: 'text-pdf', name: 'Text to PDF', icon: Icons.text_snippet_outlined),
  ToolOption(
    id: 'excel-pdf',
    name: 'Excel to PDF',
    icon: Icons.table_chart_outlined,
    requiresInternet: true,
    isBeta: true,
  ),
];

const int _maxImageInputBytes = 20 * 1024 * 1024;
const int _maxPdfInputBytes = 50 * 1024 * 1024;
const int _maxDocInputBytes = 30 * 1024 * 1024;

class ImageToolsScreen extends StatelessWidget {
  const ImageToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _ToolListScaffold(
      title: 'Image Tools',
      tools: imageTools,
      onTap: (tool) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ImageProcessingScreen(tool: tool),
          ),
        );
      },
    );
  }
}

class PdfToolsScreen extends StatelessWidget {
  final String apiKey;
  const PdfToolsScreen({super.key, required this.apiKey});

  @override
  Widget build(BuildContext context) {
    return _ToolListScaffold(
      title: 'PDF Tools',
      tools: pdfTools,
      onTap: (tool) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => PdfProcessingScreen(tool: tool, apiKey: apiKey),
          ),
        );
      },
    );
  }
}

class _ToolListScaffold extends StatelessWidget {
  final String title;
  final List<ToolOption> tools;
  final void Function(ToolOption tool) onTap;

  const _ToolListScaffold({
    required this.title,
    required this.tools,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1857E6),
            letterSpacing: 0.2,
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          const InlineBannerAd(),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              itemCount: tools.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final tool = tools[index];
                return _ToolListTile(
                  tool: tool,
                  onTap: () {
                    AnalyticsService.logEvent('tool_open', props: {'tool_id': tool.id});
                    onTap(tool);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ConvertScreen extends StatefulWidget {
  final String cloudConvertApiKey;
  const ConvertScreen({super.key, required this.cloudConvertApiKey});

  @override
  State<ConvertScreen> createState() => _ConvertScreenState();
}

class _ConvertScreenState extends State<ConvertScreen> {
  @override
  Widget build(BuildContext context) {
    return _ToolListScaffold(
      title: 'Convert Files',
      tools: convertTools,
      onTap: (tool) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => _ConvertToolScreen(
              tool: tool,
              cloudConvertApiKey: widget.cloudConvertApiKey,
            ),
          ),
        );
      },
    );
  }
}

class _ConvertToolScreen extends StatefulWidget {
  final ToolOption tool;
  final String cloudConvertApiKey;

  const _ConvertToolScreen({
    required this.tool,
    required this.cloudConvertApiKey,
  });

  @override
  State<_ConvertToolScreen> createState() => _ConvertToolScreenState();
}

class _ConvertToolScreenState extends State<_ConvertToolScreen> {
  fp.PlatformFile? _selectedFile;
  final TextEditingController _textController = TextEditingController();
  bool _processing = false;
  bool _success = false;
  int _progress = 0;
  String _resultMessage = '';
  String? _lastOutputPath;
  String _imageOutputFormat = 'jpg';
  Timer? _timer;

  Future<void> _pickFile() async {
    fp.FileType type = fp.FileType.any;
    List<String>? allowed;
    switch (widget.tool.id) {
      case 'img-pdf':
      case 'img-convert':
        type = fp.FileType.image;
        break;
      case 'pdf-word':
        type = fp.FileType.custom;
        allowed = ['pdf'];
        break;
      case 'word-pdf':
        type = fp.FileType.custom;
        allowed = ['doc', 'docx'];
        break;
      case 'excel-pdf':
        type = fp.FileType.custom;
        allowed = ['xls', 'xlsx'];
        break;
    }
    final picked = await fp.FilePicker.platform.pickFiles(
      type: type,
      allowedExtensions: allowed,
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;
    final file = picked.files.first;
    final bytes = file.bytes;
    if (bytes == null) return;
    setState(() => _selectedFile = file);
  }

  Future<String> _saveConverted(Uint8List bytes, String ext, String toolId) async {
    final dir = await getApplicationDocumentsDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final path = '${dir.path}/Converted_${toolId}_$ts.$ext';
    final out = File(path);
    await out.writeAsBytes(bytes, flush: true);
    return path;
  }

  Future<void> _convert() async {
    _timer?.cancel();
    setState(() {
      _processing = true;
      _success = false;
      _progress = 0;
      _resultMessage = '';
    });
    _timer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (_progress >= 90) {
        timer.cancel();
        return;
      }
      if (mounted) setState(() => _progress += 10);
    });
    try {
      final service = ConvertService(cloudConvertApiKey: widget.cloudConvertApiKey);
      ConvertResult result;
      if (widget.tool.id == 'img-pdf') {
        if (_selectedFile?.bytes == null) throw Exception('Select an image first');
        result = service.imageToPdf(_selectedFile!.bytes!);
      } else if (widget.tool.id == 'pdf-word') {
        if (_selectedFile?.bytes == null) throw Exception('Select a PDF first');
        result = await service.cloudConvert(
          inputBytes: _selectedFile!.bytes!,
          fileName: _selectedFile!.name,
          inputFormat: 'pdf',
          outputFormat: 'docx',
        );
      } else if (widget.tool.id == 'word-pdf') {
        if (_selectedFile?.bytes == null) throw Exception('Select a DOCX first');
        result = await service.cloudConvert(
          inputBytes: _selectedFile!.bytes!,
          fileName: _selectedFile!.name,
          inputFormat: 'docx',
          outputFormat: 'pdf',
        );
      } else if (widget.tool.id == 'excel-pdf') {
        if (_selectedFile?.bytes == null) throw Exception('Select an XLS/XLSX first');
        final ext = (_selectedFile!.extension ?? 'xlsx').toLowerCase();
        result = await service.cloudConvert(
          inputBytes: _selectedFile!.bytes!,
          fileName: _selectedFile!.name,
          inputFormat: ext == 'xls' ? 'xls' : 'xlsx',
          outputFormat: 'pdf',
        );
      } else if (widget.tool.id == 'img-convert') {
        if (_selectedFile?.bytes == null) throw Exception('Select an image first');
        result = service.convertImageFormat(_selectedFile!.bytes!, _imageOutputFormat);
      } else if (widget.tool.id == 'text-pdf') {
        if (_textController.text.trim().isEmpty) throw Exception('Enter text first');
        result = service.textToPdf(_textController.text);
      } else {
        throw Exception('Unsupported convert tool');
      }

      final path = await _saveConverted(result.bytes, result.extension, widget.tool.id);
      FileStore.addFile(
        FileItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: path.split('/').last,
          type: result.extension == 'pdf'
              ? FileType.pdf
              : result.extension == 'docx'
                  ? FileType.docx
                  : FileType.image,
          date: 'Just now',
          path: path,
        ),
      );
      if (!mounted) return;
      setState(() {
        _processing = false;
        _progress = 100;
        _success = true;
        _lastOutputPath = path;
        _resultMessage = 'Saved output to My Files';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _processing = false;
      });
      final errorText = e.toString();
      String message = 'Could not convert. Check file type/size and retry.';
      if (errorText.contains('CLOUDCONVERT_API_KEY')) {
        message = 'This conversion requires CloudConvert API key.';
      } else if (errorText.contains('No internet connection')) {
        message = 'No internet connection. Please reconnect and retry.';
      } else if (errorText.contains('timed out')) {
        message = 'Conversion request timed out. Please retry.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.tool.name)),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 8),
            const InlineBannerAd(),
            const SizedBox(height: 8),
            Expanded(
              child: Stack(
                children: [
                  ListView(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      16 + MediaQuery.of(context).padding.bottom,
                    ),
                  children: [
              if (widget.tool.id != 'text-pdf') ...[
                Builder(
                  builder: (context) {
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    final f = _selectedFile;
                    Widget? preview;
                    final ext = (f?.extension ?? '').toLowerCase();
                    if (f?.bytes != null &&
                        (ext == 'jpg' ||
                            ext == 'jpeg' ||
                            ext == 'png' ||
                            ext == 'webp' ||
                            ext == 'gif' ||
                            widget.tool.id == 'img-pdf' ||
                            widget.tool.id == 'img-convert')) {
                      preview = Image.memory(f!.bytes!, fit: BoxFit.contain);
                    } else if (f != null) {
                      preview = Center(
                        child: ListTile(
                          leading: Icon(
                            ext == 'pdf' ? Icons.picture_as_pdf_rounded : Icons.description_outlined,
                            color: ext == 'pdf' ? Colors.red : Colors.indigo,
                            size: 40,
                          ),
                          title: Text(
                            f.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: const Text('Tap card to replace'),
                        ),
                      );
                    }
                    return UploadDropCard(
                      isDark: isDark,
                      onTap: _pickFile,
                      title: f == null ? 'Upload source file' : f.name,
                      subtitle: f == null ? 'Tap to choose a file for conversion' : 'Tap to replace',
                      preview: preview,
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],
              if (widget.tool.id == 'img-convert') ...[
                DropdownButtonFormField<String>(
                  value: _imageOutputFormat,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Output image format',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'jpg', child: Text('JPG')),
                    DropdownMenuItem(value: 'png', child: Text('PNG')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _imageOutputFormat = v);
                  },
                ),
                const SizedBox(height: 12),
              ],
              if (widget.tool.id == 'text-pdf') ...[
                TextField(
                  controller: _textController,
                  minLines: 4,
                  maxLines: 7,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Input text',
                    hintText: 'Type or paste text to convert to PDF',
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (_success)
                Column(
                  children: [
                    _SuccessPanel(
                      title: 'Conversion Successful',
                      subtitle: _resultMessage,
                    ),
                    const SizedBox(height: 10),
                    _PostJobActions(
                      filePath: _lastOutputPath,
                      onOpenMyFiles: () => Navigator.pushNamed(context, '/my-files'),
                    ),
                  ],
                )
              else
                ElevatedButton(
                  onPressed: (widget.tool.id == 'text-pdf')
                      ? _convert
                      : (_selectedFile == null ? null : _convert),
                  child: const Text('Convert Now'),
                ),
                  ],
                ),
                  if (_processing)
                    _ProcessingOverlay(message: 'Converting...', progress: _progress),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CompressScreen extends StatefulWidget {
  const CompressScreen({super.key});

  @override
  State<CompressScreen> createState() => _CompressScreenState();
}

class _CompressScreenState extends State<CompressScreen> {
  final CompressService _compressService = const CompressService();
  final List<(String id, String label)> _tabs = const [
    ('image', 'Compress Image'),
    ('pdf', 'Compress PDF'),
    ('doc', 'Compress Document'),
  ];

  String _activeTab = 'image';
  int _compression = 50;
  fp.PlatformFile? _selected;
  String _imageFormat = 'jpg';
  bool _downscale = false;
  PdfCompressionLevel _pdfLevel = PdfCompressionLevel.normal;
  int _progress = 0;
  bool _processing = false;
  bool _success = false;
  int? _beforeBytes;
  int? _afterBytes;
  String _resultMessage = '';
  String? _lastOutputPath;
  Timer? _timer;

  Future<void> _pickFile() async {
    final result = await fp.FilePicker.platform.pickFiles(
      type: _activeTab == 'image'
          ? fp.FileType.image
          : _activeTab == 'pdf'
              ? fp.FileType.custom
              : fp.FileType.custom,
      allowedExtensions:
          _activeTab == 'pdf' ? ['pdf'] : _activeTab == 'doc' ? ['doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx'] : null,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read selected file. Please choose another one.')),
      );
      return;
    }
    final maxBytes = _activeTab == 'image'
        ? _maxImageInputBytes
        : _activeTab == 'pdf'
            ? _maxPdfInputBytes
            : _maxDocInputBytes;
    if (bytes.lengthInBytes > maxBytes) {
      if (!mounted) return;
      final mb = (maxBytes / (1024 * 1024)).round();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selected file is too large. Limit for this tab is ${mb}MB.')),
      );
      return;
    }
    setState(() {
      _selected = file;
      _success = false;
      _beforeBytes = null;
      _afterBytes = null;
      _resultMessage = '';
    });
  }

  Future<String> _saveCompressedFile(Uint8List bytes, String ext) async {
    final dir = await getApplicationDocumentsDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'Compressed_${_activeTab}_$ts.$ext';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<void> _startCompression() async {
    if (_selected == null || _selected!.bytes == null) return;
    _timer?.cancel();
    setState(() {
      _processing = true;
      _success = false;
      _progress = 0;
    });

    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_progress >= 90) {
        timer.cancel();
        return;
      }
      if (!mounted) return;
      setState(() => _progress += 10);
    });

    try {
      final input = _selected!.bytes!;
      late CompressResult result;

      if (_activeTab == 'image') {
        result = _compressService.compressImage(
          inputBytes: input,
          quality: _compression,
          outputFormat: _imageFormat,
          downscale: _downscale,
        );
      } else if (_activeTab == 'pdf') {
        result = _compressService.compressPdf(
          inputBytes: input,
          level: _pdfLevel,
        );
      } else {
        result = _compressService.compressDocumentAsZip(
          inputBytes: input,
          fileName: _selected!.name,
        );
      }

      final outputPath = await _saveCompressedFile(result.bytes, result.extension);
      final outputName = outputPath.split('/').last;
      FileStore.addFile(
        FileItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: outputName,
          type: _activeTab == 'image'
              ? FileType.image
              : _activeTab == 'pdf'
                  ? FileType.pdf
                  : FileType.docx,
          date: 'Just now',
          path: outputPath,
        ),
      );

      if (!mounted) return;
      setState(() {
        _processing = false;
        _progress = 100;
        _success = true;
        _lastOutputPath = outputPath;
        _beforeBytes = result.originalSize;
        _afterBytes = result.compressedSize;
        final saved = result.originalSize == 0
            ? 0
            : ((1 - (result.compressedSize / result.originalSize)) * 100).round();
        _resultMessage = 'Saved $saved% • Added to My Files';
      });
      AnalyticsService.logEvent('tool_success', props: {'tool_id': 'compress_$_activeTab'});
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        _resultMessage = 'Compression failed';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not compress this file. Please try another file or lower settings.'),
        ),
      );
      AnalyticsService.logEvent('tool_fail', props: {'tool_id': 'compress_$_activeTab', 'code': 'COMPRESS_FAIL'});
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compress Files')),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 8),
            const InlineBannerAd(),
            const SizedBox(height: 8),
            Expanded(
              child: Stack(
                children: [
                  ListView(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      16 + MediaQuery.of(context).padding.bottom,
                    ),
                  children: [
              Row(
                children: _tabs.map((tab) {
                  final selected = tab.$1 == _activeTab;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _activeTab = tab.$1;
                            _selected = null;
                            _success = false;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selected ? const Color(0xFF1857E6) : Colors.white,
                          foregroundColor: selected ? Colors.white : Colors.black87,
                        ),
                        child: Text(tab.$1.toUpperCase()),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Builder(
                builder: (context) {
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  final sub = _activeTab == 'image'
                      ? 'Tap to pick an image from your device'
                      : _activeTab == 'pdf'
                          ? 'Tap to pick a PDF'
                          : 'Tap to pick a document (Office formats)';
                  Widget? preview;
                  final sel = _selected;
                  if (sel != null) {
                    if (_activeTab == 'image' && sel.bytes != null) {
                      preview = Image.memory(sel.bytes!, fit: BoxFit.contain);
                    } else {
                      preview = Center(
                        child: ListTile(
                          leading: Icon(
                            _activeTab == 'pdf'
                                ? Icons.picture_as_pdf_rounded
                                : Icons.description_outlined,
                            color: Colors.redAccent,
                            size: 40,
                          ),
                          title: Text(
                            sel.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: const Text('Tap card to replace'),
                        ),
                      );
                    }
                  }
                  return UploadDropCard(
                    isDark: isDark,
                    onTap: _pickFile,
                    title: sel == null ? 'Choose file' : sel.name,
                    subtitle: sel == null ? sub : 'Tap to replace this file',
                    preview: preview,
                  );
                },
              ),
              const SizedBox(height: 16),
              if (_activeTab == 'image') ...[
                DropdownButtonFormField<String>(
                  value: _imageFormat,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Output format',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'jpg', child: Text('JPG')),
                    DropdownMenuItem(value: 'png', child: Text('PNG')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _imageFormat = v);
                  },
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  title: const Text('Downscale dimensions (smaller size)'),
                  value: _downscale,
                  onChanged: (v) => setState(() => _downscale = v),
                ),
              ],
              if (_activeTab == 'pdf') ...[
                DropdownButtonFormField<PdfCompressionLevel>(
                  value: _pdfLevel,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'PDF compression preset',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: PdfCompressionLevel.belowNormal,
                      child: Text('Low'),
                    ),
                    DropdownMenuItem(
                      value: PdfCompressionLevel.normal,
                      child: Text('Balanced'),
                    ),
                    DropdownMenuItem(
                      value: PdfCompressionLevel.aboveNormal,
                      child: Text('High'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _pdfLevel = v);
                  },
                ),
              ],
              Text('Compression: $_compression%'),
              Slider(
                value: _compression.toDouble(),
                min: 10,
                max: 90,
                onChanged: (v) => setState(() => _compression = v.round()),
              ),
              const SizedBox(height: 10),
              if (_success)
                Column(
                  children: [
                    _SuccessPanel(
                      title: 'Compression Complete',
                      subtitle: _resultMessage.isEmpty ? 'File is ready in My Files.' : _resultMessage,
                    ),
                    if (_beforeBytes != null && _afterBytes != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Before: ${_formatBytes(_beforeBytes!)}  •  After: ${_formatBytes(_afterBytes!)}',
                        style: const TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600),
                      ),
                    ],
                    const SizedBox(height: 10),
                    _PostJobActions(
                      filePath: _lastOutputPath,
                      onOpenMyFiles: () => Navigator.pushNamed(context, '/my-files'),
                    ),
                  ],
                )
              else if (_beforeBytes != null && _afterBytes != null)
                Text(
                  'Before: ${_formatBytes(_beforeBytes!)}  •  After: ${_formatBytes(_afterBytes!)}',
                  style: const TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600),
                )
              else
                ElevatedButton(
                  onPressed: _selected == null ? null : _startCompression,
                  child: const Text('Compress Now'),
                ),
                  ],
                ),
                  if (_processing)
                    _ProcessingOverlay(message: 'Compressing...', progress: _progress),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB'];
    double size = bytes.toDouble();
    int unit = 0;
    while (size >= 1024 && unit < units.length - 1) {
      size /= 1024;
      unit++;
    }
    return '${size.toStringAsFixed(unit == 0 ? 0 : 1)} ${units[unit]}';
  }
}

class ImageProcessingScreen extends StatefulWidget {
  final ToolOption tool;

  const ImageProcessingScreen({
    super.key,
    required this.tool,
  });

  @override
  State<ImageProcessingScreen> createState() => _ImageProcessingScreenState();
}

class _ImageProcessingScreenState extends State<ImageProcessingScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _resizeWController = TextEditingController();
  final TextEditingController _resizeHController = TextEditingController();
  bool _isPickingImage = false;
  img.Image? _decodedSource;
  Uint8List? _sourceBytes;
  Uint8List? _previewBytes;
  String? _lastOutputPath;
  String _statusText = '';
  String? _lastErrorCode;
  String? _lastErrorMessage;
  bool _processing = false;
  bool _success = false;
  bool _showOriginalPreview = false;
  int _progress = 0;
  int _quality = 80;
  bool _lockAspectRatio = true;
  int _resizeWidth = 1080;
  int _resizeHeight = 1080;
  String _cropRatio = 'free';
  String _convertFormat = 'jpg';
  int? _statInputBytes;
  int? _statOutputBytes;
  String? _statBeforeDims;
  String? _statAfterDims;
  /// Normalized crop in image space (0–1): left, top, right, bottom.
  double _cropL = 0;
  double _cropT = 0;
  double _cropR = 1;
  double _cropB = 1;
  int? _cropDragHandle;
  Timer? _timer;

  Future<void> _pickImage() async {
    if (_isPickingImage) return;
    _isPickingImage = true;
    try {
      final image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;
      final bytes = await image.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load this image.')),
        );
        return;
      }
      if (!mounted) return;
      setState(() {
        _decodedSource = decoded;
        _sourceBytes = Uint8List.fromList(bytes);
        _resizeWidth = decoded.width;
        _resizeHeight = decoded.height;
        _resizeWController.text = decoded.width.toString();
        _resizeHController.text = decoded.height.toString();
        if (widget.tool.id == 'compress-img') {
          _quality = 52;
        }
        if (widget.tool.id == 'crop') {
          _cropRatio = 'free';
        }
        _cropL = 0;
        _cropT = 0;
        _cropR = 1;
        _cropB = 1;
        _previewBytes = Uint8List.fromList(bytes);
        _lastOutputPath = null;
        _success = false;
        _showOriginalPreview = false;
        _statusText = '';
        _lastErrorCode = null;
        _lastErrorMessage = null;
        _statInputBytes = null;
        _statOutputBytes = null;
        _statBeforeDims = null;
        _statAfterDims = null;
      });
    } on PlatformException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image picker is busy. Please try again.')),
      );
    } finally {
      _isPickingImage = false;
    }
  }

  String get _processButtonLabel {
    switch (widget.tool.id) {
      case 'resize':
        return 'Resize Image';
      case 'crop':
        return 'Crop Image';
      case 'compress-img':
        return 'Compress Image';
      case 'convert-img':
        return 'Convert Image';
      case 'remove-bg':
        return 'Remove Background';
      default:
        return 'Process';
    }
  }

  bool get _removeBgUnavailable =>
      widget.tool.id == 'remove-bg' && (!Platform.isAndroid && !Platform.isIOS);

  img.Image _applyCrop(img.Image source) {
    if (widget.tool.id == 'crop') {
      final w = source.width;
      final h = source.height;
      var l = (_cropL * w).round().clamp(0, w - 1);
      var t = (_cropT * h).round().clamp(0, h - 1);
      var r = (_cropR * w).round().clamp(l + 1, w);
      var b = (_cropB * h).round().clamp(t + 1, h);
      return img.copyCrop(source, x: l, y: t, width: r - l, height: b - t);
    }
    if (_cropRatio == 'free') {
      final cropW = (source.width * 0.9).round();
      final cropH = (source.height * 0.9).round();
      final x = ((source.width - cropW) / 2).round();
      final y = ((source.height - cropH) / 2).round();
      return img.copyCrop(source, x: x, y: y, width: cropW, height: cropH);
    }
    final ratioMap = <String, double>{
      '1:1': 1.0,
      '4:3': 4 / 3,
      '16:9': 16 / 9,
      '9:16': 9 / 16,
    };
    final ratio = ratioMap[_cropRatio] ?? 1.0;
    final srcRatio = source.width / source.height;
    int cropW = source.width;
    int cropH = source.height;
    if (srcRatio > ratio) {
      cropW = (source.height * ratio).round();
    } else {
      cropH = (source.width / ratio).round();
    }
    final x = ((source.width - cropW) / 2).round();
    final y = ((source.height - cropH) / 2).round();
    return img.copyCrop(source, x: x, y: y, width: cropW, height: cropH);
  }

  void _fitCropAspect(double aspectW, double aspectH) {
    if (_decodedSource == null) return;
    final W = _decodedSource!.width.toDouble();
    final H = _decodedSource!.height.toDouble();
    final target = aspectW / aspectH;
    double cw;
    double ch;
    double cx;
    double cy;
    if (W / H > target) {
      ch = H;
      cw = H * target;
      cx = (W - cw) / 2;
      cy = 0;
    } else {
      cw = W;
      ch = W / target;
      cx = 0;
      cy = (H - ch) / 2;
    }
    setState(() {
      _cropL = cx / W;
      _cropT = cy / H;
      _cropR = (cx + cw) / W;
      _cropB = (cy + ch) / H;
    });
    _updatePreview();
  }

  void _clampCropNorm() {
    const minSide = 0.04;
    if (_cropR - _cropL < minSide) {
      final mid = (_cropL + _cropR) / 2;
      _cropL = (mid - minSide / 2).clamp(0.0, 1 - minSide);
      _cropR = (_cropL + minSide).clamp(minSide, 1.0);
    }
    if (_cropB - _cropT < minSide) {
      final mid = (_cropT + _cropB) / 2;
      _cropT = (mid - minSide / 2).clamp(0.0, 1 - minSide);
      _cropB = (_cropT + minSide).clamp(minSide, 1.0);
    }
  }

  img.Image _buildProcessedImage() {
    final source = _decodedSource!;
    switch (widget.tool.id) {
      case 'resize':
        return img.copyResize(source, width: _resizeWidth, height: _resizeHeight);
      case 'crop':
        return _applyCrop(source);
      case 'remove-bg':
      case 'compress-img':
      case 'convert-img':
      default:
        return img.Image.from(source);
    }
  }

  Future<void> _updatePreview() async {
    if (_decodedSource == null) return;
    final processed = _buildProcessedImage();
    final bytes = _encodeForCurrentTool(processed);
    if (!mounted) return;
    setState(() {
      _previewBytes = bytes;
    });
  }

  Uint8List _encodeForCurrentTool(img.Image image) {
    if (widget.tool.id == 'convert-img') {
      if (_convertFormat == 'png') return Uint8List.fromList(img.encodePng(image));
      return Uint8List.fromList(img.encodeJpg(image, quality: _quality));
    }
    if (widget.tool.id == 'remove-bg') {
      return Uint8List.fromList(img.encodePng(image));
    }
    if (widget.tool.id == 'compress-img') {
      return Uint8List.fromList(img.encodeJpg(image, quality: _quality));
    }
    return Uint8List.fromList(img.encodePng(image));
  }

  /// Re-encodes as JPEG, lowering quality (and optionally size) until output is
  /// smaller than the picked file when possible — avoids "compressed" files
  /// that are larger than the original.
  Uint8List _encodeCompressJpgSmallerThanOriginal(img.Image processed) {
    final cap = _sourceBytes?.lengthInBytes ?? 0;
    if (cap <= 0) {
      return Uint8List.fromList(img.encodeJpg(processed, quality: _quality.clamp(10, 95)));
    }
    var q = _quality.clamp(10, 95);
    var out = Uint8List.fromList(img.encodeJpg(processed, quality: q));
    var guard = 0;
    while (out.lengthInBytes >= cap && q > 12 && guard < 40) {
      guard++;
      q = (q - 4).clamp(12, 95);
      out = Uint8List.fromList(img.encodeJpg(processed, quality: q));
    }
    if (out.lengthInBytes >= cap && processed.width > 160 && processed.height > 160) {
      final w = math.max(96, (processed.width * 0.86).round());
      final h = math.max(96, (processed.height * 0.86).round());
      final small = img.copyResize(processed, width: w, height: h);
      q = math.min(q, 68);
      out = Uint8List.fromList(img.encodeJpg(small, quality: q.clamp(12, 90)));
      guard = 0;
      while (out.lengthInBytes >= cap && q > 12 && guard < 25) {
        guard++;
        q = (q - 4).clamp(12, 95);
        out = Uint8List.fromList(img.encodeJpg(small, quality: q));
      }
    }
    return out;
  }

  String _outputExt() {
    if (widget.tool.id == 'convert-img') return _convertFormat;
    if (widget.tool.id == 'remove-bg') return 'png';
    if (widget.tool.id == 'compress-img') return 'jpg';
    return 'png';
  }

  Future<String> _saveOutput(Uint8List data) async {
    final dir = await getApplicationDocumentsDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final ext = _outputExt();
    final fileName = 'IMG_${widget.tool.id}_$ts.$ext';
    final output = File('${dir.path}/$fileName');
    await output.writeAsBytes(data, flush: true);
    return output.path;
  }

  Future<void> _start() async {
    if (_decodedSource == null) return;
    _timer?.cancel();
    setState(() {
      _processing = true;
      _progress = 0;
      _statusText = '';
    });
    _timer = Timer.periodic(const Duration(milliseconds: 70), (timer) {
      if (_progress >= 90) {
        timer.cancel();
        return;
      }
      if (mounted) setState(() => _progress += 10);
    });

    try {
      Uint8List bytes;
      if (widget.tool.id == 'remove-bg') {
        if (_sourceBytes == null) {
          throw Exception('No source image');
        }
        bytes = await const SelfieSegmentationService().removeBackground(_sourceBytes!);
      } else {
        final processed = _buildProcessedImage();
        bytes = widget.tool.id == 'compress-img'
            ? _encodeCompressJpgSmallerThanOriginal(processed)
            : _encodeForCurrentTool(processed);
      }
      final path = await _saveOutput(bytes);
      final fileName = path.split('/').last;
      FileStore.addFile(
        FileItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: fileName,
          type: FileType.image,
          date: 'Just now',
          path: path,
        ),
      );
      if (!mounted) return;
      setState(() {
        _previewBytes = bytes;
        _lastOutputPath = path;
        _progress = 100;
        _processing = false;
        _success = true;
        _showOriginalPreview = false;
        _statusText = 'Saved to My Files';
        _lastErrorCode = null;
        _lastErrorMessage = null;
        if (widget.tool.id == 'resize' || widget.tool.id == 'compress-img') {
          _statInputBytes = _sourceBytes?.lengthInBytes;
          _statOutputBytes = bytes.lengthInBytes;
          _statBeforeDims = '${_decodedSource!.width} × ${_decodedSource!.height} px';
          final outImg = img.decodeImage(bytes);
          _statAfterDims = outImg != null
              ? '${outImg.width} × ${outImg.height} px'
              : '${_resizeWidth} × ${_resizeHeight} px';
        }
      });
      AnalyticsService.logEvent('tool_success', props: {'tool_id': widget.tool.id});
    } on UnsupportedError catch (e) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        _statusText = 'Not supported here';
        _lastErrorCode = 'UNSUPPORTED';
        _lastErrorMessage = e.message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'This action is not supported on this platform.')),
      );
      AnalyticsService.logEvent(
        'tool_fail',
        props: {'tool_id': widget.tool.id, 'code': _lastErrorCode ?? 'FAIL'},
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        _statusText = 'Failed to process image';
        _lastErrorCode = 'PROCESS_FAIL';
        _lastErrorMessage = widget.tool.id == 'remove-bg'
            ? 'Could not remove background. Try a clear photo with a person in frame.'
            : 'Image processing failed. Please try a different image.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.tool.id == 'remove-bg'
                ? 'Background removal failed. Use a photo with a visible person, then try again.'
                : 'Image processing failed. Please try again.',
          ),
        ),
      );
      AnalyticsService.logEvent(
        'tool_fail',
        props: {'tool_id': widget.tool.id, 'code': _lastErrorCode ?? 'FAIL'},
      );
    }
  }

  Future<void> _downloadPngCopy() async {
    if (_lastOutputPath == null) return;
    try {
      final source = File(_lastOutputPath!);
      if (!await source.exists()) {
        throw Exception('Output file not found');
      }
      final bytes = await source.readAsBytes();
      final dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      final fileName = 'BG_Removed_${DateTime.now().millisecondsSinceEpoch}.png';
      final output = File('${dir.path}/$fileName');
      await output.writeAsBytes(bytes, flush: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PNG saved: ${output.path}')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save PNG copy.')),
      );
    }
  }

  String _formatBytesStat(int b) {
    const units = ['B', 'KB', 'MB'];
    double s = b.toDouble();
    var u = 0;
    while (s >= 1024 && u < units.length - 1) {
      s /= 1024;
      u++;
    }
    return '${s.toStringAsFixed(u == 0 ? 0 : 1)} ${units[u]}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _resizeWController.dispose();
    _resizeHController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(
          widget.tool.name,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 8),
            const InlineBannerAd(),
            const SizedBox(height: 8),
            Expanded(
              child: Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      18,
                      8,
                      18,
                      18 + MediaQuery.of(context).padding.bottom,
                    ),
                  child: Column(
                    children: [
                Expanded(
                  child: UploadDropCard(
                    isDark: isDark,
                    onTap: _pickImage,
                    title: 'Choose Image',
                    subtitle: 'Tap to upload from gallery',
                    preview: _previewBytes == null
                        ? null
                        : widget.tool.id == 'crop' && _decodedSource != null && _sourceBytes != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(26),
                                  child: LayoutBuilder(
                                    builder: (context, cons) {
                                      final imgSize = Size(
                                        _decodedSource!.width.toDouble(),
                                        _decodedSource!.height.toDouble(),
                                      );
                                      final imageRect = containImageForBoxFit(
                                        Size(cons.maxWidth, cons.maxHeight),
                                        imgSize,
                                      );
                                      final hit = 48.0;
                                      final bytes = _sourceBytes!;
                                      return GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onPanStart: (d) {
                                          final local = d.localPosition;
                                          final corners = <Offset>[
                                            Offset(_cropL, _cropT),
                                            Offset(_cropR, _cropT),
                                            Offset(_cropR, _cropB),
                                            Offset(_cropL, _cropB),
                                          ];
                                          double best = 1e9;
                                          var idx = 0;
                                          for (var i = 0; i < 4; i++) {
                                            final p = Offset(
                                              imageRect.left + corners[i].dx * imageRect.width,
                                              imageRect.top + corners[i].dy * imageRect.height,
                                            );
                                            final dist = (p - local).distance;
                                            if (dist < best) {
                                              best = dist;
                                              idx = i;
                                            }
                                          }
                                          setState(() {
                                            _cropDragHandle = best <= hit ? idx : null;
                                          });
                                        },
                                        onPanUpdate: (d) {
                                          if (_cropDragHandle == null) return;
                                          final nx = ((d.localPosition.dx - imageRect.left) / imageRect.width)
                                              .clamp(0.0, 1.0);
                                          final ny = ((d.localPosition.dy - imageRect.top) / imageRect.height)
                                              .clamp(0.0, 1.0);
                                          setState(() {
                                            switch (_cropDragHandle!) {
                                              case 0:
                                                _cropL = nx;
                                                _cropT = ny;
                                                break;
                                              case 1:
                                                _cropR = nx;
                                                _cropT = ny;
                                                break;
                                              case 2:
                                                _cropR = nx;
                                                _cropB = ny;
                                                break;
                                              case 3:
                                                _cropL = nx;
                                                _cropB = ny;
                                                break;
                                            }
                                            if (_cropL > _cropR) {
                                              final t = _cropL;
                                              _cropL = _cropR;
                                              _cropR = t;
                                            }
                                            if (_cropT > _cropB) {
                                              final t = _cropT;
                                              _cropT = _cropB;
                                              _cropB = t;
                                            }
                                            _clampCropNorm();
                                          });
                                          _updatePreview();
                                        },
                                        onPanEnd: (_) {
                                          setState(() => _cropDragHandle = null);
                                        },
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            Center(
                                              child: Image.memory(
                                                bytes,
                                                fit: BoxFit.contain,
                                                errorBuilder: (_, __, ___) =>
                                                    const Center(child: Text('Preview unavailable')),
                                              ),
                                            ),
                                            CustomPaint(
                                              size: Size(cons.maxWidth, cons.maxHeight),
                                              painter: _ImageCropOverlayPainter(
                                                imageRect: imageRect,
                                                cropL: _cropL,
                                                cropT: _cropT,
                                                cropR: _cropR,
                                                cropB: _cropB,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(26),
                                  child: Image.memory(
                                    (_showOriginalPreview && _sourceBytes != null)
                                        ? _sourceBytes!
                                        : _previewBytes!,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) =>
                                        const Center(child: Text('Preview unavailable')),
                                  ),
                                ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_decodedSource != null) ...[
                  if (_lastErrorCode != null) ...[
                    _ErrorBanner(
                      code: _lastErrorCode!,
                      message: _lastErrorMessage ?? 'Something went wrong.',
                      onRetry: _decodedSource == null ? null : _start,
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (_removeBgUnavailable)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        border: Border.all(color: const Color(0xFFFED7AA)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Remove Background uses on-device ML Kit (Android & iOS only). Works best for photos with people.',
                        style: TextStyle(
                          color: Color(0xFF9A3412),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  _ImageToolControls(
                    toolId: widget.tool.id,
                    quality: _quality,
                    lockAspectRatio: _lockAspectRatio,
                    resizeWidth: _resizeWidth,
                    resizeHeight: _resizeHeight,
                    cropRatio: _cropRatio,
                    convertFormat: _convertFormat,
                    onQualityChanged: (v) {
                      setState(() => _quality = v);
                      _updatePreview();
                    },
                    onAspectLockChanged: (v) {
                      setState(() {
                        _lockAspectRatio = v;
                        if (v && _decodedSource != null) {
                          final ratio = _decodedSource!.height / _decodedSource!.width;
                          _resizeHeight = (_resizeWidth * ratio).round();
                          _resizeHController.text = _resizeHeight.toString();
                        }
                      });
                      _updatePreview();
                    },
                    resizeWidthController: _resizeWController,
                    resizeHeightController: _resizeHController,
                    onResizeWidthChanged: (v) {
                      final value = int.tryParse(v.trim());
                      if (value == null || value <= 0 || _decodedSource == null) return;
                      setState(() {
                        _resizeWidth = value;
                        if (_lockAspectRatio) {
                          final ratio = _decodedSource!.height / _decodedSource!.width;
                          _resizeHeight = (_resizeWidth * ratio).round();
                          _resizeHController.text = _resizeHeight.toString();
                        }
                      });
                      _updatePreview();
                    },
                    onResizeHeightChanged: (v) {
                      final value = int.tryParse(v.trim());
                      if (value == null || value <= 0 || _decodedSource == null) return;
                      setState(() {
                        _resizeHeight = value;
                        if (_lockAspectRatio) {
                          final ratio = _decodedSource!.width / _decodedSource!.height;
                          _resizeWidth = (_resizeHeight * ratio).round();
                          _resizeWController.text = _resizeWidth.toString();
                        }
                      });
                      _updatePreview();
                    },
                    onCropRatioChanged: (v) {
                      setState(() => _cropRatio = v);
                      _updatePreview();
                    },
                    onConvertFormatChanged: (v) {
                      setState(() => _convertFormat = v);
                      _updatePreview();
                    },
                    onCropAspectPreset: widget.tool.id == 'crop'
                        ? (aw, ah) => _fitCropAspect(aw, ah)
                        : null,
                    onCropReset: widget.tool.id == 'crop'
                        ? () {
                            setState(() {
                              _cropL = 0;
                              _cropT = 0;
                              _cropR = 1;
                              _cropB = 1;
                            });
                            _updatePreview();
                          }
                        : null,
                  ),
                  const SizedBox(height: 12),
                ],
                if (_success)
                  Column(
                    children: [
                      _SuccessPanel(
                        title: 'Done',
                        subtitle: _statusText.isEmpty
                            ? 'Processed image added to My Files.'
                            : _statusText,
                      ),
                      const SizedBox(height: 10),
                      _PostJobActions(
                        filePath: _lastOutputPath,
                        onOpenMyFiles: () => Navigator.pushNamed(context, '/my-files'),
                      ),
                      if ((widget.tool.id == 'resize' || widget.tool.id == 'compress-img') &&
                          _statInputBytes != null &&
                          _statOutputBytes != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Before: $_statBeforeDims · ${_formatBytesStat(_statInputBytes!)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'After:  $_statAfterDims · ${_formatBytesStat(_statOutputBytes!)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1857E6),
                                ),
                              ),
                              if (_statOutputBytes! < _statInputBytes!) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'File size reduced by ${((1 - _statOutputBytes! / _statInputBytes!) * 100).toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0F766E),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                      if (widget.tool.id == 'remove-bg') ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  setState(() => _showOriginalPreview = !_showOriginalPreview);
                                },
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                                  foregroundColor: const Color(0xFF0F172A),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  _showOriginalPreview ? 'Show Removed' : 'Show Original',
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _lastOutputPath == null ? null : _downloadPngCopy,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1857E6),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text(
                                  'Download PNG',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_decodedSource == null || _removeBgUnavailable) ? null : _start,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1857E6),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFBFD0F7),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _processButtonLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                    ],
                  ),
                ),
                  if (_processing)
                    _ProcessingOverlay(message: '${widget.tool.name}...', progress: _progress),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageToolControls extends StatelessWidget {
  final String toolId;
  final int quality;
  final bool lockAspectRatio;
  final int resizeWidth;
  final int resizeHeight;
  final String cropRatio;
  final String convertFormat;
  final TextEditingController resizeWidthController;
  final TextEditingController resizeHeightController;
  final ValueChanged<int> onQualityChanged;
  final ValueChanged<bool> onAspectLockChanged;
  final ValueChanged<String> onResizeWidthChanged;
  final ValueChanged<String> onResizeHeightChanged;
  final ValueChanged<String> onCropRatioChanged;
  final ValueChanged<String> onConvertFormatChanged;
  final void Function(double aspectW, double aspectH)? onCropAspectPreset;
  final VoidCallback? onCropReset;

  const _ImageToolControls({
    required this.toolId,
    required this.quality,
    required this.lockAspectRatio,
    required this.resizeWidth,
    required this.resizeHeight,
    required this.cropRatio,
    required this.convertFormat,
    required this.resizeWidthController,
    required this.resizeHeightController,
    required this.onQualityChanged,
    required this.onAspectLockChanged,
    required this.onResizeWidthChanged,
    required this.onResizeHeightChanged,
    required this.onCropRatioChanged,
    required this.onConvertFormatChanged,
    this.onCropAspectPreset,
    this.onCropReset,
  });

  @override
  Widget build(BuildContext context) {
    if (toolId == 'resize') {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: resizeWidthController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Width',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: onResizeWidthChanged,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: resizeHeightController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Height',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: onResizeHeightChanged,
                  ),
                ),
              ],
            ),
          ),
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Lock aspect ratio',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            value: lockAspectRatio,
            onChanged: onAspectLockChanged,
          ),
        ],
      );
    }

    if (toolId == 'crop') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Drag the corners on the preview to choose the crop area.',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _AnimatedChoiceChip(
                label: '1:1',
                selected: cropRatio == '1:1',
                onTap: () {
                  onCropRatioChanged('1:1');
                  onCropAspectPreset?.call(1, 1);
                },
              ),
              _AnimatedChoiceChip(
                label: '4:3',
                selected: cropRatio == '4:3',
                onTap: () {
                  onCropRatioChanged('4:3');
                  onCropAspectPreset?.call(4, 3);
                },
              ),
              _AnimatedChoiceChip(
                label: '16:9',
                selected: cropRatio == '16:9',
                onTap: () {
                  onCropRatioChanged('16:9');
                  onCropAspectPreset?.call(16, 9);
                },
              ),
              _AnimatedChoiceChip(
                label: '9:16',
                selected: cropRatio == '9:16',
                onTap: () {
                  onCropRatioChanged('9:16');
                  onCropAspectPreset?.call(9, 16);
                },
              ),
              _AnimatedChoiceChip(
                label: 'Free',
                selected: cropRatio == 'free',
                onTap: () {
                  onCropRatioChanged('free');
                  onCropReset?.call();
                },
              ),
            ],
          ),
        ],
      );
    }

    if (toolId == 'convert-img') {
      const formats = ['jpg', 'png'];
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: formats
            .map(
              (fmt) => _AnimatedChoiceChip(
                label: fmt.toUpperCase(),
                selected: convertFormat == fmt,
                onTap: () => onConvertFormatChanged(fmt),
              ),
            )
            .toList(),
      );
    }

    if (toolId == 'compress-img') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'JPEG quality',
            style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 4),
          Text(
            '$quality% (lower → smaller file)',
            style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1857E6)),
          ),
          Slider(
            value: quality.toDouble(),
            min: 10,
            max: 95,
            activeColor: const Color(0xFF1857E6),
            inactiveColor: const Color(0xFFDCE7FF),
            onChanged: (v) => onQualityChanged(v.round()),
          ),
          Text(
            'The app lowers quality automatically if the output would still be larger than your original.',
            style: TextStyle(fontSize: 12, height: 1.35, color: Colors.grey.shade600),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}

class PdfProcessingScreen extends StatefulWidget {
  final ToolOption tool;
  final String apiKey;

  const PdfProcessingScreen({super.key, required this.tool, required this.apiKey});

  @override
  State<PdfProcessingScreen> createState() => _PdfProcessingScreenState();
}

class _PdfProcessingScreenState extends State<PdfProcessingScreen> {
  final PdfToolsService _pdfService = const PdfToolsService();
  final List<fp.PlatformFile> _files = [];
  /// Path on disk for Open (written to temp if picker only returns bytes).
  String? _pdfPathForOpen;
  bool _processing = false;
  bool _success = false;
  int _progress = 0;
  String _ocrText = '';
  String _statusText = '';
  String? _errorCode;
  String? _errorMessage;
  String? _lastOutputPath;
  int _sourcePageCount = 0;
  Timer? _timer;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _rangeController = TextEditingController();
  final TextEditingController _orderController = TextEditingController();
  PdfCompressionLevel _compression = PdfCompressionLevel.normal;
  PdfPageRotateAngle _rotation = PdfPageRotateAngle.rotateAngle90;

  Future<String?> _materializePdfPath(fp.PlatformFile f) async {
    if (f.path != null) {
      final existing = File(f.path!);
      if (await existing.exists()) return f.path;
    }
    if (f.bytes == null) return null;
    final dir = await getTemporaryDirectory();
    final safe = f.name.replaceAll(RegExp(r'[^\w\-\.]'), '_');
    final path = '${dir.path}/pdf_pick_${DateTime.now().millisecondsSinceEpoch}_$safe';
    await File(path).writeAsBytes(f.bytes!, flush: true);
    return path;
  }

  Future<void> _pick() async {
    final isMerge = widget.tool.id == 'merge';
    final isOcr = widget.tool.id == 'ocr';
    final result = await fp.FilePicker.platform.pickFiles(
      allowMultiple: isMerge,
      type: fp.FileType.custom,
      allowedExtensions: isOcr ? ['pdf', 'png', 'jpg', 'jpeg', 'webp'] : ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final oversized = result.files.any((f) {
      final b = f.bytes;
      return b != null && b.lengthInBytes > _maxPdfInputBytes;
    });
    if (oversized) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('One or more files are over 50MB. Please use smaller PDFs.')),
      );
      return;
    }

    int pages = 0;
    try {
      final firstBytes = result.files.first.bytes;
      if (firstBytes != null && !isOcr) {
        pages = _pdfService.pageCount(firstBytes);
      }
    } catch (_) {
      pages = 0;
    }

    final fileForPath = isMerge ? result.files.last : result.files.first;
    final diskPath = await _materializePdfPath(fileForPath);

    setState(() {
      if (isMerge) {
        _files.addAll(result.files);
      } else {
        _files
          ..clear()
          ..add(result.files.first);
      }
      _pdfPathForOpen = diskPath;
      _success = false;
      _ocrText = '';
      _sourcePageCount = pages;
      _statusText = '';
      _errorCode = null;
      _errorMessage = null;
    });
  }

  Future<void> _showVisualPagePicker() async {
    if (_sourcePageCount == 0) return;
    final toolId = widget.tool.id;
    final initialSet = _rangeController.text.trim().isEmpty
        ? {for (int i = 1; i <= _sourcePageCount; i++) i}
        : _parsePageSet(_rangeController.text, _sourcePageCount);
    final picked = await showDialog<Set<int>>(
      context: context,
      builder: (ctx) {
        var selected = Set<int>.from(initialSet);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                toolId == 'delete'
                    ? 'Pages to remove'
                    : toolId == 'split'
                        ? 'Pages to keep (extract)'
                        : 'Pages to rotate',
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 360,
                child: ListView(
                  children: [
                    Text(
                      toolId == 'delete'
                          ? 'Selected pages will be deleted from the PDF.'
                          : toolId == 'split'
                              ? 'Only selected pages will be in the new file.'
                              : 'Only selected pages will be rotated.',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(_sourcePageCount, (i) {
                      final n = i + 1;
                      return CheckboxListTile(
                        dense: true,
                        value: selected.contains(n),
                        onChanged: (v) {
                          setDialogState(() {
                            if (v == true) {
                              selected.add(n);
                            } else {
                              selected.remove(n);
                            }
                          });
                        },
                        title: Text('Page $n'),
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, selected),
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
    if (picked == null || !mounted) return;
    if (picked.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one page.')),
      );
      return;
    }
    final sorted = picked.toList()..sort();
    setState(() {
      _rangeController.text = sorted.join(',');
    });
  }

  Set<int> _parsePageSet(String input, int totalPages) {
    final values = <int>{};
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      for (int i = 1; i <= totalPages; i++) {
        values.add(i);
      }
      return values;
    }
    final parts = trimmed.split(',');
    for (final raw in parts) {
      final p = raw.trim();
      if (p.isEmpty) continue;
      if (p.contains('-')) {
        final b = p.split('-');
        if (b.length != 2) continue;
        final start = int.tryParse(b[0].trim());
        final end = int.tryParse(b[1].trim());
        if (start == null || end == null) continue;
        final minV = start < end ? start : end;
        final maxV = start > end ? start : end;
        for (int i = minV; i <= maxV; i++) {
          if (i > 0 && i <= totalPages) values.add(i);
        }
      } else {
        final page = int.tryParse(p);
        if (page != null && page > 0 && page <= totalPages) values.add(page);
      }
    }
    return values;
  }

  List<int> _parseOrder(String input, int totalPages) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return [for (int i = 1; i <= totalPages; i++) i];
    }
    final values = <int>[];
    final seen = <int>{};
    for (final raw in trimmed.split(',')) {
      final v = int.tryParse(raw.trim());
      if (v == null || v < 1 || v > totalPages || seen.contains(v)) continue;
      seen.add(v);
      values.add(v);
    }
    for (int i = 1; i <= totalPages; i++) {
      if (!seen.contains(i)) values.add(i);
    }
    return values;
  }

  Future<String> _savePdfOutput(Uint8List bytes, String prefix) async {
    final dir = await getApplicationDocumentsDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${prefix}_$ts.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<void> _process() async {
    if (_files.isEmpty) return;

    setState(() {
      _processing = true;
      _progress = 0;
    });

    if (widget.tool.id == 'ocr') {
      try {
        final file = _files.first;
        if (file.bytes == null) {
          throw Exception('Cannot read selected file bytes');
        }
        final ext = (file.extension ?? '').toLowerCase();
        const ocr = OcrService();
        final text = ext == 'pdf'
            ? ocr.extractFromPdf(file.bytes!)
            : await ocr.extractFromImage(file.bytes!);
        if (text.trim().isEmpty) {
          throw Exception('NO_TEXT');
        }
        if (!mounted) return;
        setState(() {
          _processing = false;
          _progress = 100;
          _ocrText = text;
          _errorCode = null;
          _errorMessage = null;
        });
        AnalyticsService.logEvent('tool_success', props: {'tool_id': widget.tool.id});
      } catch (_) {
        if (!mounted) return;
        setState(() => _processing = false);
        setState(() {
          _errorCode = 'OCR_FAIL';
          _errorMessage =
              'OCR found no text. For scanned PDFs, try converting pages to images first.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OCR found no text. Try a clearer image/PDF and retry.'),
          ),
        );
        AnalyticsService.logEvent('tool_fail', props: {'tool_id': widget.tool.id, 'code': 'OCR_FAIL'});
      }
      return;
    }

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_progress >= 90) {
        timer.cancel();
        return;
      }
      if (!mounted) return;
      setState(() => _progress += 10);
    });

    try {
      Uint8List outputBytes;
      if (widget.tool.id == 'merge') {
        final all = _files
            .map((f) => f.bytes)
            .whereType<Uint8List>()
            .toList(growable: false);
        outputBytes = _pdfService.merge(all);
      } else {
        final src = _files.first.bytes;
        if (src == null) throw Exception('No file bytes');
        final pageCount = _pdfService.pageCount(src);
        switch (widget.tool.id) {
          case 'split':
            outputBytes = _pdfService.splitExtract(
              src,
              _parsePageSet(_rangeController.text, pageCount),
            );
            break;
          case 'delete':
            outputBytes = _pdfService.deletePages(
              src,
              _parsePageSet(_rangeController.text, pageCount),
            );
            break;
          case 'rearrange':
            outputBytes = _pdfService.rearrange(
              src,
              _parseOrder(_orderController.text, pageCount),
            );
            break;
          case 'rotate':
            final selectedPages = _parsePageSet(_rangeController.text, pageCount);
            outputBytes = selectedPages.length == pageCount
                ? _pdfService.rotateAll(src, _rotation)
                : _pdfService.rotateSelected(src, _rotation, selectedPages);
            break;
          case 'compress-pdf':
            outputBytes = _pdfService.compress(src, _compression);
            break;
          case 'password':
            if (_passwordController.text.trim().isEmpty) {
              throw Exception('Password is required');
            }
            outputBytes = _pdfService.passwordProtect(src, _passwordController.text.trim());
            break;
          default:
            throw Exception('Unsupported PDF tool');
        }
      }

      final path = await _savePdfOutput(outputBytes, widget.tool.id);
      final name = path.split('/').last;
      FileStore.addFile(
        FileItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          type: FileType.pdf,
          date: 'Just now',
          path: path,
        ),
      );

      if (!mounted) return;
      setState(() {
        _processing = false;
        _progress = 100;
        _success = true;
        _statusText = 'Saved to My Files';
        _lastOutputPath = path;
        _errorCode = null;
        _errorMessage = null;
      });
      AnalyticsService.logEvent('tool_success', props: {'tool_id': widget.tool.id});
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        _statusText = 'Failed to process PDF';
        _errorCode = 'PDF_PROCESS_FAIL';
        _errorMessage = 'Could not process this PDF. Verify file/pages and try again.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not process this PDF. Verify file/pages and try again.')),
      );
      AnalyticsService.logEvent('tool_fail', props: {'tool_id': widget.tool.id, 'code': 'PDF_PROCESS_FAIL'});
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _rangeController.dispose();
    _orderController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.tool.name)),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 8),
            const InlineBannerAd(),
            const SizedBox(height: 8),
            Expanded(
              child: Stack(
                children: [
                  ListView(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      16 + MediaQuery.of(context).padding.bottom,
                    ),
                  children: [
              if (_errorCode != null) ...[
                _ErrorBanner(
                  code: _errorCode!,
                  message: _errorMessage ?? 'Something went wrong.',
                  onRetry: _files.isEmpty ? null : _process,
                ),
                const SizedBox(height: 12),
              ],
              OutlinedButton.icon(
                onPressed: _pick,
                icon: const Icon(Icons.upload_file_rounded),
                label: Text(widget.tool.id == 'merge' ? 'Add PDF Files' : 'Select File'),
              ),
              const SizedBox(height: 12),
              ..._files.map(
                (file) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red),
                  title: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ),
              if (_pdfPathForOpen != null) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () async => OpenFilex.open(_pdfPathForOpen!),
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Open in another app'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (widget.tool.id != 'merge' &&
                  _files.isNotEmpty &&
                  (_files.first.extension ?? '').toLowerCase() == 'pdf' &&
                  _files.first.bytes != null) ...[
                const SizedBox(height: 4),
                Text(
                  widget.tool.id == 'ocr' ? 'Document preview' : 'Reader',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: widget.tool.id == 'ocr' ? 360 : 420,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SfPdfViewer.memory(
                      _files.first.bytes!,
                      canShowScrollHead: false,
                      canShowScrollStatus: true,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (_sourcePageCount > 0 && widget.tool.id != 'merge' && widget.tool.id != 'ocr') ...[
                Text(
                  'Pages detected: $_sourcePageCount',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 10),
              ],
              if (widget.tool.id == 'split' || widget.tool.id == 'delete') ...[
                TextField(
                  controller: _rangeController,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: widget.tool.id == 'split'
                        ? 'Pages to extract (e.g. 1-3,5)'
                        : 'Pages to delete (e.g. 2,4-6)',
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _sourcePageCount > 0 ? _showVisualPagePicker : null,
                    icon: const Icon(Icons.touch_app_outlined),
                    label: const Text('Choose pages visually'),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (widget.tool.id == 'rearrange') ...[
                TextField(
                  controller: _orderController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Page order (e.g. 3,1,2,4)',
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (widget.tool.id == 'password') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Set Password',
                  ),
                ),
              ],
              if (widget.tool.id == 'compress-pdf') ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<PdfCompressionLevel>(
                  value: _compression,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Compression level',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: PdfCompressionLevel.belowNormal,
                      child: Text('Low'),
                    ),
                    DropdownMenuItem(
                      value: PdfCompressionLevel.normal,
                      child: Text('Balanced'),
                    ),
                    DropdownMenuItem(
                      value: PdfCompressionLevel.aboveNormal,
                      child: Text('High'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _compression = v);
                  },
                ),
              ],
              if (widget.tool.id == 'rotate') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _rangeController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Pages to rotate (e.g. 2,4-6) • leave empty for all',
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _sourcePageCount > 0 ? _showVisualPagePicker : null,
                    icon: const Icon(Icons.touch_app_outlined),
                    label: const Text('Choose pages visually'),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<PdfPageRotateAngle>(
                  value: _rotation,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Rotate angle',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: PdfPageRotateAngle.rotateAngle90,
                      child: Text('90°'),
                    ),
                    DropdownMenuItem(
                      value: PdfPageRotateAngle.rotateAngle180,
                      child: Text('180°'),
                    ),
                    DropdownMenuItem(
                      value: PdfPageRotateAngle.rotateAngle270,
                      child: Text('270°'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _rotation = v);
                  },
                ),
              ],
              if (_ocrText.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Extracted text',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const SizedBox(height: 8),
                SelectableText(_ocrText),
              ],
              const SizedBox(height: 16),
              if (_success)
                Column(
                  children: [
                    _SuccessPanel(
                      title: 'PDF processed',
                      subtitle: _statusText.isEmpty ? 'Output saved to My Files.' : _statusText,
                    ),
                    const SizedBox(height: 10),
                    _PostJobActions(
                      filePath: _lastOutputPath,
                      onOpenMyFiles: () => Navigator.pushNamed(context, '/my-files'),
                    ),
                  ],
                )
              else
                ElevatedButton(
                  onPressed: _files.isEmpty ? null : _process,
                  child: Text('Process ${widget.tool.name}'),
                ),
                  ],
                ),
                  if (_processing)
                    _ProcessingOverlay(message: '${widget.tool.name}...', progress: _progress),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MyFilesScreen extends StatelessWidget {
  const MyFilesScreen({super.key});

  static Future<void> _showInFolder(String filePath) async {
    final dir = File(filePath).parent.path;
    if (Platform.isMacOS) {
      await Process.run('open', [dir]);
      return;
    }
    if (Platform.isWindows) {
      await Process.run('explorer', [dir]);
      return;
    }
    if (Platform.isLinux) {
      await Process.run('xdg-open', [dir]);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('My Files')),
      body: Column(
        children: [
          const SizedBox(height: 8),
          const InlineBannerAd(),
          const SizedBox(height: 8),
          Expanded(
            child: ValueListenableBuilder<List<FileItem>>(
              valueListenable: FileStore.files,
              builder: (context, files, _) {
                if (files.isEmpty) {
                  return const Center(child: Text('No generated files yet.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: files.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final file = files[index];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                    if (file.thumbnailPath != null && file.thumbnailPath!.isNotEmpty && File(file.thumbnailPath!).existsSync())
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(file.thumbnailPath!),
                          width: 38,
                          height: 38,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      const Icon(Icons.insert_drive_file_outlined),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(
                            file.type.name.toUpperCase(),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'More',
                      icon: const Icon(Icons.more_vert_rounded),
                      onPressed: () {
                        showModalBottomSheet<void>(
                          context: context,
                          showDragHandle: true,
                          builder: (ctx) {
                            final hasPath = file.path != null && file.path!.isNotEmpty;
                            final canShowFolder = hasPath && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);
                            return SafeArea(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.open_in_new_rounded),
                                    title: const Text('Open'),
                                    enabled: hasPath,
                                    onTap: !hasPath
                                        ? null
                                        : () async {
                                            Navigator.of(ctx).pop();
                                            await OpenFilex.open(file.path!);
                                          },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.share_outlined),
                                    title: const Text('Share'),
                                    onTap: () async {
                                      Navigator.of(ctx).pop();
                                      if (hasPath) {
                                        await SharePlus.instance.share(
                                          ShareParams(files: [XFile(file.path!)]),
                                        );
                                      } else if (file.content != null && file.content!.trim().isNotEmpty) {
                                        await SharePlus.instance.share(
                                          ShareParams(text: file.content!),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Nothing to share yet.')),
                                        );
                                      }
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.drive_file_rename_outline_rounded),
                                    title: const Text('Rename'),
                                    onTap: () async {
                                      Navigator.of(ctx).pop();
                                      final c = TextEditingController(text: file.name);
                                      final renamed = await showDialog<String>(
                                        context: context,
                                        builder: (dialogCtx) => AlertDialog(
                                          title: const Text('Rename file'),
                                          content: TextField(
                                            controller: c,
                                            decoration: const InputDecoration(labelText: 'File name'),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(dialogCtx).pop(),
                                              child: const Text('Cancel'),
                                            ),
                                            FilledButton(
                                              onPressed: () => Navigator.of(dialogCtx).pop(c.text.trim()),
                                              child: const Text('Save'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (renamed == null || renamed.isEmpty) return;
                                      if (!hasPath) {
                                        FileStore.renameById(file.id, renamed);
                                        return;
                                      }
                                      final oldFile = File(file.path!);
                                      final extMatch = RegExp(r'(\.[a-zA-Z0-9]+)$').firstMatch(oldFile.path);
                                      final ext = extMatch?.group(1) ?? '';
                                      final safeName = renamed.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
                                      final newPath = '${oldFile.parent.path}/$safeName$ext';
                                      try {
                                        await oldFile.rename(newPath);
                                        FileStore.updateById(
                                          id: file.id,
                                          newName: '$safeName$ext',
                                          newPath: newPath,
                                        );
                                      } catch (_) {
                                        FileStore.renameById(file.id, renamed);
                                      }
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.copy_rounded),
                                    title: const Text('Copy file path'),
                                    enabled: hasPath,
                                    onTap: !hasPath
                                        ? null
                                        : () async {
                                            Navigator.of(ctx).pop();
                                            await Clipboard.setData(ClipboardData(text: file.path!));
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Path copied')),
                                            );
                                          },
                                  ),
                                  if (canShowFolder)
                                    ListTile(
                                      leading: const Icon(Icons.folder_open_outlined),
                                      title: const Text('Open containing folder'),
                                      onTap: () async {
                                        Navigator.of(ctx).pop();
                                        await _showInFolder(file.path!);
                                      },
                                    ),
                                  const Divider(height: 1),
                                  ListTile(
                                    leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                                    title: const Text('Remove from list', style: TextStyle(color: Colors.red)),
                                    onTap: () {
                                      Navigator.of(ctx).pop();
                                      FileStore.removeById(file.id);
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProcessingOverlay extends StatelessWidget {
  final String message;
  final int progress;

  const _ProcessingOverlay({required this.message, required this.progress});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: const Color(0xFF0F172A).withValues(alpha: 0.42),
      child: Center(
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1857E6)),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$progress%',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Optimizing output quality. Keep this screen open.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessPanel extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SuccessPanel({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Icon(Icons.check_circle_rounded, size: 34, color: Color(0xFF16A34A)),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String code;
  final String message;
  final VoidCallback? onRetry;

  const _ErrorBanner({
    required this.code,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECDD3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Error $code',
            style: const TextStyle(
              color: Color(0xFF9F1239),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFF881337),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PostJobActions extends StatelessWidget {
  final String? filePath;
  final VoidCallback onOpenMyFiles;

  const _PostJobActions({
    required this.filePath,
    required this.onOpenMyFiles,
  });

  Future<void> _shareFile(BuildContext context) async {
    if (filePath == null) return;
    await SharePlus.instance.share(
      ShareParams(
        text: 'Shared from OfficeTools Pro',
        files: [XFile(filePath!)],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onOpenMyFiles,
            icon: const Icon(Icons.folder_open_outlined),
            label: const Text('Open My Files'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: filePath == null ? null : () => _shareFile(context),
            icon: const Icon(Icons.share_outlined),
            label: const Text('Share'),
          ),
        ),
      ],
    );
  }
}

class _ToolListTile extends StatefulWidget {
  final ToolOption tool;
  final VoidCallback onTap;

  const _ToolListTile({required this.tool, required this.onTap});

  @override
  State<_ToolListTile> createState() => _ToolListTileState();
}

class _ToolListTileState extends State<_ToolListTile> {
  bool _pressed = false;

  String _qualityLabel(String id) {
    switch (id) {
      case 'compress-pdf':
      case 'compress-img':
      case 'ocr':
      case 'remove-bg':
        return 'On-device';
      case 'img-convert':
      case 'convert-img':
      case 'resize':
      case 'crop':
        return 'Fast';
      default:
        return 'Balanced';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedScale(
      scale: _pressed ? 0.985 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: Material(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE7EBF2),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D0F172A),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1857E6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(widget.tool.icon, size: 22, color: const Color(0xFF1857E6)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.tool.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _CapabilityChip(
                            label: widget.tool.requiresInternet ? 'Online' : 'Offline',
                            color: widget.tool.requiresInternet
                                ? const Color(0xFFEA580C)
                                : const Color(0xFF16A34A),
                          ),
                          if (widget.tool.isBeta) ...[
                            const SizedBox(width: 6),
                            const _CapabilityChip(
                              label: 'Beta',
                              color: Color(0xFF7C3AED),
                            ),
                          ],
                          const SizedBox(width: 6),
                          _CapabilityChip(
                            label: _qualityLabel(widget.tool.id),
                            color: const Color(0xFF1857E6),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CapabilityChip extends StatelessWidget {
  final String label;
  final Color color;

  const _CapabilityChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AnimatedChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _AnimatedChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: const Color(0xFFE2EBFF),
      side: const BorderSide(color: Color(0xFFCBD5E1)),
      labelStyle: TextStyle(
        color: selected ? const Color(0xFF1857E6) : const Color(0xFF334155),
        fontWeight: FontWeight.w700,
      ),
      onSelected: (_) => onTap(),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      pressElevation: 0,
    );
  }
}

/// Same geometry as `BoxFit.contain` for laying overlays on previews.
Rect containImageForBoxFit(Size container, Size image) {
  final imageRatio = image.width / image.height;
  final containerRatio = container.width / container.height;
  if (imageRatio > containerRatio) {
    final width = container.width;
    final height = width / imageRatio;
    final top = (container.height - height) / 2;
    return Rect.fromLTWH(0, top, width, height);
  }
  final height = container.height;
  final width = height * imageRatio;
  final left = (container.width - width) / 2;
  return Rect.fromLTWH(left, 0, width, height);
}

class _ImageCropOverlayPainter extends CustomPainter {
  final Rect imageRect;
  final double cropL;
  final double cropT;
  final double cropR;
  final double cropB;

  _ImageCropOverlayPainter({
    required this.imageRect,
    required this.cropL,
    required this.cropT,
    required this.cropR,
    required this.cropB,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cropPixel = Rect.fromLTRB(
      imageRect.left + cropL * imageRect.width,
      imageRect.top + cropT * imageRect.height,
      imageRect.left + cropR * imageRect.width,
      imageRect.top + cropB * imageRect.height,
    );
    final outer = Path()..addRect(Offset.zero & size);
    final inner = Path()..addRect(cropPixel);
    final shade = Path.combine(PathOperation.difference, outer, inner);
    canvas.drawPath(shade, Paint()..color = const Color(0x99000000));

    canvas.drawRect(
      cropPixel,
      Paint()
        ..color = const Color(0xFF1857E6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final corners = [
      cropPixel.topLeft,
      cropPixel.topRight,
      cropPixel.bottomRight,
      cropPixel.bottomLeft,
    ];
    const radius = 11.0;
    for (final p in corners) {
      canvas.drawCircle(p, radius, Paint()..color = const Color(0xFF1857E6));
      canvas.drawCircle(
        p,
        radius + 5,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ImageCropOverlayPainter oldDelegate) =>
      oldDelegate.imageRect != imageRect ||
      oldDelegate.cropL != cropL ||
      oldDelegate.cropT != cropT ||
      oldDelegate.cropR != cropR ||
      oldDelegate.cropB != cropB;
}
