import 'package:go_router/go_router.dart';

import '../features/catalog/presentation/screens/catalog_screen.dart';

GoRouter createRouter() {
  return GoRouter(
    routes: [
      GoRoute(path: '/', redirect: (context, state) => '/products'),
      GoRoute(
        path: '/products',
        name: 'catalog',
        builder: (context, state) => const CatalogScreen(),
      ),
    ],
  );
}
