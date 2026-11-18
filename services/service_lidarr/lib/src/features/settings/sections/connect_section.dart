import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../generated/generated.dart';
import '../../../lidarr_api.dart';
import '../../../lidarr_providers.dart';
import '../widgets/dynamic_schema_form.dart';
import '../widgets/schema_preset_picker.dart';

/// Connect / Notifications configuration section.
class ConnectSection extends ConsumerWidget {
  const ConnectSection({required this.instance, super.key});

  final Instance instance;

  Future<void> _selectNotificationPresetAndAdd(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final AsyncValue<List<NotificationResource>> schemasAsync =
        ref.read(lidarrNotificationSchemaProvider(instance));
    final List<NotificationResource> presets =
        schemasAsync.value ?? <NotificationResource>[];
    if (presets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.t('loadingNotificationPresets'))),
      );
      return;
    }

    final NotificationResource? selected =
        await showSchemaPresetPicker<NotificationResource>(
      context: context,
      title: S.t('addNotificationIntegration'),
      presets: presets,
      titleBuilder: (preset) {
        final String impl = preset.implementationName?.trim() ?? '';
        final String name = preset.name?.trim() ?? '';
        if (impl.isNotEmpty) return impl;
        if (name.isNotEmpty && name != 'Notification') return name;
        return preset.implementation ?? S.t('notification');
      },
      subtitleBuilder: (preset) {
        final String impl = preset.implementationName?.trim() ?? '';
        final String name = preset.name?.trim() ?? '';
        if (impl.isNotEmpty &&
            name.isNotEmpty &&
            name != 'Notification' &&
            name != impl) {
          return name;
        }
        return '';
      },
      icon: Icons.notifications_active_outlined,
    );

    if (selected != null && context.mounted) {
      await _showNotificationEditorDialog(
        context,
        ref,
        selected,
        isNew: true,
      );
    }
  }

  Future<void> _showNotificationEditorDialog(
    BuildContext context,
    WidgetRef ref,
    NotificationResource notification, {
    bool isNew = false,
  }) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final List<Map<String, dynamic>> fields =
        (notification.fields ?? []).map((Field f) => f.toJson()).toList();

    final String initialName = isNew
        ? ((notification.implementationName?.isNotEmpty == true)
            ? notification.implementationName!
            : (notification.name != 'Notification'
                ? (notification.name ?? '')
                : ''))
        : (notification.name ?? '');

    final TextEditingController nameController =
        TextEditingController(text: initialName);

    bool onGrab = notification.onGrab ?? true;
    bool onReleaseImport = notification.onReleaseImport ?? true;
    bool onUpgrade = notification.onUpgrade ?? true;
    bool onRename = notification.onRename ?? false;
    bool onTrackRetag = notification.onTrackRetag ?? false;
    bool onArtistAdd = notification.onArtistAdd ?? false;
    bool onArtistDelete = notification.onArtistDelete ?? false;
    bool onAlbumDelete = notification.onAlbumDelete ?? false;
    bool onHealthIssue = notification.onHealthIssue ?? false;
    bool onDownloadFailure = notification.onDownloadFailure ?? false;
    final bool includeHealthWarnings =
        notification.includeHealthWarnings ?? false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext dCtx, StateSetter setDialogState) {
            return AlertDialog(
              title: Text(
                isNew
                    ? 'Add ${notification.name ?? 'Notification'}'
                    : 'Edit ${notification.name ?? 'Notification'}',
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: S.t('name'),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: Insets.md),

                      // Trigger Events Section
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: Theme.of(ctx).colorScheme.outlineVariant,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(Insets.sm),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                S.t('triggerEvents'),
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: Insets.xs),
                              SwitchListTile(
                                title: Text(S.t('onGrab')),
                                subtitle:
                                    Text(S.t('whenAReleaseIsGrabbed')),
                                value: onGrab,
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                onChanged: (bool val) =>
                                    setDialogState(() => onGrab = val),
                              ),
                              SwitchListTile(
                                title: Text(S.t('onReleaseImport')),
                                subtitle:
                                    Text(S.t('whenAnAlbumIsImported')),
                                value: onReleaseImport,
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                onChanged: (bool val) =>
                                    setDialogState(() => onReleaseImport = val),
                              ),
                              SwitchListTile(
                                title: Text(S.t('onUpgrade')),
                                subtitle: Text(
                                  S.t('whenHigherQualityReplacesExistingTrack'),
                                ),
                                value: onUpgrade,
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                onChanged: (bool val) =>
                                    setDialogState(() => onUpgrade = val),
                              ),
                              SwitchListTile(
                                title: Text(S.t('onRename')),
                                subtitle:
                                    Text(S.t('whenAudioFilesAreRenamed')),
                                value: onRename,
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                onChanged: (bool val) =>
                                    setDialogState(() => onRename = val),
                              ),
                              SwitchListTile(
                                title: Text(S.t('onTrackRetag')),
                                subtitle: Text(
                                  S.t('whenMetadataTagsAreUpdated'),
                                ),
                                value: onTrackRetag,
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                onChanged: (bool val) =>
                                    setDialogState(() => onTrackRetag = val),
                              ),
                              SwitchListTile(
                                title: Text(S.t('onArtistAddDelete')),
                                subtitle: Text(
                                  S.t('whenArtistsAreAddedOrRemoved'),
                                ),
                                value: onArtistAdd || onArtistDelete,
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                onChanged: (bool val) => setDialogState(() {
                                  onArtistAdd = val;
                                  onArtistDelete = val;
                                }),
                              ),
                              SwitchListTile(
                                title: Text(S.t('onAlbumDelete')),
                                subtitle:
                                    Text(S.t('whenAnAlbumIsDeleted')),
                                value: onAlbumDelete,
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                onChanged: (bool val) =>
                                    setDialogState(() => onAlbumDelete = val),
                              ),
                              SwitchListTile(
                                title: Text(S.t('onHealthIssue')),
                                subtitle: Text(
                                  S.t('whenSystemHealthCheckIssuesOccur'),
                                ),
                                value: onHealthIssue,
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                onChanged: (bool val) =>
                                    setDialogState(() => onHealthIssue = val),
                              ),
                              SwitchListTile(
                                title: Text(S.t('onDownloadFailure')),
                                subtitle: Text(
                                  S.t('whenADownloadFailsInClient'),
                                ),
                                value: onDownloadFailure,
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                onChanged: (bool val) => setDialogState(
                                  () => onDownloadFailure = val,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: Insets.md),

                      DynamicSchemaForm(
                        fields: fields,
                        onTest: (
                          List<Map<String, dynamic>> updatedFields,
                        ) async {
                          final LidarrApi api = await ref
                              .read(lidarrApiProvider(instance).future);
                          final NotificationResource payload =
                              notification.copyWith(
                            id: notification.id ?? 0,
                            name: nameController.text.trim().isNotEmpty
                                ? nameController.text.trim()
                                : notification.name,
                            onGrab: onGrab,
                            onReleaseImport: onReleaseImport,
                            onUpgrade: onUpgrade,
                            onRename: onRename,
                            onTrackRetag: onTrackRetag,
                            onArtistAdd: onArtistAdd,
                            onArtistDelete: onArtistDelete,
                            onAlbumDelete: onAlbumDelete,
                            onHealthIssue: onHealthIssue,
                            onDownloadFailure: onDownloadFailure,
                            includeHealthWarnings: includeHealthWarnings,
                            fields: updatedFields.map(Field.fromJson).toList(),
                          );
                          final ApiResponse<void> resp = await api.notification
                              .postNotificationTest(body: payload);
                          if (!resp.isSuccess) {
                            throw Exception(
                              resp.error?.message ?? S.t('notificationTestFailed'),
                            );
                          }
                        },
                        onSave: (
                          List<Map<String, dynamic>> updatedFields,
                        ) async {
                          try {
                            final LidarrApi api = await ref
                                .read(lidarrApiProvider(instance).future);
                            final NotificationResource payload =
                                notification.copyWith(
                              id: notification.id ?? 0,
                              name: nameController.text.trim().isNotEmpty
                                  ? nameController.text.trim()
                                  : notification.name,
                              onGrab: onGrab,
                              onReleaseImport: onReleaseImport,
                              onUpgrade: onUpgrade,
                              onRename: onRename,
                              onTrackRetag: onTrackRetag,
                              onArtistAdd: onArtistAdd,
                              onArtistDelete: onArtistDelete,
                              onAlbumDelete: onAlbumDelete,
                              onHealthIssue: onHealthIssue,
                              onDownloadFailure: onDownloadFailure,
                              includeHealthWarnings: includeHealthWarnings,
                              fields:
                                  updatedFields.map(Field.fromJson).toList(),
                            );

                            if (isNew) {
                              final ApiResponse<NotificationResource> resp =
                                  await api.notification
                                      .postNotification(body: payload);
                              if (!resp.isSuccess) {
                                throw Exception(
                                  resp.error?.message ??
                                      'Failed to create notification',
                                );
                              }
                            } else {
                              final ApiResponse<NotificationResource> resp =
                                  await api.notification.putNotificationById(
                                id: notification.id!,
                                body: payload,
                              );
                              if (!resp.isSuccess) {
                                throw Exception(
                                  resp.error?.message ??
                                      'Failed to update notification',
                                );
                              }
                            }

                            ref.invalidate(
                              lidarrNotificationsProvider(instance),
                            );
                            if (dCtx.mounted) {
                              Navigator.pop(dCtx);
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Notification integration ${isNew ? 'added' : 'updated'}!',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (dCtx.mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content:
                                      Text(S.t('failedToSaveNotificationE1', [e])),
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
    NotificationResource notification,
  ) async {
    final int? id = notification.id;
    if (id == null) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(S.t('deleteNotificationName')Notification'}?'),
        content: Text(
          'Are you sure you want to remove the "${notification.name}" notification integration?',
        ),
        actions: [
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

    if (confirmed != true || !context.mounted) return;

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      final LidarrApi api = await ref.read(lidarrApiProvider(instance).future);
      final ApiResponse<void> resp =
          await api.notification.deleteNotificationById(id: id);
      if (!resp.isSuccess) {
        throw Exception(
          resp.error?.message ?? S.t('failedToDeleteNotification'),
        );
      }

      ref.invalidate(lidarrNotificationsProvider(instance));
      messenger.showSnackBar(
        SnackBar(content: Text(S.t('notificationDeleted_2'))),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(S.t('failedToDeleteNotificationE1', [e]))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AsyncValue<List<NotificationResource>> asyncNotifications =
        ref.watch(lidarrNotificationsProvider(instance));

    // Prefetch schemas for snappy preset selection
    ref.watch(lidarrNotificationSchemaProvider(instance));

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_notification_fab',
        onPressed: () => _selectNotificationPresetAndAdd(context, ref),
        tooltip: S.t('addNotification'),
        child: const Icon(Icons.add),
      ),
      body: EasyRefresh(
        onRefresh: () async {
          ref.invalidate(lidarrNotificationsProvider(instance));
        },
        child: AsyncValueView<List<NotificationResource>>(
          value: asyncNotifications,
          data: (List<NotificationResource> notifications) {
            if (notifications.isEmpty) {
              return Center(
                child: EmptyView(
                  icon: Icons.notifications_off_outlined,
                  title: S.t('noNotificationsConfigured'),
                  message:
                      'Add notification connections (Discord, Telegram, Webhooks, Pushover, etc.) to receive alerts.',
                  action: FilledButton.icon(
                    onPressed: () =>
                        _selectNotificationPresetAndAdd(context, ref),
                    icon: const Icon(Icons.add),
                    label: Text(S.t('addConnection')),
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                Insets.md,
                Insets.md,
                Insets.md,
                80,
              ),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (BuildContext context, int index) {
                final NotificationResource item = notifications[index];
                final List<String> activeEvents = [
                  if (item.onGrab == true) S.t('grab'),
                  if (item.onReleaseImport == true) S.t('import'),
                  if (item.onUpgrade == true) 'Upgrade',
                  if (item.onRename == true) S.t('rename'),
                  if (item.onTrackRetag == true) 'Retag',
                  if (item.onHealthIssue == true) S.t('health'),
                  if (item.onDownloadFailure == true) 'Fail',
                ];

                return Card(
                  elevation: 0,
                  color: cs.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.notifications_active_outlined,
                        color: cs.onPrimaryContainer,
                        size: 22,
                      ),
                    ),
                    title: Text(
                      item.name ?? S.t('notification'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        [
                          item.implementationName ?? 'Service',
                          if (activeEvents.isNotEmpty)
                            activeEvents.join(', ')
                          else
                            S.t('noActiveTriggers'),
                        ].join(' • '),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      tooltip: S.t('deleteNotification'),
                      onPressed: () => _deleteNotification(context, ref, item),
                    ),
                    onTap: () => _showNotificationEditorDialog(
                      context,
                      ref,
                      item,
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
