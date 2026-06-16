import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared design system -- identical palette to main Embre app.
/// Merriweather headers + Lato body. Material 3, rounded components.
class AppTheme {
  // Palette -- light
  static const espresso    = Color(0xFF4A3F35);
  static const softIvory   = Color(0xFFF5F2EB);
  static const lightBeige  = Color(0xFFE8E4D9);
  static const mutedCopper = Color(0xFFC17F59);
  static const charcoal    = Color(0xFF2E2E2E);

  // Palette -- dark
  static const deepCoffee  = Color(0xFF1E1B18);
  static const darkWalnut  = Color(0xFF2A2622);
  static const softTaupe   = Color(0xFFB8B2A7);

  static ThemeData light() => _build(_lightScheme());
  static ThemeData dark()  => _build(_darkScheme());

  // ---------------------------------------------------------------------------

  static ColorScheme _lightScheme() => const ColorScheme(
    brightness:              Brightness.light,
    primary:                 espresso,
    onPrimary:               softIvory,
    secondary:               mutedCopper,
    onSecondary:             softIvory,
    tertiary:                Color(0xFF4F4B45),
    onTertiary:              espresso,
    error:                   Color(0xFFB00020),
    onError:                 Colors.white,
    surface:                 softIvory,
    onSurface:               charcoal,
    surfaceContainerHighest: Color(0xFFEDEAE2),
    onSurfaceVariant:        Color(0xFF4F4B45),
    outline:                 Color(0xFFBDB5AA),
    shadow:                  Color(0x331E1B18),
    inverseSurface:          espresso,
    onInverseSurface:        softIvory,
    inversePrimary:          mutedCopper,
    scrim:                   Color(0x66000000),
  );

  static ColorScheme _darkScheme() => const ColorScheme(
    brightness:              Brightness.dark,
    primary:                 mutedCopper,
    onPrimary:               deepCoffee,
    secondary:               espresso,
    onSecondary:             lightBeige,
    tertiary:                lightBeige,
    onTertiary:              deepCoffee,
    error:                   Color(0xFFCF6679),
    onError:                 deepCoffee,
    surface:                 darkWalnut,
    onSurface:               lightBeige,
    surfaceContainerHighest: Color(0xFF3A362F),
    onSurfaceVariant:        softTaupe,
    outline:                 Color(0xFF6D6961),
    shadow:                  Color(0x33000000),
    inverseSurface:          lightBeige,
    onInverseSurface:        espresso,
    inversePrimary:          espresso,
    scrim:                   Color(0x99000000),
  );

  static ThemeData _build(ColorScheme s) {
    final isDark   = s.brightness == Brightness.dark;
    final baseText = GoogleFonts.latoTextTheme(const TextTheme());

    TextStyle serif(double size, FontWeight w) =>
        GoogleFonts.merriweather(fontSize: size, fontWeight: w,
            color: s.onSurface, height: 1.3);

    final text = baseText.copyWith(
      displayLarge:   serif(28, FontWeight.w700),
      displayMedium:  serif(24, FontWeight.w700),
      displaySmall:   serif(20, FontWeight.w600),
      headlineLarge:  serif(28, FontWeight.w700),
      headlineMedium: serif(24, FontWeight.w700),
      headlineSmall:  serif(20, FontWeight.w600),
      titleLarge:     serif(18, FontWeight.w600),
      titleMedium:  GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w600,
          height: 1.4, color: s.onSurface),
      titleSmall:   GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w600,
          height: 1.4, color: s.onSurface),
      bodyLarge:    GoogleFonts.lato(fontSize: 16,
          height: isDark ? 1.7 : 1.6, color: s.onSurface),
      bodyMedium:   GoogleFonts.lato(fontSize: 14,
          height: isDark ? 1.7 : 1.6, color: s.onSurface),
      bodySmall:    GoogleFonts.lato(fontSize: 12,
          height: isDark ? 1.6 : 1.5, color: s.onSurfaceVariant),
      labelLarge:   GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w600,
          color: s.primary),
      labelMedium:  GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.w600,
          color: s.onSurfaceVariant),
      labelSmall:   GoogleFonts.lato(fontSize: 11, fontWeight: FontWeight.w500,
          color: s.onSurfaceVariant),
    );

    return ThemeData(
      useMaterial3:            true,
      colorScheme:             s,
      scaffoldBackgroundColor: s.surface,
      textTheme:               text,

      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? Colors.transparent : s.surface,
        foregroundColor: s.onSurface,
        elevation:       0,
        centerTitle:     false,
        titleTextStyle:  text.titleLarge,
        iconTheme:       IconThemeData(color: s.onSurface),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: s.surface,
        indicatorColor:  s.primary.withOpacity(isDark ? 0.20 : 0.15),
        labelTextStyle:  WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
            ? GoogleFonts.lato(color: s.primary, fontWeight: FontWeight.w600)
            : GoogleFonts.lato(color: s.onSurfaceVariant),
        ),
      ),

      cardTheme: CardThemeData(
        color:            s.surface,
        shadowColor:      isDark ? Colors.transparent : s.shadow,
        elevation:        isDark ? 0 : 2,
        margin:           const EdgeInsets.all(12),
        surfaceTintColor: isDark ? Colors.transparent : s.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),

      dividerTheme: DividerThemeData(
        color:     isDark ? s.outline : s.outline.withOpacity(0.5),
        thickness: 1,
      ),

      listTileTheme: ListTileThemeData(
        contentPadding:   const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        titleTextStyle:   text.titleMedium,
        subtitleTextStyle: text.bodySmall,
        iconColor:        s.onSurfaceVariant,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: s.secondary,
          foregroundColor: s.onSecondary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape:   RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation:  0,
          textStyle:  text.labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: s.primary,
          textStyle:       text.labelLarge,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled:     true,
        fillColor:  s.surface,
        labelStyle: text.bodyMedium?.copyWith(color: s.onSurfaceVariant),
        hintStyle:  text.bodyMedium?.copyWith(color: s.onSurfaceVariant),
        enabledBorder: OutlineInputBorder(
          borderSide:   BorderSide(color: s.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide:   BorderSide(color: s.primary, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: s.surfaceContainerHighest,
        labelStyle:      text.labelMedium!,
        selectedColor:   s.secondary.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}