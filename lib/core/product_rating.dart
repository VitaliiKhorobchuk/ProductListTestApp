/// API and component rating rules; unknown values stay distinct from zero.
abstract final class ProductRating {
  static const maximum = 5.0;
  static const goodThreshold = 4.0;
  static const averageThreshold = 3.0;

  static bool isValid(double? value) =>
      value != null && value.isFinite && value >= 0 && value <= maximum;
}
