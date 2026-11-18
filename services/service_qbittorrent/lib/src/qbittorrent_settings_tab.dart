import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/qbit_transfer_info.dart';
import 'qbittorrent_client.dart';
import 'qbittorrent_home.dart' show fmtBytes;
import 'qbittorrent_providers.dart';

/// The Settings tab for qBittorrent matching Sonarr's System tab design:
/// NestedScrollView with scrollable top TabBar for Behavior, Downloads, Connection,
/// Speed, BitTorrent, RSS, WebUI, and Advanced tabs.
class QbittorrentSettingsTab extends ConsumerStatefulWidget {
  const QbittorrentSettingsTab({required this.instance, super.key});

  final Instance instance;

  @override
  ConsumerState<QbittorrentSettingsTab> createState() =>
      _QbittorrentSettingsTabState();
}

class _QbittorrentSettingsTabState
    extends ConsumerState<QbittorrentSettingsTab> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _getBool(dynamic val, {bool defaultValue = false}) {
    if (val is bool) return val;
    if (val is num) return val != 0;
    if (val is String) return val.toLowerCase() == 'true' || val == '1';
    return defaultValue;
  }

  int _getInt(dynamic val, {int defaultValue = 0}) {
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val) ?? defaultValue;
    return defaultValue;
  }

  void _refreshAll() {
    final Instance instance = widget.instance;
    ref.invalidate(qbitAppVersionProvider(instance));
    ref.invalidate(qbitApiVersionProvider(instance));
    ref.invalidate(qbitPreferencesProvider(instance));
    ref.invalidate(qbitAltSpeedModeProvider(instance));
    ref.invalidate(qbitTransferProvider(instance));
    ref.invalidate(qbitNetworkInterfacesProvider(instance));
  }

  /// Settings that can cut Atrium off from this server, or switch off a
  /// protection the Web UI relies on.
  ///
  /// All four are a single tap on a phone and awkward to undo afterwards: once
  /// the address or port moves, this app can no longer reach the server to put
  /// it back.
  static const Map<String, String> _riskyPrefs = <String, String>{
    'web_ui_address':
        'Atrium reaches this server at its current address. Changing it will '
            'break this connection until you update the instance URL in '
            'Atrium.',
    'web_ui_port':
        'Atrium reaches this server on its current port. Changing it will '
            'break this connection until you update the instance URL in '
            'Atrium.',
    'web_ui_csrf_protection_enabled':
        'CSRF protection stops another site acting on your qBittorrent '
            'session. Leaving it on is recommended.',
    'web_ui_clickjacking_protection_enabled':
        "la protection anti-clickjacking empêche l'interface web d'être embarquée dans une autre "
            'page. Leaving it on is recommended.',
  };

  /// Whether a change to [key] may go ahead.
  ///
  /// A protection toggle only asks on the way off; switching one back on needs
  /// no ceremony.
  Future<bool> _confirmIfRisky(String key, dynamic value) async {
    final String? message = _riskyPrefs[key];
    if (message == null) return true;
    if (value is bool && value) return true;

    final bool? proceed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Modifier ce paramètre ?'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Le modifier'),
          ),
        ],
      ),
    );
    return proceed ?? false;
  }

  Future<void> _updatePref(String key, dynamic value) async {
    if (!await _confirmIfRisky(key, value)) {
      // Nothing was sent, so the stored value still stands. Rebuild so a
      // switch that already moved under the user's finger snaps back to it.
      if (mounted) setState(() {});
      return;
    }
    try {
      final QbittorrentClient client = await ref.read(
        qbittorrentClientProvider(widget.instance).future,
      );
      await client.setPreferences(<String, dynamic>{key: value});
      ref.invalidate(qbitPreferencesProvider(widget.instance));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paramètre enregistré'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec de la mise à jour du paramètre : $e')),
        );
      }
    }
  }

  Future<void> _showStringEditDialog({
    required String title,
    required String prefKey,
    required String initialValue,
    String? hintText,
  }) async {
    final TextEditingController controller =
        TextEditingController(text: initialValue);
    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: hintText,
            isDense: true,
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (result != null && result != initialValue) {
      await _updatePref(prefKey, result);
    }
  }

  Future<void> _showNumberEditDialog({
    required String title,
    required String prefKey,
    required int initialValue,
    String? helperText,
  }) async {
    final TextEditingController controller =
        TextEditingController(text: initialValue.toString());
    final int? result = await showDialog<int>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            helperText: helperText,
            isDense: true,
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(ctx, int.tryParse(controller.text.trim())),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (result != null && result != initialValue) {
      await _updatePref(prefKey, result);
    }
  }

  Future<void> _showOptionsDialog<T>({
    required String title,
    required String prefKey,
    required T currentValue,
    required List<({String label, T value, String? subtitle})> options,
  }) async {
    final T? selected = await showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      useRootNavigator: true,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Insets.lg,
                  Insets.xs,
                  Insets.lg,
                  Insets.sm,
                ),
                child: Text(
                  title,
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (BuildContext context, int index) {
                    final item = options[index];
                    final bool isSelected = item.value == currentValue;
                    return ListTile(
                      title: Text(
                        item.label,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? Theme.of(ctx).colorScheme.primary
                              : null,
                        ),
                      ),
                      subtitle:
                          item.subtitle != null ? Text(item.subtitle!) : null,
                      trailing: isSelected
                          ? Icon(
                              Icons.check_rounded,
                              color: Theme.of(ctx).colorScheme.primary,
                            )
                          : null,
                      onTap: () => Navigator.pop(ctx, item.value),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected != null && selected != currentValue) {
      await _updatePref(prefKey, selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Instance instance = widget.instance;
    final ThemeData theme = Theme.of(context);

    ref.listen<int>(
      qbitHomeScrollToTopProvider((instance, 1)),
      (int? previous, int next) {
        if (next > 0 && _scrollController.hasClients) {
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
          );
        }
      },
    );

    return DefaultTabController(
      length: 9,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder:
              (BuildContext innerContext, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverAppBar(
                floating: true,
                snap: true,
                pinned: true,
                scrolledUnderElevation: 0.0,
                surfaceTintColor: Colors.transparent,
                backgroundColor: theme.colorScheme.surface,
                leadingWidth: 56,
                leading: IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
                title: Text('Paramètres de ${instance.name}'),
                actions: <Widget>[
                  IconButton(
                    tooltip: 'Actualiser',
                    icon: const Icon(Icons.refresh),
                    onPressed: _refreshAll,
                  ),
                  const SizedBox(width: Insets.xs),
                ],
                bottom: TabBar(
                  dividerColor: Colors.transparent,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorColor: theme.colorScheme.primary,
                  labelColor: theme.colorScheme.primary,
                  unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelStyle: theme.textTheme.titleSmall,
                  tabs: const <Widget>[
                    Tab(text: 'Système'),
                    Tab(text: 'Comportement'),
                    Tab(text: 'Téléchargements'),
                    Tab(text: 'Connexion'),
                    Tab(text: 'Vitesse'),
                    Tab(text: 'BitTorrent'),
                    Tab(text: 'RSS'),
                    Tab(text: 'Interface web'),
                    Tab(text: 'Avancé'),
                  ],
                ),
              ),
            ];
          },
          body: TabBarView(
            children: <Widget>[
              _buildSystemTab(),
              _buildBehaviorTab(),
              _buildDownloadsTab(),
              _buildConnectionTab(),
              _buildSpeedTab(),
              _buildBitTorrentTab(),
              _buildRssTab(),
              _buildWebUiTab(),
              _buildAdvancedTab(),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 1. SYSTEM TAB
  // ==========================================
  Widget _buildSystemTab() {
    final Instance instance = widget.instance;
    final AsyncValue<String> appVersion =
        ref.watch(qbitAppVersionProvider(instance));
    final AsyncValue<String> apiVersion =
        ref.watch(qbitApiVersionProvider(instance));
    final QbitTransferInfo? transfer =
        ref.watch(qbitTransferProvider(instance)).value;
    final QbitExternalAddresses? addresses =
        ref.watch(qbitExternalAddressesProvider(instance)).value;
    // qBittorrent before 5.0 sends neither field, so there is nothing to show
    // rather than an address that will never arrive.
    final bool reportsAddresses =
        addresses != null && (addresses.v4 != null || addresses.v6 != null);

    final String shareRatio = transfer != null && transfer.dlData > 0
        ? (transfer.upData / transfer.dlData).toStringAsFixed(2)
        : '0.00';

    return _buildTabListView(
      children: <Widget>[
        _buildSectionHeader('Server Information'),
        _buildCard(
          children: <Widget>[
            _buildInfoTile(
              icon: Icons.dns_rounded,
              title: 'Version de qBittorrent',
              value: appVersion.value ?? 'Loading...',
              color: Theme.of(context).colorScheme.primary,
            ),
            const Divider(height: 1),
            _buildInfoTile(
              icon: Icons.api_rounded,
              title: "Version de l'API web",
              value: apiVersion.value ?? 'Loading...',
              color: Theme.of(context).colorScheme.secondary,
            ),
            const Divider(height: 1),
            _buildInfoTile(
              icon: Icons.wifi_tethering_rounded,
              title: 'État de la connexion',
              value: transfer?.connectionStatus.toUpperCase() ?? 'CONNECTED',
              color: transfer?.connectionStatus == 'disconnected'
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary,
            ),
            if (reportsAddresses) ...<Widget>[
              const Divider(height: 1),
              _buildAddressTile(
                title: 'IPv4 externe',
                address: addresses.v4 ?? '',
              ),
              // Most connections have no IPv6 address at all, so an empty
              // one is left out rather than shown as unknown.
              if ((addresses.v6 ?? '').isNotEmpty) ...<Widget>[
                const Divider(height: 1),
                _buildAddressTile(
                  title: 'IPv6 externe',
                  address: addresses.v6!,
                ),
              ],
            ],
            const Divider(height: 1),
            _buildInfoTile(
              icon: Icons.link_rounded,
              title: "Adresse de l'instance",
              value: instance.localUrl.isNotEmpty
                  ? instance.localUrl
                  : instance.externalUrl,
              color: Theme.of(context).colorScheme.tertiary,
            ),
          ],
        ),
        const SizedBox(height: Insets.md),
        _buildSectionHeader('Transfer Statistics'),
        _buildCard(
          children: <Widget>[
            _buildInfoTile(
              icon: Icons.arrow_downward_rounded,
              title: 'Vitesse de téléchargement actuelle',
              value: '${fmtBytes(transfer?.dlSpeed ?? 0)}/s',
              color: Theme.of(context).colorScheme.primary,
            ),
            const Divider(height: 1),
            _buildInfoTile(
              icon: Icons.arrow_upward_rounded,
              title: "Vitesse d'envoi actuelle",
              value: '${fmtBytes(transfer?.upSpeed ?? 0)}/s',
              color: Theme.of(context).colorScheme.secondary,
            ),
            const Divider(height: 1),
            _buildInfoTile(
              icon: Icons.file_download_done_rounded,
              title: 'Téléchargé dans la session',
              value: fmtBytes(transfer?.dlData ?? 0),
              color: Theme.of(context).colorScheme.primary,
            ),
            const Divider(height: 1),
            _buildInfoTile(
              icon: Icons.file_upload_outlined,
              title: 'Envoyé dans la session',
              value: fmtBytes(transfer?.upData ?? 0),
              color: Theme.of(context).colorScheme.secondary,
            ),
            const Divider(height: 1),
            _buildInfoTile(
              icon: Icons.pie_chart_outline_rounded,
              title: 'Ratio de partage de la session',
              value: shareRatio,
              color: Theme.of(context).colorScheme.tertiary,
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // 2. BEHAVIOR TAB
  // ==========================================
  Widget _buildBehaviorTab() {
    final Instance instance = widget.instance;
    final Map<String, dynamic> prefs =
        ref.watch(qbitPreferencesProvider(instance)).value ??
            <String, dynamic>{};

    return _buildTabListView(
      children: <Widget>[
        _buildSectionHeader('Localization & Interface'),
        _buildCard(
          children: <Widget>[
            _buildActionTile(
              icon: Icons.language_rounded,
              title: "Langue de l'interface",
              value: prefs['locale']?.toString() ?? 'en',
              onTap: () => _showStringEditDialog(
                title: "Langue de l'interface (ex. en, fr, de, es)",
                prefKey: 'locale',
                initialValue: prefs['locale']?.toString() ?? 'en',
              ),
            ),
          ],
        ),
        const SizedBox(height: Insets.md),
        _buildSectionHeader('Confirmations & Prompts'),
        _buildCard(
          children: <Widget>[
            _buildSwitchTile(
              icon: Icons.delete_outline_rounded,
              title: 'Confirmer la suppression des torrents',
              subtitle: 'Afficher une boîte de confirmation avant de supprimer les torrents',
              value: _getBool(
                prefs['confirm_torrent_deletion'],
                defaultValue: true,
              ),
              onChanged: (bool val) =>
                  _updatePref('confirm_torrent_deletion', val),
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              icon: Icons.refresh_rounded,
              title: 'Confirmer la revérification des torrents',
              subtitle: 'Afficher une boîte de confirmation avant la revérification forcée',
              value: _getBool(
                prefs['confirm_torrent_recheck'],
                defaultValue: true,
              ),
              onChanged: (bool val) =>
                  _updatePref('confirm_torrent_recheck', val),
            ),
          ],
        ),
        const SizedBox(height: Insets.md),
        _buildSectionHeader('Power Management'),
        _buildCard(
          children: <Widget>[
            _buildSwitchTile(
              icon: Icons.bedtime_outlined,
              title: 'Inhiber la mise en veille du système',
              subtitle: 'Empêcher la mise en veille du système tant que des torrents sont actifs',
              value: _getInt(prefs['auto_exit_mode']) != 0,
              onChanged: (bool val) =>
                  _updatePref('auto_exit_mode', val ? 1 : 0),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // 2. DOWNLOADS TAB
  // ==========================================
  Widget _buildDownloadsTab() {
    final Instance instance = widget.instance;
    final Map<String, dynamic> prefs =
        ref.watch(qbitPreferencesProvider(instance)).value ??
            <String, dynamic>{};

    return _buildTabListView(
      children: <Widget>[
        _buildSectionHeader('Storage Directories'),
        _buildCard(
          children: <Widget>[
            _buildActionTile(
              icon: Icons.folder_outlined,
              title: "Chemin d'enregistrement par défaut",
              value: prefs['save_path']?.toString() ?? 'Default',
              onTap: () => _showStringEditDialog(
                title: "Chemin d'enregistrement par défaut",
                prefKey: 'save_path',
                initialValue: prefs['save_path']?.toString() ?? '',
              ),
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              icon: Icons.folder_copy_outlined,
              title: 'Conserver les torrents incomplets dans le chemin temporaire',
              subtitle: prefs['temp_path']?.toString() ?? 'Désactivé',
              value: _getBool(prefs['temp_path_enabled']),
              onChanged: (bool val) => _updatePref('temp_path_enabled', val),
            ),
            if (_getBool(prefs['temp_path_enabled'])) ...<Widget>[
              const Divider(height: 1),
              _buildActionTile(
                icon: Icons.edit_location_alt_outlined,
                title: 'Chemin des fichiers incomplets',
                value: prefs['temp_path']?.toString() ?? '',
                onTap: () => _showStringEditDialog(
                  title: 'Chemin des fichiers incomplets',
                  prefKey: 'temp_path',
                  initialValue: prefs['temp_path']?.toString() ?? '',
                ),
              ),
            ],
            const Divider(height: 1),
            _buildActionTile(
              icon: Icons.file_download_outlined,
              title: 'Copier les fichiers .torrent vers',
              value: prefs['export_dir']?.toString().isNotEmpty == true
                  ? prefs['export_dir'].toString()
                  : 'None',
              onTap: () => _showStringEditDialog(
                title: 'Copier les fichiers .torrent vers',
                prefKey: 'export_dir',
                initialValue: prefs['export_dir']?.toString() ?? '',
              ),
            ),
          ],
        ),
        const SizedBox(height: Insets.md),
        _buildSectionHeader('File Allocation & Naming'),
        _buildCard(
          children: <Widget>[
            _buildSwitchTile(
              icon: Icons.extension_outlined,
              title: "Ajouter l'extension .!qB",
              subtitle: 'Ajouter une extension aux fichiers incomplets',
              value: _getBool(prefs['incomplete_files_ext']),
              onChanged: (bool val) => _updatePref('incomplete_files_ext', val),
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              icon: Icons.storage_rounded,
              title: "Pré-allouer l'espace disque",
              subtitle: "Pré-allouer le stockage de tous les fichiers à l'ajout",
              value: _getBool(prefs['preallocate_all']),
              onChanged: (bool val) => _updatePref('preallocate_all', val),
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              icon: Icons.auto_mode_rounded,
              title: 'Gestion automatique des torrents',
              subtitle: 'Déplacer les torrents quand les chemins des catégories changent',
              value: _getBool(prefs['auto_tmm_enabled']),
              onChanged: (bool val) => _updatePref('auto_tmm_enabled', val),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // 3. CONNECTION TAB
  // ==========================================
  Widget _buildConnectionTab() {
    final Instance instance = widget.instance;
    final Map<String, dynamic> prefs =
        ref.watch(qbitPreferencesProvider(instance)).value ??
            <String, dynamic>{};

    return _buildTabListView(
      children: <Widget>[
        _buildSectionHeader('Listening Port & Protocol'),
        _buildCard(
          children: <Widget>[
            _buildActionTile(
              icon: Icons.numbers_rounded,
              title: 'Port de connexion entrante',
              value: prefs['listen_port']?.toString() ?? 'Default',
              onTap: () => _showNumberEditDialog(
                title: 'Port de connexion entrante',
                prefKey: 'listen_port',
                initialValue: _getInt(prefs['listen_port'], defaultValue: 6881),
              ),
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              icon: Icons.router_outlined,
              title: 'Utiliser UPnP / NAT-PMP',
              subtitle: 'Ouvrir automatiquement le port via le routeur',
              value: _getBool(prefs['upnp'], defaultValue: true),
              onChanged: (bool val) => _updatePref('upnp', val),
            ),
          ],
        ),
        const SizedBox(height: Insets.md),
        _buildSectionHeader('Connection Limits'),
        _buildCard(
          children: <Widget>[
            _buildActionTile(
              icon: Icons.hub_outlined,
              title: 'Connexions maximales globales',
              value: prefs['max_connec']?.toString() ?? '500',
              onTap: () => _showNumberEditDialog(
                title: 'Connexions maximales globales',
                prefKey: 'max_connec',
                initialValue: _getInt(prefs['max_connec'], defaultValue: 500),
              ),
            ),
            const Divider(height: 1),
            _buildActionTile(
              icon: Icons.cable_rounded,
              title: 'Connexions maximales par torrent',
              value: prefs['max_connec_per_torrent']?.toString() ?? '100',
              onTap: () => _showNumberEditDialog(
                title: 'Connexions maximales par torrent',
                prefKey: 'max_connec_per_torrent',
                initialValue:
                    _getInt(prefs['max_connec_per_torrent'], defaultValue: 100),
              ),
            ),
            const Divider(height: 1),
            _buildActionTile(
              icon: Icons.upload_file_outlined,
              title: "Emplacements d'envoi maximaux globaux",
              value: prefs['max_uploads']?.toString() ?? '4',
              onTap: () => _showNumberEditDialog(
                title: "Emplacements d'envoi maximaux globaux",
                prefKey: 'max_uploads',
                initialValue: _getInt(prefs['max_uploads'], defaultValue: 4),
              ),
            ),
            const Divider(height: 1),
            _buildActionTile(
              icon: Icons.file_upload_outlined,
              title: "Emplacements d'envoi par torrent",
              value: prefs['max_uploads_per_torrent']?.toString() ?? '4',
              onTap: () => _showNumberEditDialog(
                title: "Emplacements d'envoi par torrent",
                prefKey: 'max_uploads_per_torrent',
                initialValue:
                    _getInt(prefs['max_uploads_per_torrent'], defaultValue: 4),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // 4. SPEED TAB
  // ==========================================
  Widget _buildSpeedTab() {
    final Instance instance = widget.instance;
    final Map<String, dynamic> prefs =
        ref.watch(qbitPreferencesProvider(instance)).value ??
            <String, dynamic>{};
    final bool altSpeedMode =
        ref.watch(qbitAltSpeedModeProvider(instance)).value ?? false;

    return _buildTabListView(
      children: <Widget>[
        _buildSectionHeader('Global Rate Limits'),
        _buildCard(
          children: <Widget>[
            _buildActionTile(
              icon: Icons.arrow_downward_rounded,
              title: 'Limite de téléchargement globale',
              value: _formatLimit(prefs['dl_limit']),
              onTap: () => _showNumberEditDialog(
                title: 'Limite de téléchargement globale (octets/s)',
                prefKey: 'dl_limit',
                initialValue: _getInt(prefs['dl_limit']),
                helperText: 'Entrez 0 pour illimité',
              ),
            ),
            const Divider(height: 1),
            _buildActionTile(
              icon: Icons.arrow_upward_rounded,
              title: "Limite d'envoi globale",
              value: _formatLimit(prefs['up_limit']),
              onTap: () => _showNumberEditDialog(
                title: "Limite d'envoi globale (octets/s)",
                prefKey: 'up_limit',
                initialValue: _getInt(prefs['up_limit']),
                helperText: 'Entrez 0 pour illimité',
              ),
            ),
          ],
        ),
        const SizedBox(height: Insets.md),
        _buildSectionHeader('Alternative Rate Limits'),
        _buildCard(
          children: <Widget>[
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: Insets.md,
                vertical: Insets.xs,
              ),
              secondary: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.speed_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              title: const Text('Limites de débit alternatives actives'),
              subtitle: const Text('Basculer le mode de limitation secondaire'),
              value: altSpeedMode,
              onChanged: (bool val) async {
                final QbittorrentClient client = await ref.read(
                  qbittorrentClientProvider(instance).future,
                );
                await client.toggleAltSpeedLimits();
                ref.invalidate(qbitAltSpeedModeProvider(instance));
              },
            ),
            const Divider(height: 1),
            _buildActionTile(
              icon: Icons.slow_motion_video_rounded,
              title: 'Limite de téléchargement alternative',
              value: _formatLimit(prefs['alt_dl_limit']),
              onTap: () => _showNumberEditDialog(
                title: 'Limite de téléchargement alternative (octets/s)',
                prefKey: 'alt_dl_limit',
                initialValue: _getInt(prefs['alt_dl_limit']),
                helperText: 'Entrez 0 pour illimité',
              ),
            ),
            const Divider(height: 1),
            _buildActionTile(
              icon: Icons.slow_motion_video_rounded,
              title: "Limite d'envoi alternative",
              value: _formatLimit(prefs['alt_up_limit']),
              onTap: () => _showNumberEditDialog(
                title: "Limite d'envoi alternative (octets/s)",
                prefKey: 'alt_up_limit',
                initialValue: _getInt(prefs['alt_up_limit']),
                helperText: 'Entrez 0 pour illimité',
              ),
            ),
          ],
        ),
        const SizedBox(height: Insets.md),
        _buildSectionHeader('Rate Limit Scope'),
        _buildCard(
          children: <Widget>[
            _buildSwitchTile(
              icon: Icons.compare_arrows_rounded,
              title: 'Appliquer au protocole μTP',
              subtitle: 'Appliquer les limites de débit aux connexions μTP',
              value: _getBool(prefs['limit_utp_rate'], defaultValue: true),
              onChanged: (bool val) => _updatePref('limit_utp_rate', val),
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              icon: Icons.network_check_rounded,
              title: 'Appliquer aux frais de transport',
              subtitle: 'Compter les frais TCP/IP dans les limites de vitesse',
              value: _getBool(prefs['limit_tcp_overhead']),
              onChanged: (bool val) => _updatePref('limit_tcp_overhead', val),
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              icon: Icons.lan_outlined,
              title: 'Appliquer aux pairs du LAN',
              subtitle: 'Appliquer les limites de débit aux pairs du réseau local',
              value: _getBool(prefs['limit_lan_peers']),
              onChanged: (bool val) => _updatePref('limit_lan_peers', val),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // 5. BITTORRENT TAB
  // ==========================================
  Widget _buildBitTorrentTab() {
    final Instance instance = widget.instance;
    final Map<String, dynamic> prefs =
        ref.watch(qbitPreferencesProvider(instance)).value ??
            <String, dynamic>{};

    return _buildTabListView(
      children: <Widget>[
        _buildSectionHeader('Privacy & Discovery'),
        _buildCard(
          children: <Widget>[
            _buildSwitchTile(
              icon: Icons.share_location_rounded,
              title: 'Activer DHT (table de hachage distribuée)',
              subtitle: 'Trouver plus de pairs sans tracker',
              value: _getBool(prefs['dht'], defaultValue: true),
              onChanged: (bool val) => _updatePref('dht', val),
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              icon: Icons.sync_alt_rounded,
              title: 'Activer PeX (échange de pairs)',
              subtitle: 'Échanger les listes de pairs entre essaims connectés',
              value: _getBool(prefs['pex'], defaultValue: true),
              onChanged: (bool val) => _updatePref('pex', val),
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              icon: Icons.radar_rounded,
              title: 'Activer la découverte locale de pairs (LSD)',
              subtitle: 'Découvrir les pairs sur le réseau local',
              value: _getBool(prefs['lsd'], defaultValue: true),
              onChanged: (bool val) => _updatePref('lsd', val),
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              icon: Icons.security_rounded,
              title: 'Mode anonyme',
              subtitle: "Masquer l'user-agent et l'empreinte du client",
              value: _getBool(prefs['anonymous_mode']),
              onChanged: (bool val) => _updatePref('anonymous_mode', val),
            ),
          ],
        ),
        const SizedBox(height: Insets.md),
        _buildSectionHeader('Torrent Queueing'),
        _buildCard(
          children: <Widget>[
            _buildSwitchTile(
              icon: Icons.queue_play_next_rounded,
              title: "File d'attente des torrents",
              subtitle: 'Appliquer des limites aux téléchargements/envois actifs',
              value: _getBool(prefs['queueing_enabled'], defaultValue: true),
              onChanged: (bool val) => _updatePref('queueing_enabled', val),
            ),
            const Divider(height: 1),
            _buildActionTile(
              icon: Icons.downloading_rounded,
              title: 'Téléchargements actifs maximaux',
              value: prefs['max_active_downloads']?.toString() ?? 'Unlimited',
              onTap: () => _showNumberEditDialog(
                title: 'Téléchargements actifs maximaux',
                prefKey: 'max_active_downloads',
                initialValue:
                    _getInt(prefs['max_active_downloads'], defaultValue: 3),
              ),
            ),
            const Divider(height: 1),
            _buildActionTile(
              icon: Icons.cloud_upload_outlined,
              title: 'Envois actifs maximaux',
              value: prefs['max_active_uploads']?.toString() ?? 'Unlimited',
              onTap: () => _showNumberEditDialog(
                title: 'Envois actifs maximaux',
                prefKey: 'max_active_uploads',
                initialValue:
                    _getInt(prefs['max_active_uploads'], defaultValue: 3),
              ),
            ),
            const Divider(height: 1),
            _buildActionTile(
              icon: Icons.compare_arrows_rounded,
              title: 'Torrents actifs maximaux',
              value: prefs['max_active_torrents']?.toString() ?? 'Unlimited',
              onTap: () => _showNumberEditDialog(
                title: 'Torrents actifs maximaux',
                prefKey: 'max_active_torrents',
                initialValue:
                    _getInt(prefs['max_active_torrents'], defaultValue: 5),
              ),
            ),
          ],
        ),
        const SizedBox(height: Insets.md),
        _buildSectionHeader('Seeding Limits'),
        _buildCard(
          children: <Widget>[
            _buildSwitchTile(
              icon: Icons.pie_chart_outline_rounded,
              title: 'Limite de ratio de partage',
              subtitle: prefs['max_ratio'] != null
                  ? 'Limit: ${(prefs['max_ratio'] as num).toStringAsFixed(2)}'
                  : 'Disabled',
              value: _getBool(prefs['max_ratio_enabled']),
              onChanged: (bool val) => _updatePref('max_ratio_enabled', val),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // 6. RSS TAB
  // ==========================================
  Widget _buildRssTab() {
    final Instance instance = widget.instance;
    final Map<String, dynamic> prefs =
        ref.watch(qbitPreferencesProvider(instance)).value ??
            <String, dynamic>{};

    return _buildTabListView(
      children: <Widget>[
        _buildSectionHeader('RSS Processing & Reader'),
        _buildCard(
          children: <Widget>[
            _buildSwitchTile(
              icon: Icons.rss_feed_rounded,
              title: 'Activer le traitement RSS',
              subtitle: 'Récupérer et mettre à jour les flux RSS',
              value: _getBool(
                prefs['rss_processing_enabled'],
                defaultValue: true,
              ),
              onChanged: (bool val) =>
                  _updatePref('rss_processing_enabled', val),
            ),
            const Divider(height: 1),
            _buildActionTile(
              icon: Icons.timer_outlined,
              title: "Intervalle d'actualisation des flux",
              value: '${prefs['rss_refresh_interval'] ?? 30} minutes',
              onTap: () => _showNumberEditDialog(
                title: "Intervalle d'actualisation des flux (minutes)",
                prefKey: 'rss_refresh_interval',
                initialValue:
                    _getInt(prefs['rss_refresh_interval'], defaultValue: 30),
              ),
            ),
            const Divider(height: 1),
            _buildActionTile(
              icon: Icons.article_outlined,
              title: 'Articles max. par flux',
              value: prefs['rss_max_articles_per_feed']?.toString() ?? '50',
              onTap: () => _showNumberEditDialog(
                title: 'Articles max. par flux',
                prefKey: 'rss_max_articles_per_feed',
                initialValue: _getInt(
                  prefs['rss_max_articles_per_feed'],
                  defaultValue: 50,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: Insets.md),
        _buildSectionHeader('Auto-Downloader'),
        _buildCard(
          children: <Widget>[
            _buildSwitchTile(
              icon: Icons.auto_awesome_rounded,
              title: 'Activer le téléchargement automatique RSS',
              subtitle: 'Télécharger automatiquement les règles de torrents correspondantes',
              value: _getBool(prefs['rss_auto_downloading_enabled']),
              onChanged: (bool val) =>
                  _updatePref('rss_auto_downloading_enabled', val),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // 7. WEBUI TAB
  // ==========================================
  Widget _buildWebUiTab() {
    final Instance instance = widget.instance;
    final Map<String, dynamic> prefs =
        ref.watch(qbitPreferencesProvider(instance)).value ??
            <String, dynamic>{};

    return _buildTabListView(
      children: <Widget>[
        _buildSectionHeader('Web User Interface'),
        _buildCard(
          children: <Widget>[
            _buildActionTile(
              icon: Icons.lan_rounded,
              title: "Adresse IP de l'interface web",
              value: prefs['web_ui_address']?.toString() ?? '*',
              onTap: () => _showStringEditDialog(
                title: "Adresse IP de l'interface web (* pour toutes)",
                prefKey: 'web_ui_address',
                initialValue: prefs['web_ui_address']?.toString() ?? '*',
              ),
            ),
            const Divider(height: 1),
            _buildActionTile(
              icon: Icons.numbers_rounded,
              title: "Port de l'interface web",
              value: prefs['web_ui_port']?.toString() ?? '8080',
              onTap: () => _showNumberEditDialog(
                title: "Port de l'interface web",
                prefKey: 'web_ui_port',
                initialValue: _getInt(prefs['web_ui_port'], defaultValue: 8080),
              ),
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              icon: Icons.router_rounded,
              title: "Utiliser UPnP pour le port de l'interface web",
              subtitle: "Mapper automatiquement le port de l'interface web sur le routeur",
              value: _getBool(prefs['web_ui_upnp']),
              onChanged: (bool val) => _updatePref('web_ui_upnp', val),
            ),
          ],
        ),
        const SizedBox(height: Insets.md),
        _buildSectionHeader('Security & Session'),
        _buildCard(
          children: <Widget>[
            _buildSwitchTile(
              icon: Icons.lock_outline_rounded,
              title: 'Utiliser HTTPS',
              subtitle: "Chiffrer les connexions de l'interface web avec SSL/TLS",
              value: _getBool(prefs['web_ui_use_https']),
              onChanged: (bool val) => _updatePref('web_ui_use_https', val),
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              icon: Icons.security_rounded,
              title: 'Protection CSRF',
              subtitle: 'Prévenir les attaques de falsification de requête intersite',
              value: _getBool(
                prefs['web_ui_csrf_protection_enabled'],
                defaultValue: true,
              ),
              onChanged: (bool val) =>
                  _updatePref('web_ui_csrf_protection_enabled', val),
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              icon: Icons.shield_outlined,
              title: 'Protection anti-clickjacking',
              subtitle: "Empêcher l'encadrement dans des pages web externes",
              value: _getBool(
                prefs['web_ui_clickjacking_protection_enabled'],
                defaultValue: true,
              ),
              onChanged: (bool val) =>
                  _updatePref('web_ui_clickjacking_protection_enabled', val),
            ),
            const Divider(height: 1),
            _buildActionTile(
              icon: Icons.timer_outlined,
              title: "Délai d'expiration de session",
              value: '${prefs['web_ui_session_timeout'] ?? 3600} seconds',
              onTap: () => _showNumberEditDialog(
                title: "Délai d'expiration de session (secondes)",
                prefKey: 'web_ui_session_timeout',
                initialValue: _getInt(
                  prefs['web_ui_session_timeout'],
                  defaultValue: 3600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // 8. ADVANCED TAB
  // ==========================================
  Widget _buildAdvancedTab() {
    final Instance instance = widget.instance;
    final Map<String, dynamic> prefs =
        ref.watch(qbitPreferencesProvider(instance)).value ??
            <String, dynamic>{};

    final AsyncValue<List<Map<String, String>>> ifacesAsync =
        ref.watch(qbitNetworkInterfacesProvider(instance));
    final String currentIface =
        prefs['current_network_interface']?.toString() ?? '';
    final AsyncValue<List<String>> addrsAsync = ref.watch(
      qbitNetworkInterfaceAddressesProvider((instance, currentIface)),
    );

    final dynamic storageTypeVal = prefs['resume_data_storage_type'];
    final String storageTypeDisplay = switch (storageTypeVal?.toString()) {
      '1' || 'SQLite' || 'sqlite' => 'Base de données SQLite',
      _ => 'Fichiers fastresume',
    };

    final dynamic removeModeVal = prefs['torrent_content_remove_mode'] ??
        prefs['torrent_content_removing_mode'];
    final String removeModeDisplay = switch (removeModeVal?.toString()) {
      '1' || 'Trash' || 'trash' => 'Mettre à la corbeille (si possible)',
      _ => 'Supprimer définitivement les fichiers',
    };

    return _buildTabListView(
      children: <Widget>[
        // --- 1. qBittorrent Section (Exact from screenshot) ---
        _buildSectionHeader('qBittorrent Section'),
        _buildCard(
          children: <Widget>[
            // 1. Resume data storage type
            _buildActionTile(
              icon: Icons.storage_rounded,
              title: 'Type de stockage des données de reprise (redémarrage requis)',
              value: storageTypeDisplay,
              onTap: () => _showOptionsDialog<dynamic>(
                title: 'Type de stockage des données de reprise',
                prefKey: 'resume_data_storage_type',
                currentValue: storageTypeVal ?? 0,
                options: <({String label, dynamic value, String? subtitle})>[
                  (
                    label: 'Fichiers fastresume',
                    value: storageTypeVal is String ? 'Legacy' : 0,
                    subtitle: 'Anciens fichiers .fastresume dans le répertoire BT_backup',
                  ),
                  (
                    label: 'Base de données SQLite',
                    value: storageTypeVal is String ? 'SQLite' : 1,
                    subtitle: "Stocker tout l'état des torrents dans une seule base SQLite",
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // 2. Torrent content removing mode
            _buildActionTile(
              icon: Icons.delete_sweep_outlined,
              title: 'Mode de suppression du contenu des torrents',
              value: removeModeDisplay,
              onTap: () => _showOptionsDialog<dynamic>(
                title: 'Mode de suppression du contenu des torrents',
                prefKey: 'torrent_content_remove_mode',
                currentValue: removeModeVal ?? 0,
                options: <({String label, dynamic value, String? subtitle})>[
                  (
                    label: 'Supprimer définitivement les fichiers',
                    value: removeModeVal is String ? 'Delete' : 0,
                    subtitle: 'Effacer les données utiles directement du stockage',
                  ),
                  (
                    label: 'Mettre à la corbeille (si possible)',
                    value: removeModeVal is String ? 'Trash' : 1,
                    subtitle:
                        'Move removed files to the OS Recycle Bin / Trash',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // 3. Network interface
            _buildActionTile(
              icon: Icons.lan_outlined,
              title: 'Interface réseau',
              value: currentIface.isNotEmpty ? currentIface : 'Any interface',
              onTap: () {
                final List<Map<String, String>> ifaces =
                    ifacesAsync.value ?? <Map<String, String>>[];
                final List<({String label, String value, String? subtitle})>
                    options =
                    <({String label, String value, String? subtitle})>[
                  (
                    label: 'Toute interface',
                    value: '',
                    subtitle: 'Écouter et se lier sur toutes les interfaces réseau',
                  ),
                  ...ifaces.map((Map<String, String> iface) {
                    final String name = iface['name'] ?? '';
                    final String val = iface['value'] ?? name;
                    return (
                      label: name.isNotEmpty ? name : val,
                      value: val,
                      subtitle: "Se lier strictement à l'interface $val",
                    );
                  }),
                ];
                _showOptionsDialog<String>(
                  title: 'Interface réseau',
                  prefKey: 'current_network_interface',
                  currentValue: currentIface,
                  options: options,
                );
              },
            ),
            const Divider(height: 1),

            // 4. Optional IP address to bind to
            _buildActionTile(
              icon: Icons.pin_drop_outlined,
              title: 'Adresse IP facultative à laquelle se lier',
              value:
                  (prefs['current_interface_address']?.toString().isNotEmpty ==
                          true)
                      ? prefs['current_interface_address'].toString()
                      : 'All addresses',
              onTap: () {
                final List<String> addrs = addrsAsync.value ?? <String>[];
                final String currentAddr =
                    prefs['current_interface_address']?.toString() ?? '';
                final List<({String label, String value, String? subtitle})>
                    options =
                    <({String label, String value, String? subtitle})>[
                  (
                    label: 'Toutes les adresses',
                    value: '',
                    subtitle: 'Se lier à toutes les adresses IPv4 et IPv6',
                  ),
                  (
                    label: 'Toutes les adresses IPv4 (0.0.0.0)',
                    value: '0.0.0.0',
                    subtitle: 'Écouter sur toutes les interfaces IPv4 disponibles',
                  ),
                  (
                    label: 'Toutes les adresses IPv6 (::)',
                    value: '::',
                    subtitle: 'Écouter sur toutes les interfaces IPv6 disponibles',
                  ),
                  ...addrs.map(
                    (String addr) => (
                      label: addr,
                      value: addr,
                      subtitle: null,
                    ),
                  ),
                ];
                _showOptionsDialog<String>(
                  title: 'Adresse IP facultative à laquelle se lier',
                  prefKey: 'current_interface_address',
                  currentValue: currentAddr,
                  options: options,
                );
              },
            ),
            const Divider(height: 1),

            // 5. Save resume data interval
            _buildActionTile(
              icon: Icons.timer_outlined,
              title: "Intervalle d'enregistrement des données de reprise",
              value: '${prefs['save_resume_data_interval'] ?? 60} min',
              onTap: () => _showNumberEditDialog(
                title: "Intervalle d'enregistrement des données de reprise (min)",
                prefKey: 'save_resume_data_interval',
                initialValue: _getInt(
                  prefs['save_resume_data_interval'],
                  defaultValue: 60,
                ),
                helperText: "Intervalle en minutes entre les enregistrements périodiques de l'état",
              ),
            ),
            const Divider(height: 1),

            // 6. Save statistics interval
            _buildActionTile(
              icon: Icons.query_stats_rounded,
              title: "Intervalle d'enregistrement des statistiques",
              value: '${prefs['save_statistics_interval'] ?? 15} min',
              onTap: () => _showNumberEditDialog(
                title: "Intervalle d'enregistrement des statistiques (min)",
                prefKey: 'save_statistics_interval',
                initialValue: _getInt(
                  prefs['save_statistics_interval'],
                  defaultValue: 15,
                ),
                helperText: 'Intervalle en minutes entre les enregistrements des statistiques de session',
              ),
            ),
            const Divider(height: 1),

            // 7. .torrent file size limit
            _buildActionTile(
              icon: Icons.file_present_outlined,
              title: 'Limite de taille des fichiers .torrent',
              value: '${prefs['max_torrent_file_size'] ?? 100} MiB',
              onTap: () => _showNumberEditDialog(
                title: 'Limite de taille des fichiers .torrent (Mio)',
                prefKey: 'max_torrent_file_size',
                initialValue:
                    _getInt(prefs['max_torrent_file_size'], defaultValue: 100),
                helperText:
                    'Maximum allowed file size for added .torrent files',
              ),
            ),
            const Divider(height: 1),

            // 8. Confirm torrent recheck
            _buildSwitchTile(
              icon: Icons.refresh_rounded,
              title: 'Confirmer la revérification du torrent',
              subtitle: 'Afficher une invite de confirmation avant la revérification forcée',
              value: _getBool(
                prefs['confirm_torrent_recheck'],
                defaultValue: true,
              ),
              onChanged: (bool val) =>
                  _updatePref('confirm_torrent_recheck', val),
            ),
            const Divider(height: 1),

            // 9. Recheck torrents on completion
            _buildSwitchTile(
              icon: Icons.check_circle_outline_rounded,
              title: 'Revérifier les torrents à la fin',
              subtitle: "Vérifier l'intégrité des morceaux quand le téléchargement atteint 100 %",
              value: _getBool(prefs['recheck_completed_torrents']),
              onChanged: (bool val) =>
                  _updatePref('recheck_completed_torrents', val),
            ),
            const Divider(height: 1),

            // 10. Customize application instance name
            _buildActionTile(
              icon: Icons.badge_outlined,
              title: "Personnaliser le nom de l'instance de l'application",
              value: prefs['app_instance_name']?.toString().isNotEmpty == true
                  ? prefs['app_instance_name'].toString()
                  : '(Default)',
              onTap: () => _showStringEditDialog(
                title: "Personnaliser le nom de l'instance de l'application",
                prefKey: 'app_instance_name',
                initialValue: prefs['app_instance_name']?.toString() ?? '',
                hintText: "Nom d'instance personnalisé",
              ),
            ),
            const Divider(height: 1),

            // 11. Refresh interval
            _buildActionTile(
              icon: Icons.sync_rounded,
              title: "Intervalle d'actualisation",
              value: '${prefs['refresh_interval'] ?? 1500} ms',
              onTap: () => _showNumberEditDialog(
                title: "Intervalle d'actualisation (ms)",
                prefKey: 'refresh_interval',
                initialValue:
                    _getInt(prefs['refresh_interval'], defaultValue: 1500),
                helperText: "Intervalle d'actualisation par interrogation en millisecondes",
              ),
            ),
            const Divider(height: 1),

            // 12. Resolve peer host names
            _buildSwitchTile(
              icon: Icons.dns_outlined,
              title: "Résoudre les noms d'hôtes des pairs",
              subtitle: 'Faire une recherche DNS inverse sur les IP des pairs connectés',
              value: _getBool(prefs['resolve_peer_host_names']),
              onChanged: (bool val) =>
                  _updatePref('resolve_peer_host_names', val),
            ),
            const Divider(height: 1),

            // 13. Resolve peer countries
            _buildSwitchTile(
              icon: Icons.flag_outlined,
              title: 'Résoudre les pays des pairs',
              subtitle: 'Afficher les drapeaux des pays pour la géolocalisation des IP des pairs',
              value: _getBool(
                prefs['resolve_peer_countries'],
                defaultValue: true,
              ),
              onChanged: (bool val) =>
                  _updatePref('resolve_peer_countries', val),
            ),
            const Divider(height: 1),

            // 14. Reannounce to all trackers when IP or port changed
            _buildSwitchTile(
              icon: Icons.podcasts_rounded,
              title: "Ré-annoncer à tous les trackers quand l'IP ou le port change",
              subtitle: 'Déclencher une mise à jour immédiate du tracker en cas de changement réseau',
              value: _getBool(prefs['reannounce_when_address_changed']),
              onChanged: (bool val) =>
                  _updatePref('reannounce_when_address_changed', val),
            ),
            const Divider(height: 1),

            // 15. Enable embedded tracker
            _buildSwitchTile(
              icon: Icons.hub_rounded,
              title: 'Activer le tracker intégré',
              subtitle: 'Exécuter le tracker intégré sur ce nœud qBittorrent',
              value: _getBool(prefs['enable_embedded_tracker']),
              onChanged: (bool val) =>
                  _updatePref('enable_embedded_tracker', val),
            ),
            if (_getBool(prefs['enable_embedded_tracker'])) ...<Widget>[
              const Divider(height: 1),
              // 16. Embedded tracker port
              _buildActionTile(
                icon: Icons.numbers_rounded,
                title: 'Port du tracker intégré',
                value: '${prefs['embedded_tracker_port'] ?? 9000}',
                onTap: () => _showNumberEditDialog(
                  title: 'Port du tracker intégré',
                  prefKey: 'embedded_tracker_port',
                  initialValue: _getInt(
                    prefs['embedded_tracker_port'],
                    defaultValue: 9000,
                  ),
                ),
              ),
              const Divider(height: 1),
              // 17. Enable port forwarding for embedded tracker
              _buildSwitchTile(
                icon: Icons.router_outlined,
                title: "Activer l'ouverture de port pour le tracker intégré",
                subtitle: 'Utiliser UPnP/NAT-PMP pour ouvrir le port du tracker',
                value: _getBool(prefs['embedded_tracker_port_forwarding']),
                onChanged: (bool val) =>
                    _updatePref('embedded_tracker_port_forwarding', val),
              ),
            ],
            const Divider(height: 1),

            // 18. Ignore SSL errors
            _buildSwitchTile(
              icon: Icons.gpp_maybe_outlined,
              title: 'Ignorer les erreurs SSL',
              subtitle:
                  'Ignore HTTPS certification validation errors on trackers & RSS',
              value: _getBool(prefs['ignore_ssl_errors']),
              onChanged: (bool val) => _updatePref('ignore_ssl_errors', val),
            ),
            const Divider(height: 1),

            // 19. Python executable path (may require restart)
            _buildActionTile(
              icon: Icons.terminal_rounded,
              title: "Chemin de l'exécutable Python (redémarrage peut être requis)",
              value:
                  prefs['python_executable_path']?.toString().isNotEmpty == true
                      ? prefs['python_executable_path'].toString()
                      : '(Détection automatique si vide)',
              onTap: () => _showStringEditDialog(
                title: "Chemin de l'exécutable Python",
                prefKey: 'python_executable_path',
                initialValue: prefs['python_executable_path']?.toString() ?? '',
                hintText: '(Détection automatique si vide)',
              ),
            ),
          ],
        ),
        const SizedBox(height: Insets.md),

        // --- 2. libtorrent Engine Tuning ---
        _buildSectionHeader('libtorrent & Engine Tuning'),
        _buildCard(
          children: <Widget>[
            _buildActionTile(
              icon: Icons.memory_rounded,
              title: "Cache d'écriture disque (Mio)",
              value: prefs['disk_cache']?.toString() ?? 'Auto',
              onTap: () => _showNumberEditDialog(
                title: "Cache d'écriture disque (Mio, -1 pour auto)",
                prefKey: 'disk_cache',
                initialValue: _getInt(prefs['disk_cache'], defaultValue: -1),
              ),
            ),
            const Divider(height: 1),
            _buildActionTile(
              icon: Icons.timer_outlined,
              title: 'Expiration du cache disque (TTL)',
              value: '${prefs['disk_cache_ttl'] ?? 60} seconds',
              onTap: () => _showNumberEditDialog(
                title: 'Expiration du cache disque (secondes)',
                prefKey: 'disk_cache_ttl',
                initialValue:
                    _getInt(prefs['disk_cache_ttl'], defaultValue: 60),
              ),
            ),
            const Divider(height: 1),
            _buildActionTile(
              icon: Icons.alt_route_rounded,
              title: "Threads d'E/S asynchrones",
              value: prefs['async_io_threads']?.toString() ?? '4',
              onTap: () => _showNumberEditDialog(
                title: "Threads d'E/S asynchrones",
                prefKey: 'async_io_threads',
                initialValue:
                    _getInt(prefs['async_io_threads'], defaultValue: 4),
              ),
            ),
            const Divider(height: 1),
            _buildActionTile(
              icon: Icons.speed_rounded,
              title: 'Limite de mémoire de travail (Mio)',
              value: prefs['memory_working_set_limit']?.toString() ??
                  '0 (Unlimited)',
              onTap: () => _showNumberEditDialog(
                title: 'Limite de mémoire de travail (Mio, 0 pour illimité)',
                prefKey: 'memory_working_set_limit',
                initialValue: _getInt(prefs['memory_working_set_limit']),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // SHARED BUILDER HELPERS
  // ==========================================
  Widget _buildTabListView({required List<Widget> children}) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Insets.md,
        Insets.sm,
        Insets.md,
        80,
      ),
      children: children,
    );
  }

  Widget _buildSectionHeader(String title) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Insets.xs,
        Insets.sm,
        Insets.xs,
        Insets.xs,
      ),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: cs.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: cs.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style:
            theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      trailing: Text(
        value,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// A public address qBittorrent reports, with the value under the title
  /// rather than beside it, since an IPv6 address is too long to sit beside
  /// it. Tapping copies it.
  Widget _buildAddressTile({required String title, required String address}) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final bool known = address.isNotEmpty;
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: cs.secondary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.public_rounded, color: cs.secondary, size: 20),
      ),
      title: Text(
        title,
        style:
            theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      // qBittorrent learns the address from peers and trackers, so a server
      // that has only just started has none to report yet.
      subtitle: Text(
        known ? address : 'Pas encore connu',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: known
          ? Icon(Icons.copy_rounded, size: 20, color: cs.onSurfaceVariant)
          : null,
      onTap: known ? () => _copyAddress(title, address) : null,
    );
  }

  Future<void> _copyAddress(String title, String address) async {
    String message = '$title copié';
    try {
      await Clipboard.setData(ClipboardData(text: address));
    } on PlatformException {
      message = 'Impossible de copier dans le presse-papiers';
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Insets.md,
        vertical: Insets.xs,
      ),
      secondary: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: cs.primary, size: 20),
      ),
      title: Text(
        title,
        style:
            theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
      ),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: cs.primary, size: 20),
      ),
      title: Text(
        title,
        style:
            theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        value,
        style: theme.textTheme.bodySmall?.copyWith(
          color: cs.primary,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
    );
  }

  String _formatLimit(dynamic limit) {
    if (limit == null) return 'Unlimited';
    final int bytes = int.tryParse(limit.toString()) ?? 0;
    if (bytes <= 0) return 'Unlimited';
    return '${fmtBytes(bytes)}/s';
  }
}
