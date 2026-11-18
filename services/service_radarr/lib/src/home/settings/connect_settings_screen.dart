import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../radarr_providers.dart';
import 'widgets/confirm_delete.dart';
import 'widgets/dynamic_schema_form.dart';

class ConnectSettingsScreen extends ConsumerWidget {
  const ConnectSettingsScreen({required this.instance, super.key});

  final Instance instance;

  Future<void> _selectNotificationPresetAndAdd(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final schemasAsync = ref.read(radarrNotificationSchemaProvider(instance));
    final presets = schemasAsync.value ?? [];
    if (presets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chargement des préréglages de notifications…')),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(Insets.md),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Notification',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: Insets.md),
              Expanded(
                child: ListView.builder(
                  itemCount: presets.length,
                  itemBuilder: (context, index) {
                    final preset = presets[index];
                    final name = preset['name'] as String? ?? 'Notification';
                    final implementation =
                        preset['implementationName'] as String? ?? '';

                    return ListTile(
                      title: Text(name),
                      subtitle: Text(implementation),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(context);
                        _showNotificationEditorDialog(
                          context,
                          ref,
                          preset,
                          isNew: true,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showNotificationEditorDialog(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> notification, {
    bool isNew = false,
  }) async {
    final fields = (notification['fields'] as List<dynamic>?)
            ?.map((dynamic f) => f as Map<String, dynamic>)
            .toList() ??
        [];

    final nameController =
        TextEditingController(text: notification['name'] as String? ?? '');
    bool onGrab = notification['onGrab'] as bool? ?? true;
    bool onDownload = notification['onDownload'] as bool? ?? true;
    bool onUpgrade = notification['onUpgrade'] as bool? ?? true;
    bool onRename = notification['onRename'] as bool? ?? false;
    bool onMovieAdded = notification['onMovieAdded'] as bool? ?? false;
    bool onMovieDelete = notification['onMovieDelete'] as bool? ?? false;
    bool onMovieFileDelete = notification['onMovieFileDelete'] as bool? ?? false;
    bool onMovieFileDeleteForUpgrade =
        notification['onMovieFileDeleteForUpgrade'] as bool? ?? false;
    bool onHealthIssue = notification['onHealthIssue'] as bool? ?? false;
    bool onHealthRestored = notification['onHealthRestored'] as bool? ?? false;
    bool onApplicationUpdate =
        notification['onApplicationUpdate'] as bool? ?? false;
    bool onManualInteractionRequired =
        notification['onManualInteractionRequired'] as bool? ?? false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                isNew
                    ? 'Add ${notification['name']}'
                    : 'Edit ${notification['name']}',
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nom',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: Insets.md),
                      if (notification['supportsOnGrab'] == true ||
                          notification['supportsOnDownload'] == true ||
                          notification['supportsOnUpgrade'] == true ||
                          notification['supportsOnRename'] == true ||
                          notification['supportsOnMovieAdded'] == true ||
                          notification['supportsOnMovieDelete'] == true ||
                          notification['supportsOnMovieFileDelete'] == true ||
                          notification['supportsOnMovieFileDeleteForUpgrade'] == true ||
                          notification['supportsOnHealthIssue'] == true ||
                          notification['supportsOnHealthRestored'] == true ||
                          notification['supportsOnApplicationUpdate'] == true ||
                          notification['supportsOnManualInteractionRequired'] == true) ...[
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.outlineVariant,
                            ),
                            borderRadius: Radii.card,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(Insets.sm),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Trigger Events',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                if (notification['supportsOnGrab'] == true)
                                  CheckboxListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text('Lors du grab'),
                                    value: onGrab,
                                    onChanged: (val) => setDialogState(
                                      () => onGrab = val ?? false,
                                    ),
                                  ),
                                if (notification['supportsOnDownload'] == true)
                                  CheckboxListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text('Lors du téléchargement'),
                                    value: onDownload,
                                    onChanged: (val) => setDialogState(
                                      () => onDownload = val ?? false,
                                    ),
                                  ),
                                if (notification['supportsOnUpgrade'] == true)
                                  CheckboxListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text('Lors de la mise à niveau'),
                                    value: onUpgrade,
                                    onChanged: (val) => setDialogState(
                                      () => onUpgrade = val ?? false,
                                    ),
                                  ),
                                if (notification['supportsOnRename'] == true)
                                  CheckboxListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text('Lors du renommage'),
                                    value: onRename,
                                    onChanged: (val) => setDialogState(
                                      () => onRename = val ?? false,
                                    ),
                                  ),
                                if (notification['supportsOnMovieAdded'] == true)
                                  CheckboxListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text('Film ajouté'),
                                    value: onMovieAdded,
                                    onChanged: (val) => setDialogState(
                                      () => onMovieAdded = val ?? false,
                                    ),
                                  ),
                                if (notification['supportsOnMovieDelete'] == true)
                                  CheckboxListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text('Film supprimé'),
                                    value: onMovieDelete,
                                    onChanged: (val) => setDialogState(
                                      () => onMovieDelete = val ?? false,
                                    ),
                                  ),
                                if (notification['supportsOnMovieFileDelete'] == true)
                                  CheckboxListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text('Fichier de film supprimé'),
                                    value: onMovieFileDelete,
                                    onChanged: (val) => setDialogState(
                                      () => onMovieFileDelete = val ?? false,
                                    ),
                                  ),
                                if (notification['supportsOnMovieFileDeleteForUpgrade'] == true)
                                  CheckboxListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text("Fichier de film supprimé lors d'une mise à niveau"),
                                    value: onMovieFileDeleteForUpgrade,
                                    onChanged: (val) => setDialogState(
                                      () => onMovieFileDeleteForUpgrade = val ?? false,
                                    ),
                                  ),
                                if (notification['supportsOnHealthIssue'] == true)
                                  CheckboxListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text('En cas de problème de santé'),
                                    value: onHealthIssue,
                                    onChanged: (val) => setDialogState(
                                      () => onHealthIssue = val ?? false,
                                    ),
                                  ),
                                if (notification['supportsOnHealthRestored'] == true)
                                  CheckboxListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text('Santé rétablie'),
                                    value: onHealthRestored,
                                    onChanged: (val) => setDialogState(
                                      () => onHealthRestored = val ?? false,
                                    ),
                                  ),
                                if (notification['supportsOnApplicationUpdate'] == true)
                                  CheckboxListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text("Mise à jour de l'application"),
                                    value: onApplicationUpdate,
                                    onChanged: (val) => setDialogState(
                                      () => onApplicationUpdate = val ?? false,
                                    ),
                                  ),
                                if (notification['supportsOnManualInteractionRequired'] == true)
                                  CheckboxListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text('Interaction manuelle requise'),
                                    value: onManualInteractionRequired,
                                    onChanged: (val) => setDialogState(
                                      () => onManualInteractionRequired = val ?? false,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: Insets.md),
                      ],
                      DynamicSchemaForm(
                        fields: fields,
                        onTest: (updatedFields) async {
                          final api =
                              await ref.read(radarrApiProvider(instance).future);
                          final payload = Map<String, dynamic>.from(notification);
                          payload['name'] = nameController.text.trim();
                          payload['onGrab'] = onGrab;
                          payload['onDownload'] = onDownload;
                          payload['onUpgrade'] = onUpgrade;
                          payload['onRename'] = onRename;
                          payload['onMovieAdded'] = onMovieAdded;
                          payload['onMovieDelete'] = onMovieDelete;
                          payload['onMovieFileDelete'] = onMovieFileDelete;
                          payload['onMovieFileDeleteForUpgrade'] = onMovieFileDeleteForUpgrade;
                          payload['onHealthIssue'] = onHealthIssue;
                          payload['onHealthRestored'] = onHealthRestored;
                          payload['onApplicationUpdate'] = onApplicationUpdate;
                          payload['onManualInteractionRequired'] = onManualInteractionRequired;
                          payload['fields'] = updatedFields;
                          await api.testNotification(payload);
                        },
                        onSave: (updatedFields) async {
                          try {
                            final api =
                                await ref.read(radarrApiProvider(instance).future);
                            final payload = Map<String, dynamic>.from(notification);
                            payload['name'] = nameController.text.trim();
                            payload['onGrab'] = onGrab;
                            payload['onDownload'] = onDownload;
                            payload['onUpgrade'] = onUpgrade;
                            payload['onRename'] = onRename;
                            payload['onMovieAdded'] = onMovieAdded;
                            payload['onMovieDelete'] = onMovieDelete;
                            payload['onMovieFileDelete'] = onMovieFileDelete;
                            payload['onMovieFileDeleteForUpgrade'] = onMovieFileDeleteForUpgrade;
                            payload['onHealthIssue'] = onHealthIssue;
                            payload['onHealthRestored'] = onHealthRestored;
                            payload['onApplicationUpdate'] = onApplicationUpdate;
                            payload['onManualInteractionRequired'] = onManualInteractionRequired;
                            payload['fields'] = updatedFields;

                            if (isNew) {
                              await api.createNotification(payload);
                            } else {
                              await api.updateNotification(
                                payload,
                                payload['id'] as int,
                              );
                            }

                            ref.invalidate(radarrNotificationsProvider(instance));
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Notification ${isNew ? 'added' : 'updated'}!',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Échec de l'enregistrement de la notification : $e"),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteNotification(
    BuildContext context,
    WidgetRef ref,
    int id,
    String name,
  ) async {
    final confirmed = await confirmDelete(context, 'Notification "$name"');
    if (!confirmed) return;

    try {
      final api = await ref.read(radarrApiProvider(instance).future);
      await api.deleteNotification(id);
      ref.invalidate(radarrNotificationsProvider(instance));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification supprimée !')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec de la suppression de la notification : $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notificationsAsync = ref.watch(radarrNotificationsProvider(instance));

    ref.watch(radarrNotificationSchemaProvider(instance));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connexion / Notifications'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _selectNotificationPresetAndAdd(context, ref),
        child: const Icon(Icons.add),
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: ExpressiveProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur : $err')),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(
              child: Text(
                'Aucune notification de connexion configurée. Touchez + pour en ajouter une.',
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(Insets.md),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final n = notifications[index];
              final name = n['name'] as String? ?? 'Notification';
              final impl = n['implementationName'] as String? ?? '';
              final id = n['id'] as int;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: theme.colorScheme.surfaceContainerLow,
                child: ListTile(
                  title: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Type : $impl'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () =>
                            _showNotificationEditorDialog(context, ref, n),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: theme.colorScheme.error,
                        ),
                        onPressed: () =>
                            _deleteNotification(context, ref, id, name),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
