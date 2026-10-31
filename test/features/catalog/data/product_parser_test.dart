import 'package:flutter_test/flutter_test.dart';
import 'package:product_list_test_app/core/catalog_failure.dart';
import 'package:product_list_test_app/features/catalog/data/product_parser.dart';

void main() {
  late ProductParser parser;

  setUp(() {
    parser = ProductParser(onDiagnostic: (_, _) {});
  });

  group('ProductParser', () {
    test(
      'parses API fields and keeps the API rating and returned review count',
      () {
        final product = parser.parseProduct({
          'id': 42,
          'title': ' Red Lipstick ',
          'category': 'beauty',
          'brand': ' Example Brand ',
          'description': ' A red lipstick. ',
          'price': 20,
          'discountPercentage': 25,
          'rating': 4.2,
          'stock': 10,
          'reviews': [{}, {}],
          'thumbnail': 'https://example.com/thumbnail.png',
          'images': ['https://example.com/product.png'],
        });

        expect(product.id, 42);
        expect(product.title, 'Red Lipstick');
        expect(product.brand, 'Example Brand');
        expect(product.category, 'beauty');
        expect(product.description, 'A red lipstick.');
        expect(product.price, 20);
        expect(product.discountedPrice, 15);
        expect(product.rating, 4.2);
        expect(product.reviewCount, 2);
        expect(product.stock, 10);
        expect(product.thumbnail, 'https://example.com/thumbnail.png');
        expect(product.images, ['https://example.com/product.png']);
      },
    );

    test('uses safe fallbacks for missing or invalid optional fields', () {
      final product = parser.parseProduct({
        'id': 1,
        'title': '',
        'brand': ' ',
        'price': -5,
        'discountPercentage': 120,
        'rating': 6,
        'stock': -1,
        'thumbnail': 'unsupported://image',
        'images': ['not a URL'],
      });

      expect(product.title, 'Untitled product');
      expect(product.brand, 'Unknown brand');
      expect(product.category, 'Unknown category');
      expect(product.description, 'No description available.');
      expect(product.price, isNull);
      expect(product.discountPercentage, 0);
      expect(product.rating, isNull);
      expect(product.stock, isNull);
      expect(product.reviewCount, isNull);
      expect(product.thumbnail, isNull);
      expect(product.images, isEmpty);
    });

    test('rejects unusable required product IDs without coercing them', () {
      for (final id in <Object?>[null, 0, -1, 1.5, '1']) {
        expect(
          () => parser.parseProduct({'id': id}),
          throwsA(
            isA<CatalogFailure>().having(
              (failure) => failure.kind,
              'failure kind',
              CatalogFailureKind.invalidData,
            ),
          ),
          reason: 'Invalid ID: $id',
        );
      }
    });

    test('raw cursor counts skipped malformed records as consumed', () {
      final page = parser.parseProductPage(
        {
          'products': [
            {'id': 1, 'title': 'Lipstick', 'price': 10},
            {'id': 0},
            {'id': 2, 'title': 'Onions', 'price': 2},
          ],
          'skip': 20,
          'limit': 3,
          'total': 25,
        },
        expectedSkip: 20,
        requestedLimit: 3,
      );

      expect(page.products.map((product) => product.id), [1, 2]);
      expect(page.rawCount, 3);
      expect(page.nextSkip, 23);
      expect(page.hasMore, isTrue);
    });
  });
}
