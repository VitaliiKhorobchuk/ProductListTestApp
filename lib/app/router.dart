import 'package:flutter/foundation.dart';

import 'package:go_router/go_router.dart';

import '../debug/debug_routes.dart';
import '../features/catalog/presentation/screens/catalog_screen.dart';
import '../features/catalog/presentation/screens/product_detail_route.dart';
import 'catalog_navigation.dart';
import 'navigation_error_screen.dart';

GoRouter createRouter() {
  return GoRouter(
    errorBuilder: (context, state) => const NavigationErrorScreen(),
    routes: [
      if (kDebugMode) ...createDebugRoutes(),
      GoRoute(
        path: '/',
        redirect: (context, state) => CatalogNavigation.catalogPath,
      ),
      GoRoute(
        path: CatalogNavigation.catalogPath,
        name: CatalogNavigation.catalogRoute,
        builder: (context, state) => const CatalogScreen(),
        routes: [
          GoRoute(
            path: CatalogNavigation.detailPath,
            name: CatalogNavigation.detailRoute,
            builder: (context, state) {
              final id = CatalogNavigation.parseProductId(
                state.pathParameters[CatalogNavigation.idParameter],
              );
              if (id == null) {
                return const NavigationErrorScreen(
                  title: 'Invalid product link',
                  message: 'This product link is invalid. Choose a product from the catalog.',
                );
              }
              return ProductDetailRoute(key: ValueKey(id), productId: id);
            },
          ),
        ],
      ),
    ],
  );
}
