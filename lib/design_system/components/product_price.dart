import 'package:flutter/material.dart';

import '../../../core/product_pricing.dart';
import '../theme/app_tokens.dart';

/// Display-only current/original USD prices shared by cards and details.
class ProductPrice extends StatelessWidget {
  const ProductPrice({super.key, required this.price, this.originalPrice});
  final double? price;
  final double? originalPrice;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    return Wrap(
      spacing: tokens.spaceSm,
      runSpacing: tokens.spaceXs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Semantics(
          label: ProductPricing.semanticPrice(price),
          child: ExcludeSemantics(
            child: Text(
              ProductPricing.display(price),
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        if (ProductPricing.hasDiscount(price, originalPrice))
          Semantics(
            label: ProductPricing.semanticOriginal(originalPrice!),
            child: ExcludeSemantics(
              child: Text(
                ProductPricing.amount(originalPrice!),
                style: textTheme.bodySmall?.copyWith(
                  color: tokens.onSurfaceDim,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
