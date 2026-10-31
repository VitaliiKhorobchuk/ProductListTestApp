import 'dart:async';
import 'dart:math' as math;

import '../../../core/catalog_failure.dart';
import '../../../core/request_control.dart';
import '../models/catalog_pagination.dart';
import '../models/catalog_query.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/product_page.dart';
import 'product_id_validation.dart';
import 'products_repository.dart';
import 'sample_product_data.dart';

enum SampleCatalogScenario { loaded, empty, error }

/// Temporary offline implementation. The View and Cubit use only the contract.
class SampleProductsRepository implements ProductsRepository {
  SampleProductsRepository({
    List<Product>? products,
    this.scenario = SampleCatalogScenario.loaded,
    Duration delay = defaultDelay,
  }) : _products = List.unmodifiable(products ?? sampleProducts),
       _delay = delay {
    if (delay.isNegative) throw ArgumentError.value(delay, 'delay');
  }

  factory SampleProductsRepository.fromEnvironment() {
    const value = String.fromEnvironment(
      'SAMPLE_CATALOG',
      defaultValue: 'loaded',
    );
    final scenario = switch (value) {
      'loaded' => SampleCatalogScenario.loaded,
      'empty' => SampleCatalogScenario.empty,
      'error' => SampleCatalogScenario.error,
      _ => throw ArgumentError(
        'SAMPLE_CATALOG must be loaded, empty, or error.',
      ),
    };
    return SampleProductsRepository(scenario: scenario);
  }

  static const defaultDelay = Duration(milliseconds: 500);

  final List<Product> _products;
  final Duration _delay;
  final SampleCatalogScenario scenario;

  @override
  Future<ProductPage> getProducts({
    required CatalogQuery query,
    int skip = 0,
    int limit = CatalogPagination.pageSize,
    RequestControl? control,
  }) async {
    if (skip < 0 || limit < 1) {
      throw ArgumentError('Use skip >= 0 and limit > 0.');
    }
    final products = await _readProducts(control);
    final text = query.normalizedText;
    // Simulate the remote source's broader search, then intersect locally.
    final source = products
        .where((product) {
          if (text.isNotEmpty) {
            return product.title.toLowerCase().contains(text) ||
                product.description.toLowerCase().contains(text);
          }
          return query.categorySlug == null ||
              product.category == query.categorySlug;
        })
        .toList(growable: false);
    final matches = <Product>[];
    final seen = <int>{};
    var cursor = skip;
    while (cursor < source.length && matches.length < limit) {
      control?.throwIfCancelled();
      final end = math.min(cursor + limit, source.length);
      for (final product in source.sublist(cursor, end)) {
        if (query.matches(product) && seen.add(product.id)) {
          matches.add(product);
        }
      }
      cursor = end;
    }
    return ProductPage(
      products: matches,
      nextSkip: cursor,
      hasMore: cursor < source.length,
      remoteTotal: source.length,
    );
  }

  @override
  Future<List<Category>> getCategories({RequestControl? control}) async {
    final products = await _readProducts(control);
    final names = {
      for (final category in sampleCategories) category.slug: category.name,
    };
    return List.unmodifiable(
      products
          .map((product) => product.category)
          .toSet()
          .map(
            (slug) => Category(
              slug: slug,
              name: names[slug] ?? slug.replaceAll('-', ' '),
            ),
          ),
    );
  }

  @override
  Future<Product> getProduct(int id, {RequestControl? control}) async {
    control?.throwIfCancelled();
    validateProductId(id);
    final products = await _readProducts(control);
    for (final product in products) {
      if (product.id == id) return product;
    }
    throw const CatalogFailure(
      CatalogFailureKind.notFound,
      'Product not found.',
    );
  }

  Future<List<Product>> _readProducts(RequestControl? control) async {
    control?.throwIfCancelled();
    final completion = Completer<void>();
    final timer = Timer(_delay, () {
      if (!completion.isCompleted) completion.complete();
    });
    final unsubscribe = control?.onCancel(() {
      if (!completion.isCompleted) {
        completion.completeError(const RequestCancelled());
      }
    });
    try {
      await completion.future;
    } finally {
      timer.cancel();
      unsubscribe?.call();
    }
    control?.throwIfCancelled();
    if (scenario == SampleCatalogScenario.error) {
      throw const CatalogFailure(
        CatalogFailureKind.server,
        'The example catalog could not be loaded. Please retry.',
      );
    }
    return scenario == SampleCatalogScenario.empty ? const [] : _products;
  }
}
