import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Route names, URL syntax and catalog-return behavior have one owner.
abstract final class CatalogNavigation {
  static const catalogPath = '/products';
  static const catalogRoute = 'catalog';
  static const detailRoute = 'product-detail';
  static const idParameter = 'id';
  static const detailPath = ':$idParameter';
  static final _decimalId = RegExp(r'^-?[0-9]+$');

  /// Parses URL syntax only. Numeric validity belongs to ProductsRepository.
  static int? parseProductId(String? segment) =>
      segment != null && _decimalId.hasMatch(segment)
      ? int.tryParse(segment)
      : null;

  static void openProduct(BuildContext context, int id) {
    context.goNamed(detailRoute, pathParameters: {idParameter: '$id'});
  }

  static void browseProducts(BuildContext context) =>
      context.goNamed(catalogRoute);

  static void backToCatalog(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(catalogRoute);
    }
  }
}
