import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:office_toolspro/constants.dart';
import 'package:office_toolspro/main.dart';
import 'package:office_toolspro/models/file_item.dart';
import 'package:office_toolspro/services/app_settings.dart';
import 'package:office_toolspro/services/file_store.dart';
import 'package:office_toolspro/utils/ui_safety.dart';
import 'package:office_toolspro/widgets/context_hint_card.dart';
import 'package:office_toolspro/widgets/global_banner_ad.dart';
import 'package:share_plus/share_plus.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showTopBanner = true;
  static const double _switchDownOffset = 260;
  static const double _switchUpOffset = 160;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    // Hysteresis to prevent flicker while user hovers near threshold.
    final nextShowTop =
        _showTopBanner ? offset < _switchDownOffset : offset <= _switchUpOffset;
    if (nextShowTop != _showTopBanner) {
      setState(() => _showTopBanner = nextShowTop);
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const _AppDrawer(),
      appBar: AppBar(
        backgroundColor: isDark
            ? Theme.of(context).scaffoldBackgroundColor
            : const Color(0xFFFFFFFF),
        surfaceTintColor: isDark
            ? Theme.of(context).scaffoldBackgroundColor
            : const Color(0xFFFFFFFF),
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        title: const Text(
          'OfficeTools Pro',
          style: TextStyle(
            color: Color(0xFF1857E6),
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(
              Icons.menu,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              size: 26,
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottomInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _showTopBanner
                  ? const Column(
                      key: ValueKey('top-banner'),
                      children: [
                        InlineBannerAd(),
                        SizedBox(height: 12),
                      ],
                    )
                  : const SizedBox.shrink(key: ValueKey('top-banner-hidden')),
            ),
            if (AppSettings.shouldShowTip('home.quickstart')) ...[
              ContextHintCard(
                title: 'Quick start',
                message:
                    'Use Scan Doc for camera documents, PDF Tools for page actions, and Convert for format changes.',
                onDismiss: () {
                  AppSettings.dismissTip('home.quickstart');
                  setState(() {});
                },
              ),
              const SizedBox(height: 10),
            ],
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.9,
              ),
              itemCount: mainTools.length,
              itemBuilder: (context, index) {
                final tool = mainTools[index];
                return ToolCard(tool: tool);
              },
            ),
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: !_showTopBanner
                  ? const Column(
                      key: ValueKey('mid-banner'),
                      children: [
                        InlineBannerAd(),
                        SizedBox(height: 10),
                      ],
                    )
                  : const SizedBox.shrink(key: ValueKey('mid-banner-hidden')),
            ),
            _RecentFilesSection(
              onOpenAll: () => Navigator.pushNamed(context, '/my-files'),
            ),
          ],
        ),
      ),
    );
  }
}

class ToolCard extends StatelessWidget {
  final ToolModel tool;
  const ToolCard({super.key, required this.tool});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        if (tool.route != null) {
          Navigator.pushNamed(context, tool.route!);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE7EBF2),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF111827).withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: tool.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(tool.icon, color: tool.color, size: 40),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: Text(
                tool.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0B1536),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentFilesSection extends StatelessWidget {
  final VoidCallback onOpenAll;

  const _RecentFilesSection({required this.onOpenAll});

  IconData _iconForType(FileType type) {
    switch (type) {
      case FileType.pdf:
        return Icons.picture_as_pdf_outlined;
      case FileType.image:
        return Icons.image_outlined;
      case FileType.docx:
        return Icons.description_outlined;
      case FileType.txt:
        return Icons.text_snippet_outlined;
    }
  }

  Future<void> _openFile(BuildContext context, FileItem file) async {
    if (file.path == null || file.path!.isEmpty) return;
    await OpenFilex.open(file.path!);
  }

  Future<void> _shareFile(BuildContext context, FileItem file) async {
    if (file.path != null && file.path!.isNotEmpty) {
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path!)]));
      return;
    }
    if (file.content != null && file.content!.trim().isNotEmpty) {
      await SharePlus.instance.share(ShareParams(text: file.content!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ValueListenableBuilder<List<FileItem>>(
      valueListenable: FileStore.files,
      builder: (context, files, _) {
        final recent = files.take(8).toList(growable: false);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Recent Files',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                TextButton(onPressed: onOpenAll, child: const Text('View all')),
              ],
            ),
            if (recent.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE7EBF2),
                  ),
                ),
                child: Text(
                  'No recent files yet.',
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF64748B),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              ...recent.map((file) => Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () async {
                        final path = file.path;
                        if (path == null || path.isEmpty) {
                          if (!context.mounted) return;
                          UiSafety.showSnackBar(
                            context,
                            const SnackBar(
                                content: Text(
                                    'This item has no file path to open.')),
                          );
                          return;
                        }
                        if (!context.mounted) return;
                        final open = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Open file'),
                            content: Text('Open "${file.name}"?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Open'),
                              ),
                            ],
                          ),
                        );
                        if (open == true && context.mounted) {
                          await OpenFilex.open(path);
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE7EBF2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(_iconForType(file.type),
                                color: const Color(0xFF1857E6)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    file.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    '${file.type.name.toUpperCase()} • ${file.date}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isDark
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF64748B),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              tooltip: 'Actions',
                              position: PopupMenuPosition.under,
                              offset: const Offset(-12, 4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE7EBF2),
                                ),
                              ),
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : Colors.white,
                              elevation: 8,
                              shadowColor: const Color(0xFF111827)
                                  .withValues(alpha: 0.12),
                              icon: Icon(
                                Icons.more_horiz_rounded,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                              onSelected: (value) async {
                                if (value == 'open') {
                                  await _openFile(context, file);
                                } else if (value == 'share') {
                                  await _shareFile(context, file);
                                } else if (value == 'remove') {
                                  final removed = file;
                                  FileStore.removeById(file.id);
                                  if (!context.mounted) return;
                                  UiSafety.showSnackBar(
                                    context,
                                    SnackBar(
                                      content:
                                          Text('"${removed.name}" removed'),
                                      action: SnackBarAction(
                                        label: 'Undo',
                                        onPressed: () => FileStore.restore(
                                            removed,
                                            index: 0),
                                      ),
                                    ),
                                  );
                                }
                              },
                              itemBuilder: (ctx) => [
                                PopupMenuItem(
                                  value: 'open',
                                  enabled: file.path != null &&
                                      file.path!.isNotEmpty,
                                  child: _RecentFileMenuRow(
                                    icon: Icons.open_in_new_rounded,
                                    label: 'Open',
                                    iconColor: const Color(0xFF1857E6),
                                    isDark: isDark,
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'share',
                                  child: _RecentFileMenuRow(
                                    icon: Icons.share_outlined,
                                    label: 'Share',
                                    iconColor: const Color(0xFF1857E6),
                                    isDark: isDark,
                                  ),
                                ),
                                const PopupMenuDivider(height: 1),
                                PopupMenuItem(
                                  value: 'remove',
                                  child: _RecentFileMenuRow(
                                    icon: Icons.delete_outline_rounded,
                                    label: 'Remove',
                                    iconColor: const Color(0xFFDC2626),
                                    isDark: isDark,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  )),
          ],
        );
      },
    );
  }
}

class _RecentFileMenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final bool isDark;

  const _RecentFileMenuRow({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: iconColor),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Drawer(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
          children: [
            const SizedBox(height: 4),
            _DrawerActionTile(
              icon: Icons.settings_outlined,
              label: 'Settings',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/settings');
              },
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: ThemeController.mode,
              builder: (context, mode, _) {
                final isDarkMode = mode == ThemeMode.dark;
                return Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE7EBF2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF111827)
                            .withValues(alpha: isDark ? 0.2 : 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SwitchListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1857E6).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isDarkMode
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        color: const Color(0xFF1857E6),
                        size: 22,
                      ),
                    ),
                    title: Text(
                      'Dark / Light mode',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    value: isDarkMode,
                    onChanged: (enabled) {
                      ThemeController.mode.value =
                          enabled ? ThemeMode.dark : ThemeMode.light;
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            _DrawerActionTile(
              icon: Icons.privacy_tip_outlined,
              label: 'Privacy Policy',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const _InfoPage(
                      title: 'Privacy Policy',
                      content: 'Privacy Policy (Last updated: 06 May 2026)\n\n'
                          'OfficeTools Pro is designed as a utility-first app. We process files that you choose and only for the operations you trigger.\n\n'
                          '1) Scope of data processing\n'
                          '- The app can process PDFs, images, text, and office files selected by you.\n'
                          '- Most features (merge/split/rearrange PDFs, image resize/crop/compress, calculator tools) run locally on your device.\n'
                          '- Some optional features may call third-party services when enabled (for example CloudConvert-based conversions).\n\n'
                          '2) What is stored on device\n'
                          '- Generated outputs are stored locally in the app output folder.\n'
                          '- Recent/My Files history is stored locally to help you reopen files quickly.\n'
                          '- App preferences (theme, settings toggles) are stored locally.\n'
                          '- We do not maintain a user account system in the app.\n\n'
                          '3) Cloud features and third-party providers\n'
                          '- Cloud conversion features are optional and can be disabled in Settings.\n'
                          '- If enabled, selected file content may be transmitted to the configured provider to complete conversion.\n'
                          '- Provider behavior, retention, and compliance are governed by that provider\'s policy.\n'
                          '- Avoid sending highly sensitive documents to cloud providers unless your organization approves it.\n\n'
                          '4) File ownership and responsibility\n'
                          '- You retain ownership of your files and outputs.\n'
                          '- You are responsible for rights/permissions to process shared or third-party documents.\n\n'
                          '5) Security notes\n'
                          '- We aim to keep local data handling simple and minimal.\n'
                          '- No system is 100% risk-free; keep backups for important files.\n'
                          '- Use device lock and platform security features for stronger protection.\n\n'
                          '6) Your controls\n'
                          '- Remove file entries from My Files anytime.\n'
                          '- Disable cloud features in Settings.\n'
                          '- Use local-only tools where privacy is critical.\n\n'
                          '7) Contact\n'
                          'For privacy questions or data-handling concerns: faujitec@gmail.com',
                    ),
                  ),
                );
              },
            ),
            _DrawerActionTile(
              icon: Icons.description_outlined,
              label: 'Terms of Reference',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const _InfoPage(
                      title: 'Terms of Reference',
                      content:
                          'Terms of Reference (Last updated: 06 May 2026)\n\n'
                          'By using OfficeTools Pro, you agree to the following:\n\n'
                          '1) Acceptable use\n'
                          '- Use the app only for lawful purposes.\n'
                          '- Process only files you own or are authorized to use.\n'
                          '- Do not use the app to violate privacy, IP, or regulatory obligations.\n\n'
                          '2) Accuracy and verification\n'
                          '- The app provides utility operations and best-effort processing.\n'
                          '- You must review outputs before legal, financial, compliance, or production submission.\n'
                          '- OCR, conversion, and compression may vary by source quality and file structure.\n\n'
                          '3) Third-party services\n'
                          '- Some features depend on third-party APIs and internet access.\n'
                          '- You are responsible for API keys, billing, usage limits, and provider terms.\n'
                          '- We are not responsible for provider outages, policy changes, or pricing changes.\n\n'
                          '4) Availability and compatibility\n'
                          '- Features may differ by platform/device capability.\n'
                          '- Very large or malformed files may fail or perform slowly.\n'
                          '- We may update, improve, or retire features to maintain app quality.\n\n'
                          '5) Data and backup responsibility\n'
                          '- Keep backups of important files.\n'
                          '- You are responsible for secure handling, retention, and sharing of outputs.\n\n'
                          '6) Limitation of liability\n'
                          '- The app is provided "as is" without warranty of uninterrupted availability.\n'
                          '- To the maximum extent permitted by law, we are not liable for indirect or consequential losses arising from app use.\n\n'
                          '7) Contact\n'
                          'For support or legal/terms questions: faujitec@gmail.com',
                    ),
                  ),
                );
              },
            ),
            _DrawerActionTile(
              icon: Icons.info_outline,
              label: 'About This App',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const _InfoPage(
                      title: 'About This App',
                      content:
                          'OfficeTools Pro is an all-in-one document and image productivity workspace built for fast daily tasks.\n\n'
                          'What you can do:\n'
                          '- Scan documents with crop, rotate, filter, and PDF output\n'
                          '- Work with PDFs: merge, split, rearrange, rotate, delete, compress, protect, and OCR\n'
                          '- Use image tools: resize, crop, format convert, compress, and background removal\n'
                          '- Use conversion tools: image/text/office conversion (local and cloud-supported paths)\n'
                          '- Manage generated outputs in My Files with open/share/rename/folder actions\n\n'
                          'Design goals:\n'
                          '- Keep common operations simple and fast\n'
                          '- Prefer local processing where practical\n'
                          '- Provide clear progress, error messaging, and output visibility\n\n'
                          'Current app highlights:\n'
                          '- Adaptive previews for better portrait/landscape viewing\n'
                          '- Smoother PDF preview and large-file handling improvements\n'
                          '- Enhanced calculator experience with sliders, presets, and schedule breakdowns\n'
                          '- Centralized settings for quality, cloud toggles, and scan behavior\n\n'
                          'Cloud-aware workflow:\n'
                          '- Some high-fidelity conversions use third-party cloud APIs when configured\n'
                          '- You can disable cloud features in Settings for privacy-first usage\n\n'
                          'Support and feedback:\n'
                          'We continuously improve based on user reports. For support or suggestions: faujitec@gmail.com',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE7EBF2),
        ),
        boxShadow: [
          BoxShadow(
            color:
                const Color(0xFF111827).withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1857E6).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF1857E6), size: 22),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _InfoPage extends StatelessWidget {
  final String title;
  final String content;

  const _InfoPage({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  content,
                  style: const TextStyle(fontSize: 15, height: 1.45),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
