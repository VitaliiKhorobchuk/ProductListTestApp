import 'package:flutter/material.dart';
import 'package:product_list_test_app/design_system/theme/app_theme.dart';

/// Supplies the real application theme tokens without routes or repositories.
Widget componentTestApp(
  Widget child, {
  ThemeMode themeMode = ThemeMode.light,
}) => MaterialApp(
  theme: AppTheme.light,
  darkTheme: AppTheme.dark,
  themeMode: themeMode,
  home: Scaffold(body: Center(child: child)),
);
