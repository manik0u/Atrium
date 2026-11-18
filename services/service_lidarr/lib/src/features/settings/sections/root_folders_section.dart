import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/lidarr_formatters.dart';
import '../../../generated/generated.dart';
import '../../../lidarr_api.dart';
import '../../../lidarr_providers.dart';

/// Root Folders configuration section.
class RootFoldersSection extends ConsumerWidget {
  const RootFoldersSection({required this.instance, super.key});

  final Instance instance;

  Future<void> _showAddRootFolderDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final TextEditingController pathController = TextEditingController();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    await showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Ajouter un dossier racine'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Saisissez le chemin absolu où les albums musicaux doivent être stockés.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: Insets.md),
              TextField(
                controller: pathController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Chemin du dossier',
                  hintText: '/data/media/music',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.folder_outlined),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () async {
                final String path = pathController.text.trim();
                if (path.isEmpty) return;

                Navigator.of(ctx).pop();
                try {
                  final LidarrApi api =
                      await ref.read(lidarrApiProvider(instance).future);
                  await api.rootFolder.postRootfolder(
                    body: RootFolderResource(path: path),
                  );
                  ref.invalidate(lidarrRootFoldersProvider(instance));
                  messenger.showSnackBar(
                    SnackBar(content: Text('Dossier racine ajouté : $path')),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text("Échec de l'ajout du dossier racine : $e")),
                  );
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteRootFolder(
    BuildContext context,
    WidgetRef ref,
    RootFolderResource folder,
  ) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Retirer le dossier racine'),
          content: Text(
            'Are you sure you want to remove "${folder.path}" from Lidarr? '
            'Les fichiers sur le disque ne seront pas supprimés.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Retirer'),
            ),
          ],
        );
      },
    );

    if (confirm != true || folder.id == null) return;

    try {
      final LidarrApi api = await ref.read(lidarrApiProvider(instance).future);
      await api.rootFolder.deleteRootfolderById(id: folder.id!);
      ref.invalidate(lidarrRootFoldersProvider(instance));
      messenger.showSnackBar(
        const SnackBar(content: Text('Dossier racine retiré.')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Échec du retrait du dossier racine : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final AsyncValue<List<RootFolderResource>> asyncFolders =
        ref.watch(lidarrRootFoldersProvider(instance));

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'root_folder_add_fab',
        onPressed: () => _showAddRootFolderDialog(context, ref),
        tooltip: 'Ajouter un dossier racine',
        child: const Icon(Icons.add),
      ),
      body: EasyRefresh(
        onRefresh: () async {
          ref.invalidate(lidarrRootFoldersProvider(instance));
        },
        child: AsyncValueView<List<RootFolderResource>>(
          value: asyncFolders,
          data: (List<RootFolderResource> folders) {
            if (folders.isEmpty) {
              return Center(
                child: EmptyView(
                  icon: Icons.folder_open_outlined,
                  title: 'Aucun dossier racine',
                  message: 'Aucun dossier racine configuré dans Lidarr.',
                  action: FilledButton.icon(
                    onPressed: () => _showAddRootFolderDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter un dossier racine'),
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(Insets.md),
              itemCount: folders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (BuildContext context, int index) {
                final RootFolderResource folder = folders[index];
                final String freeSpace =
                    LidarrFormatters.formatBytes(folder.freeSpace);

                return Card(
                  elevation: 0,
                  color: cs.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.folder_outlined,
                            color: cs.onPrimaryContainer,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                folder.path ?? 'Unknown Path',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: <Widget>[
                                  Icon(
                                    Icons.storage_outlined,
                                    size: 14,
                                    color: cs.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Free Space: $freeSpace',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                  if (folder.accessible == false) ...<Widget>[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: cs.errorContainer,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Inaccessible',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: cs.onErrorContainer,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          tooltip: 'Retirer le dossier racine',
                          onPressed: () =>
                              _deleteRootFolder(context, ref, folder),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
