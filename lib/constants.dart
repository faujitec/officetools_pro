import 'package:flutter/material.dart';

class AppConstants {
  static const Color primaryBlue = Color(0xFF007AFF);
  static const Color backgroundGrey = Color(0xFFF2F2F7);

  /// AdMob app ID (Android manifest + iOS Info.plist must match).
  static const String admobAppId = 'ca-app-pub-9040268910945565~1320297049';

  /// Production ad units (OfficeTools Pro — create iOS-specific units in AdMob if iOS load fails).
  static const String admobBannerAndroid =
      'ca-app-pub-9040268910945565/4876398671';
  static const String admobInterstitialAndroid =
      'ca-app-pub-9040268910945565/5231621894';

  /// Google Play listing (package must match `applicationId` in Android build).
  static final Uri playStoreListingUri = Uri.parse(
    'https://play.google.com/store/apps/details?id=com.officetoolspro.app',
  );

  /// Public legal pages (Google Sites).
  static final Uri privacyPolicyUri = Uri.parse(
    'https://sites.google.com/view/officetoolspro-privacypolicy/home',
  );

  static final Uri termsOfServiceUri = Uri.parse(
    'https://sites.google.com/view/officetoolspro-termsofservice/home',
  );

  /// Apple App Store numeric app ID from App Store Connect.
  /// Until set, iOS opens an App Store search for the app name.
  static const String appStoreAppId = String.fromEnvironment(
    'APP_STORE_ID',
    defaultValue: '',
  );

  static Uri get appStoreListingUri {
    if (appStoreAppId.isNotEmpty) {
      return Uri.parse(
        'https://apps.apple.com/app/id$appStoreAppId?action=write-review',
      );
    }
    return Uri.parse(
      'https://apps.apple.com/search?term=${Uri.encodeComponent('OfficeTools Pro')}',
    );
  }
}

class ToolModel {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final String? route;

  ToolModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.route,
  });
}

final List<ToolModel> mainTools = [
  ToolModel(
      id: 'scan',
      name: 'Scan Doc',
      icon: Icons.document_scanner_outlined,
      color: Colors.blue,
      route: '/scanner'),
  ToolModel(
      id: 'image',
      name: 'Image Tools',
      icon: Icons.image_outlined,
      color: Colors.orange,
      route: '/image-tools'),
  ToolModel(
      id: 'pdf',
      name: 'PDF Tools',
      icon: Icons.picture_as_pdf_outlined,
      color: Colors.red,
      route: '/pdf-tools'),
  ToolModel(
      id: 'convert',
      name: 'Convert Files',
      icon: Icons.sync_outlined,
      color: Colors.green,
      route: '/convert'),
  ToolModel(
      id: 'my-files',
      name: 'My Files',
      icon: Icons.folder_open_outlined,
      color: Colors.yellow[700]!,
      route: '/my-files'),
  ToolModel(
      id: 'calculators',
      name: 'Calculators',
      icon: Icons.calculate_outlined,
      color: Colors.indigo,
      route: '/calculators'),
];
