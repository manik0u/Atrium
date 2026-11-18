import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/nzbget_history_entry.dart';
import 'nzbget_api.dart';
import 'nzbget_providers.dart';

class NzbgetHistoryTab extends ConsumerWidget {
  const NzbgetHistoryTab({required this.instance, super.key});

  final Instance instance;

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function(NzbgetApi api) action,
  ) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      final NzbgetApi api =
          await ref.read(nzbgetApiProvider(instance).future);
      await action(api);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(S.t('actionFailedE1', [e]))));
    } finally {
      if (context.mounted) {
        ref.invalidate(nzbgetHistoryProvider(instance));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<NzbgetHistoryEntry>> history =
        ref.watch(nzbgetHistoryProvider(instance));
    return AsyncValueView<List<NzbgetHistoryEntry>>(
      value: history,
      onRetry: () => ref.invalidate(nzbgetHistoryProvider(instance)),
      data: (List<NzbgetHistoryEntry> entries) {
        if (entries.isEmpty) {
          return EmptyView(
            icon: Icons.history,
            title: S.t('noHistory'),
            message: S.t('completedDownloadsWillShowUpHere'),
          );
        }
        return EasyRefresh(
          header: const ClassicHeader(),
          onRefresh: () async => ref.invalidate(nzbgetHistoryProvider(instance)),
          child: ListView.builder(
            padding: Insets.page,
            itemCount: entries.length,
            itemBuilder: (BuildContext context, int index) {
              final NzbgetHistoryEntry entry = entries[index];
              final ColorScheme cs = Theme.of(context).colorScheme;
              final (IconData icon, Color color) = entry.isFailure
                  ? (Icons.error_outline, cs.error)
                  : entry.isWarning
                      ? (Icons.warning_amber_outlined, cs.tertiary)
                      : (Icons.check_circle_outline, cs.primary);
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(icon, color: color),
                title: Text(
                  entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${entry.status}'
                  '${entry.category.isEmpty ? '' : ' - ${entry.category}'}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (entry.isFailure)
                      IconButton(
                        tooltip: S.t('retry'),
                        icon: const Icon(Icons.refresh),
                        onPressed: () => _run(
                          context,
                          ref,
                          (NzbgetApi api) =>
                              api.retryHistoryItem(entry.nzbId),
                        ),
                      ),
                    IconButton(
                      tooltip: S.t('delete'),
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        final bool? confirmed = await showDialog<bool>(
                          context: context,
                          builder: (BuildContext dialogContext) => AlertDialog(
                            title: Text(S.t('deleteHistoryEntry')),
                            content: Text(entry.name),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(false),
                                child: Text(S.t('cancel')),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(true),
                                child: Text(S.t('delete')),
                              ),
                            ],
                          ),
                        );
                        if ((confirmed ?? false) && context.mounted) {
                          await _run(
                            context,
                            ref,
                            (NzbgetApi api) =>
                                api.deleteHistoryItem(entry.nzbId),
                          );
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
