import 'package:equatable/equatable.dart';

import '../../../../core/catalog_failure.dart';
import '../../models/catalog_query.dart';
import '../../models/product.dart';

enum CatalogStatus { initial, loading, loaded, empty, error }

class CatalogState extends Equatable {
  CatalogState({
    this.status = CatalogStatus.initial,
    CatalogQuery? query,
    List<Product> products = const [],
    this.nextSkip = 0,
    this.hasMore = false,
    this.failure,
  }) : query = query ?? CatalogQuery(),
       products = List.unmodifiable(products);

  final CatalogStatus status;
  final CatalogQuery query;
  final List<Product> products;
  final int nextSkip;
  final bool hasMore;
  final CatalogFailure? failure;

  @override
  List<Object?> get props => [
    status,
    query,
    products,
    nextSkip,
    hasMore,
    failure,
  ];
}
