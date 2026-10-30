import 'package:flutter/material.dart';

import '../../design_system/components/empty_state.dart';
import '../../design_system/components/error_state.dart';
import '../../design_system/components/product_card.dart';
import '../../design_system/components/product_image.dart';
import '../../design_system/components/rating_badge.dart';
import '../../design_system/components/state_message.dart';
import '../../design_system/theme/app_tokens.dart';
import 'category_chip_examples.dart';
import 'loading_image_preview.dart';
import 'showcase_models.dart';
import 'search_field_examples.dart';

const _sampleImage = 'assets/images/sample_products/red_lipstick.webp';
const _missingImage =
    'assets/images/sample_products/missing_preview_image.webp';

final showcaseComponents = <ShowcaseComponent>[
  ShowcaseComponent(
    id: 'category-chip',
    title: 'CategoryChip',
    description: 'Controlled selection, disabled states, long labels and a single-selection group.',
    icon: Icons.category_outlined,
    examples: buildCategoryChipExamples(),
  ),
  ShowcaseComponent(
    id: 'search-field',
    title: 'ProductSearchField',
    description:
        'Search typing, submission, clear, focus and lifecycle states.',
    icon: Icons.search,
    examples: buildSearchFieldExamples(),
  ),
  ShowcaseComponent(
    id: 'product-card',
    title: 'ProductCard',
    description:
        'Standard and compact cards, prices, images, ratings and actions.',
    icon: Icons.view_agenda_outlined,
    examples: _productExamples(),
  ),
  ShowcaseComponent(
    id: 'rating-badge',
    title: 'RatingBadge',
    description: 'Rating colors, boundaries, review counts and unknown values.',
    icon: Icons.star_outline,
    examples: _ratingExamples(),
  ),
  ShowcaseComponent(
    id: 'product-image',
    title: 'ProductImage',
    description: 'Loaded, loading, missing, invalid and failed images.',
    icon: Icons.image_outlined,
    examples: [
      ShowcaseExample(
        title: 'Loaded image',
        description:
            'A bundled product image; no external image service is used.',
        height: 160,
        builder: (_) => const ProductImage(
          imageUrl: _sampleImage,
          semanticLabel: 'Red lipstick',
        ),
      ),
      ShowcaseExample(
        title: 'Loading image',
        description: 'The debug asset bundle holds the real image pending until this preview is removed.',
        height: 160,
        builder: (_) => const LoadingImagePreview(),
      ),
      for (final source in <String?>[
        null,
        '',
        'unsupported://image',
        _missingImage,
      ])
        ShowcaseExample(
          title: _imageStateTitle(source),
          description: 'The component keeps its image slot and shows its unavailable fallback.',
          height: 160,
          builder: (_) => ProductImage(
            imageUrl: source,
            semanticLabel: 'Unavailable sample product',
          ),
        ),
    ],
  ),
  ShowcaseComponent(
    id: 'error-state',
    title: 'ErrorState',
    description:
        'Full-area and inline errors, optional actions and long messages.',
    icon: Icons.cloud_off_outlined,
    examples: _errorExamples(),
  ),
  ShowcaseComponent(
    id: 'empty-state',
    title: 'EmptyState',
    description: 'No data, no results, optional actions and custom icons.',
    icon: Icons.inventory_2_outlined,
    examples: _emptyExamples(),
  ),
  ShowcaseComponent(
    id: 'state-message',
    title: 'StateMessage',
    description: 'The shared message layout used by ErrorState and EmptyState.',
    icon: Icons.info_outline,
    examples: [
      for (final inline in [false, true])
        for (final hasAction in [false, true])
          ShowcaseExample(
            title:
                '${inline ? 'Inline' : 'Full-area'} shared layout · ${hasAction ? 'with action' : 'without action'}',
            description: 'Custom informational icon, copy and action.',
            height: inline ? null : 280,
            builder: (context) => StateMessage(
              title: 'Information',
              message: 'This neutral layout is reused by the two message components.',
              icon: Icons.info_outline,
              iconColor: context.tokens.primary,
              inline: inline,
              actionLabel: hasAction ? 'Acknowledge' : null,
              onAction: hasAction
                  ? () => _feedback(context, 'Shared message action activated')
                  : null,
            ),
          ),
    ],
  ),
];

ShowcaseComponent? findShowcaseComponent(String id) {
  for (final component in showcaseComponents) {
    if (component.id == id) return component;
  }
  return null;
}

String _imageStateTitle(String? source) {
  if (source == null) return 'Missing image';
  if (source.isEmpty) return 'Blank image source';
  if (source == _missingImage) return 'Failed image load';
  return 'Unsupported image source';
}

void _feedback(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

List<ShowcaseExample> _productExamples() {
  const scenarios = [
    _ProductScenario('Regular price', 'Current price without a discount.'),
    _ProductScenario(
      'Discounted',
      'Current/original prices and percentage saving.',
      price: 11.691,
      originalPrice: 12.99,
    ),
    _ProductScenario(
      'Free after discount',
      'Zero is a valid price; a full discount is shown.',
      price: 0,
      originalPrice: 12.99,
      rating: 3,
      reviewCount: 0,
    ),
    _ProductScenario(
      'Missing image and rating',
      'Unknown values keep their readable fallbacks.',
      image: null,
      rating: null,
      reviewCount: 0,
    ),
    _ProductScenario(
      'Failed image and invalid price',
      'A failed asset and a negative price show fallbacks.',
      image: _missingImage,
      price: -1,
      rating: 2.8,
    ),
    _ProductScenario(
      'Missing price',
      'A missing price hides the original price and discount.',
      price: null,
      originalPrice: 20,
      reviewCount: null,
    ),
    _ProductScenario(
      'Non-finite price',
      'Infinity is unavailable; the original price/discount stay hidden.',
      price: double.infinity,
      originalPrice: 20,
      rating: double.nan,
    ),
    _ProductScenario(
      'No discount',
      'A lower original amount does not create a discount.',
      price: 12.99,
      originalPrice: 10,
    ),
    _ProductScenario(
      'Long content and tap action',
      'Wrapping, line limits, focus and a real callback.',
      title: 'A deliberately long product title for narrow layouts and larger text settings',
      interactive: true,
    ),
    _ProductScenario(
      'Blank title/category',
      'Readable field fallbacks and an omitted brand.',
      title: '',
      category: '',
      brand: null,
    ),
  ];
  return [
    for (final variant in ProductCardVariant.values)
      for (final scenario in scenarios)
        ShowcaseExample(
          title: '${variant.name} · ${scenario.label}',
          description: scenario.description,
          builder: (context) => ProductCard(
            title: scenario.title,
            category: scenario.category,
            brand: scenario.brand,
            imageUrl: scenario.image,
            price: scenario.price,
            originalPrice: scenario.originalPrice,
            rating: scenario.rating,
            reviewCount: scenario.reviewCount,
            variant: variant,
            onTap: scenario.interactive
                ? () => _feedback(context, 'Product card activated')
                : null,
          ),
        ),
  ];
}

class _ProductScenario {
  const _ProductScenario(
    this.label,
    this.description, {
    this.title = 'Red Lipstick',
    this.category = 'beauty',
    this.brand = 'Example Beauty',
    this.image = _sampleImage,
    this.price = 12.99,
    this.originalPrice,
    this.rating = 4.4,
    this.reviewCount = 23,
    this.interactive = false,
  });

  final String label;
  final String description;
  final String title;
  final String category;
  final String? brand;
  final String? image;
  final double? price;
  final double? originalPrice;
  final double? rating;
  final int? reviewCount;
  final bool interactive;
}

List<ShowcaseExample> _ratingExamples() => [
  _rating('Good', 'Green rating with reviews.', 4.4, 23),
  _rating('Good boundary', 'Four starts the green range.', 4),
  _rating('Average', 'Amber rating with one review.', 3.5, 1),
  _rating('Average boundary', 'Three starts the amber range.', 3),
  _rating('Poor', 'Red rating below three.', 2.8, 8),
  _rating('Zero rating', 'Zero is rated; it is distinct from unknown.', 0, 0),
  _rating('Unknown', 'No rating or review count is provided.', null),
  _rating(
    'Unknown with zero reviews',
    'An explicit zero review count is visible.',
    null,
    0,
  ),
  _rating(
    'Negative review count',
    'An invalid review count is omitted.',
    4.4,
    -1,
  ),
  _rating('Invalid negative rating', 'Out-of-range ratings are neutral.', -1),
  _rating('Invalid high rating', 'Ratings above five are neutral.', 6),
  _rating('Not a number', 'Non-finite ratings are neutral.', double.nan),
  _rating(
    'Infinite rating',
    'Non-finite ratings are neutral.',
    double.infinity,
  ),
  _rating(
    'Precision boundary',
    'Known follow-up: rounded text can reach 4.0 while the raw rating remains amber.',
    3.999,
  ),
];

ShowcaseExample _rating(
  String title,
  String description,
  double? value, [
  int? count,
]) => ShowcaseExample(
  title: title,
  description: description,
  builder: (_) => RatingBadge(rating: value, reviewCount: count),
);

List<ShowcaseExample> _errorExamples() => [
  for (final inline in [false, true])
    for (final action in [false, true])
      ShowcaseExample(
        title:
            '${inline ? 'Inline' : 'Full-area'} · ${action ? 'with action' : 'without action'}',
        description:
            'The caller supplies the message and optional recovery action.',
        height: inline ? null : 280,
        builder: (context) => ErrorState(
          title: 'Could not load products',
          message: 'Check your connection and try again.',
          inline: inline,
          actionLabel: action ? 'Retry' : null,
          onAction: action
              ? () => _feedback(context, 'Retry preview activated')
              : null,
        ),
      ),
  ShowcaseExample(
    title: 'Long error and custom icon',
    description: 'Scroll inside this short area when text is enlarged.',
    height: 200,
    builder: (context) => ErrorState(
      title: 'The product collection could not be loaded right now',
      message: 'This deliberately longer message demonstrates wrapping and scrolling in narrow or short layouts. Your current selection is safe; you can try again when ready.',
      icon: Icons.wifi_off_outlined,
      actionLabel: 'Try loading the collection again',
      onAction: () => _feedback(context, 'Long error action activated'),
    ),
  ),
];

List<ShowcaseExample> _emptyExamples() => [
  for (final inline in [false, true])
    for (final action in [false, true])
      ShowcaseExample(
        title:
            '${inline ? 'Inline' : 'Full-area'} · ${action ? 'with action' : 'without action'}',
        description: 'Empty content can optionally offer a useful next step.',
        height: inline ? null : 280,
        builder: (context) => EmptyState(
          title: action ? 'No matching products' : 'No products yet',
          message: action
              ? 'Try another search or browse all products.'
              : 'There are no products in this collection.',
          inline: inline,
          actionLabel: action ? 'Browse all products' : null,
          onAction: action
              ? () => _feedback(context, 'Browse preview activated')
              : null,
        ),
      ),
  ShowcaseExample(
    title: 'Search empty state and long copy',
    description: 'Custom icon, long text and a short preview area.',
    height: 200,
    builder: (context) => EmptyState(
      title: 'No products match the current search and category',
      message: 'Try a different search phrase, choose another category, or clear the filters to discover more products in the collection.',
      icon: Icons.search_off_outlined,
      actionLabel: 'Clear the current filters',
      onAction: () => _feedback(context, 'Clear filters preview activated'),
    ),
  ),
];
