import 'dart:developer' as developer;

import 'package:bloc/bloc.dart';

import '../../../../core/catalog_failure.dart';
import '../../../../core/diagnostic_level.dart';
import '../../../../core/request_control.dart';
import '../../data/products_repository.dart';
import 'product_detail_state.dart';

export 'product_detail_state.dart';

/// Loads details independently of catalog queries, pages, and category metadata.
///
/// Every load is fresh, including repeated IDs. Generation and request identity
/// protect state from superseded results and cleanup; cancellation is internal
/// and never becomes a user-visible failure.
class ProductDetailCubit extends Cubit<ProductDetailState> {
  ProductDetailCubit(this._repository) : super(const ProductDetailState());

  final ProductsRepository _repository;
  int _generation = 0;
  RequestControl? _activeRequest;

  /// Supersedes older work and delegates ID validation to the repository.
  ///
  /// An invalid latest ID still clears the old product. The repository reports
  /// typed invalidData before data access; the requested ID stays available
  /// for deterministic retry.
  Future<void> load(int productId) async {
    if (isClosed) return;
    final generation = ++_generation;
    _activeRequest?.cancel();
    final control = RequestControl();
    _activeRequest = control;
    emit(
      ProductDetailState(
        status: ProductDetailStatus.loading,
        productId: productId,
      ),
    );
    try {
      final product = await _repository.getProduct(productId, control: control);
      if (!_canPublish(generation, control)) return;
      if (product.id != productId) {
        throw const CatalogFailure(
          CatalogFailureKind.invalidData,
          'The requested product could not be read correctly. Please retry.',
        );
      }
      emit(
        ProductDetailState(
          status: ProductDetailStatus.loaded,
          productId: productId,
          product: product,
        ),
      );
    } on RequestCancelled {
      // Superseded or closed work stays silent. An unexpectedly cancelled
      // current request is restored to idle by finally, retaining its retry ID.
    } catch (error, stack) {
      if (!_canPublish(generation, control)) return;
      emit(
        ProductDetailState(
          status: ProductDetailStatus.error,
          productId: productId,
          failure: _failure(productId, error, stack),
        ),
      );
    } finally {
      // Deliberately omit !control.isCancelled here: current cancellation must
      // release loading, while an old finally must never clear a newer control.
      if (_ownsOperation(generation, control)) {
        _activeRequest = null;
        if (state.status == ProductDetailStatus.loading) {
          emit(ProductDetailState(productId: productId));
        }
      }
    }
  }

  /// Repeats the last requested ID; no-op before the first load or after close.
  Future<void> retry() {
    final productId = state.productId;
    if (isClosed || productId == null) return Future.value();
    return load(productId);
  }

  bool _ownsOperation(int generation, RequestControl control) =>
      !isClosed &&
      generation == _generation &&
      identical(_activeRequest, control);

  bool _canPublish(int generation, RequestControl control) =>
      _ownsOperation(generation, control) && !control.isCancelled;

  static CatalogFailure _failure(
    int productId,
    Object error,
    StackTrace stack,
  ) {
    final failure = error is CatalogFailure
        ? error
        : const CatalogFailure(
            CatalogFailureKind.invalidData,
            'This product could not be loaded. Please retry.',
          );
    // Keep useful operation context without logging arbitrary repository error
    // payloads. Only current errors reach this helper; normal cancellation does
    // not produce an error diagnostic.
    developer.log(
      'Product detail loading failed for product $productId.',
      name: 'ProductDetailCubit',
      level: DiagnosticLevel.error,
      error: failure,
      stackTrace: stack,
    );
    return failure;
  }

  @override
  Future<void> close() {
    ++_generation;
    _activeRequest?.cancel();
    _activeRequest = null;
    return super.close();
  }
}
