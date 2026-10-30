import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/catalog_cubit.dart';
import '../widgets/sample_product_tile.dart';

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
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
                return const Center(child: CircularProgressIndicator());
              case CatalogStatus.loaded:
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.products.length + 1,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Example catalog · ${state.products.length} products · offline data',
                          style: Theme.of(context).textTheme.bodySmall,
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
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
