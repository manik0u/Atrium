import 'package:collection/collection.dart';
import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/lidarr_formatters.dart';
import '../../generated/generated.dart';
import '../../lidarr_api.dart';
import '../../lidarr_artwork.dart';
import '../../lidarr_providers.dart';
import '../artists/edit_album_sheet.dart';
import '../search/interactive_search_screen.dart';
import '../track_files/rename_dialog.dart';
import '../track_files/retag_dialog.dart';
import '../track_files/track_file_editor_screen.dart';

/// Dedicated canonical screen for inspecting and managing a single Lidarr album.
class AlbumDetailScreen extends ConsumerStatefulWidget {
  const AlbumDetailScreen({
    required this.instance,
    required this.artistId,
    required this.albumId,
    this.initialAlbum,
    super.key,
  });

  final Instance instance;
  final int artistId;
  final int albumId;
  final AlbumResource? initialAlbum;

  @override
  ConsumerState<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends ConsumerState<AlbumDetailScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshAlbum() async {
    ref.invalidate(
      lidarrAlbumByIdProvider((widget.instance, widget.albumId)),
    );
    ref.invalidate(
      lidarrTracksForAlbumProvider(
        (widget.instance, widget.artistId, widget.albumId),
      ),
    );
    ref.invalidate(
      lidarrTrackFilesForAlbumProvider((widget.instance, widget.albumId)),
    );
    ref.invalidate(
      lidarrAlbumsForArtistProvider((widget.instance, widget.artistId)),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.t('refreshingAlbumAndTracks')),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _autoSearch(AlbumResource album) async {
    final int id = album.id ?? widget.albumId;
    try {
      final LidarrApi api =
          await ref.read(lidarrApiProvider(widget.instance).future);
      final ApiResponse<CommandResource> resp = await api.executeCommand(
        'AlbumSearch',
        {
          'albumIds': [id],
        },
      );
      if (!resp.isSuccess) {
        throw Exception(resp.error?.message ?? S.t('failedToTriggerSearch'));
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.t('searchingForAlbumTitle')Album'}"...'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.t('searchFailedE1', [e])),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _toggleMonitored(AlbumResource album) async {
    final bool newMonitored = !(album.monitored ?? false);
    final int id = album.id ?? widget.albumId;
    try {
      final LidarrApi api =
          await ref.read(lidarrApiProvider(widget.instance).future);
      final ApiResponse<void> resp = await api.album.putAlbumMonitor(
        body: AlbumsMonitoredResource(
          albumIds: [id],
          monitored: newMonitored,
        ),
      );
      if (!resp.isSuccess) {
        throw Exception(resp.error?.message ?? S.t('failedToToggleMonitoring'));
      }
      await _refreshAlbum();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.t('failedToToggleMonitoringE1', [e])),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _interactiveSearch(AlbumResource? album) {
    LidarrInteractiveSearchScreen.show(
      context,
      instance: widget.instance,
      title: album?.title ?? S.t('album'),
      albumId: widget.albumId,
      artistId: widget.artistId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    final AsyncValue<AlbumResource> asyncAlbum = ref.watch(
      lidarrAlbumByIdProvider((widget.instance, widget.albumId)),
    );
    final AsyncValue<List<TrackResource>> asyncTracks = ref.watch(
      lidarrTracksForAlbumProvider(
        (widget.instance, widget.artistId, widget.albumId),
      ),
    );
    final AsyncValue<List<TrackFileResource>> asyncTrackFiles = ref.watch(
      lidarrTrackFilesForAlbumProvider((widget.instance, widget.albumId)),
    );

    final AlbumResource album = asyncAlbum.value ??
        widget.initialAlbum ??
        AlbumResource(id: widget.albumId);
    final List<TrackResource> tracks = asyncTracks.value ?? [];
    final List<TrackFileResource> trackFiles = asyncTrackFiles.value ?? [];

    final Map<int, TrackFileResource> trackFilesMap = {
      for (final TrackFileResource file in trackFiles)
        if (file.id != null) file.id!: file,
    };

    final Map<int, List<TrackResource>> groupedMedia = groupBy(
      tracks,
      (TrackResource t) => t.mediumNumber ?? 1,
    );
    final bool isMultiDisc = groupedMedia.length > 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          album.title ?? S.t('album'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: S.t('refreshScan'),
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAlbum,
          ),
          PopupMenuButton<String>(
            tooltip: S.t('moreOptions'),
            onSelected: (String value) {
              switch (value) {
                case 'retag':
                  showLidarrRetagDialog(
                    context,
                    instance: widget.instance,
                    artistId: widget.artistId,
                    albumId: widget.albumId,
                    albumTitle: album.title,
                  );
                  break;
                case 'rename':
                  showLidarrRenameDialog(
                    context,
                    instance: widget.instance,
                    artistId: widget.artistId,
                    albumId: widget.albumId,
                    albumTitle: album.title,
                  );
                  break;
                case 'track_files':
                  LidarrTrackFileEditorScreen.show(
                    context,
                    instance: widget.instance,
                    artistId: widget.artistId,
                    albumId: widget.albumId,
                    albumTitle: album.title,
                  );
                  break;
                case 'edit':
                  showLidarrEditAlbumSheet(
                    context,
                    instance: widget.instance,
                    artistId: widget.artistId,
                    album: album,
                    artistName: album.artist?.artistName,
                  );
                  break;
                case 'delete':
                  showLidarrDeleteAlbumDialog(
                    context,
                    instance: widget.instance,
                    artistId: widget.artistId,
                    album: album,
                    ref: ref,
                  );
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: 'track_files',
                child: ListTile(
                  leading: Icon(Icons.audio_file_outlined),
                  title: Text(S.t('trackFilesEditor')),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'rename',
                child: ListTile(
                  leading: Icon(Icons.drive_file_rename_outline),
                  title: Text(S.t('renameFiles')),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'retag',
                child: ListTile(
                  leading: Icon(Icons.label_outlined),
                  title: Text(S.t('retagFiles')),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit_outlined),
                  title: Text(S.t('editAlbum')),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete_outline, color: cs.error),
                  title: Text(
                    S.t('deleteAlbum'),
                    style: TextStyle(color: cs.error),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: EasyRefresh(
        onRefresh: _refreshAlbum,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 1. Compact M3 Hero Header Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: _AlbumHeroCard(
                  instance: widget.instance,
                  album: album,
                  onToggleMonitored: () => _toggleMonitored(album),
                  onAutoSearch: () => _autoSearch(album),
                  onInteractiveSearch: () => _interactiveSearch(album),
                ),
              ),
            ),

            // 2. Multi-Medium Tracklist Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    Text(
                      'Tracks & Media',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${tracks.length})',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Multi-Medium Tracklist Slivers
            if (asyncTracks.isLoading && tracks.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: ExpressiveProgressIndicator()),
                ),
              )
            else if (asyncTracks.hasError && tracks.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.error_outline, size: 36, color: cs.error),
                        const SizedBox(height: 8),
                        Text(
                          'Failed to load tracks',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextButton.icon(
                          icon: const Icon(Icons.refresh, size: 16),
                          label: Text(S.t('retry')),
                          onPressed: _refreshAlbum,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (tracks.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(
                    child: Text(
                      S.t('noTracksAvailableForThisAlbum'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              )
            else ...[
              for (final MapEntry<int, List<TrackResource>> entry
                  in groupedMedia.entries) ...[
                if (isMultiDisc)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                      child: Row(
                        children: [
                          Icon(
                            Icons.album_outlined,
                            size: 16,
                            color: cs.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Disc ${entry.key}',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cs.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${entry.value.length} tracks)',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final TrackResource track = entry.value[index];
                        final TrackFileResource? trackFile =
                            track.trackFileId != null
                                ? trackFilesMap[track.trackFileId]
                                : null;
                        return _TrackListTile(
                          track: track,
                          trackFile: trackFile,
                          index: index,
                          onTap: () => _showTrackDetails(
                            context,
                            widget.instance,
                            widget.artistId,
                            widget.albumId,
                            track,
                            trackFile,
                          ),
                        );
                      },
                      childCount: entry.value.length,
                    ),
                  ),
                ),
              ],
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  void _showTrackDetails(
    BuildContext context,
    Instance instance,
    int artistId,
    int albumId,
    TrackResource track,
    TrackFileResource? trackFile,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (BuildContext ctx) {
        final ThemeData theme = Theme.of(context);
        final ColorScheme cs = theme.colorScheme;
        final bool hasFile = track.hasFile == true;
        final MediaInfoResource? media = trackFile?.mediaInfo;
        final String? qualityName = trackFile?.quality?.quality?.name;

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      hasFile ? Icons.audio_file : Icons.music_note,
                      color: cs.primary,
                      size: 28,
                    ),
                    const SizedBox(width: Insets.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.title ?? S.t('trackDetails'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Disc ${track.mediumNumber ?? 1} • Track ${track.trackNumber ?? '-'} • ${LidarrFormatters.formatDurationMs(track.duration)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Insets.sm),
                const Divider(),
                const SizedBox(height: Insets.sm),
                Text(
                  'Media & File Information',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(height: Insets.sm),
                if (!hasFile || trackFile == null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      S.t('noDownloadedTrackFileOnDiskForThisTrack'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  )
                else ...[
                  if (qualityName != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Chip(
                        avatar: const Icon(Icons.high_quality, size: 16),
                        label: Text(qualityName),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  if (trackFile.path != null)
                    _InfoRow(
                      label: S.t('path'),
                      value: trackFile.path!,
                      isMonospace: true,
                    ),
                  if (trackFile.size != null)
                    _InfoRow(
                      label: S.t('size'),
                      value: LidarrFormatters.formatBytes(trackFile.size),
                    ),
                  if (media?.audioCodec != null &&
                      media!.audioCodec!.isNotEmpty)
                    _InfoRow(
                      label: S.t('codec'),
                      value: media.audioCodec!,
                    ),
                  if (media?.audioBitRate != null &&
                      media!.audioBitRate!.isNotEmpty)
                    _InfoRow(
                      label: S.t('bitrate'),
                      value: media.audioBitRate!,
                    ),
                  if (media?.audioChannels != null)
                    _InfoRow(
                      label: S.t('channels'),
                      value: '${media!.audioChannels} ch',
                    ),
                  if (media?.audioBits != null && media!.audioBits!.isNotEmpty)
                    _InfoRow(
                      label: S.t('bitDepth'),
                      value: LidarrFormatters.formatBitDepth(media.audioBits),
                    ),
                  if (media?.audioSampleRate != null &&
                      media!.audioSampleRate!.isNotEmpty)
                    _InfoRow(
                      label: S.t('sampleRate'),
                      value: LidarrFormatters.formatSampleRate(
                        media.audioSampleRate,
                      ),
                    ),
                  const SizedBox(height: Insets.md),
                  const Divider(),
                  const SizedBox(height: Insets.sm),
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.delete_outline, color: cs.error),
                    title: Text(
                      S.t('deleteAudioFile_2'),
                      style: TextStyle(
                        color: cs.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      S.t('permanentlyRemoveAudioFileFromDisk'),
                    ),
                    contentPadding: EdgeInsets.zero,
                    onTap: () async {
                      final bool? confirm = await showDialog<bool>(
                        context: context,
                        builder: (dCtx) => AlertDialog(
                          title: Text(S.t('deleteAudioFile')),
                          content: Text(
                            S.t('areYouSureYouWantToDeleteTrackTitle')track'}" from disk?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dCtx, false),
                              child: Text(S.t('cancel')),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: cs.error,
                              ),
                              onPressed: () => Navigator.pop(dCtx, true),
                              child: Text(S.t('delete')),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true && trackFile.id != null) {
                        try {
                          final api = await ref
                              .read(lidarrApiProvider(instance).future);
                          await api.trackFile
                              .deleteTrackfileById(id: trackFile.id!);
                          await _refreshAlbum();
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(S.t('trackFileDeleted')),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(S.t('failedToDeleteFileE1', [e])),
                                backgroundColor: cs.error,
                              ),
                            );
                          }
                        }
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Compact M3 Hero Card
// ---------------------------------------------------------------------------

class _AlbumHeroCard extends StatelessWidget {
  const _AlbumHeroCard({
    required this.instance,
    required this.album,
    required this.onToggleMonitored,
    required this.onAutoSearch,
    required this.onInteractiveSearch,
  });

  final Instance instance;
  final AlbumResource album;
  final VoidCallback onToggleMonitored;
  final VoidCallback onAutoSearch;
  final VoidCallback onInteractiveSearch;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    final String? coverUrl =
        LidarrArtwork.albumCoverUrl(instance, album.images);
    final String releaseDate =
        album.releaseDate != null ? album.releaseDate!.split('T').first : '';
    final String albumType = album.albumType ?? S.t('album');
    final bool isMonitored = album.monitored ?? false;

    final int trackFiles = album.statistics?.trackFileCount ?? 0;
    final int totalTracks = album.statistics?.totalTrackCount ?? 0;
    final double progress =
        totalTracks > 0 ? (trackFiles / totalTracks).clamp(0.0, 1.0) : 0.0;
    final String sizeStr =
        LidarrFormatters.formatBytes(album.statistics?.sizeOnDisk);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Row: 72x72 Cover + Info
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 72,
                height: 72,
                child: coverUrl != null
                    ? AtriumNetworkImage(
                        imageUrl: coverUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          color: cs.surfaceContainerHighest,
                          child: const Icon(Icons.album_outlined, size: 32),
                        ),
                      )
                    : Container(
                        color: cs.surfaceContainerHighest,
                        child: const Icon(Icons.album_outlined, size: 32),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.title ?? S.t('album'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (album.artist?.artistName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      album.artist!.artistName!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (albumType.isNotEmpty) albumType,
                      if (releaseDate.isNotEmpty) releaseDate,
                      if (totalTracks > 0) '$trackFiles/$totalTracks tracks',
                      if (sizeStr.isNotEmpty && sizeStr != '0 B') sizeStr,
                    ].join(' • '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Completion & Progress Bar
        if (totalTracks > 0) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 3.5,
              backgroundColor: cs.surfaceContainerHighest,
              color: progress >= 1.0 ? cs.tertiary : cs.primary,
            ),
          ),
          const SizedBox(height: 10),
        ],

        // Action Bar
        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                icon: Icon(
                  isMonitored ? Icons.bookmark : Icons.bookmark_border,
                  size: 18,
                ),
                label: Text(
                  isMonitored ? S.t('monitored') : S.t('unmonitored'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: isMonitored
                      ? cs.primaryContainer
                      : cs.surfaceContainerHighest,
                  foregroundColor:
                      isMonitored ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                onPressed: onToggleMonitored,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.tonalIcon(
                icon: const Icon(Icons.search, size: 18),
                label: Text(
                  S.t('autoSearch'),
                  style: TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                onPressed: onAutoSearch,
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              icon: const Icon(Icons.manage_search, size: 20),
              tooltip: S.t('interactiveSearch'),
              style: IconButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
              onPressed: onInteractiveSearch,
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Track List Tile
// ---------------------------------------------------------------------------

class _TrackListTile extends StatelessWidget {
  const _TrackListTile({
    required this.track,
    required this.trackFile,
    required this.index,
    required this.onTap,
  });

  final TrackResource track;
  final TrackFileResource? trackFile;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final bool hasFile = track.hasFile == true;
    final bool isExplicit = track.explicit == true;
    final String? format =
        trackFile?.mediaInfo?.audioCodec ?? trackFile?.quality?.quality?.name;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            // Track Number
            SizedBox(
              width: 32,
              child: Text(
                track.trackNumber ?? '${index + 1}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: hasFile ? cs.onSurfaceVariant : cs.outline,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 8),

            // Title + Duration + Codec chip
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          track.title ?? S.t('unknownTrack'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: hasFile ? cs.onSurface : cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (isExplicit) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: cs.outlineVariant,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'E',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        LidarrFormatters.formatDurationMs(track.duration),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      if (format != null && format.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            format.toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: cs.primary,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Trailing Status Checkmark / Missing
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(
                hasFile ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 18,
                color: hasFile ? cs.primary : cs.outlineVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.isMonospace = false,
  });

  final String label;
  final String value;
  final bool isMonospace;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: isMonospace ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
