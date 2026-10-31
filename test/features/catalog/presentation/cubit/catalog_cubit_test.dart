import 'package:flutter_test/flutter_test.dart';
import 'package:product_list_test_app/core/catalog_failure.dart';
import 'package:product_list_test_app/core/request_control.dart';
import 'package:product_list_test_app/features/catalog/data/products_repository.dart';
import 'package:product_list_test_app/features/catalog/models/catalog_pagination.dart';
import 'package:product_list_test_app/features/catalog/models/catalog_query.dart';
import 'package:product_list_test_app/features/catalog/models/category.dart';
import 'package:product_list_test_app/features/catalog/models/product.dart';
import 'package:product_list_test_app/features/catalog/models/product_page.dart';
import 'package:product_list_test_app/features/catalog/presentation/cubit/catalog_cubit.dart';

void main() {
  group('CatalogCubit', () {
    test('moves from initial through loading to loaded products', () async {
      final product = Product(id: 1, title: 'Lipstick', category: 'beauty');
      final repository = _StubRepository(
        (_) async => ProductPage(
          products: [product],
          nextSkip: 1,
          hasMore: false,
          remoteTotal: 1,
        ),
      );
      final cubit = CatalogCubit(repository);
      addTearDown(cubit.close);

      expect(cubit.state.status, CatalogStatus.initial);
      final transitions = expectLater(
        cubit.stream.map((state) => state.status),
        emitsInOrder([CatalogStatus.loading, CatalogStatus.loaded]),
      );

      await cubit.load();
      await transitions;

      expect(cubit.state.products, [product]);
      expect(cubit.state.nextSkip, 1);
      expect(cubit.state.hasMore, isFalse);
      expect(cubit.state.failure, isNull);
    });

    test('finishes an exhausted result without products as empty', () async {
      final repository = _StubRepository(
        (_) async => ProductPage(
          products: [],
          nextSkip: 0,
          hasMore: false,
          remoteTotal: 0,
        ),
      );
      final cubit = CatalogCubit(repository);
      addTearDown(cubit.close);
      final transitions = expectLater(
        cubit.stream.map((state) => state.status),
        emitsInOrder([CatalogStatus.loading, CatalogStatus.empty]),
      );

      await cubit.load();
      await transitions;

      expect(cubit.state.products, isEmpty);
      expect(cubit.state.hasMore, isFalse);
      expect(cubit.state.failure, isNull);
    });

    test('publishes a failure and recovers when retry succeeds', () async {
      const failure = CatalogFailure(
        CatalogFailureKind.connection,
        'Connection unavailable.',
      );
      final product = Product(id: 1, title: 'Lipstick', category: 'beauty');
      var attempts = 0;
      final repository = _StubRepository((_) async {
        if (++attempts == 1) throw failure;
        return ProductPage(
          products: [product],
          nextSkip: 1,
          hasMore: false,
          remoteTotal: 1,
        );
      });
      final cubit = CatalogCubit(repository);
      addTearDown(cubit.close);
      final transitions = expectLater(
        cubit.stream.map((state) => state.status),
        emitsInOrder([
          CatalogStatus.loading,
          CatalogStatus.error,
          CatalogStatus.loading,
          CatalogStatus.loaded,
        ]),
      );

      await cubit.load();
      expect(cubit.state.failure, failure);
      expect(cubit.state.products, isEmpty);

      await cubit.retry();
      await transitions;

      expect(attempts, 2);
      expect(cubit.state.products, [product]);
      expect(cubit.state.failure, isNull);
    });

    test(
      'pagination keeps existing rows and merges duplicate IDs once',
      () async {
        final first = Product(id: 1, title: 'Lipstick', category: 'beauty');
        final second = Product(id: 2, title: 'Onions', category: 'groceries');
        final third = Product(id: 3, title: 'Eggs', category: 'groceries');
        final requestedSkips = <int>[];
        final repository = _StubRepository((skip) async {
          requestedSkips.add(skip);
          return skip == 0
              ? ProductPage(
                  products: [first, second],
                  nextSkip: 2,
                  hasMore: true,
                  remoteTotal: 4,
                )
              : ProductPage(
                  products: [second, third],
                  nextSkip: 4,
                  hasMore: false,
                  remoteTotal: 4,
                );
        });
        final cubit = CatalogCubit(repository);
        addTearDown(cubit.close);
        await cubit.load();
        final transitions = expectLater(
          cubit.stream,
          emitsInOrder([
            isA<CatalogState>()
                .having((state) => state.status, 'status', CatalogStatus.loaded)
                .having((state) => state.isLoadingMore, 'loading more', isTrue)
                .having((state) => state.products, 'existing rows', [
                  first,
                  second,
                ]),
            isA<CatalogState>()
                .having((state) => state.isLoadingMore, 'loading more', isFalse)
                .having((state) => state.products, 'merged rows', [
                  first,
                  second,
                  third,
                ]),
          ]),
        );

        await cubit.loadMore();
        await transitions;

        expect(requestedSkips, [0, 2]);
        expect(cubit.state.nextSkip, 4);
        expect(cubit.state.hasMore, isFalse);
        expect(cubit.state.paginationFailure, isNull);
      },
    );
  });
}

/// Supplies deterministic pages; these tests never use HTTP or fixture delays.
class _StubRepository implements ProductsRepository {
  _StubRepository(this._getProducts);

  final Future<ProductPage> Function(int skip) _getProducts;

  @override
  Future<ProductPage> getProducts({
    required CatalogQuery query,
    int skip = 0,
    int limit = CatalogPagination.pageSize,
    RequestControl? control,
  }) => _getProducts(skip);

  @override
  Future<List<Category>> getCategories({RequestControl? control}) =>
      throw UnsupportedError('CatalogCubit must not request categories.');

  @override
  Future<Product> getProduct(int id, {RequestControl? control}) =>
      throw UnsupportedError('CatalogCubit must not request product details.');
}
