import 'package:core_models/core_models.dart';
import 'package:core_networking/core_networking.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'prowlarr_api.dart';
import 'prowlarr_form_fields.dart';
import 'prowlarr_providers.dart';

/// Settings ▸ Sync Profiles: Prowlarr's `/appprofile` list. These control which
/// search modes (RSS / automatic / interactive) and minimum seeders apply when
/// an app pulls from an indexer. Fixed-shape config (no schema), so the form is
/// a handful of toggles rather than the dynamic provider form.
class ProwlarrSyncProfilesScreen extends ConsumerWidget {
  const ProwlarrSyncProfilesScreen({required this.instance, super.key});

  final Instance instance;

  ProwlarrProviderArgs get _args =>
      (instance: instance, endpoint: 'appprofile');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Map<String, dynamic>>> profiles =
        ref.watch(prowlarrProvidersProvider(_args));
    return Scaffold(
      appBar: AppBar(title: const Text('Profils de synchro')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'prowlarr-add-appprofile',
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
      body: AsyncValueView<List<Map<String, dynamic>>>(
          value: profiles,
          onRetry: () => ref.invalidate(prowlarrProvidersProvider(_args)),
          data: (List<Map<String, dynamic>> items) {
            
            if (items.isEmpty) {
              return EasyRefresh(
        header: const ClassicHeader(
          dragText: 'Pull to refresh',
          armedText: 'Release ready',
          readyText: 'Refreshing...',
          processingText: 'Refreshing...',
          processedText: 'Succeeded',
          failedText: 'Failed',
          messageText: 'Last updated at %T',
        ),
        onRefresh: () async => ref.invalidate(prowlarrProvidersProvider(_args)),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const <Widget>[
            SizedBox(height: 100),
            EmptyView(
                icon: Icons.tune_outlined,
                title: 'Aucun profil de synchro',
                message: 'Touchez Ajouter pour créer un profil de synchro.',
              ),
          ],
        ),
      );
            }
            return EasyRefresh(
      header: const ClassicHeader(
        dragText: 'Pull to refresh',
        armedText: 'Release ready',
        readyText: 'Refreshing...',
        processingText: 'Refreshing...',
        processedText: 'Succeeded',
        failedText: 'Failed',
        messageText: 'Last updated at %T',
      ),
      onRefresh: () async => ref.invalidate(prowlarrProvidersProvider(_args)),
      child: ListView.builder(
              padding: Insets.pageH,
              itemCount: items.length,
              itemBuilder: (BuildContext context, int i) {
                final Map<String, dynamic> p = items[i];
                return ListTile(
                  leading: const Icon(Icons.tune_outlined),
                  title: Text((p['name'] as String?) ?? 'Profil'),
                  subtitle: Text(_summary(p)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openForm(context, profile: p),
                );
              },
            ),
    );
          
          },
        ),
    );
  }

  String _summary(Map<String, dynamic> p) {
    final List<String> modes = <String>[
      if (p['enableRss'] == true) 'RSS',
      if (p['enableAutomaticSearch'] == true) 'Automatic',
      if (p['enableInteractiveSearch'] == true) 'Interactive',
    ];
    final String search = modes.isEmpty ? 'Aucun mode de recherche' : modes.join(' • ');
    return '$search • min ${(p['minimumSeeders'] as num?)?.toInt() ?? 0} seeders';
  }

  void _openForm(BuildContext context, {Map<String, dynamic>? profile}) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => ProwlarrSyncProfileFormScreen(
          instance: instance,
          profile: profile,
        ),
      ),
    );
  }
}

/// Add or edit one sync profile.
class ProwlarrSyncProfileFormScreen extends ConsumerStatefulWidget {
  const ProwlarrSyncProfileFormScreen({
    required this.instance,
    this.profile,
    super.key,
  });

  final Instance instance;
  final Map<String, dynamic>? profile;

  @override
  ConsumerState<ProwlarrSyncProfileFormScreen> createState() =>
      _ProwlarrSyncProfileFormScreenState();
}

class _ProwlarrSyncProfileFormScreenState
    extends ConsumerState<ProwlarrSyncProfileFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();

  bool _rss = true;
  bool _automatic = true;
  bool _interactive = true;
  int _minSeeders = 1;

  bool _saving = false;
  bool _deleting = false;

  bool get _isEdit => widget.profile != null;

  ProwlarrProviderArgs get _args =>
      (instance: widget.instance, endpoint: 'appprofile');

  @override
  void initState() {
    super.initState();
    final Map<String, dynamic>? p = widget.profile;
    if (p != null) {
      _nameController.text = (p['name'] as String?) ?? '';
      _rss = p['enableRss'] != false;
      _automatic = p['enableAutomaticSearch'] != false;
      _interactive = p['enableInteractiveSearch'] != false;
      _minSeeders = (p['minimumSeeders'] as num?)?.toInt() ?? 1;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildPayload() {
    final Map<String, dynamic> payload =
        Map<String, dynamic>.from(widget.profile ?? <String, dynamic>{});
    payload['name'] = _nameController.text.trim();
    payload['enableRss'] = _rss;
    payload['enableAutomaticSearch'] = _automatic;
    payload['enableInteractiveSearch'] = _interactive;
    payload['minimumSeeders'] = _minSeeders;
    return payload;
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
        await api.updateProvider('appprofile', payload);
      } else {
        await api.createProvider('appprofile', payload);
      }
      _invalidate();
      messenger.showSnackBar(
        SnackBar(content: Text(_isEdit ? 'Profil enregistré' : 'Profil ajouté')),
      );
      nav.pop();
    } on Object catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text("Échec de l'enregistrement : ${_err(e)}")),
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
        title: const Text('Supprimer le profil de synchro ?'),
        content: Text('Retirer « ${_nameController.text} » de Prowlarr ?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
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
      await api.deleteProvider(
        'appprofile',
        (widget.profile!['id'] as num).toInt(),
      );
      _invalidate();
      messenger.showSnackBar(const SnackBar(content: Text('Profil supprimé')));
      nav.pop();
    } on Object catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Échec de la suppression : ${_err(e)}')),
      );
      if (mounted) {
        setState(() => _deleting = false);
      }
    }
  }

  /// Refresh both the settings list and the indexer form's profile dropdown.
  void _invalidate() {
    ref.invalidate(prowlarrProvidersProvider(_args));
    ref.invalidate(prowlarrAppProfilesProvider(widget.instance));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Modifier le profil de synchro' : 'Ajouter un profil de synchro'),
        actions: <Widget>[
          if (_isEdit)
            IconButton(
              tooltip: 'Supprimer',
              icon: _deleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: ExpressiveProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline),
              onPressed: _deleting ? null : _delete,
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
              decoration: const InputDecoration(
                labelText: 'Nom',
                border: OutlineInputBorder(),
              ),
              validator: (String? v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: Insets.md),
            ProwlarrSwitchTile(
              label: 'Activer RSS',
              subtitle: 'Autoriser les applications à récupérer les nouvelles releases via la synchro RSS',
              value: _rss,
              onChanged: (bool v) => setState(() => _rss = v),
            ),
            ProwlarrSwitchTile(
              label: 'Activer la recherche automatique',
              subtitle: 'Autoriser les applications à lancer des recherches automatiques',
              value: _automatic,
              onChanged: (bool v) => setState(() => _automatic = v),
            ),
            ProwlarrSwitchTile(
              label: 'Activer la recherche interactive',
              subtitle: 'Autoriser les applications à lancer des recherches interactives',
              value: _interactive,
              onChanged: (bool v) => setState(() => _interactive = v),
            ),
            ProwlarrIntField(
              label: 'Seeders minimum',
              helperText: 'Les torrents sous ce nombre de seeders sont rejetés',
              value: _minSeeders,
              onChanged: (int v) => _minSeeders = v,
            ),
            const SizedBox(height: Insets.lg),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: ExpressiveProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_isEdit ? 'Enregistrer' : 'Ajouter'),
            ),
          ],
        ),
      ),
    );
  }
}

String _err(Object e) {
  if (e is NetworkException && e.message.isNotEmpty) {
    return e.message;
  }
  return 'request failed';
}
