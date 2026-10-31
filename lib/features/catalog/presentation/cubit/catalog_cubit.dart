import 'dart:developer' as developer;

import 'package:bloc/bloc.dart';

import '../../../../core/catalog_failure.dart';
import '../../../../core/request_control.dart';
import '../../../../core/safe_integer.dart';
import '../../data/products_repository.dart';
import '../../models/catalog_query.dart';
import '../../models/product.dart';
import '../../models/product_page.dart';
import 'catalog_state.dart';

export 'catalog_state.dart';

/// The catalog ViewModel: knows the repository contract, not Flutter widgets.
///
/// Each effective query has a generation. Initial loads and pagination share a
/// single active request slot; control identity also prevents an old finally
/// block from clearing a replacement request. Debouncing belongs to the input
/// component, while effective query equality suppresses duplicate commits here.
class CatalogCubit extends Cubit<CatalogState> {
  CatalogCubit(this._repository) : super(CatalogState());

  final ProductsRepository _repository;
  int _generation = 0;
  RequestControl? _activeRequest;

  /// Forces a fresh first-page load of the current committed query.
  Future<void> load() => _load(state.query);

  Future<void> retry() => load();

  /// Commits text immediately; case/outer-whitespace-only changes do not reload.
  Future<void> setSearch(String text) {
    final query = CatalogQuery(
      text: text,
      categorySlug: state.query.categorySlug,
    );
    if (isClosed || query == state.query) return Future.value();
    return _load(query);
  }

  /// Changes category while retaining the latest committed search text.
  Future<void> selectCategory(String? slug) {
    final query = CatalogQuery(text: state.query.text, categorySlug: slug);
    if (isClosed || query == state.query) return Future.value();
    return _load(query);
  }

  Future<void> _load(CatalogQuery query) async {
    if (isClosed) return;
    final generation = ++_generation;
    _activeRequest?.cancel();
    final control = RequestControl();
    _activeRequest = control;
    emit(CatalogState(status: CatalogStatus.loading, query: query));
    try {
      final page = await _repository.getProducts(
        query: query,
        control: control,
      );
      if (!_canPublish(generation, control)) return;
      _validatePage(page, expectedSkip: 0);
      final products = _mergeProducts(const [], page.products);
      emit(
        CatalogState(
          status: products.isEmpty ? CatalogStatus.empty : CatalogStatus.loaded,
          query: query,
          products: products,
          nextSkip: page.nextSkip,
          hasMore: page.hasMore,
        ),
      );
    } on RequestCancelled {
      // Cancellation is internal. If it unexpectedly belongs to this still-
      // current load, finally restores initial/idle instead of inventing empty
      // results or a user failure. A future load/retry can resume explicitly.
    } catch (error, stack) {
      if (!_canPublish(generation, control)) return;
      emit(
        CatalogState(
          status: CatalogStatus.error,
          query: query,
          failure: _failure(error, stack, isPagination: false),
        ),
      );
    } finally {
      _finishOperation(generation, control);
    }
  }

  /// Automatic near-bottom loading stops after a pagination failure.
  Future<void> loadMore() => _loadMore(explicitRetry: false);

  /// Retries the same raw cursor without replacing already loaded rows.
  Future<void> retryLoadMore() => _loadMore(explicitRetry: true);

  Future<void> _loadMore({required bool explicitRetry}) async {
    if (isClosed ||
        state.status != CatalogStatus.loaded ||
        !state.hasMore ||
        state.isLoadingMore ||
        _activeRequest != null ||
        (!explicitRetry && state.paginationFailure != null)) {
      return;
    }
    final snapshot = state;
    final generation = _generation;
    final control = RequestControl();
    _activeRequest = control;
    // Emit the busy guard synchronously before starting any asynchronous work.
    emit(snapshot.copyWith(isLoadingMore: true, clearPaginationFailure: true));
    try {
      final page = await _repository.getProducts(
        query: snapshot.query,
        skip: snapshot.nextSkip,
        control: control,
      );
      if (!_canPublish(generation, control)) return;
      _validatePage(page, expectedSkip: snapshot.nextSkip);
      emit(
        snapshot.copyWith(
          products: _mergeProducts(snapshot.products, page.products),
          nextSkip: page.nextSkip,
          hasMore: page.hasMore,
          isLoadingMore: false,
          clearPaginationFailure: true,
        ),
      );
    } on RequestCancelled {
      // finally releases a still-current busy flag without adding a failure.
    } catch (error, stack) {
      if (!_canPublish(generation, control)) return;
      emit(
        snapshot.copyWith(
          isLoadingMore: false,
          paginationFailure: _failure(error, stack, isPagination: true),
        ),
      );
    } finally {
      _finishOperation(generation, control);
    }
  }

  bool _ownsOperation(int generation, RequestControl control) =>
      !isClosed &&
      generation == _generation &&
      identical(_activeRequest, control);

  bool _canPublish(int generation, RequestControl control) =>
      _ownsOperation(generation, control) && !control.isCancelled;

  void _finishOperation(int generation, RequestControl control) {
    if (!_ownsOperation(generation, control)) return;
    _activeRequest = null;
    // A repository can also complete normally after its control was cancelled.
    // Release only busy/idle state; never publish that cancelled result or let
    // an obsolete operation clear a newer request's state.
    if (state.isLoadingMore) {
      emit(state.copyWith(isLoadingMore: false));
    } else if (state.status == CatalogStatus.loading) {
      emit(CatalogState(query: state.query));
    }
  }

  static List<Product> _mergeProducts(
    Iterable<Product> existing,
    Iterable<Product> incoming,
  ) {
    final seen = <int>{};
    return [
      for (final product in existing.followedBy(incoming))
        if (seen.add(product.id)) product,
    ];
  }

  static void _validatePage(ProductPage page, {required int expectedSkip}) {
    final nextSkip = page.nextSkip;
    final total = page.remoteTotal;
    if (nextSkip < expectedSkip ||
        !SafeInteger.isInRange(nextSkip) ||
        !SafeInteger.isInRange(total) ||
        page.hasMore != (nextSkip < total) ||
        (page.hasMore && nextSkip == expectedSkip) ||
        (nextSkip > total && nextSkip != expectedSkip) ||
        page.products.length > nextSkip - expectedSkip ||
        (page.products.isEmpty && page.hasMore)) {
      throw const CatalogFailure(
        CatalogFailureKind.invalidData,
        'The catalog returned inconsistent pagination data. Please retry.',
      );
    }
  }

  static CatalogFailure _failure(
    Object error,
    StackTrace stack, {
    required bool isPagination,
  }) {
    developer.log(
      isPagination ? 'Catalog pagination failed.' : 'Catalog loading failed.',
      name: 'CatalogCubit',
      error: error,
      stackTrace: stack,
    );
    if (error is CatalogFailure) return error;
    return CatalogFailure(
      CatalogFailureKind.invalidData,
      isPagination
          ? 'More products could not be loaded. Please retry.'
          : 'Products could not be loaded. Please retry.',
    );
  }

  @override
  Future<void> close() {
    ++_generation;
    _activeRequest?.cancel();
    _activeRequest = null;
    return super.close();
  }
}
