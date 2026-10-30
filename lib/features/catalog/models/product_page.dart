import 'product.dart';

class ProductPage {
  ProductPage({
    required List<Product> products,
    required this.nextSkip,
    required this.hasMore,
    required this.remoteTotal,
  }) : products = List.unmodifiable(products);

  final List<Product> products;
  final int nextSkip;
  final bool hasMore;

  /// Source records before local title/category filtering; not a visible total.
  final int remoteTotal;
}
