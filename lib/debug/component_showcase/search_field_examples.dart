import 'package:flutter/material.dart';

import '../../design_system/components/product_search_field.dart';
import '../../design_system/theme/app_tokens.dart';
import 'showcase_models.dart';

List<ShowcaseExample> buildSearchFieldExamples() => [
  _example('Empty', 'An editable field with search hint and no clear button.'),
  _example(
    'Populated',
    'The clear button appears for editable text.',
    initialText: 'red',
  ),
  _example(
    'Focused empty',
    'Use Focus input to inspect the native focus border without stealing focus while browsing.',
    focusAction: true,
  ),
  _example(
    'Focused populated',
    'Focus and clear remain available with existing text.',
    initialText: 'lipstick',
    focusAction: true,
  ),
  _example(
    'Disabled empty',
    'Disabled input cannot be edited or cleared.',
    enabled: false,
  ),
  _example(
    'Disabled populated',
    'The value remains visible without an active clear control.',
    initialText: 'headphones',
    enabled: false,
  ),
  _example(
    'Long text',
    'Single-line text scrolls horizontally in narrow previews.',
    initialText: 'A deliberately long product search phrase for checking narrow layouts and larger text',
  ),
  _example(
    'Custom hint and clear label',
    'Caller-provided copy remains configurable.',
    hintText: 'Find something in the collection',
    clearTooltip: 'Reset search phrase',
  ),
  _example(
    'Enter fallback',
    'With no submit callback, Enter immediately calls onChanged once.',
    useSubmitCallback: false,
  ),
  ShowcaseExample(
    title: 'Internally owned controller',
    description:
        'The component seeds its own controller without an initial callback.',
    builder: (_) => const _InternalControllerPreview(),
  ),
  _example(
    'Interaction and lifecycle sandbox',
    'Inspect debounce, Enter, clear, programmatic changes and timer cancellation. These controls never search the catalog.',
    interactive: true,
    focusAction: true,
  ),
];

ShowcaseExample _example(
  String title,
  String description, {
  String initialText = '',
  String hintText = 'Search products',
  String clearTooltip = 'Clear search',
  bool enabled = true,
  bool focusAction = false,
  bool useSubmitCallback = true,
  bool interactive = false,
}) => ShowcaseExample(
  title: title,
  description: description,
  builder: (_) => _SearchFieldPreview(
    initialText: initialText,
    hintText: hintText,
    clearTooltip: clearTooltip,
    enabled: enabled,
    focusAction: focusAction,
    useSubmitCallback: useSubmitCallback,
    interactive: interactive,
  ),
);

class _SearchFieldPreview extends StatefulWidget {
  const _SearchFieldPreview({
    required this.initialText,
    required this.hintText,
    required this.clearTooltip,
    required this.enabled,
    required this.focusAction,
    required this.useSubmitCallback,
    required this.interactive,
  });

  final String initialText;
  final String hintText;
  final String clearTooltip;
  final bool enabled;
  final bool focusAction;
  final bool useSubmitCallback;
  final bool interactive;

  @override
  State<_SearchFieldPreview> createState() => _SearchFieldPreviewState();
}

class _SearchFieldPreviewState extends State<_SearchFieldPreview>
    with AutomaticKeepAliveClientMixin {
  static const _historyLimit = 8;
  late final TextEditingController _controller;
  final _focusNode = FocusNode();
  final _clock = Stopwatch();
  final _events = <String>[];
  late bool _enabled;
  late bool _useSubmitCallback;
  late String _draft;
  bool _visible = true;
  int _sequence = 0;
  int _debounceMilliseconds = 300;

  @override
  bool get wantKeepAlive => _focusNode.hasFocus;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _draft = _controller.text;
    _controller.addListener(_syncDraft);
    _focusNode.addListener(_handleFocus);
    _enabled = widget.enabled;
    _useSubmitCallback = widget.useSubmitCallback;
    _clock.start();
  }

  void _syncDraft() {
    if (_draft == _controller.text) return;
    setState(() => _draft = _controller.text);
  }

  void _handleFocus() {
    if (mounted) updateKeepAlive();
  }

  void _record(String kind, String value) {
    if (!mounted) return;
    final elapsed = _clock.elapsedMilliseconds;
    setState(() {
      _sequence++;
      _events.insert(0, '#$_sequence $kind "$value" at $elapsed ms');
      if (_events.length > _historyLimit) _events.removeLast();
    });
  }

  void _changed(String value) => _record('Changed', value);
  void _submitted(String value) => _record('Submitted', value);

  void _replaceText() {
    _controller.value = const TextEditingValue(
      text: 'external change',
      selection: TextSelection.collapsed(offset: 15),
    );
    _record('Controller set', _controller.text);
  }

  @override
  void dispose() {
    _clock.stop();
    _controller.removeListener(_syncDraft);
    _controller.dispose();
    _focusNode.removeListener(_handleFocus);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final tokens = context.tokens;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_visible)
          ProductSearchField(
            controller: _controller,
            focusNode: _focusNode,
            hintText: widget.hintText,
            clearTooltip: widget.clearTooltip,
            enabled: _enabled,
            debounceDuration: Duration(milliseconds: _debounceMilliseconds),
            onChanged: _changed,
            onSubmitted: _useSubmitCallback ? _submitted : null,
          )
        else
          const Text(
            'Input removed. Pending typing must not produce a callback.',
          ),
        if (widget.focusAction && _visible)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: _enabled ? _focusNode.requestFocus : null,
              icon: const Icon(Icons.center_focus_strong_outlined),
              label: const Text('Focus input'),
            ),
          ),
        SizedBox(height: tokens.spaceSm),
        Text('Draft: "$_draft"'),
        SizedBox(height: tokens.spaceXs),
        if (_events.isEmpty)
          const Text('No callback events yet')
        else
          for (final event in _events) Text(event),
        if (widget.interactive) ...[
          SizedBox(height: tokens.spaceLg),
          const Text('Interaction controls'),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Input visible'),
            value: _visible,
            onChanged: (value) => setState(() => _visible = value),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Input enabled'),
            value: _enabled,
            onChanged: (value) => setState(() => _enabled = value),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Use submit callback'),
            value: _useSubmitCallback,
            onChanged: (value) => setState(() => _useSubmitCallback = value),
          ),
          DropdownButton<int>(
            value: _debounceMilliseconds,
            isExpanded: true,
            items: [
              for (final duration in [300, 1500])
                DropdownMenuItem(
                  value: duration,
                  child: Text(
                    '$duration ms debounce',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _debounceMilliseconds = value);
            },
          ),
          Wrap(
            spacing: tokens.spaceSm,
            runSpacing: tokens.spaceXs,
            children: [
              TextButton(
                onPressed: _replaceText,
                child: const Text('Set text externally'),
              ),
              TextButton(
                onPressed: () {
                  _controller.clear();
                  _record('Controller cleared', '');
                },
                child: const Text('Clear externally'),
              ),
              TextButton(
                onPressed: () => setState(() {
                  _events.clear();
                  _sequence = 0;
                  _clock.reset();
                }),
                child: const Text('Reset event log'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _InternalControllerPreview extends StatefulWidget {
  const _InternalControllerPreview();

  @override
  State<_InternalControllerPreview> createState() =>
      _InternalControllerPreviewState();
}

class _InternalControllerPreviewState
    extends State<_InternalControllerPreview> {
  String _event = 'No callback events yet';

  void _changed(String value) => setState(() => _event = 'Changed "$value"');
  void _submitted(String value) =>
      setState(() => _event = 'Submitted "$value"');

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ProductSearchField(
        initialValue: 'seeded search',
        onChanged: _changed,
        onSubmitted: _submitted,
      ),
      SizedBox(height: context.tokens.spaceSm),
      Text(_event),
    ],
  );
}
