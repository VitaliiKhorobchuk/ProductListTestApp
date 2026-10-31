import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/components/empty_state.dart';
import '../../design_system/theme/app_tokens.dart';
import '../showcase_navigation.dart';
import 'showcase_examples.dart';
import 'showcase_models.dart';

class ShowcaseDetailScreen extends StatefulWidget {
  const ShowcaseDetailScreen({super.key, required this.componentId});

  final String componentId;

  @override
  State<ShowcaseDetailScreen> createState() => _ShowcaseDetailScreenState();
}

class _ShowcaseDetailScreenState extends State<ShowcaseDetailScreen> {
  static const _settingsControlWidth = 220.0;

  ShowcaseWidth _width = ShowcaseWidth.available;
  ShowcaseTextSize _textSize = ShowcaseTextSize.system;

  @override
  Widget build(BuildContext context) {
    final component = findShowcaseComponent(widget.componentId);
    if (component == null) {
      return Scaffold(
        appBar: const ShowcaseAppBar(title: 'Component not found'),
        body: EmptyState(
          title: 'Component not found',
          message: 'This component is not registered in the showcase yet.',
          actionLabel: 'View available components',
          onAction: () => context.goNamed(ShowcaseNavigation.indexRoute),
        ),
      );
    }
    final tokens = context.tokens;
    return Scaffold(
      appBar: ShowcaseAppBar(title: component.title),
      body: SafeArea(
        child: ListView.separated(
          key: PageStorageKey<String>('debug-examples-${component.id}'),
          padding: EdgeInsets.all(tokens.spaceLg),
          itemCount: component.examples.length + 1,
          separatorBuilder: (_, _) => SizedBox(height: tokens.spaceLg),
          itemBuilder: (context, index) {
            if (index == 0) return _buildSettings(context, component);
            return _ExamplePreview(
              example: component.examples[index - 1],
              width: _width,
              textSize: _textSize,
            );
          },
        ),
      ),
    );
  }

  Widget _buildSettings(BuildContext context, ShowcaseComponent component) {
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(component.description),
        SizedBox(height: tokens.spaceLg),
        Wrap(
          spacing: tokens.spaceLg,
          runSpacing: tokens.spaceSm,
          children: [
            SizedBox(
              width: _settingsControlWidth,
              child: DropdownButton<ShowcaseWidth>(
                value: _width,
                isExpanded: true,
                hint: const Text('Preview width'),
                items: [
                  for (final option in ShowcaseWidth.values)
                    DropdownMenuItem(value: option, child: Text(option.label)),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _width = value);
                },
              ),
            ),
            SizedBox(
              width: _settingsControlWidth,
              child: DropdownButton<ShowcaseTextSize>(
                value: _textSize,
                isExpanded: true,
                hint: const Text('Preview text size'),
                items: [
                  for (final option in ShowcaseTextSize.values)
                    DropdownMenuItem(value: option, child: Text(option.label)),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _textSize = value);
                },
              ),
            ),
          ],
        ),
        SizedBox(height: tokens.spaceSm),
        const Text(
          'Width presets are capped by available space. Scroll inside fixed-height message examples when needed.',
        ),
      ],
    );
  }
}

class _ExamplePreview extends StatelessWidget {
  const _ExamplePreview({
    required this.example,
    required this.width,
    required this.textSize,
  });

  final ShowcaseExample example;
  final ShowcaseWidth width;
  final ShowcaseTextSize textSize;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                example.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            SizedBox(height: tokens.spaceXs),
            Text(example.description),
            SizedBox(height: tokens.spaceSm),
            const Divider(),
            SizedBox(height: tokens.spaceSm),
            LayoutBuilder(
              builder: (context, constraints) {
                final previewWidth = math.min(
                  width.width ?? constraints.maxWidth,
                  constraints.maxWidth,
                );
                final scale = textSize.scale;
                final media = MediaQuery.of(context);
                return Align(
                  alignment: AlignmentDirectional.topStart,
                  child: SizedBox(
                    width: previewWidth,
                    height: example.height,
                    child: MediaQuery(
                      data: media.copyWith(
                        textScaler: scale == null
                            ? media.textScaler
                            : TextScaler.linear(scale),
                      ),
                      child: Align(
                        alignment: AlignmentDirectional.topStart,
                        child: Builder(builder: example.builder),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
