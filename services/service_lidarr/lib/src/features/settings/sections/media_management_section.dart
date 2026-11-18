import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../generated/generated.dart';
import '../../../lidarr_api.dart';
import '../../../lidarr_providers.dart';

/// Media Management and Track Naming configuration section.
class MediaManagementSection extends ConsumerStatefulWidget {
  const MediaManagementSection({required this.instance, super.key});

  final Instance instance;

  @override
  ConsumerState<MediaManagementSection> createState() =>
      _MediaManagementSectionState();
}

class _MediaManagementSectionState
    extends ConsumerState<MediaManagementSection> {
  // Track naming state
  bool? _renameTracks;
  TextEditingController? _stdFormatController;
  TextEditingController? _multiDiscFormatController;
  TextEditingController? _artistFolderFormatController;
  int? _colonReplacementFormat;

  // Media management state
  bool? _autoUnmonitor;
  bool? _createEmptyFolders;
  bool? _deleteEmptyFolders;
  bool? _watchLibrary;
  bool? _copyHardlinks;
  bool? _enableMediaInfo;
  TextEditingController? _extraExtensionsController;

  @override
  void dispose() {
    _stdFormatController?.dispose();
    _multiDiscFormatController?.dispose();
    _artistFolderFormatController?.dispose();
    _extraExtensionsController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    final AsyncValue<NamingConfigResource> asyncNaming =
        ref.watch(lidarrNamingConfigProvider(widget.instance));
    final AsyncValue<MediaManagementConfigResource> asyncMM =
        ref.watch(lidarrMediaManagementConfigProvider(widget.instance));

    return Scaffold(
      body: EasyRefresh(
        onRefresh: () async {
          ref.invalidate(lidarrNamingConfigProvider(widget.instance));
          ref.invalidate(lidarrMediaManagementConfigProvider(widget.instance));
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Insets.md,
            Insets.md,
            Insets.md,
            80,
          ),
          children: [
            // 1. Track Naming Configuration Card
            Card(
              elevation: 0,
              color: cs.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(Insets.md),
                child: AsyncValueView<NamingConfigResource>(
                  value: asyncNaming,
                  data: (NamingConfigResource naming) {
                    _renameTracks ??= naming.renameTracks ?? false;
                    _stdFormatController ??= TextEditingController(
                      text: naming.standardTrackFormat ??
                          S.t('artistNameAlbumTitleReleaseYearTrack00TrackTitle'),
                    );
                    _multiDiscFormatController ??= TextEditingController(
                      text: naming.multiDiscTrackFormat ??
                          S.t('medium00Track00TrackTitle'),
                    );
                    _artistFolderFormatController ??= TextEditingController(
                      text: naming.artistFolderFormat ?? S.t('artistName'),
                    );
                    _colonReplacementFormat ??=
                        naming.colonReplacementFormat ?? 0;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: cs.primaryContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.drive_file_rename_outline,
                                color: cs.onPrimaryContainer,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Track Naming Formats',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Insets.sm),
                        SwitchListTile(
                          title: Text(S.t('renameTracksAutomatically')),
                          value: _renameTracks ?? false,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (bool val) =>
                              setState(() => _renameTracks = val),
                        ),
                        const SizedBox(height: Insets.xs),
                        // Quick Token Helper Chips
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            S.t('artistName'),
                            S.t('albumTitle_2'),
                            '{Release Year}',
                            '{Track:00}',
                            S.t('trackTitle'),
                          ].map((String token) {
                            return ActionChip(
                              label: Text(
                                token,
                                style: const TextStyle(fontSize: 11),
                              ),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              onPressed: () {
                                if (_stdFormatController != null) {
                                  final text = _stdFormatController!.text;
                                  final selection =
                                      _stdFormatController!.selection;
                                  final newText = selection.isValid
                                      ? text.replaceRange(
                                          selection.start,
                                          selection.end,
                                          token,
                                        )
                                      : '$text/$token';
                                  _stdFormatController!.text = newText;
                                }
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: Insets.xs),
                        TextField(
                          controller: _stdFormatController,
                          decoration: InputDecoration(
                            labelText: S.t('standardTrackFormat'),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: Insets.sm),
                        TextField(
                          controller: _multiDiscFormatController,
                          decoration: InputDecoration(
                            labelText: S.t('multiDiscTrackFormat'),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: Insets.sm),
                        TextField(
                          controller: _artistFolderFormatController,
                          decoration: InputDecoration(
                            labelText: S.t('artistFolderFormat'),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: Insets.sm),
                        DropdownButtonFormField<int>(
                          initialValue: _colonReplacementFormat,
                          decoration: InputDecoration(
                            labelText: S.t('colonReplacementFormat'),
                            border: OutlineInputBorder(),
                          ),
                          items: <DropdownMenuItem<int>>[
                            DropdownMenuItem(
                              value: 0,
                              child: Text(S.t('delete_2')),
                            ),
                            DropdownMenuItem(
                              value: 1,
                              child: Text(S.t('dash')),
                            ),
                            DropdownMenuItem(
                              value: 2,
                              child: Text(S.t('spaceDash')),
                            ),
                            DropdownMenuItem(
                              value: 3,
                              child: Text(S.t('spaceDashSpace')),
                            ),
                            DropdownMenuItem(
                              value: 4,
                              child: Text(S.t('smartReplace')),
                            ),
                            DropdownMenuItem(
                              value: 5,
                              child: Text(S.t('leaveAsIs')),
                            ),
                            if (_colonReplacementFormat != null &&
                                _colonReplacementFormat! > 5)
                              DropdownMenuItem(
                                value: _colonReplacementFormat,
                                child: Text(S.t('formatColonReplacementFormat1', [_colonReplacementFormat])),
                              ),
                          ],
                          onChanged: (int? val) {
                            if (val != null) {
                              setState(() => _colonReplacementFormat = val);
                            }
                          },
                        ),
                        const SizedBox(height: Insets.md),
                        FilledButton.icon(
                          icon: const Icon(Icons.save, size: 18),
                          label: Text(S.t('saveNamingFormats')),
                          onPressed: () async {
                            final ScaffoldMessengerState messenger =
                                ScaffoldMessenger.of(context);
                            final NamingConfigResource payload =
                                naming.copyWith(
                              renameTracks: _renameTracks,
                              standardTrackFormat: _stdFormatController?.text,
                              multiDiscTrackFormat:
                                  _multiDiscFormatController?.text,
                              artistFolderFormat:
                                  _artistFolderFormatController?.text,
                              colonReplacementFormat: _colonReplacementFormat,
                            );

                            try {
                              final LidarrApi api = await ref.read(
                                lidarrApiProvider(widget.instance).future,
                              );
                              final ApiResponse<NamingConfigResource> resp =
                                  await api.namingConfig.putConfigNamingById(
                                id: '${naming.id}',
                                body: payload,
                              );
                              if (!resp.isSuccess) {
                                throw Exception(
                                  resp.error?.message ??
                                      'Failed to update naming config',
                                );
                              }

                              ref.invalidate(
                                lidarrNamingConfigProvider(widget.instance),
                              );
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(S.t('namingConfigurationSaved')),
                                ),
                              );
                            } catch (e) {
                              messenger.showSnackBar(
                                SnackBar(content: Text(S.t('errorE1', [e]))),
                              );
                            }
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: Insets.lg),

            // 2. Media Management Configuration Card
            Card(
              elevation: 0,
              color: cs.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(Insets.md),
                child: AsyncValueView<MediaManagementConfigResource>(
                  value: asyncMM,
                  data: (MediaManagementConfigResource mm) {
                    _autoUnmonitor ??=
                        mm.autoUnmonitorPreviouslyDownloadedTracks ?? false;
                    _createEmptyFolders ??=
                        mm.createEmptyArtistFolders ?? false;
                    _deleteEmptyFolders ??= mm.deleteEmptyFolders ?? false;
                    _watchLibrary ??= mm.watchLibraryForChanges ?? false;
                    _copyHardlinks ??= mm.copyUsingHardlinks ?? false;
                    _enableMediaInfo ??= mm.enableMediaInfo ?? true;
                    _extraExtensionsController ??= TextEditingController(
                      text: mm.extraFileExtensions ?? '',
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: cs.secondaryContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.folder_shared_outlined,
                                color: cs.onSecondaryContainer,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Media Management Options',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Insets.sm),
                        SwitchListTile(
                          title: Text(S.t('unmonitorDownloadedTracks')),
                          subtitle: Text(
                            S.t('unmonitorTracksWhenImportedOrDeleted'),
                          ),
                          value: _autoUnmonitor ?? false,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (bool val) =>
                              setState(() => _autoUnmonitor = val),
                        ),
                        SwitchListTile(
                          title: Text(S.t('createEmptyArtistFolders')),
                          value: _createEmptyFolders ?? false,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (bool val) =>
                              setState(() => _createEmptyFolders = val),
                        ),
                        SwitchListTile(
                          title: Text(S.t('deleteEmptyFolders')),
                          value: _deleteEmptyFolders ?? false,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (bool val) =>
                              setState(() => _deleteEmptyFolders = val),
                        ),
                        SwitchListTile(
                          title: Text(S.t('watchLibraryForChanges')),
                          value: _watchLibrary ?? false,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (bool val) =>
                              setState(() => _watchLibrary = val),
                        ),
                        SwitchListTile(
                          title: Text(S.t('useHardlinksInsteadOfCopy')),
                          value: _copyHardlinks ?? false,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (bool val) =>
                              setState(() => _copyHardlinks = val),
                        ),
                        SwitchListTile(
                          title: Text(S.t('analyseAudioWithMediaInfo')),
                          value: _enableMediaInfo ?? true,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (bool val) =>
                              setState(() => _enableMediaInfo = val),
                        ),
                        const SizedBox(height: Insets.xs),
                        TextField(
                          controller: _extraExtensionsController,
                          decoration: InputDecoration(
                            labelText: S.t('extraFileExtensions'),
                            hintText: S.t('eGCueNfoLog'),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: Insets.md),
                        FilledButton.icon(
                          icon: const Icon(Icons.save, size: 18),
                          label: Text(S.t('saveMediaManagement')),
                          onPressed: () async {
                            final ScaffoldMessengerState messenger =
                                ScaffoldMessenger.of(context);
                            final MediaManagementConfigResource payload =
                                mm.copyWith(
                              autoUnmonitorPreviouslyDownloadedTracks:
                                  _autoUnmonitor,
                              createEmptyArtistFolders: _createEmptyFolders,
                              deleteEmptyFolders: _deleteEmptyFolders,
                              watchLibraryForChanges: _watchLibrary,
                              copyUsingHardlinks: _copyHardlinks,
                              enableMediaInfo: _enableMediaInfo,
                              extraFileExtensions:
                                  _extraExtensionsController?.text,
                            );

                            try {
                              final LidarrApi api = await ref.read(
                                lidarrApiProvider(widget.instance).future,
                              );
                              final ApiResponse<MediaManagementConfigResource>
                                  resp = await api.mediaManagementConfig
                                      .putConfigMediamanagementById(
                                id: '${mm.id}',
                                body: payload,
                              );
                              if (!resp.isSuccess) {
                                throw Exception(
                                  resp.error?.message ??
                                      'Failed to update media management config',
                                );
                              }

                              ref.invalidate(
                                lidarrMediaManagementConfigProvider(
                                  widget.instance,
                                ),
                              );
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Media management configuration saved!',
                                  ),
                                ),
                              );
                            } catch (e) {
                              messenger.showSnackBar(
                                SnackBar(content: Text(S.t('errorE1', [e]))),
                              );
                            }
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
