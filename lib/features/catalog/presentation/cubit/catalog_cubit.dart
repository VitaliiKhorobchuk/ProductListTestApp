import 'dart:developer' as developer;

import 'package:bloc/bloc.dart';

import '../../../../core/catalog_failure.dart';
import '../../../../core/request_control.dart';
import '../../data/products_repository.dart';
import 'catalog_state.dart';

export 'catalog_state.dart';

/// The catalog ViewModel: knows the repository contract, not Flutter widgets.
class CatalogCubit extends Cubit<CatalogState> {
  CatalogCubit(this._repository) : super(CatalogState());

  final ProductsRepository _repository;
  int _generation = 0;
  RequestControl? _activeRequest;

  Future<void> load() async {
    if (isClosed) return;
    final generation = ++_generation;
    _activeRequest?.cancel();
    final control = RequestControl();
    _activeRequest = control;
    final query = state.query;
    emit(CatalogState(status: CatalogStatus.loading, query: query));
    try {
      final page = await _repository.getProducts(
        query: query,
        control: control,
      );
      if (isClosed || generation != _generation || control.isCancelled) return;
      emit(
        CatalogState(
          status: page.products.isEmpty
              ? CatalogStatus.empty
              : CatalogStatus.loaded,
          query: query,
          products: page.products,
          nextSkip: page.nextSkip,
          hasMore: page.hasMore,
        ),
      );
    } on RequestCancelled {
      // A newer load or disposal owns the outcome; cancellation is not an error.
    } catch (error, stack) {
      if (isClosed || generation != _generation) return;
      developer.log(
        'Catalog loading failed.',
        name: 'CatalogCubit',
        error: error,
        stackTrace: stack,
      );
      final failure = error is CatalogFailure
          ? error
          : const CatalogFailure(
              CatalogFailureKind.invalidData,
              'Products could not be loaded. Please retry.',
            );
      emit(
        CatalogState(
          status: CatalogStatus.error,
          query: query,
          failure: failure,
        ),
      );
    } finally {
      if (identical(_activeRequest, control)) _activeRequest = null;
    }
  }

  Future<void> retry() => load();

  @override
  Future<void> close() {
    ++_generation;
    _activeRequest?.cancel();
    _activeRequest = null;
    return super.close();
  }
}
