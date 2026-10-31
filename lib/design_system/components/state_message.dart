import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Shared layout for state components, independent of application state.
class StateMessage extends StatelessWidget {
  const StateMessage({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    required this.iconColor,
    this.actionLabel,
    this.onAction,
    this.inline = false,
  }) : assert(
         (actionLabel == null) == (onAction == null),
         'Provide both actionLabel and onAction, or neither.',
       );

  static const _maximumContentWidth = 440.0;
  static const _iconSize = 48.0;

  final String title;
  final String message;
  final IconData icon;
  final Color iconColor;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool inline;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    final padding = inline ? tokens.spaceLg : tokens.spaceXl;
    final label = actionLabel?.trim();
    assert(label == null || label.isNotEmpty, 'actionLabel must not be blank.');
    // Assertions describe the contract in debug mode. An incomplete action is
    // safely omitted in release mode rather than becoming a disabled button.
    final hasAction = label != null && label.isNotEmpty && onAction != null;

    return ColoredBox(
      color: tokens.surface,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableHeight = constraints.maxHeight - padding * 2;
          final minimumHeight =
              !inline && constraints.hasBoundedHeight && availableHeight > 0
              ? availableHeight
              : 0.0;
          return SingleChildScrollView(
            primary: false,
            padding: EdgeInsets.all(padding),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minimumHeight),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: _maximumContentWidth,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ExcludeSemantics(
                        child: Icon(icon, size: _iconSize, color: iconColor),
                      ),
                      SizedBox(height: tokens.spaceLg),
                      Semantics(
                        header: true,
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: textTheme.titleLarge?.copyWith(
                            color: tokens.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(height: tokens.spaceSm),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: tokens.onSurfaceDim,
                        ),
                      ),
                      if (hasAction) ...[
                        SizedBox(height: tokens.spaceXl),
                        FilledButton(
                          onPressed: onAction,
                          child: Text(label, textAlign: TextAlign.center),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
