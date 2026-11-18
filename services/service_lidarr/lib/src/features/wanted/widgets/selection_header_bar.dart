import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

/// Header bar displayed when items are multi-selected in Wanted views.
class SelectionHeaderBar extends StatelessWidget {
  const SelectionHeaderBar({
    required this.selectedCount,
    required this.onClear,
    required this.onSelectAll,
    required this.onInvert,
    super.key,
  });

  final int selectedCount;
  final VoidCallback onClear;
  final VoidCallback onSelectAll;
  final VoidCallback onInvert;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.md,
        vertical: Insets.xs,
      ),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.fromLTRB(
        Insets.md,
        Insets.sm,
        Insets.md,
        Insets.xs,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: S.t('cancelSelection'),
            onPressed: onClear,
          ),
          const SizedBox(width: Insets.xs),
          Text(
            '$selectedCount selected',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onPrimaryContainer,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: onSelectAll,
            child: Text(S.t('selectAll')),
          ),
          TextButton(
            onPressed: onInvert,
            child: Text(S.t('invert')),
          ),
        ],
      ),
    );
  }
}
