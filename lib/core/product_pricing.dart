/// USD price rules shared by parsing, models and product presentation.
abstract final class ProductPricing {
  static const _percent = 100.0;
  static const _decimalPlaces = 2;
  static const unavailable = 'Price unavailable';

  static bool isValidPrice(double? value) =>
      value != null && value.isFinite && value >= 0;
  static bool isValidDiscount(double? value) =>
      value != null && value.isFinite && value >= 0 && value <= _percent;
  static double? discountedPrice(double? original, double discount) {
    if (!isValidPrice(original)) return null;
    final effectiveDiscount = isValidDiscount(discount) ? discount : 0;
    return original! * (1 - effectiveDiscount / _percent);
  }

  static bool hasDiscount(double? current, double? original) =>
      isValidPrice(current) && isValidPrice(original) && original! > current!;
  static int? discountPercent(double? current, double? original) {
    if (!hasDiscount(current, original)) return null;
    final percent = ((1 - current! / original!) * _percent).round();
    return percent > 0 ? percent : null;
  }

  static String amount(double value) =>
      '\$${value.toStringAsFixed(_decimalPlaces)}';
  static String display(double? value) =>
      isValidPrice(value) ? '${amount(value!)} USD' : unavailable;
  static String semanticPrice(double? value) => isValidPrice(value)
      ? 'Price ${value!.toStringAsFixed(_decimalPlaces)} US dollars'
      : unavailable;
  static String semanticOriginal(double value) =>
      'Original price ${value.toStringAsFixed(_decimalPlaces)} US dollars';
}
