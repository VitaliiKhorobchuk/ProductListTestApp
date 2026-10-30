import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'product_image.dart';
import 'rating_badge.dart';

enum ProductCardVariant { standard, compact }

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
  final ProductCardVariant variant;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final displayTitle = title.trim().isEmpty
        ? 'Untitled product'
        : title.trim();
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(tokens.smallRadius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ProductImage(imageUrl: imageUrl, semanticLabel: displayTitle),
          if (_discountPercent case final discount?)
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
      originalPrice: _hasDiscount ? originalPrice : null,
      rating: rating,
      reviewCount: reviewCount,
    );
    final layout = LayoutBuilder(
      builder: (context, constraints) {
        if (_shouldUseStackedLayout(context, constraints)) {
          return _buildStackedLayout(
            tokens: tokens,
            image: image,
            content: content,
          );
        }
        return _buildHorizontalLayout(
          tokens: tokens,
          image: image,
          content: content,
        );
      },
    );
    return Card(
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? layout
          : Semantics(
              button: true,
              child: InkWell(onTap: onTap, child: layout),
            ),
    );
  }

  bool _shouldUseStackedLayout(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    final isCompact = variant == ProductCardVariant.compact;
    final hasNarrowWidth = constraints.maxWidth < 300;
    final hasLargeText = MediaQuery.textScalerOf(context).scale(14) > 21;
    return isCompact || hasNarrowWidth || hasLargeText;
  }

  Widget _buildStackedLayout({
    required AppTokens tokens,
    required Widget image,
    required Widget content,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            tokens.spaceMd,
            tokens.spaceMd,
            tokens.spaceMd,
            0,
          ),
          child: AspectRatio(aspectRatio: 1.5, child: image),
        ),
        Padding(padding: EdgeInsets.all(tokens.spaceLg), child: content),
      ],
    );
  }

  Widget _buildHorizontalLayout({
    required AppTokens tokens,
    required Widget image,
    required Widget content,
  }) {
    return Padding(
      padding: EdgeInsets.all(tokens.spaceLg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 96, height: 112, child: image),
          SizedBox(width: tokens.spaceLg),
          Expanded(child: content),
        ],
      ),
    );
  }

  static bool _validPrice(double? value) =>
      value != null && value.isFinite && value >= 0;

  bool get _hasDiscount =>
      _validPrice(price) &&
      _validPrice(originalPrice) &&
      originalPrice! > price!;

  int? get _discountPercent {
    if (!_hasDiscount) return null;
    final percent = ((1 - price! / originalPrice!) * 100).round();
    return percent > 0 ? percent : null;
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
    final displayCategory = category.trim().isEmpty
        ? 'Uncategorized'
        : category.trim();
    final displayBrand = brand?.trim();
    final currentPrice = price;
    final validPrice = ProductCard._validPrice(currentPrice);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          displayCategory,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: textTheme.labelSmall?.copyWith(color: tokens.onSurfaceDim),
        ),
        SizedBox(height: tokens.spaceXs),
        Text(
          title,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        if (displayBrand != null && displayBrand.isNotEmpty) ...[
          SizedBox(height: tokens.spaceXs),
          Text(
            displayBrand,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(color: tokens.onSurfaceDim),
          ),
        ],
        SizedBox(height: tokens.spaceSm),
        Wrap(
          spacing: tokens.spaceSm,
          runSpacing: tokens.spaceXs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Semantics(
              label: validPrice
                  ? 'Price ${currentPrice!.toStringAsFixed(2)} US dollars'
                  : 'Price unavailable',
              child: ExcludeSemantics(
                child: Text(
                  validPrice
                      ? '\$${currentPrice!.toStringAsFixed(2)} USD'
                      : 'Price unavailable',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            if (originalPrice case final original?)
              Semantics(
                label:
                    'Original price ${original.toStringAsFixed(2)} US dollars',
                child: ExcludeSemantics(
                  child: Text(
                    '\$${original.toStringAsFixed(2)}',
                    style: textTheme.bodySmall?.copyWith(
                      color: tokens.onSurfaceDim,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ),
              ),
          ],
        ),
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
