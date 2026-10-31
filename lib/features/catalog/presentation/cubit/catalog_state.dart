import 'package:equatable/equatable.dart';

import '../../../../core/catalog_failure.dart';
import '../../models/catalog_query.dart';
import '../../models/product.dart';

enum CatalogStatus { initial, loading, loaded, empty, error }

/// Immutable state for one committed catalog query and its loaded batches.
class CatalogState extends Equatable {
  CatalogState({
    this.status = CatalogStatus.initial,
    CatalogQuery? query,
    List<Product> products = const [],
    this.nextSkip = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.failure,
    this.paginationFailure,
  }) : query = query ?? CatalogQuery(),
       products = List.unmodifiable(products);

  final CatalogStatus status;
  final CatalogQuery query;
  final List<Product> products;
  final int nextSkip;
  final bool hasMore;
  final bool isLoadingMore;

  /// Initial-load failure; pagination failures never replace loaded content.
  final CatalogFailure? failure;
  final CatalogFailure? paginationFailure;

  /// Omitted values retain their existing state. Explicit clear flags remove
  /// nullable failures without resetting the committed query, rows, or cursor.
  CatalogState copyWith({
    CatalogStatus? status,
    CatalogQuery? query,
    List<Product>? products,
    int? nextSkip,
    bool? hasMore,
    bool? isLoadingMore,
    CatalogFailure? failure,
    CatalogFailure? paginationFailure,
    bool clearFailure = false,
    bool clearPaginationFailure = false,
  }) => CatalogState(
    status: status ?? this.status,
    query: query ?? this.query,
    products: products ?? this.products,
    nextSkip: nextSkip ?? this.nextSkip,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    failure: clearFailure ? null : failure ?? this.failure,
    paginationFailure: clearPaginationFailure
        ? null
        : paginationFailure ?? this.paginationFailure,
  );

  @override
  List<Object?> get props => [
    status,
    query,
    products,
    nextSkip,
    hasMore,
    isLoadingMore,
    failure,
    paginationFailure,
  ];
}
