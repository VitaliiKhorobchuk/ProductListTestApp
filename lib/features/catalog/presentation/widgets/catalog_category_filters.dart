import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../design_system/components/category_chip.dart';
import '../../../../design_system/theme/app_tokens.dart';
import '../../models/category.dart';
import '../cubit/catalog_cubit.dart';
import '../cubit/categories_cubit.dart';

/// Category metadata has its own loading, failure, and retry lifetime.
class CatalogCategoryFilters extends StatelessWidget {
  const CatalogCategoryFilters({super.key, required this.selectedSlug});

  static const _minimumChipSpacingUnits = 15;
  static const _maximumChipSpacingUnits = 30;
  static const _maximumChipWidthFraction = .75;
  static const _loadingIndicatorSize = 16.0;
  static const _loadingStrokeWidth = 2.0;

  final String? selectedSlug;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return BlocBuilder<CategoriesCubit, CategoriesState>(
      builder: (context, state) {
        final selectedIsMissing =
            selectedSlug != null &&
            !state.categories.any((category) => category.slug == selectedSlug);
        final categories = [
          ...state.categories,
          if (selectedIsMissing)
            Category(
              slug: selectedSlug!,
              name: selectedSlug!.replaceAll('-', ' '),
            ),
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Categories', style: Theme.of(context).textTheme.labelLarge),
            SizedBox(height: tokens.spaceXs),
            LayoutBuilder(
              builder: (context, constraints) {
                // A horizontal, naturally sized strip keeps the catalog close.
                // Bounded chip labels can wrap at large text sizes instead of
                // imposing a fixed row height or overflowing narrow viewports.
                final maximumChipWidth = math.max(
                  tokens.spacing * _minimumChipSpacingUnits,
                  math.min(
                    tokens.spacing * _maximumChipSpacingUnits,
                    constraints.maxWidth * _maximumChipWidthFraction,
                  ),
                );
                Widget chip({required String label, required String? slug}) =>
                    Padding(
                      padding: EdgeInsetsDirectional.only(end: tokens.spaceSm),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maximumChipWidth),
                        child: CategoryChip(
                          label: label,
                          selected: selectedSlug == slug,
                          onSelected: (_) =>
                              context.read<CatalogCubit>().selectCategory(slug),
                        ),
                      ),
                    );
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      chip(label: 'All products', slug: null),
                      for (final category in categories)
                        chip(label: category.name, slug: category.slug),
                    ],
                  ),
                );
              },
            ),
            if (state.status == CategoriesStatus.loading)
              Padding(
                padding: EdgeInsets.symmetric(vertical: tokens.spaceXs),
                child: Row(
                  children: [
                    const SizedBox.square(
                      dimension: _loadingIndicatorSize,
                      child: CircularProgressIndicator(
                        strokeWidth: _loadingStrokeWidth,
                      ),
                    ),
                    SizedBox(width: tokens.spaceSm),
                    Expanded(
                      child: Text(
                        'Loading categories…',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            if (state.status == CategoriesStatus.initial)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: () => context.read<CategoriesCubit>().load(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Load categories'),
                ),
              ),
            if (state.status == CategoriesStatus.empty)
              Padding(
                padding: EdgeInsets.only(top: tokens.spaceXs),
                child: Text(
                  'No categories are available. You can still browse products.',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: tokens.onSurfaceDim),
                ),
              ),
            if (state.status == CategoriesStatus.error)
              Semantics(
                liveRegion: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.failure?.message ??
                          'Categories could not be loaded.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => context.read<CategoriesCubit>().retry(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry categories'),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
