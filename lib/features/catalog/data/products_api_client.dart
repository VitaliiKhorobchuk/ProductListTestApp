import 'package:dio/dio.dart';

/// Creates the catalog's HTTP client with the agreed transport defaults.
///
/// The composition root that creates this client owns and closes it.
/// ProductsApi and RemoteProductsRepository borrow it and never close it.
/// Connection/receive timeouts do not replace the repository's overall
/// logical-operation deadline.
Dio createProductsDio() => Dio(
  BaseOptions(
    baseUrl: 'https://dummyjson.com',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: const {'Accept': 'application/json'},
  ),
);
