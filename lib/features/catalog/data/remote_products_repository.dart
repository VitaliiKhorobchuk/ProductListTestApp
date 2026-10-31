import 'dart:async';

import 'package:dio/dio.dart';

import '../../../core/catalog_failure.dart';
import '../../../core/request_control.dart';
import '../../../core/safe_integer.dart';
import '../models/catalog_pagination.dart';
import '../models/catalog_query.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/product_page.dart';
import 'product_id_validation.dart';
import 'products_api.dart';
import 'products_api_config.dart';
import 'products_repository.dart';
import 'raw_product_page.dart';

/// Converts raw API pages into complete, filtered catalog batches.
///
/// Every call owns an independent cancellation/deadline scope. Products, seen
/// IDs, and cursor advancement stay local until the entire operation succeeds;
/// a later failure discards them so a retry starts at the caller's input cursor.
/// There is no repository session cache, and this class never closes the API's
/// caller-owned HTTP client.
class RemoteProductsRepository implements ProductsRepository {
  RemoteProductsRepository(
    ProductsApi api, {
    Duration operationTimeout = ProductsApiConfig.operationTimeout,
    int rawPageSize = CatalogPagination.pageSize,
  }) : _api = api,
       _operationTimeout = operationTimeout,
       _rawPageSize = rawPageSize {
    if (operationTimeout <= Duration.zero) {
      throw ArgumentError.value(
        operationTimeout,
        'operationTimeout',
        'Must be positive.',
      );
    }
    SafeInteger.require(rawPageSize, 'rawPageSize', minimum: 1);
  }

  final ProductsApi _api;
  final Duration _operationTimeout;
  final int _rawPageSize;

  /// Returns at least [limit] unique matches, or fewer when the source ends.
  ///
  /// Search is a case-insensitive title substring intersected with the selected
  /// category. Keep all matches from each consumed page, even beyond the target:
  /// trimming would lose products after the raw cursor advances. Deduplication
  /// applies only inside this batch and only after a record matches;
  /// CatalogCubit merges IDs across independent batches.
  @override
  Future<ProductPage> getProducts({
    required CatalogQuery query,
    int skip = 0,
    int limit = CatalogPagination.pageSize,
    RequestControl? control,
  }) {
    SafeInteger.require(skip, 'skip', minimum: 0);
    SafeInteger.require(limit, 'limit', minimum: 1);
    return _run(control, (operation) async {
      final products = <Product>[];
      final seenIds = <int>{};
      var cursor = skip;
      int? remoteTotal;
      var hasMore = true;
      while (hasMore && products.length < limit) {
        operation.check();
        final page = await _api.getProducts(
          query: query,
          skip: cursor,
          limit: _rawPageSize,
          cancelToken: operation.token,
        );
        operation.check();
        _validatePage(page, expectedSkip: cursor);
        if (remoteTotal != null && remoteTotal != page.total) {
          throw _invalid(
            'The catalog total changed during this request. Retry the batch.',
          );
        }
        remoteTotal = page.total;
        for (final product in page.products) {
          operation.check();
          if (query.matches(product) && seenIds.add(product.id)) {
            products.add(product);
          }
        }
        operation.check();
        cursor = page.nextSkip;
        hasMore = page.hasMore;
      }
      operation.check();
      return ProductPage(
        products: products,
        nextSkip: cursor,
        hasMore: hasMore,
        remoteTotal: remoteTotal!,
      );
    });
  }

  /// Category and detail calls have their own scopes, independent of a scan.
  @override
  Future<List<Category>> getCategories({RequestControl? control}) => _run(
    control,
    (operation) async {
      final categories = await _api.getCategories(cancelToken: operation.token);
      operation.check();
      return categories;
    },
  );

  @override
  Future<Product> getProduct(int id, {RequestControl? control}) async {
    control?.throwIfCancelled();
    validateProductId(id);
    return _run(control, (operation) async {
      final product = await _api.getProduct(id, cancelToken: operation.token);
      operation.check();
      return product;
    });
  }

  Future<T> _run<T>(
    RequestControl? control,
    Future<T> Function(_OperationScope operation) action,
  ) async {
    final operation = _OperationScope(_operationTimeout, control);
    try {
      operation.check();
      final result = await action(operation);
      operation.check();
      return result;
    } catch (_) {
      // Deadline cancellation reaches ProductsApi as RequestCancelled. The
      // owning scope restores its timeout reason before any error can escape.
      operation.check();
      rethrow;
    } finally {
      operation.dispose();
    }
  }

  void _validatePage(RawProductPage page, {required int expectedSkip}) {
    // The parser already enforces these invariants. Checking the boundary here
    // also guards future API implementations from trapping a scan in a loop.
    if (!SafeInteger.isInRange(page.skip) ||
        !SafeInteger.isInRange(page.limit) ||
        !SafeInteger.isInRange(page.total) ||
        !SafeInteger.isInRange(page.rawCount) ||
        page.skip != expectedSkip ||
        page.rawCount > page.limit ||
        page.rawCount > _rawPageSize ||
        page.products.length > page.rawCount ||
        page.rawCount > SafeInteger.maximum - page.skip) {
      throw _invalid('The catalog returned inconsistent pagination data.');
    }
    if (page.rawCount == 0) {
      if (page.skip < page.total) {
        throw _invalid(
          'The catalog stopped before all source records were read.',
        );
      }
    } else if (page.skip >= page.total ||
        page.rawCount > page.total - page.skip ||
        page.nextSkip <= page.skip ||
        page.products.isEmpty) {
      throw _invalid('The catalog returned an unusable product page.');
    }
  }

  static CatalogFailure _invalid(String message) =>
      CatalogFailure(CatalogFailureKind.invalidData, message);
}

enum _CancellationReason { caller, deadline }

/// One logical-operation budget, including all raw pages and local filtering.
///
/// The first chronological reason wins. If a caller callback arrives after the
/// elapsed deadline but before a delayed Timer callback, the already-expired
/// deadline wins. Once caller cancellation is recorded, a later deadline cannot
/// change it. Elapsed checks also catch synchronous work that delays the Timer.
class _OperationScope {
  _OperationScope(this.timeout, RequestControl? control) {
    // This cancellation predates the operation's budget, even when the budget
    // is so short that inspecting a later callback could already exceed it.
    if (control?.isCancelled ?? false) {
      _reason = _CancellationReason.caller;
      token.cancel(_reason);
      return;
    }
    _watch.start();
    _unsubscribe = control?.onCancel(() => _cancel(_CancellationReason.caller));
    if (_reason == null) _scheduleDeadline();
  }

  final Duration timeout;
  final CancelToken token = CancelToken();
  final Stopwatch _watch = Stopwatch();
  Timer? _timer;
  void Function()? _unsubscribe;
  _CancellationReason? _reason;

  void check() {
    if (_reason == null && _watch.elapsed >= timeout) {
      _cancel(_CancellationReason.deadline);
    }
    switch (_reason) {
      case _CancellationReason.caller:
        throw const RequestCancelled();
      case _CancellationReason.deadline:
        throw const CatalogFailure(
          CatalogFailureKind.timeout,
          'The catalog operation timed out. Please try again.',
        );
      case null:
        return;
    }
  }

  void _cancel(_CancellationReason reason) {
    if (_reason != null) return;
    _reason = _watch.elapsed >= timeout ? _CancellationReason.deadline : reason;
    token.cancel(_reason);
  }

  void _scheduleDeadline() {
    final remaining = timeout - _watch.elapsed;
    _timer = Timer(remaining, () {
      // Recheck elapsed time rather than relying on platform timer precision.
      if (_reason != null) return;
      if (_watch.elapsed >= timeout) {
        _cancel(_CancellationReason.deadline);
      } else {
        _scheduleDeadline();
      }
    });
  }

  void dispose() {
    _timer?.cancel();
    _unsubscribe?.call();
    _watch.stop();
  }
}
