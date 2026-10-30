import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// A controlled category choice with native chip interaction and semantics.
///
/// The parent owns [selected] and decides whether to accept [onSelected]'s
/// proposed value. A single-selection group can ignore false to keep an active
/// category selected. A null callback disables the chip without hiding its state.
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    required this.selected,
    this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final enabled = onSelected != null;
    final foreground = enabled && selected
        ? theme.colorScheme.onPrimary
        : tokens.onSurface;
    final textStyle =
        (theme.textTheme.labelLarge ?? const TextStyle(fontSize: 14)).copyWith(
          color: foreground,
        );
    final padding = EdgeInsets.symmetric(
      horizontal: tokens.spaceSm,
      vertical: tokens.spaceXs,
    );
    final labelPadding = EdgeInsets.symmetric(horizontal: tokens.spaceXs);
    const checkmarkSize = 18.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        // RawChip measures label height before subtracting its padding/avatar.
        // Bound the label first so both measurement passes use the same width.
        final labelWidth = constraints.hasBoundedWidth
            ? math.max(
                0.0,
                constraints.maxWidth -
                    padding.horizontal -
                    labelPadding.horizontal -
                    (selected ? checkmarkSize : 0),
              )
            : double.infinity;
        return ChoiceChip(
          selected: selected,
          onSelected: onSelected,
          backgroundColor: tokens.surface,
          selectedColor: enabled ? tokens.primary : tokens.surfaceVariant,
          disabledColor: tokens.surfaceVariant,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          pressElevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.radius),
          ),
          side: WidgetStateBorderSide.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return BorderSide(color: tokens.border);
            }
            if (states.contains(WidgetState.focused)) {
              return BorderSide(
                color: selected ? theme.colorScheme.onPrimary : tokens.primary,
                width: 2,
              );
            }
            return BorderSide(
              color: selected ? tokens.primary : tokens.onSurfaceDim,
            );
          }),
          padding: padding,
          labelPadding: labelPadding,
          materialTapTargetSize: MaterialTapTargetSize.padded,
          visualDensity: VisualDensity.standard,
          labelStyle: textStyle,
          // A fixed avatar avoids the built-in checkmark growing to the full
          // height of a multi-line label. ChoiceChip still exposes selection.
          showCheckmark: false,
          avatarBoxConstraints: const BoxConstraints.tightFor(
            width: checkmarkSize,
            height: checkmarkSize,
          ),
          avatar: selected
              ? ExcludeSemantics(
                  child: Icon(
                    Icons.check,
                    size: checkmarkSize,
                    color: foreground,
                  ),
                )
              : null,
          label: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: labelWidth),
            // Replace RawChip's one-line defaults instead of merging them.
            child: DefaultTextStyle(
              style: textStyle,
              softWrap: true,
              overflow: TextOverflow.visible,
              child: Text(label),
            ),
          ),
        );
      },
    );
  }
}
