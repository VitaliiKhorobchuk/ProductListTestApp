import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../../core/catalog_failure.dart';
import '../../../core/diagnostic_level.dart';
import '../../../core/request_control.dart';
import '../../../core/safe_integer.dart';
import '../models/catalog_pagination.dart';
import '../models/catalog_query.dart';
import '../models/category.dart';
import '../models/product.dart';
import 'product_parser.dart';
import 'products_api_config.dart';
import 'raw_product_page.dart';

/// Fetches one raw API response and maps it through [ProductParser].
///
/// The caller owns the shared [Dio] client, its configuration, and its lifetime.
/// This service changes only per-request options; it never closes the client.
/// Filtering, product deduplication, multi-page scanning, retries, and the overall
/// logical-operation deadline belong to the repository implementation.
class ProductsApi {
  ProductsApi(Dio dio, {ProductParser? parser})
    : _dio = dio,
      _parser = parser ?? ProductParser();

  static const _successStatusMinimum = 200;
  static const _redirectStatusMinimum = 300;
  static const _notFoundStatus = 404;

  static bool _isSuccessfulStatus(int status) =>
      status >= _successStatusMinimum && status < _redirectStatusMinimum;

  final Dio _dio;
  final ProductParser _parser;

  /// Fetches exactly one server page without applying title/category filters.
  ///
  /// Search takes precedence over category because the API does not expose a
  /// combined endpoint. The repository will intersect search results locally.
  /// Pagination arguments are validated before any HTTP work is started.
  Future<RawProductPage> getProducts({
    required CatalogQuery query,
    int skip = 0,
    int limit = CatalogPagination.pageSize,
    CancelToken? cancelToken,
  }) {
    SafeInteger.require(skip, 'skip', minimum: 0);
    SafeInteger.require(limit, 'limit', minimum: 1);
    final hasSearch = query.text.isNotEmpty;
    final category = query.categorySlug;
    if (category == '.' || category == '..') {
      throw ArgumentError.value(
        category,
        'query.categorySlug',
        'A category slug cannot be a dot path segment.',
      );
    }
    final path = hasSearch
        ? ProductsEndpoints.search
        : category != null
        ? ProductsEndpoints.category(category)
        : ProductsEndpoints.products;
    return _getAndParse(
      path,
      cancelToken: cancelToken,
      queryParameters: {
        'skip': skip,
        'limit': limit,
        if (hasSearch) 'q': query.text,
      },
      parse: (decoded) => _parser.parseProductPage(
        decoded,
        expectedSkip: skip,
        requestedLimit: limit,
      ),
    );
  }

  /// Fetches category objects independently from the product list.
  Future<List<Category>> getCategories({CancelToken? cancelToken}) =>
      _getAndParse(
        ProductsEndpoints.categories,
        cancelToken: cancelToken,
        parse: _parser.parseCategories,
      );

  /// Fetches a product by a positive safe ID and rejects a mismatched response.
  Future<Product> getProduct(int id, {CancelToken? cancelToken}) {
    SafeInteger.require(id, 'id', minimum: 1);
    return _getAndParse(
      ProductsEndpoints.product(id),
      cancelToken: cancelToken,
      parse: (decoded) {
        final product = _parser.parseProduct(decoded);
        if (product.id != id) {
          throw const CatalogFailure(
            CatalogFailureKind.invalidData,
            'The server returned a different product than requested.',
          );
        }
        return product;
      },
    );
  }

  Future<T> _getAndParse<T>(
    String path, {
    required T Function(Object? decoded) parse,
    Map<String, Object?>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    _throwIfCancelled(cancelToken);
    late final Response<String> response;
    try {
      response = await _dio.get<String>(
        path,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        // Classify HTTP status before JSON decoding, including HTML error pages.
        // These options do not mutate the caller's shared BaseOptions.
        options: Options(
          responseType: ResponseType.plain,
          validateStatus: (status) => status != null,
        ),
      );
    } on DioException catch (error) {
      _throwIfCancelled(cancelToken);
      throw _mapDioFailure(error);
    }
    _throwIfCancelled(cancelToken);
    final status = response.statusCode;
    if (status == null) {
      throw const CatalogFailure(
        CatalogFailureKind.invalidData,
        'The server returned an invalid HTTP response.',
      );
    }
    if (!_isSuccessfulStatus(status)) throw _statusFailure(status);

    final body = response.data;
    if (body == null) {
      throw const CatalogFailure(
        CatalogFailureKind.invalidData,
        'The server returned an empty response.',
      );
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      throw const CatalogFailure(
        CatalogFailureKind.invalidData,
        'The server returned unreadable product data.',
      );
    }
    _throwIfCancelled(cancelToken);
    // Parser CatalogFailures propagate unchanged. Unrelated programming errors
    // are not caught and disguised as connection failures.
    final result = parse(decoded);
    _throwIfCancelled(cancelToken);
    return result;
  }

  static Exception _mapDioFailure(DioException error) {
    switch (error.type) {
      case DioExceptionType.cancel:
        return const RequestCancelled();
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const CatalogFailure(
          CatalogFailureKind.timeout,
          'The request timed out. Please try again.',
        );
      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
        return const CatalogFailure(
          CatalogFailureKind.connection,
          'Cannot connect securely. Check your connection and retry.',
        );
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        final status = error.response?.statusCode;
        if (status != null && !_isSuccessfulStatus(status)) {
          return _statusFailure(status);
        }
        // Unknown Dio failures may be transformation/configuration problems,
        // so do not label them as an unverified loss of network connectivity.
        // Never include the transport exception or raw body in diagnostics/UI.
        developer.log(
          'The HTTP client could not produce a usable response.',
          name: 'ProductsApi',
          level: DiagnosticLevel.error,
          stackTrace: error.stackTrace,
        );
        return const CatalogFailure(
          CatalogFailureKind.invalidData,
          'The server response could not be processed. Please retry.',
        );
    }
  }

  static CatalogFailure _statusFailure(int status) => status == _notFoundStatus
      ? const CatalogFailure(
          CatalogFailureKind.notFound,
          'The requested catalog resource could not be found.',
        )
      : const CatalogFailure(
          CatalogFailureKind.server,
          'The server could not complete the request. Please retry.',
        );

  static void _throwIfCancelled(CancelToken? token) {
    if (token?.isCancelled ?? false) throw const RequestCancelled();
  }
}
