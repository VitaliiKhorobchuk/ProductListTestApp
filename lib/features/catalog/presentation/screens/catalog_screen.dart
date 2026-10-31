import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/theme_cubit.dart';
import '../../../../debug/debug_showcase_button.dart';
import '../../../../design_system/components/empty_state.dart';
import '../../../../design_system/components/error_state.dart';
import '../../../../design_system/components/product_card.dart';
import '../../../../design_system/components/product_search_field.dart';
import '../../../../design_system/theme/app_tokens.dart';
import '../../models/catalog_query.dart';
import '../cubit/catalog_cubit.dart';
import '../widgets/catalog_category_filters.dart';
import '../widgets/catalog_product_sliver.dart';
import '../widgets/catalog_loading_sliver.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  static const _paginationThreshold = 320.0;
  final ScrollController _scrollController = ScrollController(
    keepScrollOffset: false,
  );
  final Set<CatalogQuery> _localSearchCommits = {};
  late final TextEditingController _searchController;
  late CatalogQuery _observedQuery;
  ProductCardVariant _variant = ProductCardVariant.standard;
  bool _viewportWorkScheduled = false;
  CatalogQuery? _scrollResetQuery;
  final Map<ProductCardVariant, double> _variantOffsets = {};
  ({CatalogQuery query, ProductCardVariant variant, double offset})?
  _variantRestore;

  @override
  void initState() {
    super.initState();
    _observedQuery = context.read<CatalogCubit>().state.query;
    _searchController = TextEditingController(text: _observedQuery.text);
    _scrollController.addListener(_scheduleViewportWork);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleViewportWork();
  }

  void _commitSearch(String text) {
    final cubit = context.read<CatalogCubit>();
    final query = CatalogQuery(
      text: text,
      categorySlug: cubit.state.query.categorySlug,
    );
    if (query != cubit.state.query) _localSearchCommits.add(query);
    unawaited(cubit.setSearch(text));
  }

  void _catalogChanged(BuildContext context, CatalogState state) {
    final previous = _observedQuery;
    _observedQuery = state.query;
    final queryChanged = state.query != previous;
    final wasLocalSearch =
        queryChanged && _localSearchCommits.remove(state.query);
    if (state.query.normalizedText != previous.normalizedText &&
        !wasLocalSearch &&
        _searchController.text.trim().toLowerCase() !=
            state.query.normalizedText) {
      // Category changes, appends, reloads and equivalent text echoes must not
      // replace a pending draft: a controller write cancels its debounce.
      _searchController.value = TextEditingValue(
        text: state.query.text,
        selection: TextSelection.collapsed(offset: state.query.text.length),
      );
    }
    if (queryChanged) _resetScrollFor(state.query);
    // Cursor/busy changes matter even when a page contains only duplicate IDs.
    _scheduleViewportWork();
  }

  void _reloadProducts() {
    final cubit = context.read<CatalogCubit>();
    _resetScrollFor(cubit.state.query);
    unawaited(cubit.load());
    _scheduleViewportWork();
  }

  void _resetScrollFor(CatalogQuery query) {
    _variantOffsets.clear();
    _variantRestore = null;
    _scrollResetQuery = query;
  }

  void _scheduleViewportWork() {
    if (!mounted || _viewportWorkScheduled) return;
    _viewportWorkScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewportWorkScheduled = false;
      if (!mounted) return;
      final cubit = context.read<CatalogCubit>();
      final state = cubit.state;
      if (_scrollResetQuery != null && _scrollResetQuery != state.query) {
        _scrollResetQuery = null;
      }
      if (!_scrollController.hasClients ||
          _scrollController.positions.length != 1) {
        return;
      }
      final position = _scrollController.position;
      if (!position.hasContentDimensions) return;
      // Retain the reset intent through temporary detachment/layout. A matching
      // position consumes it only when it can actually be reset.
      if (_scrollResetQuery == state.query) {
        _scrollResetQuery = null;
        _variantRestore = null;
        if (position.pixels != 0) position.jumpTo(0);
      } else if (_variantRestore case final restore?) {
        _variantRestore = null;
        if (restore.query == state.query && restore.variant == _variant) {
          final offset = restore.offset.clamp(0.0, position.maxScrollExtent);
          if (position.pixels != offset) position.jumpTo(offset);
        }
      }
      if (state.status == CatalogStatus.loaded &&
          state.hasMore &&
          !state.isLoadingMore &&
          state.paginationFailure == null &&
          position.extentAfter <= _paginationThreshold) {
        unawaited(cubit.loadMore());
      }
    });
    // Metrics notifications may arrive after a frame has already finished.
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _showOtherVariant() {
    if (_scrollResetQuery == null &&
        _variantRestore == null &&
        _scrollController.hasClients &&
        _scrollController.positions.length == 1) {
      _variantOffsets[_variant] = _scrollController.position.pixels;
    }
    setState(() {
      _variant = _variant == ProductCardVariant.standard
          ? ProductCardVariant.compact
          : ProductCardVariant.standard;
      _variantRestore = (
        query: context.read<CatalogCubit>().state.query,
        variant: _variant,
        offset: _variantOffsets[_variant] ?? 0,
      );
    });
    _scheduleViewportWork();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scheduleViewportWork);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Products',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (kDebugMode) const DebugShowcaseButton(),
          IconButton(
            tooltip: _variant == ProductCardVariant.standard
                ? 'Show grid view'
                : 'Show list view',
            onPressed: _showOtherVariant,
            icon: Icon(
              _variant == ProductCardVariant.standard
                  ? Icons.grid_view_outlined
                  : Icons.view_list_outlined,
            ),
          ),
          IconButton(
            tooltip: isDark ? 'Switch to light theme' : 'Switch to dark theme',
            onPressed: () => context.read<ThemeCubit>().toggle(
              systemBrightness: MediaQuery.platformBrightnessOf(context),
            ),
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
          ),
          IconButton(
            tooltip: 'Reload products',
            onPressed: _reloadProducts,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: BlocConsumer<CatalogCubit, CatalogState>(
          listener: _catalogChanged,
          builder: (context, state) => LayoutBuilder(
            builder: (context, constraints) =>
                NotificationListener<ScrollMetricsNotification>(
                  onNotification: (notification) {
                    if (notification.depth == 0) _scheduleViewportWork();
                    return false;
                  },
                  child: CustomScrollView(
                    key: const PageStorageKey<String>('catalog-scroll'),
                    controller: _scrollController,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.all(tokens.spaceLg),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ProductSearchField(
                                key: const ValueKey('catalog-search'),
                                controller: _searchController,
                                onChanged: _commitSearch,
                                onSubmitted: _commitSearch,
                              ),
                              SizedBox(height: tokens.spaceLg),
                              CatalogCategoryFilters(
                                selectedSlug: state.query.categorySlug,
                              ),
                              if (state.status == CatalogStatus.loaded) ...[
                                SizedBox(height: tokens.spaceLg),
                                Semantics(
                                  liveRegion: true,
                                  child: Text(
                                    '${state.products.length} ${state.products.length == 1 ? 'product' : 'products'} loaded',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: tokens.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (state.status == CatalogStatus.loaded) ...[
                        CatalogProductSliver(
                          products: state.products,
                          variant: _variant,
                          availableWidth: constraints.maxWidth,
                        ),
                        SliverToBoxAdapter(
                          child: Semantics(
                            liveRegion: true,
                            child: _PaginationFooter(state: state),
                          ),
                        ),
                      ] else if (state.status == CatalogStatus.loading)
                        CatalogLoadingSliver(
                          variant: _variant,
                          availableWidth: constraints.maxWidth,
                        )
                      else
                        SliverToBoxAdapter(
                          child: Semantics(
                            liveRegion: true,
                            child: _CatalogStatus(
                              state: state,
                              onReload: _reloadProducts,
                              onClearSearch: () {
                                _searchController.clear();
                                _commitSearch('');
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
          ),
        ),
      ),
    );
  }
}

class _CatalogStatus extends StatelessWidget {
  const _CatalogStatus({
    required this.state,
    required this.onReload,
    required this.onClearSearch,
  });
  final CatalogState state;
  final VoidCallback onReload, onClearSearch;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case CatalogStatus.initial:
        return EmptyState(
          inline: true,
          title: 'Ready to browse',
          message: 'Load products to start exploring the catalog.',
          actionLabel: 'Load products',
          onAction: onReload,
        );
      case CatalogStatus.loading:
        // The parent renders a dedicated skeleton sliver for this state.
        return const SizedBox.shrink();
      case CatalogStatus.empty:
        final hasSearch = state.query.text.isNotEmpty;
        final hasCategory = state.query.categorySlug != null;
        return EmptyState(
          inline: true,
          title: hasSearch || hasCategory
              ? 'No matching products'
              : 'No products available',
          message: hasSearch && hasCategory
              ? 'No products match “${state.query.text}” in this category. Try another search or category.'
              : hasSearch
              ? 'No products match “${state.query.text}”. Try another search.'
              : hasCategory
              ? 'This category has no products to display. Try another category.'
              : 'There are no products to display. You can reload the catalog.',
          actionLabel: hasSearch
              ? 'Clear search'
              : hasCategory
              ? 'Show all products'
              : 'Reload products',
          onAction: hasSearch
              ? onClearSearch
              : hasCategory
              ? () => context.read<CatalogCubit>().selectCategory(null)
              : onReload,
        );
      case CatalogStatus.error:
        return ErrorState(
          inline: true,
          title: 'Could not load products',
          message: state.failure?.message ?? 'Please try again.',
          actionLabel: 'Retry products',
          onAction: onReload,
        );
      case CatalogStatus.loaded:
        return const SizedBox.shrink();
    }
  }
}

class _PaginationFooter extends StatelessWidget {
  const _PaginationFooter({required this.state});
  final CatalogState state;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    if (state.isLoadingMore) {
      return Padding(
        padding: EdgeInsets.all(tokens.spaceXl),
        child: const Center(
          child: CircularProgressIndicator(
            semanticsLabel: 'Loading more products',
          ),
        ),
      );
    }
    if (state.paginationFailure case final failure?) {
      return ErrorState(
        inline: true,
        title: 'Could not load more products',
        message: failure.message,
        actionLabel: 'Retry loading more',
        onAction: () => context.read<CatalogCubit>().retryLoadMore(),
      );
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLg,
        0,
        tokens.spaceLg,
        tokens.spaceXl,
      ),
      child: Text(
        state.hasMore
            ? 'Scroll for more products'
            : 'All matching products are loaded.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: tokens.onSurfaceDim),
      ),
    );
  }
}
