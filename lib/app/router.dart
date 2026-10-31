import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../debug/debug_routes.dart';
import '../features/catalog/presentation/screens/product_detail_route.dart';
import 'adaptive/catalog_selection_prompt.dart';
import 'adaptive/catalog_shell.dart';
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
      ShellRoute(
        builder: (context, state, child) => CatalogShell(
          detailActive: state.pathParameters.containsKey(
            CatalogNavigation.idParameter,
          ),
          selectedProductId: CatalogNavigation.parseProductId(
            state.pathParameters[CatalogNavigation.idParameter],
          ),
          child: child,
        ),
        routes: [
          // The shell switches pane visibility immediately. Zero-duration child
          // pages let removed routes dispose even when their Navigator is muted.
          GoRoute(
            path: CatalogNavigation.catalogPath,
            name: CatalogNavigation.catalogRoute,
            pageBuilder: (context, state) => NoTransitionPage<void>(
              key: state.pageKey,
              child: const CatalogSelectionPrompt(),
            ),
            routes: [
              GoRoute(
                path: CatalogNavigation.detailPath,
                name: CatalogNavigation.detailRoute,
                pageBuilder: (context, state) {
                  final id = CatalogNavigation.parseProductId(
                    state.pathParameters[CatalogNavigation.idParameter],
                  );
                  return NoTransitionPage<void>(
                    key: state.pageKey,
                    child: id == null
                        ? const NavigationErrorScreen(
                            title: 'Invalid product link',
                            message: 'This product link is invalid. Choose a product from the catalog.',
                          )
                        : ProductDetailRoute(key: ValueKey(id), productId: id),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
