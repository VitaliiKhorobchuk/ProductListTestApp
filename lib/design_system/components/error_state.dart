import 'package:flutter/material.dart';

import 'state_message.dart';

/// A recoverable error presentation. The caller owns its copy and action.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.cloud_off_outlined,
    this.actionLabel,
    this.onAction,
    this.inline = false,
  }) : assert(
         (actionLabel == null) == (onAction == null),
         'Provide both actionLabel and onAction, or neither.',
       );

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Uses only the content height instead of centering in available height.
  final bool inline;

  @override
  Widget build(BuildContext context) => StateMessage(
    title: title,
    message: message,
    icon: icon,
    iconColor: Theme.of(context).colorScheme.error,
    actionLabel: actionLabel,
    onAction: onAction,
    inline: inline,
  );
}
