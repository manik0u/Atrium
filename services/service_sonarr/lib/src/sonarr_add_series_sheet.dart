import 'package:collection/collection.dart';
import 'package:core_models/core_models.dart';
import 'package:core_storage/core_storage.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progress_indicator_m3e/progress_indicator_m3e.dart';

import 'models/sonarr_series.dart';
import 'sonarr_api.dart';
import 'sonarr_providers.dart';

class SonarrAddSeriesSheet extends ConsumerStatefulWidget {
  const SonarrAddSeriesSheet({
    required this.instance,
    required this.series,
    super.key,
  });

  final Instance instance;
  final SonarrSeries series;

  @override
  ConsumerState<SonarrAddSeriesSheet> createState() =>
      _SonarrAddSeriesSheetState();
}

class _SonarrAddSeriesSheetState extends ConsumerState<SonarrAddSeriesSheet> {
  String? _selectedRootFolder;
  int? _selectedQualityProfileId;
  String _selectedMonitorType = 'all';
  String _selectedSeriesType = 'standard';
  bool _seasonFolder = true;
  bool _searchForMissing = false;
  bool _searchForCutoffUnmet = false;
  final List<int> _selectedTagIds = [];
  bool _submitting = false;

  static const List<String> _monitorTypes = <String>[
    'all',
    'future',
    'missing',
    'existing',
    'firstSeason',
    'latestSeason',
    'none',
  ];
  static const List<String> _seriesTypes = <String>[
    'standard',
    'daily',
    'anime',
  ];

  /// What was picked on the last add to this instance (issue #234).
  late final Map<String, Object?> _remembered =
      AddChoices.read('sonarr', widget.instance.id) ?? <String, Object?>{};

  @override
  void initState() {
    super.initState();
    final Object? monitor = _remembered['monitor'];
    if (monitor is String && _monitorTypes.contains(monitor)) {
      _selectedMonitorType = monitor;
    }
    final Object? seriesType = _remembered['seriesType'];
    if (seriesType is String && _seriesTypes.contains(seriesType)) {
      _selectedSeriesType = seriesType;
    }
    final Object? seasonFolder = _remembered['seasonFolder'];
    if (seasonFolder is bool) _seasonFolder = seasonFolder;
    final Object? missing = _remembered['searchForMissing'];
    if (missing is bool) _searchForMissing = missing;
    final Object? cutoff = _remembered['searchForCutoffUnmet'];
    if (cutoff is bool) _searchForCutoffUnmet = cutoff;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    final AsyncValue<List<Map<String, dynamic>>> rootFoldersAsync =
        ref.watch(sonarrRootFoldersProvider(widget.instance));
    final AsyncValue<List<Map<String, dynamic>>> qualityProfilesAsync =
        ref.watch(sonarrQualityProfilesProvider(widget.instance));
    final AsyncValue<List<Map<String, dynamic>>> tagsAsync =
        ref.watch(sonarrTagsProvider(widget.instance));

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) {
        return Scaffold(
          backgroundColor: cs.surface,
          appBar: AppBar(
            scrolledUnderElevation: 0.0,
            backgroundColor: cs.surface,
            automaticallyImplyLeading: false,
            title: Text(S.t('addSeriesOptions')),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(Insets.md),
                  children: [
                    // Hero card representing the selected series (28dp corners)
                    Card(
                      elevation: 0,
                      color: cs.primaryContainer.withValues(alpha: 0.15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(Insets.md),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: SizedBox(
                                width: 70,
                                height: 105,
                                child: _PosterImage(
                                  instance: widget.instance,
                                  series: widget.series,
                                ),
                              ),
                            ),
                            const SizedBox(width: Insets.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.series.title,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${widget.series.year} • ${widget.series.network ?? "Unknown Network"}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    widget.series.overview ??
                                        S.t('noOverviewAvailable'),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: Insets.lg),

                    // Configuration Options card (16dp corners)
                    Card(
                      elevation: 0,
                      color: cs.surfaceContainerHigh,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(Insets.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Configuration',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: Insets.md),

                            // Root folder selection
                            rootFoldersAsync.when(
                              data: (List<Map<String, dynamic>> folders) {
                                if (folders.isEmpty) {
                                  return Text(
                                    S.t('noRootFolderConfiguredInSonarr'),
                                    style: TextStyle(color: cs.error),
                                  );
                                }
                                if (_selectedRootFolder == null) {
                                  final Object? last =
                                      _remembered['rootFolderPath'];
                                  _selectedRootFolder = folders.any(
                                    (f) => f['path'] == last,
                                  )
                                      ? last! as String
                                      : folders.first['path'] as String;
                                }

                                return DropdownButtonFormField<String>(
                                  initialValue: _selectedRootFolder,
                                  decoration: InputDecoration(
                                    labelText: S.t('rootFolder'),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  items: folders.map((f) {
                                    final String path = f['path'] as String;
                                    final int freeBytes =
                                        f['freeSpace'] as int? ?? 0;
                                    final double freeGb =
                                        freeBytes / (1024 * 1024 * 1024);
                                    return DropdownMenuItem<String>(
                                      value: path,
                                      child: Text(
                                        '$path (${freeGb.toStringAsFixed(1)} GB free)',
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedRootFolder = val;
                                    });
                                  },
                                );
                              },
                              loading: () => const LinearProgressIndicatorM3E(
                                shape: ProgressM3EShape.flat,
                              ),
                              error: (e, s) =>
                                  Text(S.t('errorLoadingFoldersE1', [e])),
                            ),
                            const SizedBox(height: Insets.md),

                            // Quality Profile selection
                            qualityProfilesAsync.when(
                              data: (List<Map<String, dynamic>> profiles) {
                                if (profiles.isEmpty) {
                                  return Text(
                                    S.t('noQualityProfilesFound'),
                                    style: TextStyle(color: cs.error),
                                  );
                                }
                                if (_selectedQualityProfileId == null) {
                                  final Object? last =
                                      _remembered['qualityProfileId'];
                                  _selectedQualityProfileId = last is int &&
                                          profiles.any((p) => p['id'] == last)
                                      ? last
                                      : profiles.first['id'] as int;
                                }

                                return DropdownButtonFormField<int>(
                                  initialValue: _selectedQualityProfileId,
                                  decoration: InputDecoration(
                                    labelText: S.t('qualityProfile'),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  items: profiles.map((p) {
                                    return DropdownMenuItem<int>(
                                      value: p['id'] as int,
                                      child: Text(p['name'] as String),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedQualityProfileId = val;
                                    });
                                  },
                                );
                              },
                              loading: () => const SizedBox.shrink(),
                              error: (e, s) =>
                                  Text(S.t('errorLoadingProfilesE1', [e])),
                            ),
                            const SizedBox(height: Insets.md),

                            // Monitor options dropdown
                            DropdownButtonFormField<String>(
                              initialValue: _selectedMonitorType,
                              decoration: InputDecoration(
                                labelText: S.t('monitor'),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: 'all',
                                  child: Text(S.t('allEpisodes')),
                                ),
                                DropdownMenuItem(
                                  value: 'future',
                                  child: Text(S.t('futureEpisodes')),
                                ),
                                DropdownMenuItem(
                                  value: 'missing',
                                  child: Text(S.t('missingEpisodes')),
                                ),
                                DropdownMenuItem(
                                  value: 'existing',
                                  child: Text(S.t('existingEpisodes')),
                                ),
                                DropdownMenuItem(
                                  value: 'firstSeason',
                                  child: Text(S.t('firstSeason')),
                                ),
                                DropdownMenuItem(
                                  value: 'latestSeason',
                                  child: Text(S.t('latestSeason')),
                                ),
                                DropdownMenuItem(
                                  value: 'none',
                                  child: Text(S.t('none')),
                                ),
                              ],
                              onChanged: (val) {
                                setState(() {
                                  _selectedMonitorType = val ?? 'all';
                                });
                              },
                            ),
                            const SizedBox(height: Insets.md),

                            // Series Type dropdown
                            DropdownButtonFormField<String>(
                              initialValue: _selectedSeriesType,
                              decoration: InputDecoration(
                                labelText: S.t('seriesType'),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: 'standard',
                                  child: Text(S.t('standard')),
                                ),
                                DropdownMenuItem(
                                  value: 'daily',
                                  child: Text(S.t('daily')),
                                ),
                                DropdownMenuItem(
                                  value: 'anime',
                                  child: Text(S.t('anime')),
                                ),
                              ],
                              onChanged: (val) {
                                setState(() {
                                  _selectedSeriesType = val ?? 'standard';
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: Insets.md),

                    // Switches card (16dp corners)
                    Card(
                      elevation: 0,
                      color: cs.surfaceContainerHigh,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: Text(S.t('seasonFolder')),
                            subtitle:
                                Text(S.t('storeFilesInSeasonFolders')),
                            value: _seasonFolder,
                            onChanged: (val) {
                              setState(() {
                                _seasonFolder = val;
                              });
                            },
                          ),
                          const Divider(height: 1),
                          SwitchListTile(
                            title: Text(S.t('searchMissingEpisodes')),
                            subtitle:
                                Text(S.t('searchIndexersForMissingFiles')),
                            value: _searchForMissing,
                            onChanged: (val) {
                              setState(() {
                                _searchForMissing = val;
                              });
                            },
                          ),
                          const Divider(height: 1),
                          SwitchListTile(
                            title: Text(S.t('searchCutoffUnmet')),
                            subtitle: Text(S.t('upgradeLowerQualityFiles')),
                            value: _searchForCutoffUnmet,
                            onChanged: (val) {
                              setState(() {
                                _searchForCutoffUnmet = val;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Insets.md),

                    // Tags card (16dp corners)
                    tagsAsync.maybeWhen(
                      data: (List<Map<String, dynamic>> tags) {
                        if (tags.isEmpty) return const SizedBox.shrink();
                        return Card(
                          elevation: 0,
                          color: cs.surfaceContainerHigh,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(Insets.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  S.t('tags'),
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: cs.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: Insets.sm),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: tags.map((t) {
                                    final int id = t['id'] as int;
                                    final String label = t['label'] as String;
                                    final bool selected =
                                        _selectedTagIds.contains(id);
                                    return FilterChip(
                                      label: Text(label),
                                      selected: selected,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      onSelected: (val) {
                                        setState(() {
                                          if (val) {
                                            _selectedTagIds.add(id);
                                          } else {
                                            _selectedTagIds.remove(id);
                                          }
                                        });
                                      },
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),

              // Add Action Button Panel (Capsule stadium button)
              Padding(
                padding: const EdgeInsets.all(Insets.md),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      shape: const StadiumBorder(),
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                    ),
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? ExpressiveProgressIndicator(color: cs.onPrimary)
                        : Text(
                            S.t('addSeries'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    if (_selectedRootFolder == null || _selectedQualityProfileId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(S.t('pleaseSelectARootFolderAndQualityProfile')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final SonarrApi api =
          await ref.read(sonarrApiProvider(widget.instance).future);

      // Construct payload matching SeriesResource and AddSeriesOptions in v3.yaml
      final Map<String, dynamic> payload = {
        'title': widget.series.title,
        'tvdbId': widget.series.tvdbId,
        'qualityProfileId': _selectedQualityProfileId,
        'titleSlug': widget.series.titleSlug ??
            widget.series.title
                .toLowerCase()
                .replaceAll(RegExp(r'[^a-z0-9]'), '-'),
        'images': widget.series.images.map((i) => i.toJson()).toList(),
        'seasons': widget.series.seasons.map((s) => s.toJson()).toList(),
        'monitored': true,
        'seasonFolder': _seasonFolder,
        'seriesType': _selectedSeriesType,
        'rootFolderPath': _selectedRootFolder,
        'tags': _selectedTagIds,
        'addOptions': {
          'monitor': _selectedMonitorType,
          'searchForMissingEpisodes': _searchForMissing,
          'searchForCutoffUnmetEpisodes': _searchForCutoffUnmet,
        },
      };

      // Taken with the payload: the controls stay live while the add runs.
      final Map<String, Object?> choices = <String, Object?>{
        'rootFolderPath': _selectedRootFolder,
        'qualityProfileId': _selectedQualityProfileId,
        'monitor': _selectedMonitorType,
        'seriesType': _selectedSeriesType,
        'seasonFolder': _seasonFolder,
        'searchForMissing': _searchForMissing,
        'searchForCutoffUnmet': _searchForCutoffUnmet,
      };

      await api.addSeries(payload);
      AddChoices.write('sonarr', widget.instance.id, choices);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.t('addedWidgetSeriesTitleSuccessfully1', [widget.series.title])),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        // Refresh local series list provider
        ref.invalidate(sonarrSeriesProvider(widget.instance));
        // Only the sheet: whoever opened it decides what else closes.
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.t('failedToAddSeriesE1', [e])),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }
}

class _PosterImage extends ConsumerWidget {
  const _PosterImage({required this.instance, required this.series});

  final Instance instance;
  final SonarrSeries series;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SonarrApi? api = ref.watch(sonarrApiProvider(instance)).value;
    final SonarrImage? poster = series.images.firstWhereOrNull(
      (SonarrImage i) => i.coverType == 'poster',
    );
    final String? url =
        poster == null ? null : api?.posterUrl(poster, preferRemote: true);

    if (url == null) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        child: const Center(
          child: Icon(Icons.tv),
        ),
      );
    }

    return AtriumNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        child: const Center(
          child: ExpressiveProgressIndicator(),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        child: const Center(
          child: Icon(Icons.broken_image_outlined),
        ),
      ),
    );
  }
}
