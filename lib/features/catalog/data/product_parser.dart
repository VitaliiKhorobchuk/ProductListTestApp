import 'dart:developer' as developer;

import '../../../core/catalog_failure.dart';
import '../../../core/product_labels.dart';
import '../../../core/product_pricing.dart';
import '../models/category.dart';
import '../models/product.dart';
import 'raw_product_page.dart';

/// Maps already-decoded API values into transport-independent catalog models.
///
/// Optional descriptive fields receive display defaults; invalid required
/// identities or response envelopes throw [CatalogFailureKind.invalidData].
/// No network requests, JSON-text decoding, filtering, or product deduplication
/// occur here. The optional diagnostic callback receives a safe message and a
/// logging level (900 for warnings, 1000 for an unavailable price), never a raw
/// payload. Without a callback, diagnostics go to dart:developer.
class ProductParser {
  ProductParser({void Function(String message, int level)? onDiagnostic})
    : _onDiagnostic = onDiagnostic ?? _logDiagnostic;

  // This upper bound gives native Dart and JavaScript the same integer identity
  // and cursor semantics. Integral doubles such as 1.0 are valid JSON numbers.
  static const _maxSafeInteger = 9007199254740991;
  final void Function(String message, int level) _onDiagnostic;

  /// Parses one product, requiring a positive JavaScript-safe integer ID.
  ///
  /// Numeric strings and fractional/non-finite numbers are not coerced. Prices
  /// retain their original API meaning; [Product.discountedPrice] calculates the
  /// displayed discount. Only absolute HTTP(S) image URLs enter API models.
  Product parseProduct(Object? decoded) {
    final record = _requireObject(decoded, 'The product record is invalid.');
    final id = _safeInteger(record['id']);
    if (id == null || id == 0) {
      throw _invalid('The product has an invalid ID.');
    }

    final originalPrice = _finiteNumber(record['price']);
    final price = ProductPricing.isValidPrice(originalPrice)
        ? originalPrice
        : null;
    if (price == null) {
      _diagnose('Product $id has an invalid or missing price.', level: 1000);
    }

    final discount = _finiteNumber(record['discountPercentage']);
    final rating = _finiteNumber(record['rating']);
    final stock = _safeInteger(record['stock']);
    final thumbnail = _imageUrl(record['thumbnail']);
    if (thumbnail == null) {
      _diagnose('Product $id has an invalid or missing thumbnail.');
    }

    final images = <String>[];

    final rawImages = record['images'];
    if (rawImages is List) {
      for (final rawImage in rawImages) {
        final image = _imageUrl(rawImage);
        if (image == null) {
          _diagnose('Product $id has an invalid gallery image.');
        } else {
          images.add(image);
        }
      }
    } else if (rawImages != null) {
      _diagnose('Product $id has an invalid gallery image list.');
    }

    final reviews = record['reviews'];
    return Product(
      id: id,
      title: _text(record['title'], ProductLabels.untitledProduct),
      category: _text(record['category'], ProductLabels.unknownCategory),
      description: _text(
        record['description'],
        ProductLabels.missingDescription,
      ),
      brand: _text(record['brand'], ProductLabels.unknownBrand),
      price: price,
      discountPercentage: ProductPricing.isValidDiscount(discount)
          ? discount!
          : 0,
      rating: rating != null && rating >= 0 && rating <= 5 ? rating : null,
      reviewCount: reviews is List ? reviews.length : null,
      stock: stock,
      thumbnail: thumbnail,
      images: images,
    );
  }

  /// Parses a category object with a stable, nonblank API slug.
  /// Missing names are humanized from the slug, which itself is not rewritten.
  Category parseCategory(Object? decoded) {
    final record = _requireObject(decoded, 'The category record is invalid.');
    final rawSlug = record['slug'];
    if (rawSlug is! String || rawSlug.trim().isEmpty) {
      throw _invalid('The category has an invalid slug.');
    }
    final slug = rawSlug.trim();
    return Category(
      slug: slug,
      name: _text(record['name'], _humanizeSlug(slug)),
    );
  }

  /// Parses API category objects, preserving the first occurrence of each slug.
  /// Malformed entries are skipped; a nonempty entirely invalid list is an error.
  List<Category> parseCategories(Object? decoded) {
    if (decoded is! List) {
      throw _invalid('The category list is invalid.');
    }
    final categories = <Category>[];
    final seenSlugs = <String>{};
    for (final record in decoded) {
      try {
        final category = parseCategory(record);
        if (seenSlugs.add(category.slug)) categories.add(category);
      } on CatalogFailure {
        _diagnose(
          'Skipped a category record with an invalid identity or shape.',
        );
      }
    }
    if (decoded.isNotEmpty && categories.isEmpty) {
      throw _invalid('The category list contains no usable records.');
    }
    return List.unmodifiable(categories);
  }

  /// Validates a server envelope before mapping its records.
  ///
  /// The server skip must match the requested cursor. Counts and metadata must
  /// be safe nonnegative integers; raw count cannot exceed either limit or the
  /// remaining server total. Empty pages are accepted only at/after exhaustion.
  /// An exhausted response may report limit zero. Malformed records are skipped
  /// without reducing [RawProductPage.rawCount]; an all-invalid nonempty page
  /// fails before any repository filtering can hide the data error.
  RawProductPage parseProductPage(
    Object? decoded, {
    required int expectedSkip,
    required int requestedLimit,
  }) {
    if (expectedSkip < 0 || expectedSkip > _maxSafeInteger) {
      throw ArgumentError.value(
        expectedSkip,
        'expectedSkip',
        'Must be a safe nonnegative integer.',
      );
    }
    if (requestedLimit <= 0 || requestedLimit > _maxSafeInteger) {
      throw ArgumentError.value(
        requestedLimit,
        'requestedLimit',
        'Must be a safe positive integer.',
      );
    }
    final envelope = _requireObject(decoded, 'The product page is invalid.');
    final rawProducts = envelope['products'];
    final skip = _safeInteger(envelope['skip']);
    final limit = _safeInteger(envelope['limit']);
    final total = _safeInteger(envelope['total']);
    if (rawProducts is! List ||
        skip == null ||
        limit == null ||
        total == null) {
      throw _invalid('The product page has invalid pagination metadata.');
    }
    if (skip != expectedSkip) {
      throw _invalid('The product page does not match the requested cursor.');
    }
    final rawCount = rawProducts.length;
    if (rawCount > limit ||
        rawCount > requestedLimit ||
        rawCount > _maxSafeInteger - skip) {
      throw _invalid('The product page has inconsistent record counts.');
    }
    if (rawCount == 0) {
      if (skip < total) {
        throw _invalid(
          'The product page is empty before the catalog is exhausted.',
        );
      }
    } else if (skip >= total || rawCount > total - skip) {
      throw _invalid('The product page exceeds the remaining server total.');
    }

    final products = <Product>[];
    for (final record in rawProducts) {
      try {
        products.add(parseProduct(record));
      } on CatalogFailure {
        _diagnose(
          'Skipped a product record with an invalid identity or shape.',
        );
      }
    }
    if (rawCount > 0 && products.isEmpty) {
      throw _invalid('The product page contains no usable records.');
    }
    return RawProductPage(
      products: products,
      rawCount: rawCount,
      skip: skip,
      limit: limit,
      total: total,
    );
  }

  static Map<Object?, Object?> _requireObject(Object? value, String message) {
    if (value is! Map) throw _invalid(message);
    return value;
  }

  static int? _safeInteger(Object? value) {
    if (value is! num ||
        !value.isFinite ||
        value < 0 ||
        value > _maxSafeInteger ||
        value != value.truncateToDouble()) {
      return null;
    }
    return value.toInt();
  }

  static double? _finiteNumber(Object? value) =>
      value is num && value.isFinite ? value.toDouble() : null;

  static String _text(Object? value, String fallback) =>
      value is String && value.trim().isNotEmpty ? value.trim() : fallback;

  static String? _imageUrl(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    final uri = Uri.tryParse(value.trim());
    return uri != null &&
            uri.hasAuthority &&
            uri.host.isNotEmpty &&
            (uri.scheme == 'http' || uri.scheme == 'https')
        ? uri.toString()
        : null;
  }

  static String _humanizeSlug(String slug) {
    final words = slug
        .split(RegExp(r'[-_\s]+'))
        .where((word) => word.isNotEmpty);
    if (words.isEmpty) return slug;
    return words
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  static CatalogFailure _invalid(String message) =>
      CatalogFailure(CatalogFailureKind.invalidData, message);

  void _diagnose(String message, {int level = 900}) =>
      _onDiagnostic(message, level);

  static void _logDiagnostic(String message, int level) =>
      developer.log(message, name: 'ProductParser', level: level);
}
