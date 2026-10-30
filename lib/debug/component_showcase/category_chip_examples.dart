import 'package:flutter/material.dart';

import '../../design_system/components/category_chip.dart';
import '../../design_system/theme/app_tokens.dart';
import 'showcase_models.dart';

List<ShowcaseExample> buildCategoryChipExamples() => [
  _example('Unselected', 'Beauty', selected: false),
  _example('Selected', 'Beauty', selected: true),
  _example('Disabled unselected', 'Furniture', selected: false, enabled: false),
  _example('Disabled selected', 'Furniture', selected: true, enabled: false),
  _example(
    'Long label',
    'Kitchen accessories and everyday household essentials',
    selected: false,
  ),
  _example(
    'Selected long label',
    'Kitchen accessories and everyday household essentials',
    selected: true,
  ),
  _example(
    'Unbroken label',
    'ExtraLongCategoryNameWithoutSpacesForNarrowLayouts',
    selected: false,
  ),
  ShowcaseExample(
    title: 'Single-selection group',
    description: 'The preview parent owns selection. Tapping the selected chip keeps it selected; All products clears the category. Furniture is unavailable. No catalog request is made.',
    builder: (_) => const _SingleSelectionPreview(),
  ),
];

ShowcaseExample _example(
  String title,
  String label, {
  required bool selected,
  bool enabled = true,
}) => ShowcaseExample(
  title: title,
  description: enabled
      ? 'Controlled preview: activation reports a proposed value; the supplied selected state stays fixed. Use the group below to change selection.'
      : 'A null callback disables interaction while preserving the supplied selected state.',
  builder: (_) => _ControlledChipPreview(
    label: label,
    selected: selected,
    enabled: enabled,
  ),
);

class _ControlledChipPreview extends StatefulWidget {
  const _ControlledChipPreview({
    required this.label,
    required this.selected,
    required this.enabled,
  });

  final String label;
  final bool selected;
  final bool enabled;

  @override
  State<_ControlledChipPreview> createState() => _ControlledChipPreviewState();
}

class _ControlledChipPreviewState extends State<_ControlledChipPreview> {
  int _activationCount = 0;
  bool? _lastProposal;

  void _selected(bool proposed) {
    setState(() {
      _activationCount++;
      _lastProposal = proposed;
    });
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CategoryChip(
        label: widget.label,
        selected: widget.selected,
        onSelected: widget.enabled ? _selected : null,
      ),
      SizedBox(height: context.tokens.spaceSm),
      Text(
        _lastProposal == null
            ? 'No selection callbacks yet'
            : 'Proposed selected: $_lastProposal. Activations: $_activationCount.',
      ),
    ],
  );
}

enum _PreviewCategory {
  all('All products'),
  beauty('Beauty'),
  fragrances('Fragrances'),
  furniture('Furniture'),
  kitchen('Kitchen accessories');

  const _PreviewCategory(this.label);

  final String label;
}

class _SingleSelectionPreview extends StatefulWidget {
  const _SingleSelectionPreview();

  @override
  State<_SingleSelectionPreview> createState() =>
      _SingleSelectionPreviewState();
}

class _SingleSelectionPreviewState extends State<_SingleSelectionPreview>
    with AutomaticKeepAliveClientMixin {
  _PreviewCategory _selectedCategory = _PreviewCategory.all;
  String _lastAction = 'No selection callbacks yet';
  int _activationCount = 0;

  @override
  bool get wantKeepAlive => true;

  void _select(_PreviewCategory category, bool proposed) {
    setState(() {
      _activationCount++;
      if (proposed) {
        _selectedCategory = category;
        _lastAction = 'Selected ${category.label}';
      } else {
        _lastAction = 'Kept ${category.label} selected';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final tokens = context.tokens;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: tokens.spaceSm,
          runSpacing: tokens.spaceSm,
          children: [
            for (final category in _PreviewCategory.values)
              CategoryChip(
                label: category.label,
                selected: category == _selectedCategory,
                onSelected: category == _PreviewCategory.furniture
                    ? null
                    : (proposed) => _select(category, proposed),
              ),
          ],
        ),
        SizedBox(height: tokens.spaceSm),
        Text('Selection: ${_selectedCategory.label}'),
        Text('$_lastAction. Activations: $_activationCount.'),
      ],
    );
  }
}
