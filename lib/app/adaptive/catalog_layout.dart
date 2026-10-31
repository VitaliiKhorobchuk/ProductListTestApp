/// All widths are logical pixels measured after safe-area insets.
abstract final class CatalogLayout {
  static const breakpoint = 768.0;
  static const catalogWidth = 380.0;
  static const dividerWidth = 1.0;

  static bool isSplit(double safeWidth) => safeWidth >= breakpoint;
}
