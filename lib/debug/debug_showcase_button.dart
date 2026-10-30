import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'showcase_navigation.dart';

class DebugShowcaseButton extends StatelessWidget {
  const DebugShowcaseButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Open component showcase',
    icon: const Icon(Icons.widgets_outlined),
    onPressed: () => context.pushNamed(ShowcaseNavigation.indexRoute),
  );
}
