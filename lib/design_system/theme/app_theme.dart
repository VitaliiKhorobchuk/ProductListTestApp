import 'package:flutter/material.dart';

import 'app_tokens.dart';

abstract final class AppTheme {
  static final ThemeData light = _build(AppTokens.light, Brightness.light);
  static final ThemeData dark = _build(AppTokens.dark, Brightness.dark);

  static ThemeData _build(AppTokens tokens, Brightness brightness) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: tokens.primary,
          brightness: brightness,
        ).copyWith(
          primary: tokens.primary,
          // White text on the specified dark-blue accent is too low in contrast.
          onPrimary: tokens.onAccent,
          surface: tokens.surface,
          onSurface: tokens.onSurface,
          onSurfaceVariant: tokens.onSurface,
          surfaceContainerLowest: tokens.surface,
          surfaceContainerLow: tokens.surfaceVariant,
          surfaceContainer: tokens.surfaceVariant,
          surfaceContainerHigh: tokens.surfaceVariant,
          surfaceContainerHighest: tokens.surfaceVariant,
          outline: tokens.onSurfaceDim,
          outlineVariant: tokens.border,
          error: tokens.ratingPoor,
          onError: tokens.onAccent,
        );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: tokens.surface,
    );
    final rounded = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(tokens.radius),
    );
    return base.copyWith(
      extensions: [tokens],
      textTheme: base.textTheme
          .apply(bodyColor: tokens.onSurface, displayColor: tokens.onSurface)
          .copyWith(
            bodySmall: base.textTheme.bodySmall?.copyWith(
              color: tokens.onSurfaceDim,
            ),
          ),
      appBarTheme: AppBarThemeData(
        backgroundColor: tokens.surface,
        foregroundColor: tokens.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          color: tokens.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: tokens.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: rounded.copyWith(
          side: BorderSide(color: tokens.border, width: tokens.borderWidth),
        ),
      ),
      iconTheme: IconThemeData(color: tokens.onSurfaceDim),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: tokens.onSurface,
          focusColor: tokens.focusOverlay,
          hoverColor: tokens.hoverOverlay,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: tokens.border,
        thickness: tokens.borderWidth,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: tokens.primary),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: tokens.primary,
          foregroundColor: scheme.onPrimary,
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spaceXl,
            vertical: tokens.spaceMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.smallRadius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        // Use the strong foreground instead of small blue text in dark mode.
        style: TextButton.styleFrom(foregroundColor: tokens.onSurface),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: tokens.surface,
        contentPadding: EdgeInsets.symmetric(
          horizontal: tokens.spaceLg,
          vertical: tokens.spaceMd,
        ),
        hintStyle: TextStyle(color: tokens.onSurfaceDim),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radius),
          borderSide: BorderSide(
            color: tokens.onSurfaceDim,
            width: tokens.borderWidth,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radius),
          borderSide: BorderSide(
            color: tokens.onSurfaceDim,
            width: tokens.borderWidth,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radius),
          borderSide: BorderSide(
            color: tokens.primary,
            width: tokens.emphasizedBorderWidth,
          ),
        ),
      ),
      focusColor: tokens.focusOverlay,
      hoverColor: tokens.hoverOverlay,
    );
  }
}
