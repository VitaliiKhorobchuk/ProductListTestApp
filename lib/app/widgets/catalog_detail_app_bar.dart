import 'package:flutter/material.dart';

import '../adaptive/catalog_layout_scope.dart';

/// Gives detail, recovery, and prompt panes the same adaptive navigation chrome.
class CatalogDetailAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const CatalogDetailAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.onClearSelection,
  });

  final String title;
  final VoidCallback? onBack;
  final VoidCallback? onClearSelection;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isSplit = CatalogLayoutScope.of(context).isSplit;
    return AppBar(
      automaticallyImplyLeading: false,
      leading: !isSplit && onBack != null
          ? IconButton(
              tooltip: 'Back to products',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
            )
          : null,
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      actions: [
        if (isSplit && onClearSelection != null)
          IconButton(
            tooltip: 'Clear selection',
            onPressed: onClearSelection,
            icon: const Icon(Icons.close),
          ),
      ],
    );
  }
}
