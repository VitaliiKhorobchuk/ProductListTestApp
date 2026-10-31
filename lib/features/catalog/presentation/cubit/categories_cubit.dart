import 'dart:async';
import 'dart:developer' as developer;

import 'package:bloc/bloc.dart';

import '../../../../core/catalog_failure.dart';
import '../../../../core/request_control.dart';
import '../../data/products_repository.dart';
import 'categories_state.dart';

export 'categories_state.dart';

/// Loads category metadata once per session; retries never reload products.
class CategoriesCubit extends Cubit<CategoriesState> {
  CategoriesCubit(this._repository) : super(CategoriesState());

  final ProductsRepository _repository;
  int _generation = 0;
  RequestControl? _activeRequest;
  Future<void>? _pendingLoad;

  /// Shares an in-flight operation and reuses completed metadata, including empty.
  Future<void> load() {
    if (isClosed) return Future.value();
    final pending = _pendingLoad;
    if (pending != null) return pending;
    if (state.status == CategoriesStatus.loaded ||
        state.status == CategoriesStatus.empty) {
      return Future.value();
    }
    return _startLoad();
  }

  /// Explicit retry replaces any older operation with a fresh request.
  Future<void> retry() => isClosed ? Future.value() : _startLoad();

  Future<void> _startLoad() {
    final generation = ++_generation;
    _activeRequest?.cancel();
    final control = RequestControl();
    final completion = Completer<void>();
    _activeRequest = control;
    // Install the shared Future before starting work, even if the repository
    // throws synchronously or a listener requests another load.
    _pendingLoad = completion.future;
    unawaited(
      _fetch(generation, control).then(
        (_) => completion.complete(),
        onError: (Object error, StackTrace stack) =>
            completion.completeError(error, stack),
      ),
    );
    return completion.future;
  }

  Future<void> _fetch(int generation, RequestControl control) async {
    emit(CategoriesState(status: CategoriesStatus.loading));
    try {
      final categories = await _repository.getCategories(control: control);
      if (!_canPublish(generation, control)) return;
      emit(
        CategoriesState(
          status: categories.isEmpty
              ? CategoriesStatus.empty
              : CategoriesStatus.loaded,
          categories: categories,
        ),
      );
    } on RequestCancelled {
      // Supersession/disposal is silent; finally releases a current idle load.
    } catch (error, stack) {
      if (!_canPublish(generation, control)) return;
      developer.log(
        'Category loading failed.',
        name: 'CategoriesCubit',
        error: error,
        stackTrace: stack,
      );
      emit(
        CategoriesState(
          status: CategoriesStatus.error,
          failure: error is CatalogFailure
              ? error
              : const CatalogFailure(
                  CatalogFailureKind.invalidData,
                  'Categories could not be loaded. Please retry.',
                ),
        ),
      );
    } finally {
      if (_ownsOperation(generation, control)) {
        _activeRequest = null;
        _pendingLoad = null;
        // An unexpectedly cancelled current operation is idle, never a false
        // successful empty category list or a visible cancellation failure.
        if (state.status == CategoriesStatus.loading) {
          emit(CategoriesState());
        }
      }
    }
  }

  bool _ownsOperation(int generation, RequestControl control) =>
      !isClosed &&
      generation == _generation &&
      identical(_activeRequest, control);

  bool _canPublish(int generation, RequestControl control) =>
      _ownsOperation(generation, control) && !control.isCancelled;

  @override
  Future<void> close() {
    ++_generation;
    _activeRequest?.cancel();
    _activeRequest = null;
    _pendingLoad = null;
    return super.close();
  }
}
