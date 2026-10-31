import 'package:flutter/material.dart';

import '../../../../design_system/components/product_card.dart';
import '../../../../design_system/theme/app_tokens.dart';

/// Shared lazy row geometry keeps loading and loaded catalog layouts aligned.
class CatalogRowsSliver extends StatelessWidget {
  const CatalogRowsSliver({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.variant,
    required this.availableWidth,
    this.addSemanticIndexes = true,
  });

  static const _referenceTextSize = 16.0;
  static const _minimumColumnSpacingUnits = 20;
  static const _maximumTextScale = 3.0;
  static const _maximumColumns = 4;

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final ProductCardVariant variant;
  final double availableWidth;
  final bool addSemanticIndexes;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final gap = tokens.spaceLg;
    final contentWidth = availableWidth - tokens.spaceLg * 2;
    final textScale =
        MediaQuery.textScalerOf(context).scale(_referenceTextSize) /
        _referenceTextSize;
    final minimumWidth =
        tokens.spacing *
        _minimumColumnSpacingUnits *
        textScale.clamp(1, _maximumTextScale);
    final columns = variant == ProductCardVariant.standard
        ? 1
        : ((contentWidth + gap) / (minimumWidth + gap)).floor().clamp(
            1,
            _maximumColumns,
          );
    final rows = (itemCount + columns - 1) ~/ columns;
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLg,
        0,
        tokens.spaceLg,
        tokens.spaceLg,
      ),
      sliver: SliverList.separated(
        itemCount: rows,
        addSemanticIndexes: addSemanticIndexes,
        separatorBuilder: (context, index) => SizedBox(height: gap),
        itemBuilder: (context, row) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var column = 0; column < columns; column++) ...[
              if (column > 0) SizedBox(width: gap),
              Expanded(
                child: row * columns + column < itemCount
                    ? itemBuilder(context, row * columns + column)
                    : const SizedBox.shrink(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
