import 'package:core_models/core_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../generated/generated.dart';
import '../../../lidarr_api.dart';
import '../../../lidarr_providers.dart';
import '../../track_files/rename_dialog.dart';
import '../../track_files/retag_dialog.dart';

/// Floating bottom action bar presenting bulk actions for selected albums.
class AlbumBulkActionsBar extends ConsumerWidget {
  const AlbumBulkActionsBar({
    required this.instance,
    required this.artistId,
    required this.selectedIds,
    required this.onClear,
    super.key,
  });

  final Instance instance;
  final int artistId;
  final Set<int> selectedIds;
  final VoidCallback onClear;

  Future<void> _setMonitoring(
    BuildContext context,
    WidgetRef ref,
    bool monitored,
  ) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final Color errorColor = Theme.of(context).colorScheme.error;
    try {
      final LidarrApi api = await ref.read(lidarrApiProvider(instance).future);
      final ApiResponse<void> resp = await api.album.putAlbumMonitor(
        body: AlbumsMonitoredResource(
          albumIds: selectedIds.toList(),
          monitored: monitored,
        ),
      );
      if (!resp.isSuccess) {
        throw Exception(
          resp.error?.message ?? S.t('failedToUpdateAlbumMonitoring'),
        );
      }

      ref.invalidate(lidarrAlbumsForArtistProvider((instance, artistId)));
      ref.invalidate(lidarrArtistByIdProvider((instance, artistId)));
      ref.invalidate(lidarrArtistsProvider(instance));
      onClear();

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${selectedIds.length} ${selectedIds.length == 1 ? 'album' : 'albums'} set to ${monitored ? S.t('monitored') : S.t('unmonitored')}',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(S.t('failedE1', [e])),
          backgroundColor: errorColor,
        ),
      );
    }
  }

  Future<void> _searchSelected(BuildContext context, WidgetRef ref) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final Color errorColor = Theme.of(context).colorScheme.error;
    try {
      final LidarrApi api = await ref.read(lidarrApiProvider(instance).future);
      final ApiResponse<CommandResource> resp = await api.executeCommand(
        'AlbumSearch',
        {'albumIds': selectedIds.toList()},
      );
      if (!resp.isSuccess) {
        throw Exception(
          resp.error?.message ?? S.t('failedToTriggerSearchForSelectedAlbums'),
        );
      }

      onClear();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Searching for missing tracks in ${selectedIds.length} ${selectedIds.length == 1 ? 'album' : 'albums'}...',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(S.t('searchFailedE1', [e])),
          backgroundColor: errorColor,
        ),
      );
    }
  }

  Future<void> _deleteSelected(BuildContext context, WidgetRef ref) async {
    bool deleteFiles = false;
    bool addImportListExclusion = true;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            final ThemeData theme = Theme.of(context);
            final ColorScheme cs = theme.colorScheme;

            return AlertDialog(
              title: Text(S.t('deleteSelectedIdsLengthAlbums1', [selectedIds.length])),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Are you sure you want to delete ${selectedIds.length} selected albums from your library?',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    title: Text(S.t('deleteFilesFromDisk')),
                    subtitle: Text(S.t('permanentlyRemoveAudioFiles')),
                    value: deleteFiles,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (bool? val) =>
                        setState(() => deleteFiles = val ?? false),
                  ),
                  CheckboxListTile(
                    title: Text(S.t('addImportListExclusion')),
                    subtitle:
                        Text(S.t('preventReAddingByAutomatedLists')),
                    value: addImportListExclusion,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (bool? val) =>
                        setState(() => addImportListExclusion = val ?? false),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(S.t('cancel')),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.error,
                    foregroundColor: cs.onError,
                  ),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text(S.t('delete')),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final Color errorColor = Theme.of(context).colorScheme.error;
    try {
      final LidarrApi api = await ref.read(lidarrApiProvider(instance).future);
      for (final int albumId in selectedIds) {
        await api.album.deleteAlbumById(
          id: albumId,
          deleteFiles: deleteFiles,
          addImportListExclusion: addImportListExclusion,
        );
      }

      ref.invalidate(lidarrAlbumsForArtistProvider((instance, artistId)));
      ref.invalidate(lidarrArtistByIdProvider((instance, artistId)));
      ref.invalidate(lidarrArtistsProvider(instance));
      onClear();

      messenger.showSnackBar(
        SnackBar(
          content: Text(S.t('selectedidsLengthAlbumsDeletedSuccessfully1', [selectedIds.length])),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(S.t('failedToDeleteAlbumsE1', [e])),
          backgroundColor: errorColor,
        ),
      );
    }
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surfaceContainer,
      elevation: 4,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionItem(
                icon: Icons.bookmark,
                label: S.t('monitor'),
                color: cs.primary,
                onPressed: () => _setMonitoring(context, ref, true),
              ),
              _buildActionItem(
                icon: Icons.bookmark_border,
                label: S.t('unmonitor'),
                color: cs.onSurfaceVariant,
                onPressed: () => _setMonitoring(context, ref, false),
              ),
              _buildActionItem(
                icon: Icons.search,
                label: S.t('search'),
                color: cs.primary,
                onPressed: () => _searchSelected(context, ref),
              ),
              _buildActionItem(
                icon: Icons.delete_outline,
                label: S.t('delete'),
                color: cs.error,
                onPressed: () => _deleteSelected(context, ref),
              ),
              _buildActionItem(
                icon: Icons.more_vert,
                label: S.t('more'),
                color: cs.onSurfaceVariant,
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    showDragHandle: true,
                    useRootNavigator: true,
                    builder: (BuildContext ctx) => SafeArea(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(
                                Icons.drive_file_rename_outline,
                              ),
                              title: Text(S.t('renameFiles')),
                              subtitle: Text(
                                'Rename audio files for ${selectedIds.length} albums',
                              ),
                              onTap: () {
                                Navigator.pop(ctx);
                                showLidarrRenameDialog(
                                  context,
                                  instance: instance,
                                  artistId: artistId,
                                  albumIds: selectedIds,
                                );
                                onClear();
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.sell_outlined),
                              title: Text(S.t('writeAudioTags')),
                              subtitle: Text(
                                'Sync metadata tags for ${selectedIds.length} albums',
                              ),
                              onTap: () {
                                Navigator.pop(ctx);
                                showLidarrRetagDialog(
                                  context,
                                  instance: instance,
                                  artistId: artistId,
                                  albumIds: selectedIds,
                                );
                                onClear();
                              },
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
