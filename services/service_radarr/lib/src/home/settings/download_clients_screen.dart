import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../radarr_providers.dart';
import 'widgets/confirm_delete.dart';
import 'widgets/dynamic_schema_form.dart';

class DownloadClientsScreen extends ConsumerStatefulWidget {
  const DownloadClientsScreen({
    required this.instance,
    super.key,
  });

  final Instance instance;

  @override
  ConsumerState<DownloadClientsScreen> createState() =>
      _DownloadClientsScreenState();
}

class _DownloadClientsScreenState extends ConsumerState<DownloadClientsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.t('downloadClientsMappings')),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: S.t('clients')),
            Tab(text: S.t('pathMappings')),
            Tab(text: S.t('options')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _DownloadClientsTab(instance: widget.instance),
          _RemotePathMappingsTab(instance: widget.instance),
          _DownloadClientOptionsTab(instance: widget.instance),
        ],
      ),
    );
  }
}

class _DownloadClientsTab extends ConsumerWidget {
  const _DownloadClientsTab({required this.instance});

  final Instance instance;

  Future<void> _selectClientPresetAndAdd(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final schemasAsync = ref.read(radarrDownloadClientSchemaProvider(instance));
    final presets = schemasAsync.value ?? [];
    if (presets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.t('loadingDownloadClientPresets'))),
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
                S.t('addDownloadClient'),
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
                    final name = preset['name'] as String? ?? S.t('client');
                    final implementation =
                        preset['implementationName'] as String? ?? '';

                    return ListTile(
                      title: Text(name),
                      subtitle: Text(implementation),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(context);
                        _showClientEditorDialog(
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

  Future<void> _showClientEditorDialog(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> client, {
    bool isNew = false,
  }) async {
    final fields = (client['fields'] as List<dynamic>?)
            ?.map((dynamic f) => f as Map<String, dynamic>)
            .toList() ??
        [];

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title:
              Text(isNew ? S.t('addClient_2')name']}' : 'Edit ${client['name']}'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: DynamicSchemaForm(
                fields: fields,
                onTest: (updatedFields) async {
                  final api =
                      await ref.read(radarrApiProvider(instance).future);
                  final payload = Map<String, dynamic>.from(client);
                  payload['fields'] = updatedFields;
                  await api.testDownloadClient(payload);
                },
                onSave: (updatedFields) async {
                  try {
                    final api =
                        await ref.read(radarrApiProvider(instance).future);
                    final payload = Map<String, dynamic>.from(client);
                    payload['fields'] = updatedFields;

                    if (isNew) {
                      await api.createDownloadClient(payload);
                    } else {
                      await api.updateDownloadClient(
                        payload,
                        payload['id'] as int,
                      );
                    }

                    ref.invalidate(radarrDownloadClientsProvider(instance));
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Download client ${isNew ? 'added' : 'updated'}!',
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(S.t('failedToSaveDownloadClientE1', [e])),
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

  Future<void> _deleteClient(
    BuildContext context,
    WidgetRef ref,
    int id,
    String name,
  ) async {
    final confirmed = await confirmDelete(context, 'Download Client "$name"');
    if (!confirmed) return;

    try {
      final api = await ref.read(radarrApiProvider(instance).future);
      await api.deleteDownloadClient(id);
      ref.invalidate(radarrDownloadClientsProvider(instance));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.t('downloadClientDeleted'))),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.t('failedToDeleteDownloadClientE1', [e]))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final clientsAsync = ref.watch(radarrDownloadClientsProvider(instance));

    ref.watch(radarrDownloadClientSchemaProvider(instance));

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _selectClientPresetAndAdd(context, ref),
        child: const Icon(Icons.add),
      ),
      body: clientsAsync.when(
        loading: () => const Center(child: ExpressiveProgressIndicator()),
        error: (err, _) => Center(child: Text(S.t('errorErr1', [err]))),
        data: (clients) {
          if (clients.isEmpty) {
            return Center(
              child: Text(S.t('noDownloadClientsConfiguredTapToAddOne')),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(Insets.md),
            itemCount: clients.length,
            itemBuilder: (context, index) {
              final c = clients[index];
              final name = c['name'] as String? ?? S.t('client');
              final proto = c['protocol'] as String? ?? S.t('torrent');
              final id = c['id'] as int;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: theme.colorScheme.surfaceContainerLow,
                child: ListTile(
                  title: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(S.t('protocolProtoToUpperCase1', [proto.toUpperCase()])),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () =>
                            _showClientEditorDialog(context, ref, c),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: theme.colorScheme.error,
                        ),
                        onPressed: () => _deleteClient(context, ref, id, name),
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

class _RemotePathMappingsTab extends ConsumerWidget {
  const _RemotePathMappingsTab({required this.instance});

  final Instance instance;

  Future<void> _showMappingDialog(
    BuildContext context,
    WidgetRef ref, [
    Map<String, dynamic>? mapping,
  ]) async {
    final isEdit = mapping != null;
    final hostController =
        TextEditingController(text: mapping?['host'] as String? ?? '');
    final remoteController =
        TextEditingController(text: mapping?['remotePath'] as String? ?? '');
    final localController =
        TextEditingController(text: mapping?['localPath'] as String? ?? '');

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEdit ? S.t('editPathMapping') : S.t('addPathMapping')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: hostController,
                decoration: InputDecoration(
                  labelText: S.t('host'),
                  helperText: S.t('downloadClientHostExactlyAsConfigured'),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: Insets.md),
              TextField(
                controller: remoteController,
                decoration: InputDecoration(
                  labelText: S.t('remotePath'),
                  helperText: S.t('pathReportedByDownloadClient'),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: Insets.md),
              TextField(
                controller: localController,
                decoration: InputDecoration(
                  labelText: S.t('localPath'),
                  helperText: S.t('pathAccessibleByRadarrLocalSystem'),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(S.t('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final api =
                      await ref.read(radarrApiProvider(instance).future);
                  final payload = mapping != null
                      ? Map<String, dynamic>.from(mapping)
                      : <String, dynamic>{};

                  payload['host'] = hostController.text.trim();
                  payload['remotePath'] = remoteController.text.trim();
                  payload['localPath'] = localController.text.trim();

                  if (isEdit) {
                    await api.updateRemotePathMapping(
                      payload,
                      payload['id'] as int,
                    );
                  } else {
                    await api.createRemotePathMapping(payload);
                  }

                  ref.invalidate(radarrRemotePathMappingsProvider(instance));
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(S.t('pathMappingSaved'))),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(S.t('errorE1', [e]))),
                    );
                  }
                }
              },
              child: Text(S.t('save')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteMapping(
    BuildContext context,
    WidgetRef ref,
    int id,
    String host,
  ) async {
    final confirmed = await confirmDelete(context, S.t('pathMappingForHost1', [host]));
    if (!confirmed) return;

    try {
      final api = await ref.read(radarrApiProvider(instance).future);
      await api.deleteRemotePathMapping(id);
      ref.invalidate(radarrRemotePathMappingsProvider(instance));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.t('pathMappingDeleted'))),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.t('failedToDeletePathMappingE1', [e]))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final mappingsAsync = ref.watch(radarrRemotePathMappingsProvider(instance));

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showMappingDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: mappingsAsync.when(
        loading: () => const Center(child: ExpressiveProgressIndicator()),
        error: (err, _) => Center(child: Text(S.t('errorErr1', [err]))),
        data: (mappings) {
          if (mappings.isEmpty) {
            return Center(
              child: Text(S.t('noPathMappingsConfiguredTapToAddOne')),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(Insets.md),
            itemCount: mappings.length,
            itemBuilder: (context, index) {
              final m = mappings[index];
              final id = m['id'] as int;
              final host = m['host'] as String? ?? 'localhost';
              final remote = m['remotePath'] as String? ?? '';
              final local = m['localPath'] as String? ?? '';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: theme.colorScheme.surfaceContainerLow,
                child: ListTile(
                  title: Text(
                    'Host: $host',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(S.t('remoteRemoteLocalLocal2', [remote, local])),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _showMappingDialog(context, ref, m),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: theme.colorScheme.error,
                        ),
                        onPressed: () => _deleteMapping(context, ref, id, host),
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

class _DownloadClientOptionsTab extends ConsumerStatefulWidget {
  const _DownloadClientOptionsTab({required this.instance});

  final Instance instance;

  @override
  ConsumerState<_DownloadClientOptionsTab> createState() =>
      _DownloadClientOptionsTabState();
}

class _DownloadClientOptionsTabState
    extends ConsumerState<_DownloadClientOptionsTab> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool _initialized = false;
  Map<String, dynamic>? _rawConfig;

  bool _enableCompletedDownloadHandling = false;
  bool _autoRedownloadFailed = false;

  void _initialize(Map<String, dynamic> config) {
    if (_initialized) return;
    _initialized = true;
    _rawConfig = config;

    _enableCompletedDownloadHandling =
        config['enableCompletedDownloadHandling'] as bool? ?? false;
    _autoRedownloadFailed = config['autoRedownloadFailed'] as bool? ?? false;
  }

  Future<void> _save() async {
    if (_rawConfig == null) return;
    setState(() => _saving = true);

    try {
      final api = await ref.read(radarrApiProvider(widget.instance).future);
      final payload = Map<String, dynamic>.from(_rawConfig!);
      payload['enableCompletedDownloadHandling'] =
          _enableCompletedDownloadHandling;
      payload['autoRedownloadFailed'] = _autoRedownloadFailed;

      await api.updateDownloadClientConfig(payload);
      ref.invalidate(radarrDownloadClientConfigProvider(widget.instance));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.t('downloadClientConfigSaved'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.t('errorE1', [e]))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final configAsync =
        ref.watch(radarrDownloadClientConfigProvider(widget.instance));

    return configAsync.when(
      loading: () => const Center(child: ExpressiveProgressIndicator()),
      error: (err, stack) => Center(child: Text(S.t('errorErr1', [err]))),
      data: (config) {
        _initialize(config);

        return Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(Insets.md),
            children: [
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(Insets.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        S.t('completedDownloadHandling'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: Insets.md),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(S.t('enableCompletedDownloadHandling')),
                        subtitle: Text(
                          S.t('automaticallyImportFinishedDownloadsFromClients'),
                        ),
                        value: _enableCompletedDownloadHandling,
                        onChanged: (val) => setState(
                          () => _enableCompletedDownloadHandling = val,
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(S.t('redownloadFailed')),
                        subtitle: Text(
                          S.t('searchForAReleaseAlternativeIfDownloadReportsFailure'),
                        ),
                        value: _autoRedownloadFailed,
                        onChanged: (val) =>
                            setState(() => _autoRedownloadFailed = val),
                      ),
                      const SizedBox(height: Insets.lg),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const ExpressiveProgressIndicator()
                              : Text(S.t('saveOptions')),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
