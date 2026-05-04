import 'package:flutter/material.dart';

class AppConstants {
  static const Color primaryBlue = Color(0xFF007AFF);
  static const Color backgroundGrey = Color(0xFFF2F2F7);
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
  ToolModel(id: 'scan', name: 'Scan Doc', icon: Icons.document_scanner_outlined, color: Colors.blue, route: '/scanner'),
  ToolModel(id: 'image', name: 'Image Tools', icon: Icons.image_outlined, color: Colors.orange, route: '/image-tools'),
  ToolModel(id: 'pdf', name: 'PDF Tools', icon: Icons.picture_as_pdf_outlined, color: Colors.red, route: '/pdf-tools'),
  ToolModel(id: 'convert', name: 'Convert Files', icon: Icons.sync_outlined, color: Colors.green, route: '/convert'),
  ToolModel(id: 'compress', name: 'Compress Files', icon: Icons.compress_outlined, color: Colors.yellow[700]!, route: '/compress'),
  ToolModel(id: 'calculators', name: 'Calculators', icon: Icons.calculate_outlined, color: Colors.indigo, route: '/calculators'),
];
