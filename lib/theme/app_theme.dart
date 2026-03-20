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
      Color(0xFF38003C),
      Color(0xFF5A005D),
      Color(0xFF8D008F),
      Color(0xFFB000B2),
    ],
    stops: [0.0, 0.4, 0.8, 1.0],
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
        outline: Colors.grey.withOpacity(0.1),
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
}
