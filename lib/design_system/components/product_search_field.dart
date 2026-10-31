import 'dart:async';

import 'package:flutter/material.dart';

/// A search input that debounces user typing without normalizing the query.
///
/// Typing calls [onChanged] after [debounceDuration]. Clear calls it immediately
/// with an empty string. Enter cancels pending typing and calls [onSubmitted],
/// or [onChanged] when no submit callback was provided. Initial and programmatic
/// controller values do not trigger either callback.
class ProductSearchField extends StatefulWidget {
  const ProductSearchField({
    super.key,
    required this.onChanged,
    this.onSubmitted,
    this.hintText = 'Search products',
    this.clearTooltip = 'Clear search',
    this.controller,
    this.focusNode,
    this.initialValue = '',
    this.enabled = true,
    this.debounceDuration = defaultDebounceDuration,
  }) : assert(
         controller == null || initialValue == '',
         'Provide a controller or a nonempty initialValue, not both.',
       );

  static const defaultDebounceDuration = Duration(milliseconds: 300);

  /// Receives debounced user edits, immediate clears, and submissions when
  /// [onSubmitted] is absent. Whitespace and case are preserved.
  final ValueChanged<String> onChanged;

  /// Handles Enter exclusively when supplied; [onChanged] is not also called.
  final ValueChanged<String>? onSubmitted;
  final String hintText;
  final String clearTooltip;

  /// Remains owned by the caller. Programmatic text replacements cancel
  /// pending typing but do not search; selection-only changes preserve it. When omitted, an internal controller is
  /// created and disposed here. Removing an external controller keeps its value.
  final TextEditingController? controller;

  /// Remains owned by the caller. An omitted node is created and disposed here.
  final FocusNode? focusNode;

  /// Seeds the internal controller only when this widget is first created.
  final String initialValue;
  final bool enabled;

  /// Must be nonnegative. A changed duration cancels any pending typing.
  final Duration debounceDuration;

  @override
  State<ProductSearchField> createState() => _ProductSearchFieldState();
}

class _ProductSearchFieldState extends State<ProductSearchField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late TextEditingValue _observedValue;
  late bool _ownsController;
  late bool _ownsFocusNode;
  Timer? _debounce;
  bool _awaitingComposition = false;

  @override
  void initState() {
    super.initState();
    _checkDuration();
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ?? TextEditingController(text: widget.initialValue);
    _observedValue = _controller.value;
    _controller.addListener(_handleControllerChanged);
    _ownsFocusNode = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void didUpdateWidget(covariant ProductSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkDuration();
    if (oldWidget.controller != widget.controller) {
      _replaceController();
    }
    if (oldWidget.focusNode != widget.focusNode) {
      _cancelPending();
      if (_ownsFocusNode) _focusNode.dispose();
      _ownsFocusNode = widget.focusNode == null;
      _focusNode = widget.focusNode ?? FocusNode();
    }
    if (oldWidget.debounceDuration != widget.debounceDuration ||
        oldWidget.enabled != widget.enabled) {
      _cancelPending();
    }
  }

  void _checkDuration() {
    assert(
      !widget.debounceDuration.isNegative,
      'debounceDuration must be nonnegative.',
    );
  }

  void _replaceController() {
    _cancelPending();
    final previousValue = _controller.value;
    _controller.removeListener(_handleControllerChanged);
    if (_ownsController) _controller.dispose();
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ?? TextEditingController.fromValue(previousValue);
    _observedValue = _controller.value;
    _controller.addListener(_handleControllerChanged);
  }

  static bool _isComposing(TextEditingValue value) =>
      value.composing.isValid && !value.composing.isCollapsed;

  void _handleControllerChanged() {
    final previous = _observedValue;
    final current = _controller.value;
    _observedValue = current;
    if (previous.text != current.text) {
      // User edits reach onChanged next. Controller-only edits stop here.
      _cancelPending();
      if (previous.text.isEmpty != current.text.isEmpty) setState(() {});
      return;
    }
    if (_isComposing(current)) {
      if (_debounce != null) {
        _cancelPending();
        _awaitingComposition = true;
      }
      return;
    }
    // IMEs can finish composition without changing the text, so onChanged
    // alone is insufficient. Ordinary selection changes never search.
    if (_awaitingComposition && widget.enabled) {
      _scheduleChanged(current.text);
    }
  }

  void _handleChanged(String text) {
    _cancelPending();
    if (!widget.enabled) return;
    if (_isComposing(_controller.value)) {
      _awaitingComposition = true;
      return;
    }
    _scheduleChanged(text);
  }

  void _scheduleChanged(String text) {
    _cancelPending();
    _debounce = Timer(widget.debounceDuration, () {
      _debounce = null;
      if (!mounted ||
          !widget.enabled ||
          _controller.text != text ||
          _isComposing(_controller.value)) {
        return;
      }
      widget.onChanged(text);
    });
  }

  void _handleSubmitted(String text) {
    _cancelPending();
    if (!widget.enabled || _isComposing(_controller.value)) return;
    final submit = widget.onSubmitted ?? widget.onChanged;
    submit(text);
  }

  void _clear() {
    _cancelPending();
    if (!widget.enabled) return;
    _controller.clear();
    _focusNode.requestFocus();
    widget.onChanged('');
  }

  void _cancelPending() {
    _debounce?.cancel();
    _debounce = null;
    _awaitingComposition = false;
  }

  @override
  void dispose() {
    _cancelPending();
    _controller.removeListener(_handleControllerChanged);
    if (_ownsController) _controller.dispose();
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    // The native hint names an empty field. Keep its purpose exposed once filled.
    label: _controller.text.isEmpty ? null : widget.hintText,
    child: TextField(
      controller: _controller,
      focusNode: _focusNode,
      enabled: widget.enabled,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.search,
      autocorrect: false,
      enableSuggestions: false,
      onChanged: widget.enabled ? _handleChanged : null,
      onSubmitted: widget.enabled ? _handleSubmitted : null,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: const ExcludeSemantics(child: Icon(Icons.search)),
        suffixIcon: widget.enabled && _controller.text.isNotEmpty
            ? IconButton(
                tooltip: widget.clearTooltip,
                onPressed: _clear,
                icon: const Icon(Icons.clear),
              )
            : null,
      ),
    ),
  );
}
