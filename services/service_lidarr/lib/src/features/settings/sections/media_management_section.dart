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
                          "{Nom de l'artiste}/{Titre de l'album} ({Année de sortie})/{Piste:00} - {Titre de la piste}",
                    );
                    _multiDiscFormatController ??= TextEditingController(
                      text: naming.multiDiscTrackFormat ??
                          '{Support:00}/{Piste:00} - {Titre de la piste}',
                    );
                    _artistFolderFormatController ??= TextEditingController(
                      text: naming.artistFolderFormat ?? "{Nom de l'artiste}",
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
                          title: const Text('Renommer automatiquement les pistes'),
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
                            '{Artist Name}',
                            "{Titre de l'album}",
                            '{Release Year}',
                            '{Track:00}',
                            '{Titre de la piste}',
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
                          decoration: const InputDecoration(
                            labelText: 'Format standard des pistes',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: Insets.sm),
                        TextField(
                          controller: _multiDiscFormatController,
                          decoration: const InputDecoration(
                            labelText: 'Format des pistes multi-disques',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: Insets.sm),
                        TextField(
                          controller: _artistFolderFormatController,
                          decoration: const InputDecoration(
                            labelText: "Format des dossiers d'artiste",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: Insets.sm),
                        DropdownButtonFormField<int>(
                          initialValue: _colonReplacementFormat,
                          decoration: const InputDecoration(
                            labelText: 'Format de remplacement des deux-points',
                            border: OutlineInputBorder(),
                          ),
                          items: <DropdownMenuItem<int>>[
                            const DropdownMenuItem(
                              value: 0,
                              child: Text('Supprimer (:)'),
                            ),
                            const DropdownMenuItem(
                              value: 1,
                              child: Text('Tiret (-)'),
                            ),
                            const DropdownMenuItem(
                              value: 2,
                              child: Text('Espace tiret ( -)'),
                            ),
                            const DropdownMenuItem(
                              value: 3,
                              child: Text('Espace tiret espace ( - )'),
                            ),
                            const DropdownMenuItem(
                              value: 4,
                              child: Text('Remplacement intelligent ( - )'),
                            ),
                            const DropdownMenuItem(
                              value: 5,
                              child: Text('Laisser tel quel (:)'),
                            ),
                            if (_colonReplacementFormat != null &&
                                _colonReplacementFormat! > 5)
                              DropdownMenuItem(
                                value: _colonReplacementFormat,
                                child: Text('Format $_colonReplacementFormat'),
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
                          label: const Text('Enregistrer les formats de nommage'),
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
                                const SnackBar(
                                  content: Text('Configuration de nommage enregistrée !'),
                                ),
                              );
                            } catch (e) {
                              messenger.showSnackBar(
                                SnackBar(content: Text('Erreur : $e')),
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
                          title: const Text('Ne plus surveiller les pistes téléchargées'),
                          subtitle: const Text(
                            "Ne plus surveiller les pistes à l'import ou à la suppression",
                          ),
                          value: _autoUnmonitor ?? false,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (bool val) =>
                              setState(() => _autoUnmonitor = val),
                        ),
                        SwitchListTile(
                          title: const Text("Créer les dossiers d'artiste vides"),
                          value: _createEmptyFolders ?? false,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (bool val) =>
                              setState(() => _createEmptyFolders = val),
                        ),
                        SwitchListTile(
                          title: const Text('Supprimer les dossiers vides'),
                          value: _deleteEmptyFolders ?? false,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (bool val) =>
                              setState(() => _deleteEmptyFolders = val),
                        ),
                        SwitchListTile(
                          title: const Text('Surveiller les changements de la bibliothèque'),
                          value: _watchLibrary ?? false,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (bool val) =>
                              setState(() => _watchLibrary = val),
                        ),
                        SwitchListTile(
                          title: const Text('Utiliser des liens durs au lieu de copier'),
                          value: _copyHardlinks ?? false,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (bool val) =>
                              setState(() => _copyHardlinks = val),
                        ),
                        SwitchListTile(
                          title: const Text("Analyser l'audio avec MediaInfo"),
                          value: _enableMediaInfo ?? true,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (bool val) =>
                              setState(() => _enableMediaInfo = val),
                        ),
                        const SizedBox(height: Insets.xs),
                        TextField(
                          controller: _extraExtensionsController,
                          decoration: const InputDecoration(
                            labelText: 'Extensions de fichiers supplémentaires',
                            hintText: 'ex. cue, nfo, log',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: Insets.md),
                        FilledButton.icon(
                          icon: const Icon(Icons.save, size: 18),
                          label: const Text('Enregistrer la gestion des médias'),
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
                                SnackBar(content: Text('Erreur : $e')),
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
