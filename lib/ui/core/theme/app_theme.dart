import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const _seed = Color(0xFF2F5FDB);
  static const _bodyFontFamily = 'Inter';
  static const _headingFontFamily = 'Instrument Serif';

  static ThemeData get light => _themeFrom(Brightness.light);

  static ThemeData get dark => _themeFrom(Brightness.dark);

  static ThemeData _themeFrom(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    ).copyWith(
      onSurface: isDark ? const Color(0xFFEDEDED) : const Color(0xFF333333),
      onSurfaceVariant: isDark
          ? const Color(0xFF9A9A9A)
          : const Color(0xFF777777),
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: _bodyFontFamily,
    );

    const buttonTextStyle = TextStyle(
      fontFamily: _bodyFontFamily,
      fontWeight: FontWeight.w600,
      fontSize: 15,
      height: 20 / 15,
    );
    const compactButtonTextStyle = TextStyle(
      fontFamily: _bodyFontFamily,
      fontWeight: FontWeight.w600,
      fontSize: 14,
      height: 18 / 14,
    );

    return base.copyWith(
      textTheme: _textThemeFrom(base.textTheme),
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: _headingFontFamily,
          fontSize: 28,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.3,
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLow,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? const Color(0xFF0077E6)
              : colorScheme.surfaceContainerHighest,
        ),
        thumbColor: const WidgetStatePropertyAll(Colors.white),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          textStyle: buttonTextStyle,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          side: BorderSide(color: colorScheme.outlineVariant, width: 1.4),
          textStyle: buttonTextStyle,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size(56, 40),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          textStyle: compactButtonTextStyle,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  static TextTheme _textThemeFrom(TextTheme base) {
    TextStyle? heading(TextStyle? style, {required double size}) {
      return style?.copyWith(
        fontFamily: _headingFontFamily,
        fontWeight: FontWeight.w400,
        fontSize: size,
        letterSpacing: -0.3,
        height: 1.15,
      );
    }

    TextStyle? label(
      TextStyle? style, {
      required double size,
      required double lineHeight,
    }) {
      return style?.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: size,
        height: lineHeight / size,
      );
    }

    TextStyle? body(
      TextStyle? style, {
      double size = 14,
      double lineHeight = 20,
    }) {
      return style?.copyWith(
        fontWeight: FontWeight.w400,
        fontSize: size,
        height: lineHeight / size,
      );
    }

    return base.copyWith(
      // Page-level titles keep the serif display face.
      displayLarge: heading(base.displayLarge, size: 48),
      displayMedium: heading(base.displayMedium, size: 40),
      displaySmall: heading(base.displaySmall, size: 32),
      headlineLarge: heading(base.headlineLarge, size: 30),
      headlineMedium: heading(base.headlineMedium, size: 26),
      headlineSmall: heading(base.headlineSmall, size: 24),
      titleLarge: heading(base.titleLarge, size: 22),
      // In-content row/card titles and labels follow the Inter cheatsheet.
      titleMedium: label(base.titleMedium, size: 16, lineHeight: 20),
      titleSmall: label(base.titleSmall, size: 13, lineHeight: 16),
      labelLarge: label(base.labelLarge, size: 13, lineHeight: 16),
      labelMedium: label(base.labelMedium, size: 12, lineHeight: 16),
      labelSmall: label(base.labelSmall, size: 11, lineHeight: 14),
      bodyLarge: body(base.bodyLarge),
      bodyMedium: body(base.bodyMedium),
      bodySmall: body(base.bodySmall, size: 12, lineHeight: 16),
    );
  }
}
