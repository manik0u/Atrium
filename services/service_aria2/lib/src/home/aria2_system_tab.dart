import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../aria2_api.dart';
import '../aria2_format.dart';
import '../aria2_providers.dart';
import '../models/aria2_snapshot.dart';

/// Tab 3: Daemon metadata, enabled features, telemetry, and daemon maintenance operations.
class Aria2SystemTab extends ConsumerStatefulWidget {
  const Aria2SystemTab({
    required this.instance,
    this.onOpenDrawer,
    super.key,
  });

  final Instance instance;
  final VoidCallback? onOpenDrawer;

  @override
  ConsumerState<Aria2SystemTab> createState() => _Aria2SystemTabState();
}

class _Aria2SystemTabState extends ConsumerState<Aria2SystemTab> {
  late final ScrollController _scrollController;
  String _sessionId = '';
  bool _loadingSession = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _fetchSessionId();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchSessionId() async {
    setState(() => _loadingSession = true);
    try {
      final Aria2Api api = await ref.read(
        aria2ApiProvider(widget.instance).future,
      );
      final String sid = await api.getSessionId();
      if (mounted) setState(() => _sessionId = sid);
    } catch (_) {
      // Ignore
    } finally {
      if (mounted) setState(() => _loadingSession = false);
    }
  }

  Future<void> _run(
    BuildContext context,
    String successMessage,
    Future<void> Function(Aria2Api api) action,
  ) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      final Aria2Api api = await ref.read(
        aria2ApiProvider(widget.instance).future,
      );
      await action(api);
      messenger.showSnackBar(
        SnackBar(
          content: Text(successMessage),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text("Échec de l'action : $e")));
    } finally {
      if (mounted) {
        ref.invalidate(aria2SnapshotProvider(widget.instance));
      }
    }
  }

  Future<void> _confirmShutdown(
    BuildContext context, {
    bool force = false,
  }) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(force ? "Forcer l'arrêt d'aria2 ?" : 'Arrêter le démon aria2 ?'),
        content: Text(
          force
              ? 'Cela terminera immédiatement le processus aria2 sans attendre la fin des téléchargements.'
              : 'Cela arrêtera proprement tous les téléchargements actifs, enregistrera la session et quittera le démon.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Arrêter'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted && context.mounted) {
      await _run(
        context,
        'Shutdown signal sent to aria2',
        (Aria2Api api) => force ? api.forceShutdown() : api.shutdown(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final AsyncValue<Aria2Snapshot> snapshot = ref.watch(
      aria2SnapshotProvider(widget.instance),
    );

    ref.listen<int>(aria2ScrollToTopProvider((widget.instance, 2)), (
      previous,
      next,
    ) {
      if (next > 0 && _scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: widget.onOpenDrawer ??
              () => Scaffold.of(context).openDrawer(),
        ),
        title: const Text('Système'),
        actions: <Widget>[
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (String val) {
              if (val == 'save_session') {
                _run(
                  context,
                  'Session saved to file',
                  (Aria2Api api) => api.saveSession(),
                );
              } else if (val == 'shutdown') {
                _confirmShutdown(context);
              } else if (val == 'force_shutdown') {
                _confirmShutdown(context, force: true);
              }
            },
            itemBuilder: (BuildContext context) =>
                const <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'save_session',
                    child: ListTile(
                      leading: Icon(Icons.save_outlined),
                      title: Text('Enregistrer la session'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: 'shutdown',
                    child: ListTile(
                      leading: Icon(Icons.power_settings_new),
                      title: Text('Arrêter le démon'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'force_shutdown',
                    child: ListTile(
                      leading: Icon(Icons.flash_on),
                      title: Text('Arrêt forcé'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: AsyncValueView<Aria2Snapshot>(
        value: snapshot,
        onRetry: () {
          ref.invalidate(aria2SnapshotProvider(widget.instance));
          _fetchSessionId();
        },
        data: (Aria2Snapshot data) {
          return EasyRefresh(
            onRefresh: () async {
              ref.invalidate(aria2SnapshotProvider(widget.instance));
              final Future<void> session = _fetchSessionId();
              // Hold the indicator until the new stats are in, not just the
              // session ID.
              await ref.read(aria2SnapshotProvider(widget.instance).future);
              await session;
            },
            child: ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                Insets.md,
                Insets.xs,
                Insets.md,
                Insets.xl,
              ),
              children: <Widget>[
                // Section 1: Daemon & Version
                Material(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(Insets.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Icon(Icons.computer_outlined, color: cs.primary),
                            const SizedBox(width: Insets.sm),
                            Text(
                              'Daemon Information',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Insets.md),
                        _Row(
                          label: "Version d'aria2",
                          value: data.version.version.isEmpty
                              ? 'Unknown'
                              : data.version.version,
                        ),
                        _Row(
                          label: 'ID de session',
                          value: _loadingSession
                              ? 'Loading...'
                              : _sessionId.isEmpty
                              ? 'Not available'
                              : _sessionId,
                        ),
                        const _Row(
                          label: 'Protocole RPC',
                          value: 'JSON-RPC 2.0 (HTTP)',
                        ),
                        _Row(
                          label: 'Secret protégé',
                          value: (widget.instance.auth is InstanceAuthApiKey &&
                                  (widget.instance.auth as InstanceAuthApiKey)
                                      .apiKey
                                      .isNotEmpty)
                              ? 'Yes (token configured)'
                              : 'Non (RPC ouvert)',
                        ),
                        const SizedBox(height: Insets.sm),
                        Text(
                          'Enabled Capabilities',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: Insets.xs),
                        Wrap(
                          spacing: Insets.xs,
                          runSpacing: Insets.xs,
                          children: <Widget>[
                            for (final String feature
                                in data.version.enabledFeatures)
                              Chip(
                                label: Text(
                                  feature,
                                  style: theme.textTheme.labelSmall,
                                ),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: Insets.md),

                // Section 2: Global Telemetry
                Material(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(Insets.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Icon(Icons.query_stats, color: cs.primary),
                            const SizedBox(width: Insets.sm),
                            Text(
                              'Global Telemetry',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Insets.md),
                        _Row(
                          label: 'Téléchargements actifs',
                          value: '${data.stat.numActive}',
                        ),
                        _Row(
                          label: 'En attente dans la file',
                          value: '${data.stat.numWaiting}',
                        ),
                        _Row(
                          label: 'Arrêtés en mémoire',
                          value: '${data.stat.numStopped}',
                        ),
                        _Row(
                          label: 'Arrêtés au total (historique)',
                          value: '${data.stat.numStoppedTotal}',
                        ),
                        _Row(
                          label: 'Bande passante de téléchargement',
                          value: aria2FmtRate(data.stat.downloadSpeed),
                        ),
                        _Row(
                          label: "Bande passante d'envoi",
                          value: aria2FmtRate(data.stat.uploadSpeed),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: Insets.md),

                // Section 3: Operations & Maintenance
                Material(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(Insets.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Icon(Icons.build_outlined, color: cs.primary),
                            const SizedBox(width: Insets.sm),
                            Text(
                              'Maintenance Operations',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Insets.md),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.save_outlined),
                          title: const Text('Enregistrer la session maintenant'),
                          subtitle: const Text(
                            'Vider les téléchargements actifs et en file vers le fichier de session',
                          ),
                          trailing: OutlinedButton(
                            onPressed: () => _run(
                              context,
                              'Session saved to disk',
                              (Aria2Api api) => api.saveSession(),
                            ),
                            child: const Text('Enregistrer'),
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.cleaning_services_outlined),
                          title: const Text('Purger les résultats arrêtés'),
                          subtitle: const Text(
                            'Effacer tous les résultats terminés, en erreur et retirés',
                          ),
                          trailing: OutlinedButton(
                            onPressed: () => _run(
                              context,
                              'Résultats arrêtés purgés du démon',
                              (Aria2Api api) => api.purgeDownloadResult(),
                            ),
                            child: const Text('Purger'),
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.power_settings_new,
                            color: cs.error,
                          ),
                          title: Text(
                            'Shutdown daemon',
                            style: TextStyle(color: cs.error),
                          ),
                          subtitle: const Text(
                            'Arrêter toutes les tâches et terminer le processus aria2',
                          ),
                          trailing: FilledButton.tonal(
                            style: FilledButton.styleFrom(
                              backgroundColor: cs.errorContainer,
                              foregroundColor: cs.onErrorContainer,
                            ),
                            onPressed: () => _confirmShutdown(context),
                            child: const Text('Arrêter'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
