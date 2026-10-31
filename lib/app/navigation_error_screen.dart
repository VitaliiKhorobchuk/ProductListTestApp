import 'package:flutter/material.dart';

import '../design_system/components/error_state.dart';
import 'catalog_navigation.dart';

/// Friendly recovery for malformed product links and unrecognized routes.
class NavigationErrorScreen extends StatelessWidget {
  const NavigationErrorScreen({
    super.key,
    this.title = 'Page not found',
    this.message = 'This link does not point to an available page.',
  });
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      leading: BackButton(
        onPressed: () => CatalogNavigation.backToCatalog(context),
      ),
    ),
    body: SafeArea(
      child: ErrorState(
        title: title,
        message: message,
        actionLabel: 'Browse products',
        onAction: () => CatalogNavigation.browseProducts(context),
      ),
    ),
  );
}
