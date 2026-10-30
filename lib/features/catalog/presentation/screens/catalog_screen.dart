import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/theme_cubit.dart';
import '../../../../debug/debug_showcase_button.dart';
import '../../../../design_system/components/empty_state.dart';
import '../../../../design_system/components/error_state.dart';
import '../../../../design_system/components/product_card.dart';
import '../../../../design_system/theme/app_tokens.dart';
import '../../models/product.dart';
import '../cubit/catalog_cubit.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  ProductCardVariant _variant = ProductCardVariant.standard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          if (kDebugMode) const DebugShowcaseButton(),
          IconButton(
            tooltip: _variant == ProductCardVariant.standard
                ? 'Show grid view'
                : 'Show list view',
            onPressed: () => setState(() {
              _variant = _variant == ProductCardVariant.standard
                  ? ProductCardVariant.compact
                  : ProductCardVariant.standard;
            }),
            icon: Icon(
              _variant == ProductCardVariant.standard
                  ? Icons.grid_view_outlined
                  : Icons.view_list_outlined,
            ),
          ),
          IconButton(
            tooltip: isDark ? 'Switch to light theme' : 'Switch to dark theme',
            onPressed: () => context.read<ThemeCubit>().toggle(
              systemBrightness: MediaQuery.platformBrightnessOf(context),
            ),
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
          ),
          IconButton(
            tooltip: 'Reload products',
            onPressed: () => context.read<CatalogCubit>().load(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<CatalogCubit, CatalogState>(
          builder: (context, state) {
            switch (state.status) {
              case CatalogStatus.initial:
              case CatalogStatus.loading:
                return const Center(
                  child: CircularProgressIndicator(
                    semanticsLabel: 'Loading products',
                  ),
                );
              case CatalogStatus.loaded:
                return _CatalogProducts(
                  products: state.products,
                  variant: _variant,
                );
              case CatalogStatus.empty:
                return const EmptyState(
                  title: 'No products yet',
                  message: 'There are no products in this example catalog.',
                );
              case CatalogStatus.error:
                return ErrorState(
                  title: 'Could not load products',
                  message: state.failure?.message ?? 'Please try again.',
                  actionLabel: 'Retry',
                  onAction: () => context.read<CatalogCubit>().retry(),
                );
            }
          },
        ),
      ),
    );
  }
}

/// Lays out display-only cards; the Cubit still owns the loaded product data.
class _CatalogProducts extends StatelessWidget {
  const _CatalogProducts({required this.products, required this.variant});

  final List<Product> products;
  final ProductCardVariant variant;

  Widget _card(Product product) => ProductCard(
    key: ValueKey(product.id),
    title: product.title,
    brand: product.brand,
    category: product.category.replaceAll('-', ' '),
    imageUrl: product.thumbnail,
    price: product.discountedPrice,
    originalPrice: product.price,
    rating: product.rating,
    reviewCount: product.reviewCount,
    variant: variant,
    // Detail navigation will supply onTap in its own checkpoint.
  );

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = tokens.spaceLg;
        final contentWidth = constraints.maxWidth - tokens.spaceLg * 2;
        final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
        final minimumWidth = tokens.spacing * 20 * textScale.clamp(1, 3);
        final columns = variant == ProductCardVariant.standard
            ? 1
            : ((contentWidth + gap) / (minimumWidth + gap)).floor().clamp(1, 4);
        final rows = (products.length + columns - 1) ~/ columns;
        return CustomScrollView(
          key: PageStorageKey<String>('sample-catalog-${variant.name}'),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.all(tokens.spaceLg),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Example catalog · ${products.length} products · offline data',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: tokens.onSurface),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                tokens.spaceLg,
                0,
                tokens.spaceLg,
                tokens.spaceLg,
              ),
              sliver: SliverList.separated(
                itemCount: rows,
                separatorBuilder: (context, index) => SizedBox(height: gap),
                itemBuilder: (context, row) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var column = 0; column < columns; column++) ...[
                      if (column > 0) SizedBox(width: gap),
                      Expanded(
                        child: row * columns + column < products.length
                            ? _card(products[row * columns + column])
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
