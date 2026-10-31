import 'package:flutter/material.dart';

import '../../../../design_system/components/product_card.dart';
import '../../../../design_system/theme/app_tokens.dart';
import '../../models/product.dart';

/// Lazy rows allow each card to grow with its content and the user's text size.
class CatalogProductSliver extends StatelessWidget {
  const CatalogProductSliver({
    super.key,
    required this.products,
    required this.variant,
    required this.availableWidth,
  });

  final List<Product> products;
  final ProductCardVariant variant;
  final double availableWidth;

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
    // Detail navigation belongs to a later checkpoint.
  );

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final gap = tokens.spaceLg;
    final contentWidth = availableWidth - tokens.spaceLg * 2;
    final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
    final minimumWidth = tokens.spacing * 20 * textScale.clamp(1, 3);
    final columns = variant == ProductCardVariant.standard
        ? 1
        : ((contentWidth + gap) / (minimumWidth + gap)).floor().clamp(1, 4);
    final rows = (products.length + columns - 1) ~/ columns;
    return SliverPadding(
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
    );
  }
}
