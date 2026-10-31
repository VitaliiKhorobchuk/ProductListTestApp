import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/catalog_navigation.dart';
import '../../data/products_repository.dart';
import '../cubit/product_detail_cubit.dart';
import 'product_detail_screen.dart';

/// The route owns this Cubit; the app-owned repository/catalog remain alive.
class ProductDetailRoute extends StatelessWidget {
  const ProductDetailRoute({super.key, required this.productId});
  final int productId;
  @override
  Widget build(BuildContext context) => BlocProvider(
    key: ValueKey(productId),
    create: (context) =>
        ProductDetailCubit(context.read<ProductsRepository>())..load(productId),
    child: ProductDetailScreen(
      onBack: () => CatalogNavigation.backToCatalog(context),
      onBrowseProducts: () => CatalogNavigation.browseProducts(context),
    ),
  );
}
