import 'package:core_models/core_models.dart';
import 'package:core_networking/core_networking.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bazarr_api.dart';
import 'bazarr_providers.dart';
import 'bazarr_search_screen.dart';
import 'bazarr_subtitle_chips.dart';
import 'models/bazarr_models.dart';

/// Per-series subtitle view: the episode list with present / missing subtitle
/// chips, a manual-search action per episode, and delete on downloaded subs.
class BazarrSeriesDetailScreen extends ConsumerWidget {
  const BazarrSeriesDetailScreen({
    required this.instance,
    required this.series,
    super.key,
  });

  final Instance instance;
  final BazarrSeries series;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BazarrEpisodesArgs args =
        (instance: instance, seriesId: series.sonarrSeriesId);
    final AsyncValue<List<BazarrEpisode>> episodes =
        ref.watch(bazarrEpisodesProvider(args));
    return Scaffold(
      appBar:
          AppBar(title: Text(series.title, overflow: TextOverflow.ellipsis)),
      body: AsyncValueView<List<BazarrEpisode>>(
          value: episodes,
          onRetry: () => ref.invalidate(bazarrEpisodesProvider(args)),
          data: (List<BazarrEpisode> eps) {
            
            if (eps.isEmpty) {
              return EasyRefresh(
        header: ClassicHeader(
          dragText: S.t('pullToRefresh'),
          armedText: S.t('releaseReady'),
          readyText: S.t('refreshing'),
          processingText: S.t('refreshing'),
          processedText: S.t('succeeded'),
          failedText: S.t('failed'),
          messageText: S.t('lastUpdatedAtT'),
        ),
        onRefresh: () async => ref.invalidate(bazarrEpisodesProvider(args)),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: <Widget>[
            SizedBox(height: 100),
            EmptyView(
                icon: Icons.subtitles_outlined,
                title: S.t('noEpisodes'),
                message: S.t('thisSeriesHasNoEpisodeFilesInBazarr'),
              ),
          ],
        ),
      );
            }
            return EasyRefresh(
      header: ClassicHeader(
        dragText: S.t('pullToRefresh'),
        armedText: S.t('releaseReady'),
        readyText: S.t('refreshing'),
        processingText: S.t('refreshing'),
        processedText: S.t('succeeded'),
        failedText: S.t('failed'),
        messageText: S.t('lastUpdatedAtT'),
      ),
      onRefresh: () async => ref.invalidate(bazarrEpisodesProvider(args)),
      child: ListView.builder(
              padding: Insets.page,
              itemCount: eps.length + 1,
              itemBuilder: (BuildContext context, int index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: Insets.md),
                    child: _HeaderCard(series: series),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: Insets.sm),
                  child: _EpisodeCard(
                    instance: instance,
                    episode: eps[index - 1],
                  ),
                );
              },
            ),
    );
          
          },
        ),
    );
  }
}

/// Tonal hero header: a poster-stand-in tile, the title, and metadata pills.
class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.series});

  final BazarrSeries series;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Insets.lg),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.tv_outlined, color: cs.primary, size: 28),
          ),
          const SizedBox(width: Insets.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  series.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: Insets.sm),
                Wrap(
                  spacing: Insets.xs,
                  runSpacing: Insets.xs,
                  children: <Widget>[
                    if (series.year != null)
                      _MetaPill(
                        icon: Icons.calendar_today,
                        label: '${series.year}',
                        color: cs.secondary,
                      ),
                    _MetaPill(
                      icon: series.monitored
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      label: series.monitored ? S.t('monitored') : S.t('unmonitored'),
                      color: series.monitored ? cs.primary : cs.outline,
                    ),
                    _MetaPill(
                      icon: Icons.video_library_outlined,
                      label: S.t('seriesEpisodeFileCountFiles1', [series.episodeFileCount]),
                      color: cs.tertiary,
                    ),
                    if (series.episodeMissingCount > 0)
                      _MetaPill(
                        icon: Icons.report_outlined,
                        label: S.t('seriesEpisodeMissingCountMissing1', [series.episodeMissingCount]),
                        color: cs.error,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EpisodeCard extends ConsumerWidget {
  const _EpisodeCard({required this.instance, required this.episode});

  final Instance instance;
  final BazarrEpisode episode;

  String get _code => 'S${(episode.season ?? 0).toString().padLeft(2, '0')}'
      'E${(episode.episode ?? 0).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Insets.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '$_code · ${episode.title}',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                tooltip: S.t('searchSubtitles'),
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.subtitles_outlined),
                onPressed: () =>
                    Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute<void>(
                    builder: (_) => BazarrSubtitleSearchScreen(
                      instance: instance,
                      isMovie: false,
                      id: episode.sonarrEpisodeId,
                      seriesId: episode.sonarrSeriesId,
                      title: '$_code · ${episode.title}',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.sm),
          BazarrSubtitleChips(
            present: episode.subtitles,
            missing: episode.missingSubtitles,
            onDeletePresent: (BazarrSubtitle s) =>
                _confirmDelete(context, ref, s),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    BazarrSubtitle s,
  ) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    if (!(s.path?.isNotEmpty ?? false)) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            S.t('thisSubtitleIsEmbeddedInTheVideoAndCannotBeRemovedHere'),
          ),
        ),
      );
      return;
    }
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(S.t('deleteSubtitle')),
        content: Text(
          'Remove the ${s.name.isNotEmpty ? s.name : s.code2.toUpperCase()} ' +
          S.t('subtitleForCode1', [_code]),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(S.t('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(S.t('delete')),
          ),
        ],
      ),
    );
    if (ok != true) {
      return;
    }
    try {
      final BazarrApi api = await ref.read(bazarrApiProvider(instance).future);
      await api.deleteEpisodeSubtitle(
        seriesId: episode.sonarrSeriesId,
        episodeId: episode.sonarrEpisodeId,
        subtitle: s,
      );
      ref.invalidate(
        bazarrEpisodesProvider(
          (instance: instance, seriesId: episode.sonarrSeriesId),
        ),
      );
      ref.invalidate(bazarrWantedProvider(instance));
      ref.invalidate(bazarrBadgesProvider(instance));
      messenger.showSnackBar(SnackBar(content: Text(S.t('subtitleDeleted'))));
    } on Object catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(S.t('deleteFailedErrE1', [_err(e)]))),
      );
    }
  }
}

/// Small tonal metadata pill (icon + label), tinted by [color].
class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

String _err(Object e) {
  if (e is NetworkException && e.message.isNotEmpty) {
    return e.message;
  }
  return 'request failed';
}
