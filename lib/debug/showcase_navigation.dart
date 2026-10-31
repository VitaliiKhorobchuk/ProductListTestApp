import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../app/theme/theme_cubit.dart';
import '../app/catalog_navigation.dart';

abstract final class ShowcaseNavigation {
  static const path = '/debug/components';
  static const indexRoute = 'debug-components';
  static const detailRoute = 'debug-component';
}

class ShowcaseAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ShowcaseAppBar({super.key, required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppBar(
      title: Text(title),
      leading: BackButton(
        onPressed: () {
          CatalogNavigation.backToCatalog(context);
        },
      ),
      actions: [
        IconButton(
          tooltip: isDark ? 'Switch to light theme' : 'Switch to dark theme',
          onPressed: () => context.read<ThemeCubit>().toggle(
            systemBrightness: MediaQuery.platformBrightnessOf(context),
          ),
          icon: Icon(
            isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          ),
        ),
      ],
    );
  }
}
