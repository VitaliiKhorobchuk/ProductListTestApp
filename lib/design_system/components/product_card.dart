import 'package:flutter/material.dart';

import '../../../core/product_labels.dart';
import '../../../core/product_pricing.dart';
import '../theme/app_tokens.dart';
import 'product_card_layout.dart';
import 'product_image.dart';
import 'product_price.dart';
import 'rating_badge.dart';

export 'product_card_layout.dart' show ProductCardVariant;

/// A display-only product summary. Prices are already calculated by the caller.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.title,
    required this.category,
    this.brand,
    this.imageUrl,
    this.price,
    this.originalPrice,
    this.rating,
    this.reviewCount,
    this.onTap,
    this.selected = false,
    this.variant = ProductCardVariant.standard,
  });

  final String title;
  final String category;
  final String? brand;
  final String? imageUrl;

  /// Current/displayed USD amount, including any applicable discount.
  final double? price;

  /// Shown struck through only when valid and greater than the current price.
  final double? originalPrice;
  final double? rating;
  final int? reviewCount;
  final VoidCallback? onTap;

  /// Indicates the current master-detail selection without changing the surface.
  final bool selected;
  final ProductCardVariant variant;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final displayTitle = ProductLabels.title(title);
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(tokens.smallRadius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ProductImage(imageUrl: imageUrl, semanticLabel: displayTitle),
          if (ProductPricing.discountPercent(price, originalPrice)
              case final discount?)
            PositionedDirectional(
              top: tokens.spaceXs,
              start: tokens.spaceXs,
              child: _DiscountLabel(percent: discount),
            ),
        ],
      ),
    );
    final content = _ProductContent(
      title: displayTitle,
      category: category,
      brand: brand,
      price: price,
      originalPrice: originalPrice,
      rating: rating,
      reviewCount: reviewCount,
    );
    final layout = ProductCardLayout(
      variant: variant,
      image: image,
      content: content,
    );
    final interaction = onTap == null
        ? layout
        : InkWell(onTap: onTap, child: layout);
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: selected
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(tokens.radius),
              side: BorderSide(
                color: tokens.primary,
                width: tokens.emphasizedBorderWidth,
              ),
            )
          : null,
      child: onTap != null || selected
          ? Semantics(
              button: onTap != null ? true : null,
              selected: selected ? true : null,
              child: interaction,
            )
          : interaction,
    );
  }
}

class _ProductContent extends StatelessWidget {
  const _ProductContent({
    required this.title,
    required this.category,
    required this.brand,
    required this.price,
    required this.originalPrice,
    required this.rating,
    required this.reviewCount,
  });

  static const _metadataMaxLines = 2;
  static const _titleMaxLines = 3;

  final String title;
  final String category;
  final String? brand;
  final double? price;
  final double? originalPrice;
  final double? rating;
  final int? reviewCount;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    final displayCategory = ProductLabels.category(category);
    final displayBrand = ProductLabels.optionalBrand(brand);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          displayCategory,
          maxLines: _metadataMaxLines,
          overflow: TextOverflow.ellipsis,
          style: textTheme.labelSmall?.copyWith(color: tokens.onSurfaceDim),
        ),
        SizedBox(height: tokens.spaceXs),
        Text(
          title,
          maxLines: _titleMaxLines,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        if (displayBrand != null) ...[
          SizedBox(height: tokens.spaceXs),
          Text(
            displayBrand,
            maxLines: _metadataMaxLines,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(color: tokens.onSurfaceDim),
          ),
        ],
        SizedBox(height: tokens.spaceSm),
        ProductPrice(price: price, originalPrice: originalPrice),
        SizedBox(height: tokens.spaceSm),
        RatingBadge(rating: rating, reviewCount: reviewCount),
      ],
    );
  }
}

class _DiscountLabel extends StatelessWidget {
  const _DiscountLabel({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Semantics(
      label: '$percent percent off',
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tokens.primary,
            borderRadius: BorderRadius.circular(tokens.smallRadius),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.spaceXs,
              vertical: tokens.spaceXs,
            ),
            child: Text(
              '-$percent%',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
