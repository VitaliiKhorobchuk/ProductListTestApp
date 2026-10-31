import 'package:flutter/material.dart';

import '../../../../design_system/components/product_card_layout.dart';
import '../../../../design_system/theme/app_tokens.dart';
import 'catalog_rows_sliver.dart';

/// Static, decorative placeholders for a fresh result set, never pagination.
class CatalogLoadingSliver extends StatelessWidget {
  const CatalogLoadingSliver({
    super.key,
    required this.variant,
    required this.availableWidth,
  });

  static const _placeholderCount = 6;
  final ProductCardVariant variant;
  final double availableWidth;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Semantics(
            container: true,
            liveRegion: true,
            label: 'Loading products',
            child: ExcludeSemantics(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  tokens.spaceLg,
                  0,
                  tokens.spaceLg,
                  tokens.spaceLg,
                ),
                child: Text(
                  'Loading products…',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: tokens.onSurfaceDim),
                ),
              ),
            ),
          ),
        ),
        CatalogRowsSliver(
          itemCount: _placeholderCount,
          variant: variant,
          availableWidth: availableWidth,
          // These are not real products or announced list positions/counts.
          addSemanticIndexes: false,
          itemBuilder: (context, index) => _LoadingCard(variant: variant),
        ),
      ],
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.variant});
  final ProductCardVariant variant;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return ExcludeSemantics(
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ProductCardLayout(
          variant: variant,
          image: DecoratedBox(
            decoration: BoxDecoration(
              color: tokens.surfaceVariant,
              borderRadius: BorderRadius.circular(tokens.smallRadius),
            ),
          ),
          content: const _LoadingContent(),
        ),
      ),
    );
  }
}

class _LoadingContent extends StatelessWidget {
  const _LoadingContent();

  static const _categoryWidth = .4;
  static const _titleWidth = .85;
  static const _brandWidth = .55;
  static const _priceWidth = .5;
  static const _ratingWidth = .3;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LoadingBar(widthFactor: _categoryWidth, style: textTheme.labelSmall!),
        SizedBox(height: tokens.spaceXs),
        _LoadingBar(widthFactor: _titleWidth, style: textTheme.titleMedium!),
        SizedBox(height: tokens.spaceXs),
        _LoadingBar(widthFactor: _brandWidth, style: textTheme.bodySmall!),
        SizedBox(height: tokens.spaceSm),
        _LoadingBar(widthFactor: _priceWidth, style: textTheme.titleMedium!),
        SizedBox(height: tokens.spaceSm),
        _LoadingBar(widthFactor: _ratingWidth, style: textTheme.labelMedium!),
      ],
    );
  }
}

class _LoadingBar extends StatelessWidget {
  const _LoadingBar({required this.widthFactor, required this.style});

  static const _defaultLineHeight = 1.2;
  static const _barTintOpacity = .16;
  final double widthFactor;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final height =
        MediaQuery.textScalerOf(context).scale(style.fontSize!) *
        (style.height ?? _defaultLineHeight);
    final color = Color.alphaBlend(
      tokens.onSurfaceDim.withValues(alpha: _barTintOpacity),
      tokens.surfaceVariant,
    );
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: AlignmentDirectional.centerStart,
      child: SizedBox(
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(tokens.smallRadius),
          ),
        ),
      ),
    );
  }
}
