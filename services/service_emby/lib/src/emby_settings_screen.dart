import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'emby_client.dart';
import 'emby_providers.dart';

class EmbySettingsScreen extends ConsumerWidget {
  const EmbySettingsScreen({required this.instance, super.key});

  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<({double progress, String state})?> scanState =
        ref.watch(embyLibraryScanProvider(instance));

    return Scaffold(
      appBar: AppBar(
        title: Text(S.t('embySettings')),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.sync),
            title: Text(S.t('scanMediaLibrary')),
            subtitle: scanState.when(
              data: (({double progress, String state})? data) {
                if (data == null || data.state == 'Idle') {
                  return Text(S.t('ready'));
                }
                return Text(
                  '${data.state} - ${data.progress.toStringAsFixed(1)}%',
                );
              },
              loading: () => Text(S.t('checkingStatus')),
              error: (Object err, StackTrace stack) =>
                  Text(S.t('errorCheckingStatus')),
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
                      final EmbyClient client =
                          await ref.read(embyClientProvider(instance).future);
                      await client.startLibraryScan();
                      if (!context.mounted) return;
                      ref.invalidate(embyLibraryScanProvider(instance));
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(S.t('failedToStartScanE1', [e]))),
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
