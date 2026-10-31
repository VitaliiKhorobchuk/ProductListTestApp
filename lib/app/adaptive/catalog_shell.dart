import 'package:flutter/material.dart';

import '../../features/catalog/presentation/screens/catalog_screen.dart';
import 'catalog_layout.dart';
import 'catalog_layout_scope.dart';

/// Keeps the catalog and the child Navigator in fixed element-tree positions.
class CatalogShell extends StatefulWidget {
  const CatalogShell({
    super.key,
    required this.detailActive,
    required this.selectedProductId,
    required this.child,
  });

  final bool detailActive;
  final int? selectedProductId;
  final Widget child;

  @override
  State<CatalogShell> createState() => _CatalogShellState();
}

class _CatalogShellState extends State<CatalogShell> {
  double? _lastVisibleCatalogWidth;

  @override
  Widget build(BuildContext context) {
    final routeIsCurrent = ModalRoute.of(context)?.isCurrent ?? true;
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSplit = CatalogLayout.isSplit(constraints.maxWidth);
            final info = CatalogLayoutInfo(
              isSplit: isSplit,
              detailActive: widget.detailActive,
              selectedProductId: widget.selectedProductId,
              routeIsCurrent: routeIsCurrent,
            );
            final catalogWidth = isSplit
                ? CatalogLayout.catalogWidth
                : constraints.maxWidth;
            if (info.catalogVisible || _lastVisibleCatalogWidth == null) {
              _lastVisibleCatalogWidth = catalogWidth;
            }
            return CatalogLayoutScope(
              info: info,
              child: CustomMultiChildLayout(
                delegate: _PaneLayout(
                  isSplit: isSplit,
                  catalogWidth: info.catalogVisible
                      ? catalogWidth
                      : _lastVisibleCatalogWidth!,
                ),
                children: [
                  LayoutId(
                    id: _Pane.catalog,
                    child: _PaneVisibility(
                      visible: info.catalogVisible,
                      child: const CatalogScreen(),
                    ),
                  ),
                  LayoutId(
                    id: _Pane.divider,
                    child: ColoredBox(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  LayoutId(
                    id: _Pane.detail,
                    child: _PaneVisibility(
                      visible: info.detailVisible,
                      child: widget.child,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PaneVisibility extends StatelessWidget {
  const _PaneVisibility({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) => Offstage(
    offstage: !visible,
    child: ExcludeFocus(
      excluding: !visible,
      child: ExcludeSemantics(
        excluding: !visible,
        child: TickerMode(enabled: visible, child: child),
      ),
    ),
  );
}

enum _Pane { catalog, divider, detail }

class _PaneLayout extends MultiChildLayoutDelegate {
  _PaneLayout({required this.isSplit, required this.catalogWidth});

  final bool isSplit;
  final double catalogWidth;

  @override
  void performLayout(Size size) {
    final dividerWidth = isSplit ? CatalogLayout.dividerWidth : 0.0;
    final detailLeft = isSplit
        ? CatalogLayout.catalogWidth + dividerWidth
        : 0.0;
    layoutChild(
      _Pane.catalog,
      BoxConstraints.tight(Size(catalogWidth, size.height)),
    );
    positionChild(_Pane.catalog, Offset.zero);
    layoutChild(
      _Pane.divider,
      BoxConstraints.tight(Size(dividerWidth, size.height)),
    );
    positionChild(_Pane.divider, Offset(CatalogLayout.catalogWidth, 0));
    layoutChild(
      _Pane.detail,
      BoxConstraints.tight(Size(size.width - detailLeft, size.height)),
    );
    positionChild(_Pane.detail, Offset(detailLeft, 0));
  }

  @override
  bool shouldRelayout(_PaneLayout oldDelegate) =>
      isSplit != oldDelegate.isSplit ||
      catalogWidth != oldDelegate.catalogWidth;
}
