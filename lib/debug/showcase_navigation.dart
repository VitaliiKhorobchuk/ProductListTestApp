import 'package:flutter/material.dart';

import '../app/catalog_navigation.dart';
import '../app/widgets/theme_toggle_button.dart';

abstract final class ShowcaseNavigation {
  static const path = '/debug/components';
  static const indexRoute = 'debug-components';
  static const detailRoute = 'debug-component';
  static const componentIdParameter = 'componentId';
  static const detailPath = ':$componentIdParameter';
}

class ShowcaseAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ShowcaseAppBar({super.key, required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      leading: BackButton(
        onPressed: () {
          CatalogNavigation.backToCatalog(context);
        },
      ),
      actions: const [ThemeToggleButton()],
    );
  }
}
