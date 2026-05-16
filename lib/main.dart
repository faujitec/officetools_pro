import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:office_toolspro/constants.dart';
import 'package:office_toolspro/screens/calculators_screen.dart';
import 'package:office_toolspro/screens/home_screen.dart';
import 'package:office_toolspro/screens/scanner_screen.dart';
import 'package:office_toolspro/screens/settings_screen.dart';
import 'package:office_toolspro/screens/tool_flows_screen.dart';
import 'package:office_toolspro/services/app_settings.dart';
import 'package:office_toolspro/services/consent_service.dart';
import 'package:office_toolspro/services/file_store.dart';
import 'package:office_toolspro/services/interstitial_ad_service.dart';
import 'package:office_toolspro/theme_controller.dart';
import 'package:office_toolspro/utils/system_ui.dart';
import 'package:office_toolspro/widgets/ads_click_tracker.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FileStore.load();
  await AppSettings.load();
  ThemeController.applyPreference(AppSettings.state.value.themePreference);
  await ConsentService.gatherConsent();
  await MobileAds.instance.initialize();
  InterstitialAdService.instance.initialize();
  runApp(const OfficeToolsApp());
}

class OfficeToolsApp extends StatefulWidget {
  const OfficeToolsApp({super.key});

  @override
  State<OfficeToolsApp> createState() => _OfficeToolsAppState();
}

class _OfficeToolsAppState extends State<OfficeToolsApp>
    with WidgetsBindingObserver {
  static Color? _cachedDarkSurface;

  @override
  void initState() {
    super.initState();
    enableEdgeToEdgeUi();
    WidgetsBinding.instance.addObserver(this);
    ThemeController.mode.addListener(_syncSystemNavigationBar);
    _syncSystemNavigationBar();
  }

  @override
  void dispose() {
    InterstitialAdService.instance.dispose();
    ThemeController.mode.removeListener(_syncSystemNavigationBar);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    _syncSystemNavigationBar();
  }

  void _syncSystemNavigationBar() {
    final mode = ThemeController.mode.value;
    final platform =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final useDark = switch (mode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system => platform == Brightness.dark,
    };
    _cachedDarkSurface ??= ColorScheme.fromSeed(
      seedColor: AppConstants.primaryBlue,
      brightness: Brightness.dark,
    ).surface;
    SystemChrome.setSystemUIOverlayStyle(
      overlayForBrightness(useDark ? Brightness.dark : Brightness.light),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (context, mode, _) {
        final lightScheme = ColorScheme.fromSeed(
          seedColor: AppConstants.primaryBlue,
          surface: AppConstants.backgroundGrey,
        );
        final darkScheme = ColorScheme.fromSeed(
          seedColor: AppConstants.primaryBlue,
          brightness: Brightness.dark,
        );
        return MaterialApp(
          title: 'OfficeTools Pro',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          builder: (context, child) {
            return AdsClickTracker(
              child: AnnotatedRegion<SystemUiOverlayStyle>(
                value: overlayForTheme(Theme.of(context)),
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: lightScheme,
            textTheme: ThemeData(
              useMaterial3: true,
              colorScheme: lightScheme,
            ).textTheme,
            scaffoldBackgroundColor: AppConstants.backgroundGrey,
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFFFFFFF),
              surfaceTintColor: Color(0xFFFFFFFF),
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(
                color: Colors.black,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: Color(0xFFE7EBF2)),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              labelStyle: const TextStyle(
                color: Color(0xFF334155),
                fontWeight: FontWeight.w600,
              ),
              floatingLabelStyle: const TextStyle(
                color: Color(0xFF1857E6),
                fontWeight: FontWeight.w700,
              ),
              hintStyle: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD6DEEA)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD6DEEA)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF1857E6), width: 1.4),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1857E6),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFBFD0F7),
                disabledForegroundColor: const Color(0xFF475569),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            chipTheme: ChipThemeData(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999)),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              labelStyle: const TextStyle(fontWeight: FontWeight.w700),
              selectedColor: const Color(0xFFE2EBFF),
              backgroundColor: Colors.white,
              checkmarkColor: const Color(0xFF1857E6),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            ),
            snackBarTheme: SnackBarThemeData(
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              contentTextStyle: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: darkScheme,
            scaffoldBackgroundColor: darkScheme.surface,
            textTheme: ThemeData(
              useMaterial3: true,
              colorScheme: darkScheme,
              brightness: Brightness.dark,
            ).textTheme,
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF1E293B),
              isDense: true,
              labelStyle: const TextStyle(
                color: Color(0xFFCBD5E1),
                fontWeight: FontWeight.w600,
              ),
              floatingLabelStyle: const TextStyle(
                color: Color(0xFF93C5FD),
                fontWeight: FontWeight.w700,
              ),
              hintStyle: const TextStyle(
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF334155)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF334155)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF60A5FA), width: 1.3),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF334155),
                disabledForegroundColor: const Color(0xFFE2E8F0),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE2E8F0),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                side: const BorderSide(color: Color(0xFF334155)),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            chipTheme: ChipThemeData(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999)),
              side: const BorderSide(color: Color(0xFF334155)),
              labelStyle: const TextStyle(fontWeight: FontWeight.w700),
              selectedColor: const Color(0xFF1D4ED8),
              backgroundColor: const Color(0xFF1E293B),
              checkmarkColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            ),
            snackBarTheme: SnackBarThemeData(
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF111827),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              contentTextStyle: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
          home: const HomeScreen(),
          routes: {
            '/scanner': (context) => const ScannerScreen(),
            '/image-tools': (context) => const ImageToolsScreen(),
            '/pdf-tools': (context) => const PdfToolsScreen(),
            '/convert': (context) => const ConvertScreen(),
            '/calculators': (context) => const CalculatorsScreen(),
            '/my-files': (context) => const MyFilesScreen(),
            '/settings': (context) => const SettingsScreen(),
          },
        );
      },
    );
  }
}
