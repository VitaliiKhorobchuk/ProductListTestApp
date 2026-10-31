import '../../../core/catalog_failure.dart';

const _maximumSafeProductId = 9007199254740991;

/// Enforces the detail lookup contract shared by repository implementations.
///
/// Run after caller-cancellation checks and before HTTP, fixture access or delay.
void validateProductId(int id) {
  if (id <= 0 || id > _maximumSafeProductId) {
    throw const CatalogFailure(
      CatalogFailureKind.invalidData,
      'This product link has an invalid product ID.',
    );
  }
}
