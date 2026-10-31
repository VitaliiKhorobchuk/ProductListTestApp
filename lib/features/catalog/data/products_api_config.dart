/// Transport defaults and the budget for a complete repository operation.
abstract final class ProductsApiConfig {
  static const baseUrl = 'https://dummyjson.com';
  static const connectTimeout = Duration(seconds: 10);
  static const receiveTimeout = Duration(seconds: 15);
  static const operationTimeout = Duration(seconds: 30);
  static const headers = {'Accept': 'application/json'};
}

/// HTTP paths are independent of similarly named application routes.
abstract final class ProductsEndpoints {
  static const products = '/products';
  static const search = '$products/search';
  static const categories = '$products/categories';

  static String category(String slug) =>
      '$products/category/${Uri.encodeComponent(slug)}';
  static String product(int id) => '$products/$id';
}
