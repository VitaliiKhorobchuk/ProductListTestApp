import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// A numeric rating whose meaning remains available without its color.
class RatingBadge extends StatelessWidget {
  const RatingBadge({super.key, required this.rating, this.reviewCount});

  final double? rating;
  final int? reviewCount;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final value = rating;
    final valid = value != null && value.isFinite && value >= 0 && value <= 5;
    final color = _ratingColor(valid ? value : null, tokens);
    final text = valid ? _formatRating(value) : 'Not rated';
    final count = reviewCount;
    final hasCount = count != null && count >= 0;
    final label = _ratingLabel(
      ratingText: text,
      hasRating: valid,
      reviewCount: hasCount ? count : null,
    );

    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(tokens.smallRadius),
            border: Border.all(color: color.withValues(alpha: .35)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.spaceSm,
              vertical: tokens.spaceXs,
            ),
            child: Wrap(
              spacing: tokens.spaceXs,
              runSpacing: tokens.spaceXs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Icon(
                  valid ? Icons.star_rounded : Icons.star_border_rounded,
                  color: color,
                  size: 18,
                ),
                Text(
                  text,
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(color: color, fontWeight: FontWeight.w600),
                ),
                if (hasCount)
                  Text(
                    '($count)',
                    style: Theme.of(context).textTheme.labelMedium
                        ?.copyWith(color: tokens.onSurfaceDim),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Selects a color for a validated rating; null represents an unknown rating.
  static Color _ratingColor(double? value, AppTokens tokens) {
    if (value == null) return tokens.onSurfaceDim;
    if (value >= 4) return tokens.ratingGood;
    if (value >= 3) return tokens.ratingAverage;
    return tokens.ratingPoor;
  }

  static String _ratingLabel({
    required String ratingText,
    required bool hasRating,
    int? reviewCount,
  }) {
    final ratingLabel = hasRating ? 'Rated $ratingText out of 5' : 'Not rated';
    if (reviewCount == null) return ratingLabel;

    final reviewWord = reviewCount == 1 ? 'review' : 'reviews';
    return '$ratingLabel, $reviewCount $reviewWord';
  }

  static String _formatRating(double value) {
    final formatted = value.toStringAsFixed(2);
    return formatted.endsWith('0')
        ? formatted.substring(0, formatted.length - 1)
        : formatted;
  }
}
