import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const _seed = Color(0xFF0E7C66);
  static const _bodyFontFamily = 'Inter';
  static const _headingFontFamily = 'Manrope';

  static ThemeData get light => _themeFrom(Brightness.light);

  static ThemeData get dark => _themeFrom(Brightness.dark);

  static ThemeData _themeFrom(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: _bodyFontFamily,
    );

    return base.copyWith(
      textTheme: _headingsIn(base.textTheme),
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: _headingFontFamily,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLow,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  static TextTheme _headingsIn(TextTheme base) {
    TextStyle? heading(TextStyle? style, FontWeight weight) {
      return style?.copyWith(
        fontFamily: _headingFontFamily,
        fontWeight: weight,
      );
    }

    return base.copyWith(
      displayLarge: heading(base.displayLarge, FontWeight.w800),
      displayMedium: heading(base.displayMedium, FontWeight.w800),
      displaySmall: heading(base.displaySmall, FontWeight.w700),
      headlineLarge: heading(base.headlineLarge, FontWeight.w700),
      headlineMedium: heading(base.headlineMedium, FontWeight.w700),
      headlineSmall: heading(base.headlineSmall, FontWeight.w700),
      titleLarge: heading(base.titleLarge, FontWeight.w600),
      titleMedium: heading(base.titleMedium, FontWeight.w600),
      titleSmall: heading(base.titleSmall, FontWeight.w600),
    );
  }
}
