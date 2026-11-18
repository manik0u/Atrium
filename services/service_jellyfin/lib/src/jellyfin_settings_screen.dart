import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'jellyfin_client.dart';
import 'jellyfin_providers.dart';

class JellyfinSettingsScreen extends ConsumerWidget {
  const JellyfinSettingsScreen({required this.instance, super.key});

  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<({double progress, String state})?> scanState =
        ref.watch(jellyfinLibraryScanProvider(instance));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres Jellyfin'),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Analyser la bibliothèque multimédia'),
            subtitle: scanState.when(
              data: (({double progress, String state})? data) {
                if (data == null || data.state == 'Idle') {
                  return const Text('Prêt');
                }
                return Text(
                  '${data.state} - ${data.progress.toStringAsFixed(1)}%',
                );
              },
              loading: () => const Text('Vérification du statut…'),
              error: (Object err, StackTrace stack) =>
                  const Text('Erreur lors de la vérification du statut'),
            ),
            trailing: scanState.maybeWhen(
              data: (({double progress, String state})? data) {
                if (data != null && data.state == 'Running') {
                  return ExpressiveProgressIndicator(
                    value: data.progress > 0 ? data.progress / 100.0 : null,
                  );
                }
                return IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () async {
                    try {
                      final JellyfinClient client = await ref
                          .read(jellyfinClientProvider(instance).future);
                      await client.startLibraryScan();
                      if (!context.mounted) return;
                      ref.invalidate(jellyfinLibraryScanProvider(instance));
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Échec du démarrage de l'analyse : $e")),
                        );
                      }
                    }
                  },
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }
}
