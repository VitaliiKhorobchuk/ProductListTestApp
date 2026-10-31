import '../../../core/product_labels.dart';
import '../models/product.dart';

/// Presentation policy for cards/details, independent of Flutter and transport.
extension ProductPresentation on Product {
  String get displayTitle => ProductLabels.title(title);
  String get displayBrand => ProductLabels.brand(brand);
  String get displayCategory => ProductLabels.category(category);
  String get displayDescription => ProductLabels.description(description);

  /// Product owns canonical image order/deduplication; presentation only chooses
  /// a thumbnail fallback. ProductImage owns source/failure handling.
  List<String> get galleryImages {
    if (images.isNotEmpty) return images;
    final fallback = thumbnail?.trim();
    return fallback == null || fallback.isEmpty
        ? const []
        : List.unmodifiable([fallback]);
  }
}
