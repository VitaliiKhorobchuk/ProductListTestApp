import 'package:flutter/material.dart';

@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.primary,
    required this.onAccent,
    required this.surface,
    required this.surfaceVariant,
    required this.onSurface,
    required this.onSurfaceDim,
    required this.border,
    required this.ratingGood,
    required this.ratingAverage,
    required this.ratingPoor,
    this.radius = 12,
    this.smallRadius = 8,
    this.spacing = 8,
    this.borderWidth = 1,
    this.emphasizedBorderWidth = 2,
  });

  final Color primary;
  final Color onAccent;
  final Color surface;
  final Color surfaceVariant;
  final Color onSurface;
  final Color onSurfaceDim;
  final Color border;
  final Color ratingGood;
  final Color ratingAverage;
  final Color ratingPoor;
  final double radius;
  final double smallRadius;
  final double spacing;
  final double borderWidth;
  final double emphasizedBorderWidth;

  static const _focusOpacity = .18;
  static const _hoverOpacity = .08;

  Color get focusOverlay => primary.withValues(alpha: _focusOpacity);
  Color get hoverOverlay => primary.withValues(alpha: _hoverOpacity);

  double get spaceXs => spacing / 2;
  double get spaceSm => spacing;
  double get spaceMd => spacing * 1.5;
  double get spaceLg => spacing * 2;
  double get spaceXl => spacing * 3;

  static const light = AppTokens(
    primary: Color(0xFF2563EB),
    onAccent: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF1F5F9),
    onSurface: Color(0xFF0F172A),
    onSurfaceDim: Color(0xFF64748B),
    border: Color(0xFFE2E8F0),
    ratingGood: Color(0xFF15803D),
    ratingAverage: Color(0xFFB45309),
    ratingPoor: Color(0xFFB91C1C),
  );

  static const dark = AppTokens(
    primary: Color(0xFF3B82F6),
    onAccent: Color(0xFF0F172A),
    surface: Color(0xFF1E1E2E),
    surfaceVariant: Color(0xFF2A2A3C),
    onSurface: Color(0xFFE2E8F0),
    onSurfaceDim: Color(0xFF94A3B8),
    border: Color(0xFF414155),
    ratingGood: Color(0xFF86EFAC),
    ratingAverage: Color(0xFFFCD34D),
    ratingPoor: Color(0xFFFCA5A5),
  );

  @override
  AppTokens copyWith({
    Color? primary,
    Color? onAccent,
    Color? surface,
    Color? surfaceVariant,
    Color? onSurface,
    Color? onSurfaceDim,
    Color? border,
    Color? ratingGood,
    Color? ratingAverage,
    Color? ratingPoor,
    double? radius,
    double? smallRadius,
    double? spacing,
    double? borderWidth,
    double? emphasizedBorderWidth,
  }) {
    return AppTokens(
      primary: primary ?? this.primary,
      onAccent: onAccent ?? this.onAccent,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      onSurface: onSurface ?? this.onSurface,
      onSurfaceDim: onSurfaceDim ?? this.onSurfaceDim,
      border: border ?? this.border,
      ratingGood: ratingGood ?? this.ratingGood,
      ratingAverage: ratingAverage ?? this.ratingAverage,
      ratingPoor: ratingPoor ?? this.ratingPoor,
      radius: radius ?? this.radius,
      smallRadius: smallRadius ?? this.smallRadius,
      spacing: spacing ?? this.spacing,
      borderWidth: borderWidth ?? this.borderWidth,
      emphasizedBorderWidth:
          emphasizedBorderWidth ?? this.emphasizedBorderWidth,
    );
  }

  @override
  AppTokens lerp(covariant AppTokens? other, double t) {
    if (other == null) return this;
    return AppTokens(
      primary: Color.lerp(primary, other.primary, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      onSurfaceDim: Color.lerp(onSurfaceDim, other.onSurfaceDim, t)!,
      border: Color.lerp(border, other.border, t)!,
      ratingGood: Color.lerp(ratingGood, other.ratingGood, t)!,
      ratingAverage: Color.lerp(ratingAverage, other.ratingAverage, t)!,
      ratingPoor: Color.lerp(ratingPoor, other.ratingPoor, t)!,
      radius: radius + (other.radius - radius) * t,
      smallRadius: smallRadius + (other.smallRadius - smallRadius) * t,
      spacing: spacing + (other.spacing - spacing) * t,
      borderWidth: borderWidth + (other.borderWidth - borderWidth) * t,
      emphasizedBorderWidth:
          emphasizedBorderWidth +
          (other.emphasizedBorderWidth - emphasizedBorderWidth) * t,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppTokens get tokens {
    final tokens = Theme.of(this).extension<AppTokens>();
    assert(
      tokens != null,
      'AppTokens must be registered in the application theme.',
    );
    return tokens!;
  }
}
