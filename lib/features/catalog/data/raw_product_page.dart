import '../models/product.dart';

/// A validated server page before local title/category filtering or deduplication.
///
/// [rawCount] includes rejected product records. Consequently [nextSkip] advances
/// through the server data rather than the smaller list of usable [products].
/// [total] is the server total, not a count of visible products.
///
/// [ProductParser] validates metadata and cursor safety before constructing this
/// value. A repository can combine several raw pages into a domain ProductPage.
class RawProductPage {
  RawProductPage({
    required List<Product> products,
    required this.rawCount,
    required this.skip,
    required this.limit,
    required this.total,
  }) : products = List.unmodifiable(products);

  final List<Product> products;
  final int rawCount;
  final int skip;
  final int limit;
  final int total;

  int get nextSkip => skip + rawCount;
  bool get hasMore => nextSkip < total;
}
