import 'package:flutter/material.dart';

class ShowcaseExample {
  const ShowcaseExample({
    required this.title,
    required this.description,
    required this.builder,
    this.height,
  });

  final String title;
  final String description;
  final WidgetBuilder builder;
  final double? height;
}

class ShowcaseComponent {
  const ShowcaseComponent({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.examples,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final List<ShowcaseExample> examples;
}

enum ShowcaseWidth {
  available('Available width', null),
  narrow('Narrow · 160px', 160),
  phone('Phone · 320px', 320),
  wide('Wide · 600px', 600);

  const ShowcaseWidth(this.label, this.width);
  final String label;
  final double? width;
}

enum ShowcaseTextSize {
  system('System text', null),
  normal('100% text', 1),
  large('150% text', 1.5),
  extraLarge('200% text', 2);

  const ShowcaseTextSize(this.label, this.scale);
  final String label;
  final double? scale;
}
