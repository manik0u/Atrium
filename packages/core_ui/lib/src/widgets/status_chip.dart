import 'package:core_models/core_models.dart';
import 'package:flutter/material.dart';

/// A small colored pill conveying an instance's [Health] at a glance.
class StatusChip extends StatelessWidget {
  const StatusChip({required this.health, this.compact = false, super.key});

  final Health health;

  /// When true, renders just the dot + short label in a tighter footprint
  /// (used inside dense list tiles).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final (Color color, String label) = switch (health) {
      Health.ok => (Colors.green, S.t('online')),
      Health.warning => (Colors.orange, S.t('warning')),
      Health.error => (scheme.error, S.t('offline')),
      Health.unknown => (scheme.outline, S.t('unknown')),
    };

    final Widget dot = Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );

    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          dot,
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      );
    }

    return Chip(
      avatar: dot,
      label: Text(label),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
