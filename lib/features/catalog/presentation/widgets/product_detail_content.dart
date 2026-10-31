import 'package:flutter/material.dart';

import '../../../../design_system/components/product_price.dart';
import '../../../../design_system/components/rating_badge.dart';
import '../../../../design_system/theme/app_tokens.dart';
import '../../models/product.dart';
import '../product_presentation.dart';
import 'product_gallery.dart';

/// A phone-first reading layout that also stays comfortable on a wide viewport.
class ProductDetailContent extends StatelessWidget {
  const ProductDetailContent({super.key, required this.product});

  static const _maximumContentWidth = 720.0;
  static const _descriptionLineHeight = 1.6;
  final Product product;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maximumContentWidth),
          child: Padding(
            padding: EdgeInsets.all(tokens.spaceLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProductGallery(
                  productId: product.id,
                  productTitle: product.displayTitle,
                  images: product.galleryImages,
                ),
                SizedBox(height: tokens.spaceXl),
                Wrap(
                  spacing: tokens.spaceMd,
                  runSpacing: tokens.spaceSm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: tokens.surfaceVariant,
                        borderRadius: BorderRadius.circular(tokens.smallRadius),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: tokens.spaceMd,
                          vertical: tokens.spaceSm,
                        ),
                        child: Text(
                          product.displayCategory,
                          style: textTheme.labelMedium?.copyWith(
                            color: tokens.onSurface,
                          ),
                        ),
                      ),
                    ),
                    RatingBadge(
                      rating: product.rating,
                      reviewCount: product.reviewCount,
                    ),
                  ],
                ),
                SizedBox(height: tokens.spaceLg),
                Semantics(
                  header: true,
                  liveRegion: true,
                  child: Text(
                    product.displayTitle,
                    style: textTheme.headlineMedium?.copyWith(
                      color: tokens.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: tokens.spaceSm),
                Text(
                  'Brand: ${product.displayBrand}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: tokens.onSurfaceDim,
                  ),
                ),
                SizedBox(height: tokens.spaceXl),
                ProductPrice(
                  price: product.discountedPrice,
                  originalPrice: product.price,
                ),
                SizedBox(height: tokens.spaceXs),
                Text(
                  'Prices in USD',
                  style: textTheme.bodySmall?.copyWith(
                    color: tokens.onSurfaceDim,
                  ),
                ),
                SizedBox(height: tokens.spaceLg),
                _ProductAvailability(stock: product.stock),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: tokens.spaceXl),
                  child: const Divider(),
                ),
                Semantics(
                  header: true,
                  child: Text(
                    'Description',
                    style: textTheme.titleMedium?.copyWith(
                      color: tokens.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: tokens.spaceSm),
                Text(
                  product.displayDescription,
                  style: textTheme.bodyLarge?.copyWith(
                    color: tokens.onSurfaceDim,
                    height: _descriptionLineHeight,
                  ),
                ),
                SizedBox(height: tokens.spaceXl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductAvailability extends StatelessWidget {
  const _ProductAvailability({required this.stock});

  static const _iconSize = 20.0;
  final int? stock;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final value = stock;
    final isKnown = value != null && value >= 0;
    final isInStock = isKnown && value > 0;
    final label = !isKnown
        ? 'Availability unknown'
        : isInStock
        ? 'In stock · $value available'
        : 'Out of stock';
    final color = !isKnown
        ? tokens.onSurfaceDim
        : isInStock
        ? tokens.ratingGood
        : tokens.ratingPoor;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Icon(
            !isKnown
                ? Icons.help_outline
                : isInStock
                ? Icons.check_circle_outline
                : Icons.remove_circle_outline,
            size: _iconSize,
            color: color,
          ),
        ),
        SizedBox(width: tokens.spaceSm),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
