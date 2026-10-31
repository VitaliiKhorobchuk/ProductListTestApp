import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/widgets/catalog_detail_app_bar.dart';
import '../../../../core/catalog_failure.dart';
import '../../../../design_system/components/empty_state.dart';
import '../../../../design_system/components/error_state.dart';
import '../../../../design_system/theme/app_tokens.dart';
import '../cubit/product_detail_cubit.dart';
import '../widgets/product_detail_content.dart';

/// Displays route-owned detail state without coupling the feature to routing.
class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({
    super.key,
    required this.onBack,
    required this.onBrowseProducts,
  });

  final VoidCallback onBack;
  final VoidCallback onBrowseProducts;

  Widget _status(Widget child) => Semantics(liveRegion: true, child: child);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: CatalogDetailAppBar(
      title: 'Product details',
      onBack: onBack,
      onClearSelection: onBrowseProducts,
    ),
    body: SafeArea(
      child: BlocBuilder<ProductDetailCubit, ProductDetailState>(
        builder: (context, state) {
          switch (state.status) {
            case ProductDetailStatus.initial:
              final canRetry = state.productId != null;
              return _status(
                EmptyState(
                  title: 'Ready to load this product',
                  message: canRetry
                      ? 'Load the product details when you are ready.'
                      : 'Choose a product from the catalog to see its details.',
                  actionLabel: canRetry ? 'Load product' : 'Browse products',
                  onAction: canRetry
                      ? () => context.read<ProductDetailCubit>().retry()
                      : onBrowseProducts,
                ),
              );
            case ProductDetailStatus.loading:
              return Semantics(
                container: true,
                liveRegion: true,
                label: 'Loading product details',
                child: ExcludeSemantics(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(context.tokens.spaceXl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          SizedBox(height: context.tokens.spaceLg),
                          const Text('Loading product details…'),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            case ProductDetailStatus.error:
              if (state.failure?.kind == CatalogFailureKind.notFound) {
                return _status(
                  EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'Product not found',
                    message: state.failure?.message ?? 'This product is no longer available. Choose another product from the catalog.',
                    actionLabel: 'Browse products',
                    onAction: onBrowseProducts,
                  ),
                );
              }
              return _status(
                ErrorState(
                  title: state.failure?.kind == CatalogFailureKind.invalidData
                      ? 'Product information unavailable'
                      : 'Could not load this product',
                  message: state.failure?.message ?? 'Please try again.',
                  actionLabel: 'Retry product',
                  onAction: () => context.read<ProductDetailCubit>().retry(),
                ),
              );
            case ProductDetailStatus.loaded:
              final product = state.product;
              if (product == null) {
                return _status(
                  ErrorState(
                    title: 'Product information unavailable',
                    message: 'The product details could not be displayed. Please try again.',
                    actionLabel: 'Retry product',
                    onAction: () => context.read<ProductDetailCubit>().retry(),
                  ),
                );
              }
              return ProductDetailContent(
                key: ValueKey(product.id),
                product: product,
              );
          }
        },
      ),
    ),
  );
}
