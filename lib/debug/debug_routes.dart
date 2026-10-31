import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'component_showcase/showcase_detail_screen.dart';
import 'component_showcase/showcase_index_screen.dart';
import 'showcase_navigation.dart';

List<RouteBase> createDebugRoutes() {
  if (!kDebugMode) return const [];
  return [
    GoRoute(
      path: ShowcaseNavigation.path,
      name: ShowcaseNavigation.indexRoute,
      builder: (context, state) => const ShowcaseIndexScreen(),
      routes: [
        GoRoute(
          path: ShowcaseNavigation.detailPath,
          name: ShowcaseNavigation.detailRoute,
          builder: (context, state) => ShowcaseDetailScreen(
            componentId:
                state.pathParameters[ShowcaseNavigation.componentIdParameter] ??
                '',
          ),
        ),
      ],
    ),
  ];
}
