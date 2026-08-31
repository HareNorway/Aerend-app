import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class ScSaasThemeTokens {
  // ── Brand purple ramp ──────────────────────────────────────────────
  static const Color primary = Color(0xFF7F5FC4);        // --ae-purple-600
  static const Color primaryDarkMode = Color(0xFF9B83C6);
  static const Color primarySoft = Color(0xFF9B7FD4);    // --ae-purple-500
  static const Color primaryHover = Color(0xFF6B4FA8);   // --ae-purple-700
  static const Color primaryDisabled = Color(0xFFB8A2E2);// --ae-purple-400
  static const Color primaryTint = Color(0xFFE8DEF5);    // --ae-purple-100

  // ── Semantic / status ──────────────────────────────────────────────
  static const Color accent = Color(0xFF6CC985);         // --ae-acid
  static const Color accentSoft = Color(0xFFE8F8F2);
  static const Color danger = Color(0xFFDC4040);         // --ae-error
  static const Color dangerSoft = Color(0xFFFDEDED);
  static const Color success = Color(0xFF22A769);        // --ae-success
  static const Color warning = Color(0xFFC98A1A);        // --ae-warning

  // ── Surfaces ───────────────────────────────────────────────────────
  static const Color background = Color(0xFFF4F0FB);     // --ae-lavender
  static const Color backgroundLavender = Color(0xFFF4F0FB);
  static const Color card = Color(0xFFFFFFFF);

  // ── Text ───────────────────────────────────────────────────────────
  static const Color text = Color(0xFF2D1B5B);           // --ae-midnight
  static const Color ink = Color(0xFF0F1620);            // --ae-ink (body text)
  static const Color muted = Color(0xFF6B4FA8);          // --ae-purple-700

  // ── Neutrals ───────────────────────────────────────────────────────
  static const Color gray50 = Color(0xFFF8F9FA);         // --ae-gray-50
  static const Color gray100 = Color(0xFFEFF1F4);        // --ae-gray-100
  static const Color gray300 = Color(0xFFCFD1D7);        // --ae-gray-300
  static const Color gray400 = Color(0xFF9890A8);        // --ae-gray-400
  static const Color gray500 = Color(0xFF8F8AA3);        // --ae-gray-500 (rendered Dugnad value)
  static const Color gray600 = Color(0xFF4B4458);        // --ae-gray-600 (body/description text)
  static const Color gray700 = Color(0xFF555660);        // --ae-gray-700
  static const Color border = Color(0xFFEFF1F4);         // --ae-gray-100
  static const Color rowHover = Color(0xFFF4F2FA);

  /// Matches design token `--ae-midnight` (e.g. Sign in with Apple).
  static const Color midnightButton = Color(0xFF2D1B5B);
  static const Color secondaryButton = midnightButton;

  // ── Shadows (constants only — applied in later component chunks) ──
  // --ae-shadow-card: hairline ring + two soft layers.
  static const List<BoxShadow> shadowCard = [
    BoxShadow(color: Color(0x0D2D1B5B), spreadRadius: 1),
    BoxShadow(color: Color(0x0F2D1B5B), blurRadius: 5, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x1F2D1B5B), blurRadius: 22, offset: Offset(0, 10), spreadRadius: -8),
  ];
  static const List<BoxShadow> shadowButton = [
    BoxShadow(color: Color(0x142D1B5B), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x667F5FC4), blurRadius: 18, offset: Offset(0, 6), spreadRadius: -8),
  ];
  static const List<BoxShadow> shadowDeep = [
    BoxShadow(color: Color(0x332D1B5B), blurRadius: 64, offset: Offset(0, 24), spreadRadius: -16),
  ];

  // ── Font families ─────────────────────────────────────────────────
  static String get fontFamily =>
      GoogleFonts.plusJakartaSans().fontFamily ?? 'Plus Jakarta Sans';

  static String get fontFamilyMono =>
      GoogleFonts.jetBrainsMono().fontFamily ?? 'JetBrains Mono';
}

class ScSaasTheme {
  static ThemeData light() {
    final ThemeData base = ThemeData.light();
    final ColorScheme scheme = base.colorScheme.copyWith(
      primary: ScSaasThemeTokens.primary,
      secondary: ScSaasThemeTokens.primary,
      surface: ScSaasThemeTokens.card,
      onSurface: ScSaasThemeTokens.text,
    );

    return base.copyWith(
      primaryColor: ScSaasThemeTokens.primary,
      colorScheme: scheme,
      unselectedWidgetColor: ScSaasThemeTokens.primary,
      scaffoldBackgroundColor: ScSaasThemeTokens.background,
      cardColor: ScSaasThemeTokens.card,
      dividerColor: ScSaasThemeTokens.border,
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
        },
      ),
      cardTheme: const CardThemeData(
        color: ScSaasThemeTokens.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: ScSaasThemeTokens.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: ScSaasThemeTokens.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: ScSaasThemeTokens.primary,
        selectionColor: ScSaasThemeTokens.primary.withValues(alpha: 0.2),
        selectionHandleColor: ScSaasThemeTokens.primary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ScSaasThemeTokens.card,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ScSaasThemeTokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ScSaasThemeTokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ScSaasThemeTokens.primary),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: ScSaasThemeTokens.primary,
        circularTrackColor: ScSaasThemeTokens.rowHover,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ScSaasThemeTokens.text,
        contentTextStyle: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
      ),
      iconTheme: const IconThemeData(
        size: 22,
        color: ScSaasThemeTokens.text,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        titleSpacing: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
        shadowColor: Color(0x00000000),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: ScSaasThemeTokens.text, size: 22),
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
        bodyColor: ScSaasThemeTokens.text,
        displayColor: ScSaasThemeTokens.text,
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: ScSaasThemeTokens.primaryDarkMode,
      fontFamily: ScSaasThemeTokens.fontFamily,
      colorScheme: const ColorScheme.dark(
        primary: ScSaasThemeTokens.primaryDarkMode,
        secondary: ScSaasThemeTokens.primaryDarkMode,
        surface: Color(0xFF121212),
        onPrimary: Color(0xFF121212),
        onSurface: Colors.white,
      ),
      unselectedWidgetColor: Colors.white70,
      scaffoldBackgroundColor: const Color(0xFF0F0F0F),
      cardColor: const Color(0xFF121212),
      dividerColor: const Color(0xFF2A2A2A),
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
        },
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFF121212),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xFF121212),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF121212),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: ScSaasThemeTokens.primaryDarkMode,
        circularTrackColor: Color(0xFF2A2A2A),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        titleSpacing: 0,
        backgroundColor: Color(0xFF0F0F0F),
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: ScSaasThemeTokens.primaryDarkMode,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.dark().textTheme,
      ).apply(bodyColor: Colors.white, displayColor: Colors.white),
    );
  }
}
