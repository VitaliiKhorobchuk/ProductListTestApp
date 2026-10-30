import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../debug/debug_routes.dart';
import '../features/catalog/presentation/screens/catalog_screen.dart';

GoRouter createRouter() {
  return GoRouter(
    routes: [
      if (kDebugMode) ...createDebugRoutes(),
      GoRoute(path: '/', redirect: (context, state) => '/products'),
      GoRoute(
        path: '/products',
        name: 'catalog',
        builder: (context, state) => const CatalogScreen(),
      ),
    ],
  );
}
