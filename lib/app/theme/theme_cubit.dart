import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart' show Brightness, ThemeMode;

/// Owns the app's appearance preference for the current session.
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.system);

  void setMode(ThemeMode mode) => emit(mode);

  /// Resolve system mode at the time of the action, then select its opposite.
  void toggle({required Brightness systemBrightness}) {
    final isDark =
        state == ThemeMode.dark ||
        (state == ThemeMode.system && systemBrightness == Brightness.dark);
    setMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }
}
