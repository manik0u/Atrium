import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../generated/generated.dart';
import '../../../lidarr_api.dart';
import '../../../lidarr_providers.dart';

/// Dialog for mass editing monitored status, profiles, and root folder.
class BulkEditDialog extends ConsumerStatefulWidget {
  const BulkEditDialog({
    required this.instance,
    required this.selectedIds,
    required this.onSuccess,
    super.key,
  });

  final Instance instance;
  final Set<int> selectedIds;
  final VoidCallback onSuccess;

  @override
  ConsumerState<BulkEditDialog> createState() => _BulkEditDialogState();
}

class _BulkEditDialogState extends ConsumerState<BulkEditDialog> {
  bool? _monitored;
  NewItemMonitorTypes? _monitorNewItems;
  int? _qualityProfileId;
  int? _metadataProfileId;
  String? _rootFolderPath;
  bool _moveFiles = false;
  bool _submitting = false;

  Future<void> _submit() async {
    setState(() => _submitting = true);

    try {
      final LidarrApi api =
          await ref.read(lidarrApiProvider(widget.instance).future);
      final resource = ArtistEditorResource(
        artistIds: widget.selectedIds.toList(),
        monitored: _monitored,
        monitorNewItems: _monitorNewItems,
        qualityProfileId: _qualityProfileId,
        metadataProfileId: _metadataProfileId,
        rootFolderPath: _rootFolderPath,
        moveFiles: _moveFiles,
        deleteFiles: false,
        addImportListExclusion: false,
        applyTags: ApplyTags.add,
      );

      final ApiResponse<void> resp =
          await api.artistEditor.putArtistEditor(body: resource);
      if (!resp.isSuccess) {
        throw Exception(resp.error?.message ?? S.t('failedToUpdateArtists'));
      }

      if (!mounted) return;

      ref.invalidate(lidarrArtistsProvider(widget.instance));
      for (final int id in widget.selectedIds) {
        ref.invalidate(lidarrArtistByIdProvider((widget.instance, id)));
      }

      widget.onSuccess();
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Updated ${widget.selectedIds.length} ${_selectedIdsCountLabel()}.',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.t('bulkUpdateFailedE1', [e])),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  String _selectedIdsCountLabel() =>
      widget.selectedIds.length == 1 ? 'artist' : 'artists';

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<QualityProfileResource>> qualityProfilesAsync =
        ref.watch(lidarrQualityProfilesProvider(widget.instance));
    final AsyncValue<List<MetadataProfileResource>> metadataProfilesAsync =
        ref.watch(lidarrMetadataProfilesProvider(widget.instance));
    final AsyncValue<List<RootFolderResource>> rootFoldersAsync =
        ref.watch(lidarrRootFoldersProvider(widget.instance));

    return AlertDialog(
      scrollable: true,
      title:
          Text('Edit ${widget.selectedIds.length} ${_selectedIdsCountLabel()}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
            const SizedBox(height: Insets.xs),
            // Monitored
            DropdownButtonFormField<bool?>(
              isExpanded: true,
              initialValue: _monitored,
              decoration: InputDecoration(
                labelText: S.t('monitored'),
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(child: Text(S.t('keepCurrent'))),
                DropdownMenuItem(value: true, child: Text(S.t('monitored'))),
                DropdownMenuItem(value: false, child: Text(S.t('unmonitored'))),
              ],
              onChanged: (val) => setState(() => _monitored = val),
            ),
            const SizedBox(height: Insets.md),
            // Monitor New Items
            DropdownButtonFormField<NewItemMonitorTypes?>(
              isExpanded: true,
              initialValue: _monitorNewItems,
              decoration: InputDecoration(
                labelText: S.t('monitorNewItems'),
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(child: Text(S.t('keepCurrent'))),
                DropdownMenuItem(
                  value: NewItemMonitorTypes.all,
                  child: Text(S.t('allAlbums')),
                ),
                DropdownMenuItem(
                  value: NewItemMonitorTypes.newVal,
                  child: Text(S.t('newAlbums')),
                ),
                DropdownMenuItem(
                  value: NewItemMonitorTypes.none,
                  child: Text(S.t('none')),
                ),
              ],
              onChanged: (val) => setState(() => _monitorNewItems = val),
            ),
            const SizedBox(height: Insets.md),
            // Quality Profile
            qualityProfilesAsync.when(
              data: (profiles) => DropdownButtonFormField<int?>(
                isExpanded: true,
                initialValue: _qualityProfileId,
                decoration: InputDecoration(
                  labelText: S.t('qualityProfile'),
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(child: Text(S.t('keepCurrent'))),
                  ...profiles.map(
                    (p) => DropdownMenuItem(
                      value: p.id,
                      child: Text(p.name ?? S.t('profilePId1', [p.id])),
                    ),
                  ),
                ],
                onChanged: (val) => setState(() => _qualityProfileId = val),
              ),
              loading: () => const SizedBox(
                height: 50,
                child: Center(child: ExpressiveProgressIndicator()),
              ),
              error: (_, __) => Text(S.t('errorLoadingQualityProfiles')),
            ),
            const SizedBox(height: Insets.md),
            // Metadata Profile
            metadataProfilesAsync.when(
              data: (profiles) => DropdownButtonFormField<int?>(
                isExpanded: true,
                initialValue: _metadataProfileId,
                decoration: InputDecoration(
                  labelText: S.t('metadataProfile'),
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(child: Text(S.t('keepCurrent'))),
                  ...profiles.map(
                    (p) => DropdownMenuItem(
                      value: p.id,
                      child: Text(p.name ?? S.t('profilePId1', [p.id])),
                    ),
                  ),
                ],
                onChanged: (val) => setState(() => _metadataProfileId = val),
              ),
              loading: () => const SizedBox(
                height: 50,
                child: Center(child: ExpressiveProgressIndicator()),
              ),
              error: (_, __) => Text(S.t('errorLoadingMetadataProfiles')),
            ),
            const SizedBox(height: Insets.md),
            // Root Folder
            rootFoldersAsync.when(
              data: (folders) => Column(
                children: [
                  DropdownButtonFormField<String?>(
                    isExpanded: true,
                    initialValue: _rootFolderPath,
                    decoration: InputDecoration(
                      labelText: S.t('rootFolder'),
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(child: Text(S.t('keepCurrent'))),
                      ...folders.map(
                        (f) => DropdownMenuItem(
                          value: f.path,
                          child: Text(
                            f.path ?? S.t('unknown'),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (val) => setState(() {
                      _rootFolderPath = val;
                      if (val == null) _moveFiles = false;
                    }),
                  ),
                  if (_rootFolderPath != null)
                    CheckboxListTile(
                      title: Text(S.t('moveExistingFiles')),
                      subtitle: Text(
                        S.t('automaticallyMigrateAudioFilesToTheNewRootFolder'),
                      ),
                      value: _moveFiles,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) =>
                          setState(() => _moveFiles = val ?? false),
                    ),
                ],
              ),
              loading: () => const SizedBox(
                height: 50,
                child: Center(child: ExpressiveProgressIndicator()),
              ),
              error: (_, __) => Text(S.t('errorLoadingRootFolders')),
            ),
          ],
        ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: Text(S.t('cancel')),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: ExpressiveProgressIndicator(strokeWidth: 2),
                )
              : Text(S.t('applyChanges')),
        ),
      ],
    );
  }
}
