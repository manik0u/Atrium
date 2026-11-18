import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'qbittorrent_client.dart';
import 'qbittorrent_providers.dart';

class QbittorrentActionUtils {
  static Future<void> run(
    WidgetRef ref,
    Instance instance,
    Future<void> Function(QbittorrentClient) action,
  ) async {
    final QbittorrentClient client =
        await ref.read(qbittorrentClientProvider(instance).future);
    await action(client);
    ref.invalidate(qbitRawTorrentsProvider(instance));
    ref.invalidate(qbitSelectionProvider(instance));
  }

  static Future<void> confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Instance instance,
    Set<String> selectedHashes,
  ) async {
    bool deleteFiles = false;
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) => AlertDialog(
          title: const Text('Supprimer les torrents sélectionnés ?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Are you sure to delete the selected ${selectedHashes.length} torrents?',
              ),
              const SizedBox(height: Insets.md),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Supprimer les fichiers'),
                value: deleteFiles,
                onChanged: (bool? v) =>
                    setState(() => deleteFiles = v ?? false),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('ANNULER'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('CONFIRMER'),
            ),
          ],
        ),
      ),
    );
    if (ok ?? false) {
      final QbittorrentClient client =
          await ref.read(qbittorrentClientProvider(instance).future);
      await client.delete(selectedHashes.toList(), deleteFiles: deleteFiles);
      ref.invalidate(qbitSelectionProvider(instance));
      ref.invalidate(qbitRawTorrentsProvider(instance));
    }
  }

  static Future<void> editCategory(
    BuildContext context,
    WidgetRef ref,
    Instance instance,
    Set<String> selectedHashes,
  ) async {
    final List<String> cats =
        await ref.read(qbitCategoriesProvider(instance).future);
    if (!context.mounted) return;
    final String? chosen = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => SimpleDialog(
        title: const Text('Définir la catégorie'),
        children: <Widget>[
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(''),
            child: const Text('Aucun'),
          ),
          for (final String c in cats)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(c),
              child: Text(c),
            ),
        ],
      ),
    );
    if (chosen != null) {
      await run(
        ref,
        instance,
        (QbittorrentClient c) => c.setCategory(selectedHashes.toList(), chosen),
      );
    }
  }

  static Future<void> editTags(
    BuildContext context,
    WidgetRef ref,
    Instance instance,
    Set<String> selectedHashes,
  ) async {
    final TextEditingController ctrl = TextEditingController();
    final String? chosen = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Définir les balises'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'tag1, tag2'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(ctrl.text),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (chosen != null && chosen.isNotEmpty) {
      await run(
        ref,
        instance,
        (QbittorrentClient c) => c.addTags(selectedHashes.toList(), chosen),
      );
    }
  }

  static Future<void> editSavePath(
    BuildContext context,
    WidgetRef ref,
    Instance instance,
    Set<String> selectedHashes,
  ) async {
    final TextEditingController ctrl = TextEditingController();
    final String? chosen = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text("Définir le chemin d'enregistrement"),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: '/downloads/new_path'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(ctrl.text),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (chosen != null && chosen.isNotEmpty) {
      await run(
        ref,
        instance,
        (QbittorrentClient c) => c.setLocation(selectedHashes.toList(), chosen),
      );
    }
  }

  static Future<void> rename(
    BuildContext context,
    WidgetRef ref,
    Instance instance,
    Set<String> selectedHashes,
  ) async {
    final TextEditingController ctrl = TextEditingController();
    final String? chosen = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Renommer'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Nouveau nom'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(ctrl.text),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (chosen != null && chosen.isNotEmpty) {
      await run(
        ref,
        instance,
        (QbittorrentClient c) => c.rename(selectedHashes.first, chosen),
      );
    }
  }
}
