import '../../../core/catalog_failure.dart';
import '../../../core/request_control.dart';
import '../models/catalog_pagination.dart';
import '../models/catalog_query.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/product_page.dart';

abstract class ProductsRepository {
  Future<ProductPage> getProducts({
    required CatalogQuery query,
    int skip = 0,
    int limit = CatalogPagination.pageSize,
    RequestControl? control,
  });

  Future<List<Category>> getCategories({RequestControl? control});

  /// Looks up a positive JavaScript-safe integer ID (1..9007199254740991).
  ///
  /// Implementations must reject invalid IDs with [CatalogFailure] of kind
  /// [CatalogFailureKind.invalidData] before HTTP, fixture access or simulated
  /// delay. Check an already-cancelled [control] first, yielding
  /// [RequestCancelled]. A valid but missing ID yields
  /// [CatalogFailureKind.notFound].
  Future<Product> getProduct(int id, {RequestControl? control});
}
