import 'package:flutter/widgets.dart';

/// Route-derived presentation data, shared by pane chrome and catalog behavior.
class CatalogLayoutInfo {
  const CatalogLayoutInfo({
    this.isSplit = false,
    this.detailActive = false,
    this.selectedProductId,
    this.routeIsCurrent = true,
  });

  final bool isSplit;
  final bool detailActive;
  final int? selectedProductId;
  final bool routeIsCurrent;

  bool get catalogVisible => routeIsCurrent && (isSplit || !detailActive);
  bool get detailVisible => routeIsCurrent && (isSplit || detailActive);
}

class CatalogLayoutScope extends InheritedWidget {
  const CatalogLayoutScope({
    super.key,
    required this.info,
    required super.child,
  });

  final CatalogLayoutInfo info;

  static CatalogLayoutInfo of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CatalogLayoutScope>()?.info ??
      const CatalogLayoutInfo();

  @override
  bool updateShouldNotify(CatalogLayoutScope oldWidget) =>
      info.isSplit != oldWidget.info.isSplit ||
      info.detailActive != oldWidget.info.detailActive ||
      info.selectedProductId != oldWidget.info.selectedProductId ||
      info.routeIsCurrent != oldWidget.info.routeIsCurrent;
}
