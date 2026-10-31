import 'package:dio/dio.dart';

import 'products_api_config.dart';

/// Creates the catalog's HTTP client with the agreed transport defaults.
///
/// The composition root that creates this client owns and closes it.
/// ProductsApi and RemoteProductsRepository borrow it and never close it.
/// Connection/receive timeouts do not replace the repository's overall
/// logical-operation deadline.
Dio createProductsDio() => Dio(
  BaseOptions(
    baseUrl: ProductsApiConfig.baseUrl,
    connectTimeout: ProductsApiConfig.connectTimeout,
    receiveTimeout: ProductsApiConfig.receiveTimeout,
    headers: ProductsApiConfig.headers,
  ),
);
