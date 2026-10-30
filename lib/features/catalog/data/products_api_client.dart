import 'package:dio/dio.dart';

/// Creates the catalog's HTTP client with the agreed transport defaults.
///
/// The composition root will own and close this client when the remote
/// repository is connected. ProductsApi borrows it and never closes it.
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
