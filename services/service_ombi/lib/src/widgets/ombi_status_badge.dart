import 'package:core_models/core_models.dart';
import 'package:flutter/material.dart';

import '../models/ombi_models.dart';
import 'ombi_visuals.dart';

/// Ombi's Recently Requested cards' words, which the dashboard shows.
String ombiRecentStatusLabel(OmbiRecentStatus status) => switch (status) {
      OmbiRecentStatus.pending => S.t('pending'),
      OmbiRecentStatus.approved => S.t('approved'),
      OmbiRecentStatus.partlyAvailable => S.t('partiallyAvailable'),
      OmbiRecentStatus.available => S.t('available'),
      OmbiRecentStatus.denied => S.t('denied'),
    };

/// Where a request stands, as a small filled pill, in the words of Ombi's
/// request list.
class OmbiStatusBadge extends StatelessWidget {
  const OmbiStatusBadge({required this.status, super.key});

  final OmbiRequestStatus status;

  static String labelFor(OmbiRequestStatus status) => switch (status) {
        OmbiRequestStatus.pending => S.t('pendingApproval'),
        OmbiRequestStatus.processing => S.t('processingRequest'),
        OmbiRequestStatus.available => S.t('available'),
        OmbiRequestStatus.denied => S.t('denied'),
      };

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final (Color foreground, Color background, IconData icon) =
        switch (status) {
      OmbiRequestStatus.pending => (
          cs.onPrimaryContainer,
          cs.primaryContainer,
          Icons.hourglass_top_rounded,
        ),
      OmbiRequestStatus.processing => (
          cs.onSecondaryContainer,
          cs.secondaryContainer,
          Icons.autorenew_rounded,
        ),
      OmbiRequestStatus.available => (
          cs.onTertiaryContainer,
          cs.tertiaryContainer,
          Icons.check_circle_outline_rounded,
        ),
      OmbiRequestStatus.denied => (
          cs.onErrorContainer,
          cs.errorContainer,
          Icons.block_rounded,
        ),
    };
    return OmbiPill(
      label: labelFor(status),
      foreground: foreground,
      background: background,
      icon: icon,
    );
  }
}

/// The tag Ombi puts beside a request that asked for a 4K copy too.
class OmbiFourKBadge extends StatelessWidget {
  const OmbiFourKBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return OmbiPill(
      label: '4K',
      foreground: cs.onSurfaceVariant,
      background: cs.surfaceContainerHighest,
    );
  }
}
