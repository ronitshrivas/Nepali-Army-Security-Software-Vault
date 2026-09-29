import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Visual identity for the Secure Officer Vault console.
///
/// The palette draws on the Nepali Army's identity: crimson (the national colour
/// of Nepal) as the primary accent, a deep forest/olive green for structure, and
/// a muted khaki/gold for highlights. The console is dark-first — appropriate for
/// an operations tool used in low light and long shifts — with a matching light
/// theme for daytime field use.
class AppColors {
  // Nepal crimson — primary brand accent.
  static const crimson = Color(0xFFA6192E);
  static const crimsonBright = Color(0xFFC8283C);
  static const crimsonDeep = Color(0xFF7A0F20);

  // Military green — structure and secondary actions.
  static const olive = Color(0xFF3B4A2F);
  static const forest = Color(0xFF2A3521);

  // Khaki / brass — highlights, chips, subtle accents.
  static const khaki = Color(0xFFB9A66B);
  static const brass = Color(0xFFCBAE5E);

  // Dark surfaces.
  static const bgDark = Color(0xFF12140F);
  static const surfaceDark = Color(0xFF1B1E17);
  static const surfaceDarkAlt = Color(0xFF232720);
  static const outlineDark = Color(0xFF3A3E33);

  // Light surfaces.
  static const bgLight = Color(0xFFF3F2EC);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceLightAlt = Color(0xFFEAE8DD);
  static const outlineLight = Color(0xFFCDCABA);

  // Status colours (severity / device state).
  static const success = Color(0xFF4C8C4A);
  static const warning = Color(0xFFD9A227);
  static const danger = Color(0xFFC8283C);
  static const info = Color(0xFF4A7BB0);
  static const neutral = Color(0xFF8A8D80);
}

class AppTheme {
  static ThemeData dark() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.crimsonBright,
      onPrimary: Colors.white,
      secondary: AppColors.khaki,
      onSecondary: Color(0xFF1B1E17),
      tertiary: AppColors.olive,
      onTertiary: Colors.white,
      error: AppColors.danger,
      onError: Colors.white,
      surface: AppColors.surfaceDark,
      onSurface: Color(0xFFE7E6DD),
      surfaceContainerHighest: AppColors.surfaceDarkAlt,
      outline: AppColors.outlineDark,
    );
    return _base(scheme, AppColors.bgDark);
  }

  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.crimson,
      onPrimary: Colors.white,
      secondary: AppColors.brass,
      onSecondary: Color(0xFF1B1E17),
      tertiary: AppColors.olive,
      onTertiary: Colors.white,
      error: AppColors.danger,
      onError: Colors.white,
      surface: AppColors.surfaceLight,
      onSurface: Color(0xFF1C1D18),
      surfaceContainerHighest: AppColors.surfaceLightAlt,
      outline: AppColors.outlineLight,
    );
    return _base(scheme, AppColors.bgLight);
  }

  static ThemeData _base(ColorScheme scheme, Color bg) {
    final isDark = scheme.brightness == Brightness.dark;
    final textTheme = GoogleFonts.interTextTheme(
      isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      textTheme: textTheme.copyWith(
        titleLarge: GoogleFonts.robotoSlab(
          textStyle: textTheme.titleLarge,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: GoogleFonts.robotoSlab(
          textStyle: textTheme.titleMedium,
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColors.forest : AppColors.olive,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.robotoSlab(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.4)),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        side: BorderSide(color: scheme.outline.withValues(alpha: 0.5)),
        labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outline.withValues(alpha: 0.4),
        thickness: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        indicatorColor: scheme.primary.withValues(alpha: 0.18),
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
