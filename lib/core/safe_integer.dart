/// Integer bounds shared by native Dart and JavaScript clients.
abstract final class SafeInteger {
  static const maximum = 9007199254740991;

  static bool isInRange(int value, {int minimum = 0}) =>
      value >= minimum && value <= maximum;

  /// Accepts integral JSON numbers without coercing strings or fractions.
  static int? parse(Object? value, {int minimum = 0}) {
    if (value is! num ||
        !value.isFinite ||
        value < minimum ||
        value > maximum ||
        value != value.truncateToDouble()) {
      return null;
    }
    return value.toInt();
  }

  /// Programmer-input validation; domain failures remain caller-owned.
  static void require(int value, String name, {required int minimum}) {
    if (!isInRange(value, minimum: minimum)) {
      throw ArgumentError.value(
        value,
        name,
        'Must be a safe integer between $minimum and $maximum.',
      );
    }
  }
}
