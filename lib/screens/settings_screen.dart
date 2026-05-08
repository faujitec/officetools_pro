import 'package:flutter/material.dart';
import 'package:office_toolspro/services/app_settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ValueListenableBuilder<AppSettingsState>(
        valueListenable: AppSettings.state,
        builder: (context, settings, _) {
          return ListView(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
            children: [
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
              SwitchListTile(
                value: settings.cloudFeaturesEnabled,
                onChanged: (v) => AppSettings.update(
                    settings.copyWith(cloudFeaturesEnabled: v)),
                title: const Text('Enable cloud conversion features'),
                subtitle: Text(
                  'Controls CloudConvert-based tools (PDF/Word/Excel conversion).',
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
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
            ],
          );
        },
      ),
    );
  }
}
