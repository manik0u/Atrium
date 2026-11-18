import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/sonarr_series.dart';
import 'sonarr_providers.dart';

class SonarrSettingsFormScreen extends ConsumerStatefulWidget {
  const SonarrSettingsFormScreen({
    required this.instance,
    required this.series,
    super.key,
  });

  final Instance instance;
  final SonarrSeries series;

  @override
  ConsumerState<SonarrSettingsFormScreen> createState() =>
      _SonarrSettingsFormScreenState();
}

class _SonarrSettingsFormScreenState
    extends ConsumerState<SonarrSettingsFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _pathController;
  late final Future<Map<String, dynamic>> _rawSeriesFuture;

  bool _monitored = true;
  String? _monitorNewItems;
  int? _selectedQualityProfileId;
  String _seriesType = 'standard';
  bool _seasonFolder = true;
  List<int> _selectedTagIds = [];

  bool _saving = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _pathController = TextEditingController();
    // Fetch the raw series JSON exactly once. Creating this future inline in
    // build() would refire GET /series/{id} on every setState.
    _rawSeriesFuture = ref
        .read(sonarrApiProvider(widget.instance).future)
        .then((api) => api.getSeriesRaw(widget.series.id));
  }

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  void _initializeValues(Map<String, dynamic> rawSeries) {
    if (_initialized) return;
    _initialized = true;

    _pathController.text = (rawSeries['path'] as String?) ?? '';
    _monitored = (rawSeries['monitored'] as bool?) ?? true;
    // Only present on Sonarr versions that support it. When absent the
    // control is hidden and the field is never written back.
    _monitorNewItems = rawSeries['monitorNewItems'] as String?;
    _selectedQualityProfileId = rawSeries['qualityProfileId'] as int?;
    _seriesType = (rawSeries['seriesType'] as String?) ?? 'standard';
    _seasonFolder = (rawSeries['seasonFolder'] as bool?) ?? true;
    _selectedTagIds =
        List<int>.from((rawSeries['tags'] as Iterable?) ?? <int>[]);
  }

  Future<void> _save(Map<String, dynamic> rawSeries) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final api = await ref.read(sonarrApiProvider(widget.instance).future);

    // Overlay only edited fields on the fetched raw series map so everything
    // else round-trips untouched.
    final Map<String, dynamic> payload = Map<String, dynamic>.from(rawSeries);
    payload['path'] = _pathController.text.trim();
    payload['monitored'] = _monitored;
    if (_monitorNewItems != null) {
      payload['monitorNewItems'] = _monitorNewItems;
    }
    payload['qualityProfileId'] = _selectedQualityProfileId;
    payload['seriesType'] = _seriesType;
    payload['seasonFolder'] = _seasonFolder;
    payload['tags'] = _selectedTagIds;

    try {
      await api.updateSeriesRaw(payload);
      ref.invalidate(
        sonarrSeriesByIdProvider((widget.instance, widget.series.id)),
      );
      ref.invalidate(sonarrSeriesProvider(widget.instance));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.t('seriesSettingsSavedSuccessfully'))),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.t('failedToSaveSettingsE1', [e]))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final profilesAsync =
        ref.watch(sonarrQualityProfilesProvider(widget.instance));
    final tagsAsync = ref.watch(sonarrTagsProvider(widget.instance));

    return FutureBuilder<Map<String, dynamic>>(
      future: _rawSeriesFuture,
      builder: (context, snapshot) {
        final rawSeries = snapshot.data;
        if (rawSeries != null) {
          _initializeValues(rawSeries);
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(S.t('editSeriesSettings')),
            actions: [
              if (_saving)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: ExpressiveProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (rawSeries != null)
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: () => _save(rawSeries),
                ),
            ],
          ),
          body: snapshot.hasError
              ? Center(
                  child: Text(
                    'Error loading series metadata: ${snapshot.error}',
                  ),
                )
              : rawSeries == null
                  ? const Center(child: ExpressiveProgressIndicator())
                  : Form(
                      key: _formKey,
                      child: ListView(
                        padding: const EdgeInsets.all(Insets.md),
                        children: [
                          Text(
                            widget.series.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: Insets.md),

                          // Path field
                          TextFormField(
                            controller: _pathController,
                            decoration: InputDecoration(
                              labelText: S.t('path'),
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.folder_open),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return S.t('pathCannotBeEmpty');
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: Insets.md),

                          // Monitoring: Sonarr stores a `monitored` bool on
                          // the series, plus `monitorNewItems` (all/none) on
                          // versions that support it.
                          SwitchListTile(
                            title: Text(S.t('monitored')),
                            subtitle: Text(
                              S.t('downloadMonitoredEpisodesForThisSeries'),
                            ),
                            secondary: const Icon(Icons.bookmark_outline),
                            value: _monitored,
                            onChanged: (val) {
                              setState(() => _monitored = val);
                            },
                          ),
                          if (_monitorNewItems != null) ...[
                            const SizedBox(height: Insets.md),
                            DropdownButtonFormField<String>(
                              initialValue: _monitorNewItems,
                              decoration: InputDecoration(
                                labelText: S.t('monitorNewSeasons'),
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.bookmark_add_outlined),
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: 'all',
                                  child: Text(S.t('all')),
                                ),
                                DropdownMenuItem(
                                  value: 'none',
                                  child: Text(S.t('none')),
                                ),
                                // Keep any unexpected server value selectable
                                // so the dropdown never hits the
                                // missing-value assert.
                                if (_monitorNewItems != 'all' &&
                                    _monitorNewItems != 'none')
                                  DropdownMenuItem(
                                    value: _monitorNewItems,
                                    child: Text(_monitorNewItems!),
                                  ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _monitorNewItems = val);
                                }
                              },
                            ),
                          ],
                          const SizedBox(height: Insets.md),

                          // Quality Profile dropdown
                          profilesAsync.when(
                            loading: () => const Center(
                              child: ExpressiveProgressIndicator(),
                            ),
                            error: (err, stack) =>
                                Text(S.t('errorLoadingProfilesErr1', [err])),
                            data: (profiles) {
                              // Ensure the selected profile exists; a stale
                              // or missing id would trip the dropdown's
                              // missing-value assert.
                              final hasSelected = profiles.any(
                                (p) => p['id'] == _selectedQualityProfileId,
                              );
                              if (!hasSelected) {
                                _selectedQualityProfileId = profiles.isNotEmpty
                                    ? profiles.first['id'] as int?
                                    : null;
                              }
                              return DropdownButtonFormField<int>(
                                initialValue: _selectedQualityProfileId,
                                decoration: InputDecoration(
                                  labelText: S.t('qualityProfile'),
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.high_quality),
                                ),
                                items: profiles.map((p) {
                                  return DropdownMenuItem<int>(
                                    value: p['id'] as int,
                                    child: Text(
                                      (p['name'] as String?) ?? S.t('unknown'),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(
                                    () => _selectedQualityProfileId = val,
                                  );
                                },
                              );
                            },
                          ),
                          const SizedBox(height: Insets.md),

                          // Series Type dropdown
                          DropdownButtonFormField<String>(
                            initialValue: _seriesType,
                            decoration: InputDecoration(
                              labelText: S.t('seriesType'),
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.tv),
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
                              if (_seriesType != 'standard' &&
                                  _seriesType != 'daily' &&
                                  _seriesType != 'anime')
                                DropdownMenuItem(
                                  value: _seriesType,
                                  child: Text(_seriesType),
                                ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _seriesType = val);
                              }
                            },
                          ),
                          const SizedBox(height: Insets.md),

                          // Season Folder switch
                          SwitchListTile(
                            title: Text(S.t('useSeasonFolder')),
                            subtitle: Text(
                              S.t('storeFilesInSubfoldersForEachSeason'),
                            ),
                            value: _seasonFolder,
                            onChanged: (val) {
                              setState(() => _seasonFolder = val);
                            },
                          ),
                          const SizedBox(height: Insets.md),

                          // Tags multi-selector section
                          tagsAsync.when(
                            loading: () => const Center(
                              child: ExpressiveProgressIndicator(),
                            ),
                            error: (err, stack) =>
                                Text(S.t('errorLoadingTagsErr1', [err])),
                            data: (tags) {
                              if (tags.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    S.t('tags'),
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: Insets.xs),
                                  Wrap(
                                    spacing: Insets.xs,
                                    runSpacing: Insets.xs,
                                    children: tags.map((t) {
                                      final id = t['id'] as int;
                                      final label =
                                          (t['label'] as String?) ?? '';
                                      final isSelected =
                                          _selectedTagIds.contains(id);
                                      return FilterChip(
                                        label: Text(label),
                                        selected: isSelected,
                                        onSelected: (selected) {
                                          setState(() {
                                            if (selected) {
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
                              );
                            },
                          ),
                        ],
                      ),
                    ),
        );
      },
    );
  }
}
