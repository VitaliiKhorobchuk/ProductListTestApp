import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../design_system/theme/app_theme.dart';
import '../features/catalog/data/products_api.dart';
import '../features/catalog/data/products_api_client.dart';
import '../features/catalog/data/products_repository.dart';
import '../features/catalog/data/remote_products_repository.dart';
import '../features/catalog/presentation/cubit/catalog_cubit.dart';
import '../features/catalog/presentation/cubit/categories_cubit.dart';
import 'router.dart';
import 'theme/theme_cubit.dart';

class ProductListTestApp extends StatefulWidget {
  const ProductListTestApp({super.key, this.repository});

  /// Optional startup-only data source override, owned by the caller.
  ///
  /// Without an override the app owns a remote HTTP client. Changing this value
  /// after mounting does not replace the active repository or its client.
  final ProductsRepository? repository;

  @override
  State<ProductListTestApp> createState() => _ProductListTestAppState();
}

class _ProductListTestAppState extends State<ProductListTestApp> {
  late final GoRouter _router;
  late final ProductsRepository _repository;
  late final Dio? _ownedDio;

  @override
  void initState() {
    super.initState();
    final repository = widget.repository;
    if (repository != null) {
      _ownedDio = null;
      _repository = repository;
    } else {
      final dio = createProductsDio();
      _ownedDio = dio;
      _repository = RemoteProductsRepository(ProductsApi(dio));
    }
    _router = createRouter();
  }

  @override
  void dispose() {
    _router.dispose();
    _ownedDio?.close(force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<ProductsRepository>.value(
      value: _repository,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => ThemeCubit()),
          // Lazy: fetch metadata when the catalog first consumes category state.
          BlocProvider(
            create: (context) =>
                CategoriesCubit(context.read<ProductsRepository>())..load(),
          ),
          BlocProvider(
            create: (context) =>
                CatalogCubit(context.read<ProductsRepository>())..load(),
          ),
        ],
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, mode) => MaterialApp.router(
            title: 'ProductListTestApp',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: mode,
            routerConfig: _router,
          ),
        ),
      ),
    );
  }
}
