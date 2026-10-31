import 'package:equatable/equatable.dart';

import '../../../../core/catalog_failure.dart';
import '../../models/product.dart';

enum ProductDetailStatus { initial, loading, loaded, error }

/// Immutable detail state for the most recently requested product ID.
///
/// Not-found is represented by the typed [failure], rather than a second flag
/// or status that could contradict it. New loads and failures have no old
/// [product]; a cancelled current load is idle but retains [productId] for retry.
class ProductDetailState extends Equatable {
  const ProductDetailState({
    this.status = ProductDetailStatus.initial,
    this.productId,
    this.product,
    this.failure,
  });

  final ProductDetailStatus status;
  final int? productId;
  final Product? product;
  final CatalogFailure? failure;

  @override
  List<Object?> get props => [status, productId, product, failure];
}
