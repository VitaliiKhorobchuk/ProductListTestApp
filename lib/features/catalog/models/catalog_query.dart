import 'package:equatable/equatable.dart';

import 'product.dart';

class CatalogQuery extends Equatable {
  CatalogQuery({String text = '', String? categorySlug})
    : text = text.trim(),
      categorySlug = categorySlug == null || categorySlug.trim().isEmpty
          ? null
          : categorySlug.trim();

  final String text;
  final String? categorySlug;

  String get normalizedText => text.toLowerCase();

  /// Final title/category match after the broader server search.
  bool matches(Product product) =>
      product.title.toLowerCase().contains(normalizedText) &&
      (categorySlug == null || product.category == categorySlug);

  @override
  List<Object?> get props => [normalizedText, categorySlug];
}
