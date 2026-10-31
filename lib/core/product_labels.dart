/// Shared fallback text and display normalization for product fields.
abstract final class ProductLabels {
  static const untitledProduct = 'Untitled product';
  static const unknownCategory = 'Unknown category';
  static const unknownBrand = 'Unknown brand';
  static const missingDescription = 'No description available.';

  static String title(String value) => _text(value, untitledProduct);
  static String category(String value) =>
      _text(value, unknownCategory).replaceAll('-', ' ');
  static String brand(String? value) => optionalBrand(value) ?? unknownBrand;
  static String description(String value) => _text(value, missingDescription);
  static String? optionalBrand(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? null : text;
  }

  static String _text(String value, String fallback) =>
      value.trim().isEmpty ? fallback : value.trim();
}
