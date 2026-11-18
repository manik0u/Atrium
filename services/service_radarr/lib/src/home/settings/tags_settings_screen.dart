import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../radarr_providers.dart';
import 'widgets/confirm_delete.dart';

class TagsSettingsScreen extends ConsumerWidget {
  const TagsSettingsScreen({required this.instance, super.key});

  final Instance instance;

  Future<void> _showAddTagDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.t('addTag')),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: S.t('tagLabel'),
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(S.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(S.t('add')),
          ),
        ],
      ),
    );

    if (ok == true && controller.text.trim().isNotEmpty) {
      try {
        final api = await ref.read(radarrApiProvider(instance).future);
        await api.createTag(controller.text.trim());
        ref.invalidate(radarrTagsProvider(instance));
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.t('failedToAddTagE1', [e]))),
          );
        }
      }
    }
  }

  Future<void> _deleteTag(
    BuildContext context,
    WidgetRef ref,
    int id,
    String label,
  ) async {
    final ok = await confirmDelete(context, S.t('tagLabel1', [label]));
    if (ok) {
      try {
        final api = await ref.read(radarrApiProvider(instance).future);
        await api.deleteTag(id);
        ref.invalidate(radarrTagsProvider(instance));
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.t('failedToDeleteTagE1', [e]))),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tagsAsync = ref.watch(radarrTagsProvider(instance));

    return Scaffold(
      appBar: AppBar(
        title: Text(S.t('tags')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTagDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: tagsAsync.when(
        loading: () => const Center(child: ExpressiveProgressIndicator()),
        error: (err, _) => Center(child: Text(S.t('errorErr1', [err]))),
        data: (tags) {
          if (tags.isEmpty) {
            return Center(
              child: Text(S.t('noTagsDefinedTapToAddOne')),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(Insets.md),
            itemCount: tags.length,
            itemBuilder: (context, index) {
              final t = tags[index];
              final label = t['label'] as String? ?? '';
              final id = t['id'] as int;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: theme.colorScheme.surfaceContainerLow,
                child: ListTile(
                  title: Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: theme.colorScheme.error,
                    ),
                    onPressed: () => _deleteTag(context, ref, id, label),
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
