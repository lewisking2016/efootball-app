import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TeamLogo extends StatelessWidget {
  final String logoData;
  final double size;

  const TeamLogo({
    super.key,
    required this.logoData,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    if (logoData.isEmpty) {
      return Icon(Icons.shield, size: size, color: AppTheme.primaryPurple);
    }

    if (logoData.startsWith('assets/')) {
      return Image.asset(
        logoData,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, _, _) => Icon(Icons.broken_image, size: size, color: AppTheme.primaryPurple),
      );
    }

    if (logoData.startsWith('http://') || logoData.startsWith('https://')) {
      return Image.network(
        logoData,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, _, _) => Icon(Icons.broken_image, size: size, color: AppTheme.primaryPurple),
      );
    }

    // Attempt to decode Base64 string from Firebase db
    try {
      // Remove data URI scheme if present (e.g., 'data:image/png;base64,')
      final String base64String = logoData.contains(',') ? logoData.split(',').last : logoData;
      return Image.memory(
        base64Decode(base64String),
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, _, _) => Icon(Icons.broken_image, size: size, color: AppTheme.primaryPurple),
      );
    } catch (e) {
      return Icon(Icons.image_not_supported, size: size, color: AppTheme.primaryPurple);
    }
  }
}
