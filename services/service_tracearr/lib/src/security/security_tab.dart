import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/tracearr_providers.dart';
import 'widgets/security_incident_ledger_section.dart';

/// Main Security destination for Tracearr in Atrium.
///
/// Features Sentinel policy violation ledger, severity filtering,
/// real-time triage, and incident resolution tracking.
class SecurityTab extends ConsumerStatefulWidget {
  const SecurityTab({
    required this.instance,
    super.key,
  });

  final Instance instance;

  @override
  ConsumerState<SecurityTab> createState() => _SecurityTabState();
}

class _SecurityTabState extends ConsumerState<SecurityTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    ref.invalidate(tracearrViolationsProvider(widget.instance));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    ref.listen<int>(
      tracearrHomeScrollToTopProvider((widget.instance, 4)),
      (previous, next) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        }
      },
    );

    final violationsAsync = ref.watch(tracearrViolationsProvider(widget.instance));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          tooltip: S.t('openMenu'),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.instance.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              S.t('security'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: EasyRefresh(
        header: ClassicHeader(
          dragText: S.t('pullToRefresh'),
          armedText: S.t('releaseReady'),
          readyText: S.t('refreshingSecurityAuditLedger'),
          processingText: S.t('refreshingSecurityAuditLedger'),
          processedText: S.t('updated'),
          failedText: S.t('failed'),
          messageText: S.t('lastUpdatedAtT'),
        ),
        onRefresh: _refreshAll,
        child: ListView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.lg,
            vertical: Insets.md,
          ),
          children: [
            // Sentinel Policy Violation Incident Ledger
            RepaintBoundary(
              child: SecurityIncidentLedgerSection(
                instance: widget.instance,
                violationsAsync: violationsAsync,
                onRetry: () =>
                    ref.invalidate(tracearrViolationsProvider(widget.instance)),
              ),
            ),
            const SizedBox(height: Insets.xl),
          ],
        ),
      ),
    );
  }
}
