import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../generated/generated.dart';
import '../../../lidarr_api.dart';
import '../../../lidarr_providers.dart';

/// Tags and Auto-Tagging rules configuration section.
class TagsSection extends ConsumerWidget {
  const TagsSection({required this.instance, super.key});

  final Instance instance;

  Future<void> _showAddTagDialog(BuildContext context, WidgetRef ref) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final TextEditingController tagController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Ajouter une balise'),
        content: TextField(
          controller: tagController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Libellé de la balise',
            hintText: 'ex. favorite, lossless',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              final String label = tagController.text.trim();
              if (label.isEmpty) return;

              try {
                final LidarrApi api =
                    await ref.read(lidarrApiProvider(instance).future);
                final ApiResponse<TagResource> resp =
                    await api.tag.postTag(body: TagResource(label: label));
                if (!resp.isSuccess) {
                  throw Exception(resp.error?.message ?? "Échec de l'ajout de la balise");
                }

                ref.invalidate(lidarrTagsProvider(instance));
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Balise ajoutée avec succès !')),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  messenger.showSnackBar(SnackBar(content: Text('Erreur : $e')));
                }
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTag(
    BuildContext context,
    WidgetRef ref,
    TagResource tag,
  ) async {
    final int? id = tag.id;
    if (id == null) return;

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Supprimer la balise'),
        content: Text('Voulez-vous vraiment supprimer la balise « ${tag.label} » ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final LidarrApi api = await ref.read(lidarrApiProvider(instance).future);
      await api.tag.deleteTagById(id: id);
      ref.invalidate(lidarrTagsProvider(instance));
      messenger.showSnackBar(
        SnackBar(content: Text('Balise « ${tag.label} » supprimée.')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Échec de la suppression de la balise : $e')),
      );
    }
  }

  Future<void> _showAddEditAutoTaggingDialog(
    BuildContext context,
    WidgetRef ref, [
    AutoTaggingResource? rule,
  ]) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final bool isNew = rule == null;
    final TextEditingController nameController =
        TextEditingController(text: rule?.name ?? '');
    bool removeTagsAutomatically = rule?.removeTagsAutomatically ?? false;
    final List<int> selectedTags = List<int>.from(rule?.tags ?? <int>[]);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dCtx) {
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setDialogState) {
            final AsyncValue<List<TagResource>> asyncTags =
                ref.watch(lidarrTagsProvider(instance));

            return AlertDialog(
              title: Text(
                isNew ? 'Add Auto-Tagging Rule' : 'Edit Auto-Tagging Rule',
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nom de la règle',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: Insets.sm),
                      SwitchListTile(
                        title: const Text('Retirer automatiquement les balises'),
                        subtitle: const Text(
                          'Retirer la balise si les conditions ne sont plus remplies',
                        ),
                        value: removeTagsAutomatically,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (bool val) =>
                            setDialogState(() => removeTagsAutomatically = val),
                      ),
                      const SizedBox(height: Insets.sm),
                      const Text(
                        'Tags to Apply',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: Insets.xs),
                      asyncTags.when(
                        data: (List<TagResource> allTags) {
                          if (allTags.isEmpty) {
                            return const Text('Aucune balise disponible.');
                          }
                          return Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: allTags.map((TagResource t) {
                              final int? tId = t.id;
                              if (tId == null) return const SizedBox.shrink();
                              final bool isSelected =
                                  selectedTags.contains(tId);
                              return FilterChip(
                                label: Text(t.label ?? 'Balise $tId'),
                                selected: isSelected,
                                onSelected: (bool selected) {
                                  setDialogState(() {
                                    if (selected) {
                                      selectedTags.add(tId);
                                    } else {
                                      selectedTags.remove(tId);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dCtx),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () async {
                    final String name = nameController.text.trim();
                    if (name.isEmpty) return;

                    final AutoTaggingResource payload =
                        (rule ?? const AutoTaggingResource()).copyWith(
                      name: name,
                      removeTagsAutomatically: removeTagsAutomatically,
                      tags: selectedTags,
                    );

                    try {
                      final LidarrApi api =
                          await ref.read(lidarrApiProvider(instance).future);
                      if (isNew) {
                        final ApiResponse<AutoTaggingResource> resp = await api
                            .autoTagging
                            .postAutotagging(body: payload);
                        if (!resp.isSuccess) {
                          throw Exception(
                            resp.error?.message ??
                                'Failed to create auto-tagging rule',
                          );
                        }
                      } else {
                        final ApiResponse<AutoTaggingResource> resp =
                            await api.autoTagging.putAutotaggingById(
                          id: '${rule.id}',
                          body: payload,
                        );
                        if (!resp.isSuccess) {
                          throw Exception(
                            resp.error?.message ??
                                'Failed to update auto-tagging rule',
                          );
                        }
                      }

                      ref.invalidate(lidarrAutoTaggingProvider(instance));
                      if (dCtx.mounted) {
                        Navigator.pop(dCtx);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'Auto-tagging rule ${isNew ? 'added' : 'updated'}!',
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (dCtx.mounted) {
                        messenger.showSnackBar(
                          SnackBar(content: Text('Erreur : $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteAutoTagging(
    BuildContext context,
    WidgetRef ref,
    AutoTaggingResource rule,
  ) async {
    final int? id = rule.id;
    if (id == null) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text("Supprimer la règle d'auto-tag ?"),
        content: Text('Voulez-vous vraiment supprimer « ${rule.name} » ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      final LidarrApi api = await ref.read(lidarrApiProvider(instance).future);
      final ApiResponse<void> resp =
          await api.autoTagging.deleteAutotaggingById(id: id);
      if (!resp.isSuccess) {
        throw Exception(
          resp.error?.message ?? "Échec de la suppression de la règle d'auto-tag",
        );
      }

      ref.invalidate(lidarrAutoTaggingProvider(instance));
      messenger.showSnackBar(
        const SnackBar(content: Text("Règle d'auto-tag supprimée.")),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text("Échec de la suppression de la règle d'auto-tag : $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final AsyncValue<List<TagResource>> asyncTags =
        ref.watch(lidarrTagsProvider(instance));
    final AsyncValue<List<AutoTaggingResource>> asyncAutoTagging =
        ref.watch(lidarrAutoTaggingProvider(instance));

    return EasyRefresh(
      onRefresh: () async {
        ref.invalidate(lidarrTagsProvider(instance));
        ref.invalidate(lidarrAutoTaggingProvider(instance));
      },
      child: ListView(
        padding: const EdgeInsets.all(Insets.md),
        children: [
          // Tags Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.label_outline, size: 20, color: cs.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Tags',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton.filledTonal(
                icon: const Icon(Icons.add, size: 18),
                tooltip: 'Ajouter une balise',
                onPressed: () => _showAddTagDialog(context, ref),
              ),
            ],
          ),
          const SizedBox(height: Insets.sm),
          AsyncValueView<List<TagResource>>(
            value: asyncTags,
            data: (List<TagResource> tags) {
              if (tags.isEmpty) {
                return Card(
                  elevation: 0,
                  color: cs.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Aucune balise créée. Utilisez les balises pour étiqueter et filtrer les artistes ou albums.',
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Wrap(
                spacing: Insets.sm,
                runSpacing: Insets.sm,
                children: tags.map((TagResource tag) {
                  return Chip(
                    avatar: const Icon(Icons.tag, size: 16),
                    label: Text(
                      tag.label ?? 'Balise ${tag.id}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    backgroundColor: cs.surfaceContainerHigh,
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => _deleteTag(context, ref, tag),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: Insets.xl),
          // Auto-Tagging Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, size: 20, color: cs.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Auto-Tagging Rules',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton.filledTonal(
                icon: const Icon(Icons.add, size: 18),
                tooltip: "Ajouter une règle d'auto-tag",
                onPressed: () => _showAddEditAutoTaggingDialog(context, ref),
              ),
            ],
          ),
          const SizedBox(height: Insets.sm),
          AsyncValueView<List<AutoTaggingResource>>(
            value: asyncAutoTagging,
            data: (List<AutoTaggingResource> rules) {
              if (rules.isEmpty) {
                return Card(
                  elevation: 0,
                  color: cs.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Aucune règle d'auto-tag configurée.",
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: rules.map((AutoTaggingResource rule) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
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
                            Icons.auto_awesome,
                            color: cs.onPrimaryContainer,
                            size: 22,
                          ),
                        ),
                        title: Text(
                          rule.name ?? 'Rule',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          [
                            '${rule.tags?.length ?? 0} tags',
                            if (rule.removeTagsAutomatically == true)
                              'Auto-remove tags',
                          ].join(' • '),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          tooltip: 'Supprimer la règle',
                          onPressed: () =>
                              _deleteAutoTagging(context, ref, rule),
                        ),
                        onTap: () =>
                            _showAddEditAutoTaggingDialog(context, ref, rule),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
