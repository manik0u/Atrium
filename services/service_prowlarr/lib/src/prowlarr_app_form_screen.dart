import 'package:core_models/core_models.dart';
import 'package:core_networking/core_networking.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'prowlarr_api.dart';
import 'prowlarr_form_fields.dart';
import 'prowlarr_providers.dart';

/// Add or edit a Prowlarr application target (Sonarr, Radarr, ...).
///
/// In ADD mode ([appId] null) it first shows the short list of application
/// definitions (`/applications/schema`), then the config form for the chosen
/// one. In EDIT mode it loads the raw application by id and shows the same form.
/// Dynamic `fields` render via [ProwlarrDynamicField]; the payload round-trips
/// the whole object. Mirrors the indexer form, minus enable/priority/sync-
/// profile and plus a sync-level selector.
class ProwlarrAppFormScreen extends ConsumerStatefulWidget {
  const ProwlarrAppFormScreen({required this.instance, this.appId, super.key});

  final Instance instance;
  final int? appId;

  @override
  ConsumerState<ProwlarrAppFormScreen> createState() =>
      _ProwlarrAppFormScreenState();
}

class _ProwlarrAppFormScreenState extends ConsumerState<ProwlarrAppFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();

  Map<String, dynamic>? _selected; // chosen schema (add) or raw app (edit)
  List<Map<String, dynamic>> _fields = <Map<String, dynamic>>[];

  String _syncLevel = 'addOnly';

  bool _showAdvanced = false;
  bool _testing = false;
  bool _saving = false;
  bool _deleting = false;

  // Edit-mode raw load error (null while loading or once loaded).
  String? _loadError;

  bool get _isEdit => widget.appId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _loadRaw();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadRaw() async {
    if (_loadError != null) {
      setState(() => _loadError = null);
    }
    try {
      final ProwlarrApi api =
          await ref.read(prowlarrApiProvider(widget.instance).future);
      final Map<String, dynamic> raw =
          await api.getApplicationRaw(widget.appId!);
      if (!mounted) {
        return;
      }
      setState(() => _adopt(raw));
    } on Object catch (e) {
      if (mounted) {
        setState(() => _loadError = _errorMessage(e));
      }
    }
  }

  /// Seed the form state from a schema or raw application map.
  void _adopt(Map<String, dynamic> source) {
    _selected = source;
    _nameController.text = (source['name'] as String?) ??
        (source['implementationName'] as String?) ??
        '';
    _fields = ((source['fields'] as List<dynamic>?) ?? <dynamic>[])
        .map(
          (dynamic f) => Map<String, dynamic>.from(f as Map<dynamic, dynamic>),
        )
        .toList();
    final String? lvl = source['syncLevel'] as String?;
    _syncLevel = (lvl == null || lvl.isEmpty) ? 'addOnly' : lvl;
  }

  Map<String, dynamic> _buildPayload() {
    final Map<String, dynamic> payload = Map<String, dynamic>.from(_selected!);
    payload['name'] = _nameController.text.trim();
    payload['fields'] = _fields;
    payload['syncLevel'] = _syncLevel;
    payload['tags'] = (payload['tags'] as List<dynamic>?) ?? <dynamic>[];
    return payload;
  }

  Future<void> _test() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _testing = true);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      final ProwlarrApi api =
          await ref.read(prowlarrApiProvider(widget.instance).future);
      await api.testApplicationRaw(_buildPayload());
      messenger.showSnackBar(SnackBar(content: Text(S.t('testPassed'))));
    } on Object catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(S.t('testFailedErrorMessageE1', [_errorMessage(e)]))),
      );
    } finally {
      if (mounted) {
        setState(() => _testing = false);
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    final NavigatorState nav = Navigator.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      final ProwlarrApi api =
          await ref.read(prowlarrApiProvider(widget.instance).future);
      final Map<String, dynamic> payload = _buildPayload();
      if (_isEdit) {
        await api.updateApplicationRaw(payload);
      } else {
        await api.createApplicationRaw(payload);
      }
      ref.invalidate(prowlarrApplicationsProvider(widget.instance));
      messenger.showSnackBar(
        SnackBar(
          content: Text(_isEdit ? S.t('applicationSaved') : S.t('applicationAdded')),
        ),
      );
      nav.pop();
    } on Object catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(S.t('saveFailedErrorMessageE1', [_errorMessage(e)]))),
      );
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _delete() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(S.t('deleteApplication')),
        content: Text(S.t('removeNameControllerTextFromProwlarr1', [_nameController.text])),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(S.t('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(S.t('delete')),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) {
      return;
    }
    final NavigatorState nav = Navigator.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    setState(() => _deleting = true);
    try {
      final ProwlarrApi api =
          await ref.read(prowlarrApiProvider(widget.instance).future);
      await api.deleteApplication(widget.appId!);
      ref.invalidate(prowlarrApplicationsProvider(widget.instance));
      messenger.showSnackBar(
        SnackBar(content: Text(S.t('applicationDeleted'))),
      );
      nav.pop();
    } on Object catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(S.t('deleteFailedErrorMessageE1', [_errorMessage(e)]))),
      );
      if (mounted) {
        setState(() => _deleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isEdit && _selected == null) {
      return Scaffold(
        appBar: AppBar(title: Text(S.t('editApplication'))),
        body: _loadError != null
            ? ErrorView(
                title: S.t('couldNotLoadApplication'),
                message: _loadError!,
                onRetry: _loadRaw,
              )
            : const Center(child: ExpressiveProgressIndicator()),
      );
    }
    if (_selected == null) {
      return _AppSchemaPicker(
        instance: widget.instance,
        onPick: (Map<String, dynamic> schema) => setState(() => _adopt(schema)),
      );
    }
    return _buildForm(context);
  }

  Widget _buildForm(BuildContext context) {
    final String impl = (_selected!['implementationName'] as String?) ?? '';
    final String title = _isEdit
        ? 'Edit ${_nameController.text}'
        : 'Add ${_selected!['name'] ?? impl}';

    final List<Map<String, dynamic>> visibleFields =
        _fields.where((Map<String, dynamic> f) {
      if (!_showAdvanced && f['advanced'] == true) {
        return false;
      }
      if (f['hidden'] == 'hidden') {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(title, overflow: TextOverflow.ellipsis),
        actions: <Widget>[
          if (_isEdit)
            IconButton(
              tooltip: S.t('delete'),
              icon: _deleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: ExpressiveProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline),
              onPressed: _deleting ? null : _delete,
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(S.t('advanced'), style: TextStyle(fontSize: 12)),
              Switch(
                value: _showAdvanced,
                onChanged: (bool v) => setState(() => _showAdvanced = v),
              ),
            ],
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: Insets.page,
          children: <Widget>[
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: S.t('name'),
                border: OutlineInputBorder(),
              ),
              validator: (String? v) =>
                  (v == null || v.trim().isEmpty) ? S.t('required') : null,
            ),
            const SizedBox(height: Insets.md),
            DropdownButtonFormField<String>(
              initialValue: _syncLevel,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: S.t('syncLevel'),
                helperText: S.t('howProwlarrKeepsThisAppIndexersInSync'),
                border: OutlineInputBorder(),
              ),
              items: <DropdownMenuItem<String>>[
                DropdownMenuItem<String>(
                  value: 'disabled',
                  child: Text(S.t('disabled')),
                ),
                DropdownMenuItem<String>(
                  value: 'addOnly',
                  child: Text(S.t('addAndRemoveOnly')),
                ),
                DropdownMenuItem<String>(
                  value: 'fullSync',
                  child: Text(S.t('fullSync')),
                ),
              ],
              onChanged: (String? v) =>
                  setState(() => _syncLevel = v ?? _syncLevel),
            ),
            const SizedBox(height: Insets.md),
            ...visibleFields.map(
              (Map<String, dynamic> f) => ProwlarrDynamicField(
                key: ValueKey<String>('${f['name']}'),
                field: f,
              ),
            ),
            const SizedBox(height: Insets.lg),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _testing ? null : _test,
                    icon: _testing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: ExpressiveProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.science_outlined),
                    label: Text(S.t('test')),
                  ),
                ),
                const SizedBox(width: Insets.md),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: ExpressiveProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_isEdit ? S.t('save') : S.t('add')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The list of application definitions shown in ADD mode (short - Sonarr,
/// Radarr, Lidarr, Readarr, Mylar, LazyLibrarian, Whisparr).
class _AppSchemaPicker extends ConsumerWidget {
  const _AppSchemaPicker({required this.instance, required this.onPick});

  final Instance instance;
  final ValueChanged<Map<String, dynamic>> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Map<String, dynamic>>> schemas =
        ref.watch(prowlarrApplicationSchemasProvider(instance));
    return Scaffold(
      appBar: AppBar(title: Text(S.t('addApplication'))),
      body: AsyncValueView<List<Map<String, dynamic>>>(
        value: schemas,
        onRetry: () =>
            ref.invalidate(prowlarrApplicationSchemasProvider(instance)),
        data: (List<Map<String, dynamic>> list) {
          if (list.isEmpty) {
            return EmptyView(
              icon: Icons.apps_outlined,
              title: S.t('noApplications'),
              message: S.t('prowlarrReturnedNoApplicationDefinitions'),
            );
          }
          return ListView.builder(
            padding: Insets.pageH,
            itemCount: list.length,
            itemBuilder: (BuildContext context, int i) {
              final Map<String, dynamic> s = list[i];
              final String name = (s['implementationName'] as String?) ??
                  (s['name'] as String?) ??
                  S.t('unknown');
              return ListTile(
                leading: const Icon(Icons.apps),
                title: Text(name),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onPick(s),
              );
            },
          );
        },
      ),
    );
  }
}

String _errorMessage(Object e) {
  if (e is NetworkException && e.message.isNotEmpty) {
    return e.message;
  }
  return 'request failed';
}
