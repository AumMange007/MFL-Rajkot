import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand palette
  static const _primary   = Color(0xFF4F46E5); // Indigo-600
  static const _secondary = Color(0xFF0EA5E9); // Sky-500
  static const _surface   = Color(0xFFF8F9FF); // near-white with blue tint
  static const _card      = Colors.white;
  static const _ink       = Color(0xFF0F172A); // Slate-900
  static const _inkMuted  = Color(0xFF64748B); // Slate-500
  static const _border    = Color(0xFFE2E8F0); // Slate-200

  // Accent colours used across feature areas
  static const teal    = Color(0xFF0D9488);
  static const violet  = Color(0xFF7C3AED);
  static const amber   = Color(0xFFF59E0B);
  static const rose    = Color(0xFFE11D48);
  static const emerald = Color(0xFF059669);

  // ── Light ─────────────────────────────────────────────────────────────────
  static ThemeData get light {
    final base = ColorScheme.fromSeed(
      seedColor: _primary,
      brightness: Brightness.light,
      surface: _surface,
    ).copyWith(
      primary: _primary,
      secondary: _secondary,
      surface: _surface,
      onSurface: _ink,
    );

    final textTheme = GoogleFonts.interTextTheme().copyWith(
      displayLarge:  GoogleFonts.inter(fontSize: 57, fontWeight: FontWeight.w700, color: _ink),
      displayMedium: GoogleFonts.inter(fontSize: 45, fontWeight: FontWeight.w700, color: _ink),
      headlineLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w700, color: _ink),
      headlineMedium:GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, color: _ink),
      headlineSmall: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: _ink),
      titleLarge:    GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: _ink),
      titleMedium:   GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: _ink),
      titleSmall:    GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: _ink),
      bodyLarge:     GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: _ink),
      bodyMedium:    GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: _inkMuted),
      bodySmall:     GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: _inkMuted),
      labelLarge:    GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: _ink),
      labelMedium:   GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: _inkMuted),
      labelSmall:    GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: _inkMuted),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: base,
      textTheme: textTheme,
      scaffoldBackgroundColor: _surface,

      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: _ink,
        surfaceTintColor: Colors.transparent,
        shadowColor: _border,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: _ink,
        ),
        iconTheme: const IconThemeData(color: _inkMuted),
        actionsIconTheme: const IconThemeData(color: _inkMuted),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: _card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _border, width: 1),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: GoogleFonts.inter(fontSize: 14, color: _inkMuted),
        hintStyle: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF94A3B8)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: rose),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: rose, width: 2),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primary,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: _primary, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primary,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF1F5F9),
        labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide.none,
      ),

      dividerTheme: const DividerThemeData(
        color: _border,
        thickness: 1,
        space: 1,
      ),

      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        titleTextStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: _ink),
        subtitleTextStyle: GoogleFonts.inter(fontSize: 13, color: _inkMuted),
        iconColor: _inkMuted,
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: _ink,
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        extendedTextStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
      ),

      drawerTheme: const DrawerThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: _ink),
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: _inkMuted),
      ),
    );
  }

  // ── Dark ──────────────────────────────────────────────────────────────────
  static ThemeData get dark {
    final base = ColorScheme.fromSeed(
      seedColor: _primary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFF818CF8),
      secondary: _secondary,
      surface: const Color(0xFF0F172A),
    );

    final textTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: base,
      textTheme: textTheme,
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        color: Color(0xFF1E293B),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: Color(0xFF334155)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF818CF8), width: 2)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
