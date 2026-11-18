import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../radarr_providers.dart';

class RadarrRenameDialog extends ConsumerStatefulWidget {
  const RadarrRenameDialog({
    required this.instance,
    required this.movieId,
    super.key,
  });

  final Instance instance;
  final int movieId;

  @override
  ConsumerState<RadarrRenameDialog> createState() => _RadarrRenameDialogState();
}

class _RadarrRenameDialogState extends ConsumerState<RadarrRenameDialog> {
  bool _renaming = false;

  Future<void> _executeRename(List<int> fileIds) async {
    setState(() => _renaming = true);

    try {
      final api = await ref.read(radarrApiProvider(widget.instance).future);
      await api.renameFiles(widget.movieId, fileIds);
      if (!mounted) return;

      ref.invalidate(
        radarrMovieByIdProvider((widget.instance, widget.movieId)),
      );
      ref.invalidate(
        radarrRenamePreviewProvider((widget.instance, widget.movieId)),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.t('filesRenamedSuccessfully'))),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.t('renameFailedE1', [e]))),
        );
      }
    } finally {
      if (mounted) setState(() => _renaming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewAsync = ref
        .watch(radarrRenamePreviewProvider((widget.instance, widget.movieId)));
    final ThemeData theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AlertDialog(
      title: Text(S.t('renameFiles')),
      content: SizedBox(
        width: double.maxFinite,
        height: 350,
        child: previewAsync.when(
          loading: () => const Center(child: ExpressiveProgressIndicator()),
          error: (err, stack) =>
              Center(child: Text(S.t('errorLoadingRenamePreviewErr1', [err]))),
          data: (files) {
            if (files.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: colors.tertiary,
                      size: 48,
                    ),
                    const SizedBox(height: Insets.sm),
                    Text(
                      S.t('allFilesAreCorrectlyNamed'),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: files.length,
              itemBuilder: (context, index) {
                final f = files[index];
                // Paths may use either separator depending on the server OS.
                final separators = RegExp(r'[\\/]');
                final current =
                    (f['existingPath'] as String?)?.split(separators).last ??
                        S.t('unknownName');
                final proposed =
                    (f['newPath'] as String?)?.split(separators).last ??
                        S.t('unknownName');

                return Padding(
                  padding: const EdgeInsets.only(bottom: Insets.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Proposed Rename',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        current,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.error,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        proposed,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.tertiary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _renaming ? null : () => Navigator.pop(context),
          child: Text(S.t('cancel')),
        ),
        previewAsync.maybeWhen(
          data: (files) => files.isEmpty
              ? const SizedBox.shrink()
              : ElevatedButton(
                  onPressed: _renaming
                      ? null
                      : () {
                          final List<int> ids = files
                              .map((f) => f['movieFileId'] as int)
                              .toList();
                          _executeRename(ids);
                        },
                  child: _renaming
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: ExpressiveProgressIndicator(strokeWidth: 2),
                        )
                      : Text(S.t('rename')),
                ),
          orElse: () => const SizedBox.shrink(),
        ),
      ],
    );
  }
}
