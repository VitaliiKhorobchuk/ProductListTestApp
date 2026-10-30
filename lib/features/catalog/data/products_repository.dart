import '../../../core/request_control.dart';
import '../models/catalog_query.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/product_page.dart';

abstract class ProductsRepository {
  Future<ProductPage> getProducts({
    required CatalogQuery query,
    int skip = 0,
    int limit = 20,
    RequestControl? control,
  });

  Future<List<Category>> getCategories({RequestControl? control});

  Future<Product> getProduct(int id, {RequestControl? control});
}
