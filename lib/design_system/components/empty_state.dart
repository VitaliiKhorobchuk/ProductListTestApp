import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'state_message.dart';

/// An empty collection presentation. The caller owns its copy and action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inventory_2_outlined,
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
    iconColor: context.tokens.primary,
    actionLabel: actionLabel,
    onAction: onAction,
    inline: inline,
  );
}
