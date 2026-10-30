import 'package:flutter/material.dart';

import '../../../../design_system/theme/app_tokens.dart';
import '../../models/product.dart';

/// Basic sample presentation; the design-system ProductCard comes later.
class SampleProductTile extends StatelessWidget {
  const SampleProductTile({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    final amount = product.discountedPrice;
    return Card(
      color: tokens.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radius),
        side: BorderSide(color: tokens.border),
      ),
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceLg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: tokens.surfaceVariant,
              foregroundColor: tokens.primary,
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            SizedBox(width: tokens.spaceLg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: textTheme.titleMedium?.copyWith(
                      color: tokens.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: tokens.spaceXs),
                  Text(
                    '${product.brand} · ${product.category.replaceAll('-', ' ')}',
                    style: textTheme.bodySmall?.copyWith(
                      color: tokens.onSurfaceDim,
                    ),
                  ),
                  SizedBox(height: tokens.spaceSm),
                  Text(
                    amount == null
                        ? 'Price unavailable'
                        : '\$${amount.toStringAsFixed(2)} USD',
                    style: textTheme.bodyMedium?.copyWith(
                      color: tokens.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
