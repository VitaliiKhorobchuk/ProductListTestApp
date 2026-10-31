import '../../../core/catalog_failure.dart';
import '../../../core/safe_integer.dart';

/// Enforces the detail lookup contract shared by repository implementations.
///
/// Run after caller-cancellation checks and before HTTP, fixture access or delay.
void validateProductId(int id) {
  if (!SafeInteger.isInRange(id, minimum: 1)) {
    throw const CatalogFailure(
      CatalogFailureKind.invalidData,
      'This product link has an invalid product ID.',
    );
  }
}
