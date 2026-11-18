import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../generated/generated.dart';
import '../../../lidarr_api.dart';
import '../../../lidarr_providers.dart';

/// Dialog for bulk deletion of artists and files.
class BulkDeleteDialog extends ConsumerStatefulWidget {
  const BulkDeleteDialog({
    required this.instance,
    required this.selectedIds,
    required this.onSuccess,
    super.key,
  });

  final Instance instance;
  final Set<int> selectedIds;
  final VoidCallback onSuccess;

  @override
  ConsumerState<BulkDeleteDialog> createState() => _BulkDeleteDialogState();
}

class _BulkDeleteDialogState extends ConsumerState<BulkDeleteDialog> {
  bool _deleteFiles = false;
  bool _addImportListExclusion = false;
  bool _submitting = false;

  Future<void> _submit() async {
    setState(() => _submitting = true);

    try {
      final LidarrApi api =
          await ref.read(lidarrApiProvider(widget.instance).future);
      final resource = ArtistEditorResource(
        artistIds: widget.selectedIds.toList(),
        deleteFiles: _deleteFiles,
        addImportListExclusion: _addImportListExclusion,
        moveFiles: false,
        applyTags: ApplyTags.add,
      );

      final ApiResponse<void> resp =
          await api.artistEditor.deleteArtistEditor(body: resource);
      if (!resp.isSuccess) {
        throw Exception(resp.error?.message ?? 'Échec de la suppression des artistes');
      }

      if (!mounted) return;

      ref.invalidate(lidarrArtistsProvider(widget.instance));
      ref.invalidate(lidarrHistoryProvider(widget.instance));
      ref.invalidate(lidarrQueueProvider(widget.instance));

      widget.onSuccess();
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.selectedIds.length} artiste(s) supprimé(s).'),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Échec de la suppression groupée : $e'),
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

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    return AlertDialog(
      title: Text('Supprimer ${widget.selectedIds.length} artistes ?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you sure you want to delete ${widget.selectedIds.length} selected artists from your Lidarr library?',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            title: const Text('Supprimer les fichiers du disque'),
            subtitle: const Text('Supprimer définitivement les fichiers audio'),
            value: _deleteFiles,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) => setState(() => _deleteFiles = val ?? false),
          ),
          CheckboxListTile(
            title: const Text("Ajouter une exclusion de liste d'import"),
            subtitle: const Text('Empêcher le rajout par les listes automatiques'),
            value: _addImportListExclusion,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) =>
                setState(() => _addImportListExclusion = val ?? false),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: cs.error,
            foregroundColor: cs.onError,
          ),
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: ExpressiveProgressIndicator(strokeWidth: 2),
                )
              : Text('Supprimer (${widget.selectedIds.length})'),
        ),
      ],
    );
  }
}
