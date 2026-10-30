import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/theme_cubit.dart';
import '../../../../design_system/theme/app_tokens.dart';
import '../cubit/catalog_cubit.dart';
import '../widgets/sample_product_tile.dart';

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
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
                return ListView.separated(
                  key: const PageStorageKey<String>('sample-catalog-scroll'),
                  padding: EdgeInsets.all(tokens.spaceLg),
                  itemCount: state.products.length + 1,
                  separatorBuilder: (context, index) =>
                      SizedBox(height: tokens.spaceSm),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: tokens.spaceSm),
                        child: Text(
                          'Example catalog · ${state.products.length} products · offline data',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: tokens.onSurface,
                          ),
                        ),
                      );
                    }
                    final product = state.products[index - 1];
                    return SampleProductTile(
                      key: ValueKey(product.id),
                      product: product,
                    );
                  },
                );
              case CatalogStatus.empty:
                return const _CatalogMessage(
                  icon: Icons.inventory_2_outlined,
                  title: 'No products yet',
                  message: 'There are no products in this example catalog.',
                );
              case CatalogStatus.error:
                return _CatalogMessage(
                  icon: Icons.cloud_off_outlined,
                  title: 'Could not load products',
                  message: state.failure?.message ?? 'Please try again.',
                  onRetry: () => context.read<CatalogCubit>().retry(),
                );
            }
          },
        ),
      ),
    );
  }
}

class _CatalogMessage extends StatelessWidget {
  const _CatalogMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(tokens.spaceXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: onRetry == null ? tokens.primary : theme.colorScheme.error,
            ),
            SizedBox(height: tokens.spaceLg),
            Text(
              title,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: tokens.spaceSm),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tokens.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              SizedBox(height: tokens.spaceLg),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
