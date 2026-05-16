import 'package:flutter/material.dart';
import 'package:office_toolspro/services/app_settings.dart';
import 'package:office_toolspro/services/consent_service.dart';
import 'package:office_toolspro/utils/scroll_insets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPad = edgeToEdgeBottomPadding(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Settings')),
      body: ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: ValueListenableBuilder<AppSettingsState>(
        valueListenable: AppSettings.state,
        builder: (context, settings, _) {
          return ListView(
            padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPad),
            children: [
              Text(
                'Scan Doc',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              SwitchListTile(
                value: settings.autoDetectScanEdges,
                onChanged: (v) => AppSettings.update(
                    settings.copyWith(autoDetectScanEdges: v)),
                title: const Text('Auto-detect document edges'),
                subtitle: Text(
                  'Pre-fills crop corners after capture.',
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
              ),
              SwitchListTile(
                value: settings.keepOriginalScanCopy,
                onChanged: (v) => AppSettings.update(
                    settings.copyWith(keepOriginalScanCopy: v)),
                title: const Text('Keep original scan copy'),
                subtitle: Text(
                  'Saves first captured image alongside scan PDF.',
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
              ),
              Text(
                'Default image quality: ${settings.defaultImageQuality}%',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              Slider(
                min: 50,
                max: 100,
                divisions: 50,
                value: settings.defaultImageQuality.toDouble(),
                onChanged: (v) => AppSettings.update(
                  settings.copyWith(defaultImageQuality: v.round()),
                ),
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<bool>(
                valueListenable: ConsentService.privacyOptionsRequired,
                builder: (context, required, _) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Privacy options'),
                    subtitle: Text(
                      required
                          ? 'Manage advertising privacy options.'
                          : 'No privacy options required right now.',
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    enabled: required,
                    onTap: required
                        ? () async {
                            await ConsentService.showPrivacyOptions();
                          }
                        : null,
                  );
                },
              ),
            ],
          );
        },
      ),
      ),
    );
  }
}
