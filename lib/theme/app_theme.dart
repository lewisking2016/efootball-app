import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryPurple = Color(0xFF38003C);
  static const Color accentGreen = Color(0xFF00FF85);
  static const Color redForm = Color(0xFFE62E2D);
  static const Color darkBackground = Color(0xFF1E1E1E);
  static const Color lightBackground = Color(0xFFFBFBFB);
  static const Color cardColorLight = Color(0xFFFFFFFF);
  static const Color textColorLight = Color(0xFF1A1A1A);
  static const Color textColorDark = Color(0xFFFFFFFF);
  
  // High-Fidelity Gradients
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1A0025), // Very deep EPL dark purple
      Color(0xFF38003C), // EPL primary purple
      Color(0xFF5C0070), // Mid purple
      Color(0xFF6B007C), // EPL accent purple
    ],
    stops: [0.0, 0.35, 0.7, 1.0],
  );

  static const LinearGradient eplGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF00FF85), // EPL Green
      Color(0xFF38003C), // EPL Purple
    ],
  );

  static LinearGradient getTournamentGradient(String tournamentId) {
    if (tournamentId == 'champions_league') {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF00143F), Color(0xFF04297A), Color(0xFF004488)],
      );
    } else if (tournamentId == 'la_liga') {
      return const LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [Color(0xFFEE1222), Color(0xFFFF5F5F)],
      );
    } else if (tournamentId == 'epl') {
      return eplGradient;
    }
    return headerGradient;
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: lightBackground,
      primaryColor: primaryPurple,
      colorScheme: ColorScheme.light(
        primary: primaryPurple,
        secondary: accentGreen,
        surface: cardColorLight,
        onSurface: textColorLight,
        outline: Colors.grey.withValues(alpha: 0.1),
      ),
      // PREMIUM TYPOGRAPHY: Inter for Body, Outfit for Headings
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: textColorLight),
        displayMedium: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: textColorLight),
        displaySmall: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: textColorLight),
        headlineMedium: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: textColorLight),
        titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: primaryPurple),
        titleTextStyle: GoogleFonts.outfit(
          color: primaryPurple,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  static InputDecoration getAuthInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70, fontSize: 13),
      prefixIcon: Icon(icon, color: accentGreen, size: 20),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: accentGreen, width: 2),
      ),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
