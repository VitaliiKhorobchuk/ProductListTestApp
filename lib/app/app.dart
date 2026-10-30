import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../features/catalog/data/products_repository.dart';
import '../features/catalog/data/sample_products_repository.dart';
import '../features/catalog/presentation/cubit/catalog_cubit.dart';
import 'router.dart';

class ProductListTestApp extends StatefulWidget {
  const ProductListTestApp({super.key, this.repository});

  /// Override at startup to swap the data source without changing the ViewModel.
  final ProductsRepository? repository;

  @override
  State<ProductListTestApp> createState() => _ProductListTestAppState();
}

class _ProductListTestAppState extends State<ProductListTestApp> {
  late final GoRouter _router;
  late final ProductsRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository =
        widget.repository ?? SampleProductsRepository.fromEnvironment();
    _router = createRouter();
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<ProductsRepository>.value(
      value: _repository,
      child: BlocProvider(
        create: (context) =>
            CatalogCubit(context.read<ProductsRepository>())..load(),
        child: MaterialApp.router(
          title: 'ProductListTestApp',
          debugShowCheckedModeBanner: false,
          routerConfig: _router,
        ),
      ),
    );
  }
}
