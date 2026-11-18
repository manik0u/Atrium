import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../radarr_providers.dart';
import 'widgets/dynamic_schema_form.dart';

class MetadataSettingsScreen extends ConsumerWidget {
  const MetadataSettingsScreen({required this.instance, super.key});

  final Instance instance;

  Future<void> _showMetadataEditorDialog(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> metadata,
  ) async {
    final fields = (metadata['fields'] as List<dynamic>?)
            ?.map((dynamic f) => f as Map<String, dynamic>)
            .toList() ??
        [];

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(S.t('editMetadata')name']}'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: DynamicSchemaForm(
                fields: fields,
                onSave: (updatedFields) async {
                  try {
                    final api =
                        await ref.read(radarrApiProvider(instance).future);
                    final payload = Map<String, dynamic>.from(metadata);
                    payload['fields'] = updatedFields;

                    await api.updateMetadataConfig(
                      payload,
                      payload['id'] as int,
                    );
                    ref.invalidate(radarrMetadataConfigsProvider(instance));
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Metadata "${metadata['name']}" updated!',
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(S.t('failedToSaveMetadataSettingsE1', [e])),
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final configsAsync = ref.watch(radarrMetadataConfigsProvider(instance));

    return Scaffold(
      appBar: AppBar(
        title: Text(S.t('metadataConsumers')),
      ),
      body: configsAsync.when(
        loading: () => const Center(child: ExpressiveProgressIndicator()),
        error: (err, _) => Center(child: Text(S.t('errorErr1', [err]))),
        data: (configs) {
          if (configs.isEmpty) {
            return Center(child: Text(S.t('noMetadataConsumersFound')));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(Insets.md),
            itemCount: configs.length,
            itemBuilder: (context, index) {
              final c = configs[index];
              final name = c['name'] as String? ?? S.t('metadata');
              final enable = c['enable'] as bool? ?? false;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: theme.colorScheme.surfaceContainerLow,
                child: ListTile(
                  title: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(S.t('statusEnableEnabledDisabled1', [enable ? S.t('enabled') : S.t('off')])),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: enable,
                        onChanged: (val) async {
                          try {
                            final api = await ref
                                .read(radarrApiProvider(instance).future);
                            final payload = Map<String, dynamic>.from(c);
                            payload['enable'] = val;
                            await api.updateMetadataConfig(
                              payload,
                              payload['id'] as int,
                            );
                            ref.invalidate(
                              radarrMetadataConfigsProvider(instance),
                            );
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(S.t('errorE1', [e]))),
                              );
                            }
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () =>
                            _showMetadataEditorDialog(context, ref, c),
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
