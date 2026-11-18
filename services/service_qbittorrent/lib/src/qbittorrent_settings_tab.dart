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
  static final Map<String, String> _riskyPrefs = <String, String>{
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
        S.t('clickjackingProtectionStopsTheWebUIBeingEmbeddedInAnother') +
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
        title: Text(S.t('changeThisSetting')),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(S.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(S.t('changeIt')),
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
          SnackBar(
            content: Text(S.t('settingSaved')),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.t('failedToUpdateSettingE1', [e]))),
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
            child: Text(S.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(S.t('save')),
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
            child: Text(S.t('cancel')),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(ctx, int.tryParse(controller.text.trim())),
            child: Text(S.t('save')),
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
                title: Text(S.t('instanceNameSettings1', [instance.name])),
                actions: <Widget>[
                  IconButton(
                    tooltip: S.t('refresh'),
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
                  tabs: <Widget>[
                    Tab(text: S.t('system')),
                    Tab(text: S.t('behavior')),
                    Tab(text: S.t('downloads')),
                    Tab(text: S.t('connection')),
                    Tab(text: S.t('speed')),
                    Tab(text: 'BitTorrent'),
                    Tab(text: 'RSS'),
                    Tab(text: S.t('webui')),
                    Tab(text: S.t('advanced')),
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
              title: S.t('qbittorrentVersion'),
              value: appVersion.value ?? S.t('loading'),
              color: Theme.of(context).colorScheme.primary,
            ),
            const Divider(height: 1),
            _buildInfoTile(
              icon: Icons.api_rounded,
              title: S.t('webAPIVersion'),
              value: apiVersion.value ?? S.t('loading'),
              color: Theme.of(context).colorScheme.secondary,
            ),
            const Divider(height: 1),
            _buildInfoTile(
              icon: Icons.wifi_tethering_rounded,
              title: S.t('connectionStatus'),
              value: transfer?.connectionStatus.toUpperCase() ?? 'CONNECTED',
              color: transfer?.connectionStatus == 'disconnected'
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary,
            ),
            if (reportsAddresses) ...<Widget>[
              const Divider(height: 1),
              _buildAddressTile(
                title: S.t('externalIPv4'),
                address: addresses.v4 ?? '',
              ),
              // Most connections have no IPv6 address at all, so an empty
              // one is left out rather than shown as unknown.
              if ((addresses.v6 ?? '').isNotEmpty) ...<Widget>[
                const Divider(height: 1),
                _buildAddressTile(
                  title: S.t('externalIPv6'),
                  address: addresses.v6!,
                ),
              ],
            ],
            const Divider(height: 1),
            _buildInfoTile(
              icon: Icons.link_rounded,
              title: S.t('instanceAddress'),
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
              title: S.t('currentDownloadSpeed'),
              value: '${fmtBytes(transfer?.dlSpeed ?? 0)}/s',
              color: Theme.of(context).colorScheme.primary,
            ),
            const Divider(height: 1),
            _buildInfoTile(
              icon: Icons.arrow_upward_rounded,
              title: S.t('currentUploadSpeed'),
              value: '${fmtBytes(transfer?.upSpeed ?? 0)}/s',
              color: Theme.of(context).colorScheme.secondary,
            ),
            const Divider(height: 1),
            _buildInfoTile(
              icon: Icons.file_download_done_rounded,
              title: S.t('sessionDownloaded'),
              value: fmtBytes(transfer?.dlData ?? 0),
              color: Theme.of(context).colorScheme.primary,
            ),
            const Divider(height: 1),
            _buildInfoTile(
              icon: Icons.file_upload_outlined,
              title: S.t('sessionUploaded'),
              value: fmtBytes(transfer?.upData ?? 0),
              color: Theme.of(context).colorScheme.secondary,
            ),
            const Divider(height: 1),
            _buildInfoTile(
              icon: Icons.pie_chart_outline_rounded,
              title: S.t('sessionShareRatio'),
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
              title: S.t('uiLocale'),
              value: prefs['locale']?.toString() ?? 'en',
              onTap: () => _showStringEditDialog(
                title: S.t('uiLocaleEGEnFrDeEs'),
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
              title: S.t('confirmTorrentDeletion'),
              subtitle: S.t('showConfirmationDialogBeforeDeletingTorrents'),
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
              title: S.t('confirmTorrentRecheck'),
              subtitle: S.t('showConfirmationDialogBeforeForceRechecking'),
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
              title: S.t('inhibitSystemSleep'),
              subtitle: S.t('preventSystemStandbyWhileTorrentsAreActive'),
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
              title: S.t('defaultSavePath'),
              value: prefs['save_path']?.toString() ?? S.t('default'),
              onTap: () => _showStringEditDialog(
                title: S.t('defaultSavePath'),
                prefKey: 'save_path',
                initialValue: prefs['save_path']?.toString() ?? '',
              ),
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              icon: Icons.folder_copy_outlined,
              title: S.t('keepIncompleteTorrentsInTempPath'),
              subtitle: prefs['temp_path']?.toString() ?? S.t('disabled'),
              value: _getBool(prefs['temp_path_enabled']),
              onChanged: (bool val) => _updatePref('temp_path_enabled', val),
            ),
            if (_getBool(prefs['temp_path_enabled'])) ...<Widget>[
              const Divider(height: 1),
              _buildActionTile(
                icon: Icons.edit_location_alt_outlined,
                title: S.t('incompleteFilesPath'),
                value: prefs['temp_path']?.toString() ?? '',
                onTap: () => _showStringEditDialog(
                  title: S.t('incompleteFilesPath'),
                  prefKey: 'temp_path',
                  initialValue: prefs['temp_path']?.toString() ?? '',
                ),
              ),
            ],
            const Divider(height: 1),
            _buildActionTile(
              icon: Icons.file_download_outlined,
              title: S.t('copyTorrentFilesTo'),
              value: prefs['export_dir']?.toString().isNotEmpty == true
                  ? prefs['export_dir'].toString()
                  : 'None',
              onTap: () => _showStringEditDialog(
                title: S.t('copyTorrentFilesTo'),
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
              title: S.t('appendQBExtension'),
              subtitle: S.t('appendExtensionToIncompleteFiles'),
              value: _getBool(prefs['incomplete_files_ext']),
              onChanged: (bool val) => _updatePref('incomplete_files_ext', val),
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              icon: Icons.storage_rounded,
              title: S.t('preAllocateDiskSpace'),
              subtitle: S.t('preAllocateStorageForAllFilesOnAdd'),
              value: _getBool(prefs['preallocate_all']),
              onChanged: (bool val) => _updatePref('preallocate_all', val),
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              icon: Icons.auto_mode_rounded,
              title: S.t('automaticTorrentManagement'),
              subtitle: S.t('relocateTorrentsWhenCategoryPathsChange'),
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
              title: S.t('incomingConnectionPort'),
              value: prefs['listen_port']?.toString() ?? S.t('default'),
              onTap: () => _showNumberEditDialog(
                title: S.t('incomingConnectionPort'),
                prefKey: 'listen_port',
                initialValue: _getInt(prefs['listen_port'], defaultValue: 6881),
              ),
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              icon: Icons.router_outlined,
              title: S.t('useUPnPNATPMP'),
              subtitle: S.t('forwardPortAutomaticallyViaRouter'),
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
              title: S.t('globalMaximumConnections'),
              value: prefs['max_connec']?.toString() ?? '500',
              onTap: () => _showNumberEditDialog(
                title: S.t('globalMaximumConnections'),
                prefKey: 'max_connec',
                initialValue: _getInt(prefs['max_connec'], defaultValue: 500),
              ),
            ),
            const Divider(height: 1),
            _buildActionTile(
              icon: Icons.cable_rounded,
              title: S.t('maximumConnectionsPerTorrent'),
              value: prefs['max_connec_per_torrent']?.toString() ?? '100',
              onTap: () => _showNumberEditDialog(
                title: S.t('maximumConnectionsPerTorrent'),
                prefKey: 'max_connec_per_torrent',
                initialValue:
                    _getInt(prefs['max_connec_per_torrent'], defaultValue: 100),
              ),
            ),
            const Divider(height: 1),
            _buildActionTile(
              icon: Icons.upload_file_outlined,
              title: S.t('globalMaximumUploadSlots'),
              value: prefs['max_uploads']?.toString() ?? '4',
              onTap: () => _showNumberEditDialog(
                title: S.t('globalMaximumUploadSlots'),
                prefKey: 'max_uploads',
                initialValue: _getInt(prefs['max_uploads'], defaultValue: 4),
              ),
            ),
            const Divider(height: 1),
            _buildActionTile(
              icon: Icons.file_upload_outlined,
              title: S.t('uploadSlotsPerTorrent'),
              value: prefs['max_uploads_per_torrent']?.toString() ?? '4',
              onTap: () => _showNumberEditDialog(
                title: S.t('uploadSlotsPerTorrent'),
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
              title: S.t('globalDownloadLimit'),
              value: _formatLimit(prefs['dl_limit']),
              onTap: () => _showNumberEditDialog(
                title: S.t('globalDownloadLimitBytesS'),
                prefKey: 'dl_limit',
                initialValue: _getInt(prefs['dl_limit']),
                helperText: S.t('enter0ForUnlimited'),
              ),
            ),
            const Divider(height: 1),
            _buildActionTile(
              icon: Icons.arrow_upward_rounded,
              title: S.t('globalUploadLimit'),
              value: _formatLimit(prefs['up_limit']),
              onTap: () => _showNumberEditDialog(
                title: S.t('globalUploadLimitBytesS'),
                prefKey: 'up_limit',
                initialValue: _getInt(prefs['up_limit']),
                helperText: S.t('enter0ForUnlimited'),
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
              title: Text(S.t('alternativeRateLimitsActive')),
              subtitle: Text(S.t('toggleSecondaryThrottleMode')),
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
              title: S.t('altDownloadLimit'),
              value: _formatLimit(prefs['alt_dl_limit']),
              onTap: () => _showNumberEditDialog(
                title: S.t('altDownloadLimitBytesS'),
                prefKey: 'alt_dl_limit',
                initialValue: _getInt(prefs['alt_dl_limit']),
                helperText: S.t('enter0ForUnlimited'),
              ),
            ),
            const Divider(height: 1),
            _buildActionTile(
              icon: Icons.slow_motion_video_rounded,
              title: S.t('altUploadLimit'),
              value: _formatLimit(prefs['alt_up_limit']),
              onTap: () => _showNumberEditDialog(
                title: S.t('altUploadLimitBytesS'),
                prefKey: 'alt_up_limit',
                initialValue: _getInt(prefs['alt_up_limit']),
                helperText: S.t('enter0ForUnlimited'),
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
              title: S.t('applyToTPProtocol'),
              subtitle: S.t('enforceRateLimitsOnTPConnections'),
              value: _getBool(prefs['limit_utp_rate'], defaultValue: true),
              onChanged: (bool val) => _updatePref('limit_utp_rate', val),
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              icon: Icons.network_check_rounded,
              title: S.t('applyToTransportOverhead'),
              subtitle: S.t('countTCPIPTransportOverheadInSpeedLimits'),
              value: _getBool(prefs['limit_tcp_overhead']),
              onChanged: (bool val) => _updatePref('limit_tcp_overhead', val),
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              icon: Icons.lan_outlined,
              title: S.t('applyToPeersOnLAN'),
              subtitle: S.t('enforceRateLimitsOnLocalNetworkPeers'),
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
              title: S.t('enableDHTDistributedHashTable'),
              subtitle: S.t('findMorePeersWithoutTrackers'),
              value: _getBool(prefs['dht'], defaultValue: true),
              onChanged: (bool val) => _updatePref('dht', val),
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              icon: Icons.sync_alt_rounded,
              title: S.t('enablePeXPeerExchange'),
              subtitle: S.t('exchangePeerListsBetweenConnectedSwarms'),
              value: _getBool(prefs['pex'], defaultValue: true),
              onChanged: (bool val) => _updatePref('pex', val),
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              icon: Icons.radar_rounded,
              title: S.t('enableLocalPeerDiscoveryLSD'),
              subtitle: S.t('discoverPeersOnLocalLANNetwork'),
              value: _getBool(prefs['lsd'], defaultValue: true),
              onChanged: (bool val) => _updatePref('lsd', val),
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              icon: Icons.security_rounded,
              title: S.t('anonymousMode'),
              subtitle: S.t('hideUserAgentAndClientFingerprint'),
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
              title: S.t('torrentQueueing'),
              subtitle: S.t('enforceLimitsOnActiveDownloadsUploads'),
              value: _getBool(prefs['queueing_enabled'], defaultValue: true),
              onChanged: (bool val) => _updatePref('queueing_enabled', val),
            ),
            const Divider(height: 1),
            _buildActionTile(
              icon: Icons.downloading_rounded,
              title: S.t('maximumActiveDownloads'),
              value: prefs['max_active_downloads']?.toString() ?? S.t('unlimited'),
              onTap: () => _showNumberEditDialog(
                title: S.t('maximumActiveDownloads'),
                prefKey: 'max_active_downloads',
                initialValue:
                    _getInt(prefs['max_active_downloads'], defaultValue: 3),
              ),
            ),
            const Divider(height: 1),
            _buildActionTile(
              icon: Icons.cloud_upload_outlined,
              title: S.t('maximumActiveUploads'),
              value: prefs['max_active_uploads']?.toString() ?? S.t('unlimited'),
              onTap: () => _showNumberEditDialog(
                title: S.t('maximumActiveUploads'),
                prefKey: 'max_active_uploads',
                initialValue:
                    _getInt(prefs['max_active_uploads'], defaultValue: 3),
              ),
            ),
            const Divider(height: 1),
            _buildActionTile(
              icon: Icons.compare_arrows_rounded,
              title: S.t('maximumActiveTorrents'),
              value: prefs['max_active_torrents']?.toString() ?? S.t('unlimited'),
              onTap: () => _showNumberEditDialog(
                title: S.t('maximumActiveTorrents'),
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
              title: S.t('shareRatioLimit'),
              subtitle: prefs['max_ratio'] != null
                  ? 'Limit: ${(prefs['max_ratio'] as num).toStringAsFixed(2)}'
                  : S.t('disabled'),
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
              title: S.t('enableRSSProcessing'),
              subtitle: S.t('fetchAndUpdateRSSFeeds'),
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
              title: S.t('feedsRefreshInterval'),
              value: '${prefs['rss_refresh_interval'] ?? 30} minutes',
              onTap: () => _showNumberEditDialog(
                title: S.t('feedsRefreshIntervalMinutes'),
                prefKey: 'rss_refresh_interval',
                initialValue:
                    _getInt(prefs['rss_refresh_interval'], defaultValue: 30),
              ),
            ),
            const Divider(height: 1),
            _buildActionTile(
              icon: Icons.article_outlined,
              title: S.t('maxArticlesPerFeed'),
              value: prefs['rss_max_articles_per_feed']?.toString() ?? '50',
              onTap: () => _showNumberEditDialog(
                title: S.t('maxArticlesPerFeed'),
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
              title: S.t('enableRSSAutoDownloading'),
              subtitle: S.t('automaticallyDownloadMatchedTorrentRules'),
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
              title: S.t('webUIIPAddress'),
              value: prefs['web_ui_address']?.toString() ?? '*',
              onTap: () => _showStringEditDialog(
                title: S.t('webUIIPAddressForAll'),
                prefKey: 'web_ui_address',
                initialValue: prefs['web_ui_address']?.toString() ?? '*',
              ),
            ),
            const Divider(height: 1),
            _buildActionTile(
              icon: Icons.numbers_rounded,
              title: S.t('webUIPort'),
              value: prefs['web_ui_port']?.toString() ?? '8080',
              onTap: () => _showNumberEditDialog(
                title: S.t('webUIPort'),
                prefKey: 'web_ui_port',
                initialValue: _getInt(prefs['web_ui_port'], defaultValue: 8080),
              ),
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              icon: Icons.router_rounded,
              title: S.t('useUPnPForWebUIPort'),
              subtitle: S.t('automaticallyMapWebUIPortOnRouter'),
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
              title: S.t('useHTTPS'),
              subtitle: S.t('encryptWebUIConnectionsWithSSLTLS'),
              value: _getBool(prefs['web_ui_use_https']),
              onChanged: (bool val) => _updatePref('web_ui_use_https', val),
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              icon: Icons.security_rounded,
              title: S.t('csrfProtection'),
              subtitle: S.t('preventCrossSiteRequestForgeryAttacks'),
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
              title: S.t('clickjackingProtection'),
              subtitle: S.t('preventFramingInExternalWebPages'),
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
              title: S.t('sessionTimeout'),
              value: '${prefs['web_ui_session_timeout'] ?? 3600} seconds',
              onTap: () => _showNumberEditDialog(
                title: S.t('sessionTimeoutSeconds'),
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
      '1' || 'SQLite' || 'sqlite' => S.t('sqliteDatabase'),
      _ => S.t('fastresumeFiles'),
    };

    final dynamic removeModeVal = prefs['torrent_content_remove_mode'] ??
        prefs['torrent_content_removing_mode'];
    final String removeModeDisplay = switch (removeModeVal?.toString()) {
      '1' || 'Trash' || 'trash' => S.t('moveToTrashIfPossible'),
      _ => S.t('deleteFilesPermanently'),
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
              title: S.t('resumeDataStorageTypeRequiresRestart'),
              value: storageTypeDisplay,
              onTap: () => _showOptionsDialog<dynamic>(
                title: S.t('resumeDataStorageType'),
                prefKey: 'resume_data_storage_type',
                currentValue: storageTypeVal ?? 0,
                options: <({String label, dynamic value, String? subtitle})>[
                  (
                    label: S.t('fastresumeFiles'),
                    value: storageTypeVal is String ? 'Legacy' : 0,
                    subtitle: S.t('legacyFastresumeFilesInBTBackupDirectory'),
                  ),
                  (
                    label: S.t('sqliteDatabase'),
                    value: storageTypeVal is String ? 'SQLite' : 1,
                    subtitle: S.t('storeAllTorrentStateInASingleSQLiteDB'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // 2. Torrent content removing mode
            _buildActionTile(
              icon: Icons.delete_sweep_outlined,
              title: S.t('torrentContentRemovingMode'),
              value: removeModeDisplay,
              onTap: () => _showOptionsDialog<dynamic>(
                title: S.t('torrentContentRemovingMode'),
                prefKey: 'torrent_content_remove_mode',
                currentValue: removeModeVal ?? 0,
                options: <({String label, dynamic value, String? subtitle})>[
                  (
                    label: S.t('deleteFilesPermanently'),
                    value: removeModeVal is String ? S.t('delete') : 0,
                    subtitle: S.t('erasePayloadDataDirectlyFromStorage'),
                  ),
                  (
                    label: S.t('moveToTrashIfPossible'),
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
              title: S.t('networkInterface'),
              value: currentIface.isNotEmpty ? currentIface : S.t('anyInterface'),
              onTap: () {
                final List<Map<String, String>> ifaces =
                    ifacesAsync.value ?? <Map<String, String>>[];
                final List<({String label, String value, String? subtitle})>
                    options =
                    <({String label, String value, String? subtitle})>[
                  (
                    label: S.t('anyInterface'),
                    value: '',
                    subtitle: S.t('listenAndBindAcrossAllNetworkInterfaces'),
                  ),
                  ...ifaces.map((Map<String, String> iface) {
                    final String name = iface['name'] ?? '';
                    final String val = iface['value'] ?? name;
                    return (
                      label: name.isNotEmpty ? name : val,
                      value: val,
                      subtitle: S.t('bindStrictlyToInterfaceVal1', [val]),
                    );
                  }),
                ];
                _showOptionsDialog<String>(
                  title: S.t('networkInterface'),
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
              title: S.t('optionalIPAddressToBindTo'),
              value:
                  (prefs['current_interface_address']?.toString().isNotEmpty ==
                          true)
                      ? prefs['current_interface_address'].toString()
                      : S.t('allAddresses'),
              onTap: () {
                final List<String> addrs = addrsAsync.value ?? <String>[];
                final String currentAddr =
                    prefs['current_interface_address']?.toString() ?? '';
                final List<({String label, String value, String? subtitle})>
                    options =
                    <({String label, String value, String? subtitle})>[
                  (
                    label: S.t('allAddresses'),
                    value: '',
                    subtitle: S.t('bindToAllIPv4AndIPv6Addresses'),
                  ),
                  (
                    label: S.t('allIPv4Addresses0000'),
                    value: '0.0.0.0',
                    subtitle: S.t('listenOnAllAvailableIPv4Interfaces'),
                  ),
                  (
                    label: S.t('allIPv6Addresses'),
                    value: '::',
                    subtitle: S.t('listenOnAllAvailableIPv6Interfaces'),
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
                  title: S.t('optionalIPAddressToBindTo'),
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
              title: S.t('saveResumeDataInterval'),
              value: '${prefs['save_resume_data_interval'] ?? 60} min',
              onTap: () => _showNumberEditDialog(
                title: S.t('saveResumeDataIntervalMin'),
                prefKey: 'save_resume_data_interval',
                initialValue: _getInt(
                  prefs['save_resume_data_interval'],
                  defaultValue: 60,
                ),
                helperText: S.t('intervalInMinutesBetweenPeriodicStateSaves'),
              ),
            ),
            const Divider(height: 1),

            // 6. Save statistics interval
            _buildActionTile(
              icon: Icons.query_stats_rounded,
              title: S.t('saveStatisticsInterval'),
              value: '${prefs['save_statistics_interval'] ?? 15} min',
              onTap: () => _showNumberEditDialog(
                title: S.t('saveStatisticsIntervalMin'),
                prefKey: 'save_statistics_interval',
                initialValue: _getInt(
                  prefs['save_statistics_interval'],
                  defaultValue: 15,
                ),
                helperText: S.t('intervalInMinutesBetweenSavingSessionStats'),
              ),
            ),
            const Divider(height: 1),

            // 7. .torrent file size limit
            _buildActionTile(
              icon: Icons.file_present_outlined,
              title: S.t('torrentFileSizeLimit'),
              value: '${prefs['max_torrent_file_size'] ?? 100} MiB',
              onTap: () => _showNumberEditDialog(
                title: S.t('torrentFileSizeLimitMiB'),
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
              title: S.t('confirmTorrentRecheck_2'),
              subtitle: S.t('showConfirmationPromptBeforeForceRechecking'),
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
              title: S.t('recheckTorrentsOnCompletion'),
              subtitle: S.t('verifyPieceIntegrityAfterDownloadReaches100'),
              value: _getBool(prefs['recheck_completed_torrents']),
              onChanged: (bool val) =>
                  _updatePref('recheck_completed_torrents', val),
            ),
            const Divider(height: 1),

            // 10. Customize application instance name
            _buildActionTile(
              icon: Icons.badge_outlined,
              title: S.t('customizeApplicationInstanceName'),
              value: prefs['app_instance_name']?.toString().isNotEmpty == true
                  ? prefs['app_instance_name'].toString()
                  : '(Default)',
              onTap: () => _showStringEditDialog(
                title: S.t('customizeApplicationInstanceName'),
                prefKey: 'app_instance_name',
                initialValue: prefs['app_instance_name']?.toString() ?? '',
                hintText: S.t('customInstanceName'),
              ),
            ),
            const Divider(height: 1),

            // 11. Refresh interval
            _buildActionTile(
              icon: Icons.sync_rounded,
              title: S.t('refreshInterval'),
              value: '${prefs['refresh_interval'] ?? 1500} ms',
              onTap: () => _showNumberEditDialog(
                title: S.t('refreshIntervalMs'),
                prefKey: 'refresh_interval',
                initialValue:
                    _getInt(prefs['refresh_interval'], defaultValue: 1500),
                helperText: S.t('pollingRefreshIntervalInMilliseconds'),
              ),
            ),
            const Divider(height: 1),

            // 12. Resolve peer host names
            _buildSwitchTile(
              icon: Icons.dns_outlined,
              title: S.t('resolvePeerHostNames'),
              subtitle: S.t('performReverseDNSLookupOnConnectedPeerIPs'),
              value: _getBool(prefs['resolve_peer_host_names']),
              onChanged: (bool val) =>
                  _updatePref('resolve_peer_host_names', val),
            ),
            const Divider(height: 1),

            // 13. Resolve peer countries
            _buildSwitchTile(
              icon: Icons.flag_outlined,
              title: S.t('resolvePeerCountries'),
              subtitle: S.t('showCountryFlagsForPeerIPGeolocation'),
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
              title: S.t('reannounceToAllTrackersWhenIPOrPortChanged'),
              subtitle: S.t('triggerInstantTrackerUpdateOnNetworkChange'),
              value: _getBool(prefs['reannounce_when_address_changed']),
              onChanged: (bool val) =>
                  _updatePref('reannounce_when_address_changed', val),
            ),
            const Divider(height: 1),

            // 15. Enable embedded tracker
            _buildSwitchTile(
              icon: Icons.hub_rounded,
              title: S.t('enableEmbeddedTracker'),
              subtitle: S.t('runBuiltInTrackerOnThisQBittorrentNode'),
              value: _getBool(prefs['enable_embedded_tracker']),
              onChanged: (bool val) =>
                  _updatePref('enable_embedded_tracker', val),
            ),
            if (_getBool(prefs['enable_embedded_tracker'])) ...<Widget>[
              const Divider(height: 1),
              // 16. Embedded tracker port
              _buildActionTile(
                icon: Icons.numbers_rounded,
                title: S.t('embeddedTrackerPort'),
                value: '${prefs['embedded_tracker_port'] ?? 9000}',
                onTap: () => _showNumberEditDialog(
                  title: S.t('embeddedTrackerPort'),
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
                title: S.t('enablePortForwardingForEmbeddedTracker'),
                subtitle: S.t('useUPnPNATPMPToOpenTrackerPort'),
                value: _getBool(prefs['embedded_tracker_port_forwarding']),
                onChanged: (bool val) =>
                    _updatePref('embedded_tracker_port_forwarding', val),
              ),
            ],
            const Divider(height: 1),

            // 18. Ignore SSL errors
            _buildSwitchTile(
              icon: Icons.gpp_maybe_outlined,
              title: S.t('ignoreSSLErrors'),
              subtitle:
                  'Ignore HTTPS certification validation errors on trackers & RSS',
              value: _getBool(prefs['ignore_ssl_errors']),
              onChanged: (bool val) => _updatePref('ignore_ssl_errors', val),
            ),
            const Divider(height: 1),

            // 19. Python executable path (may require restart)
            _buildActionTile(
              icon: Icons.terminal_rounded,
              title: S.t('pythonExecutablePathMayRequireRestart'),
              value:
                  prefs['python_executable_path']?.toString().isNotEmpty == true
                      ? prefs['python_executable_path'].toString()
                      : S.t('autoDetectIfEmpty'),
              onTap: () => _showStringEditDialog(
                title: S.t('pythonExecutablePath'),
                prefKey: 'python_executable_path',
                initialValue: prefs['python_executable_path']?.toString() ?? '',
                hintText: S.t('autoDetectIfEmpty'),
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
              title: S.t('diskWriteCacheMiB'),
              value: prefs['disk_cache']?.toString() ?? 'Auto',
              onTap: () => _showNumberEditDialog(
                title: S.t('diskWriteCacheMiB1ForAuto'),
                prefKey: 'disk_cache',
                initialValue: _getInt(prefs['disk_cache'], defaultValue: -1),
              ),
            ),
            const Divider(height: 1),
            _buildActionTile(
              icon: Icons.timer_outlined,
              title: S.t('diskCacheExpiryTTL'),
              value: '${prefs['disk_cache_ttl'] ?? 60} seconds',
              onTap: () => _showNumberEditDialog(
                title: S.t('diskCacheExpirySeconds'),
                prefKey: 'disk_cache_ttl',
                initialValue:
                    _getInt(prefs['disk_cache_ttl'], defaultValue: 60),
              ),
            ),
            const Divider(height: 1),
            _buildActionTile(
              icon: Icons.alt_route_rounded,
              title: S.t('asynchronousIOThreads'),
              value: prefs['async_io_threads']?.toString() ?? '4',
              onTap: () => _showNumberEditDialog(
                title: S.t('asynchronousIOThreads'),
                prefKey: 'async_io_threads',
                initialValue:
                    _getInt(prefs['async_io_threads'], defaultValue: 4),
              ),
            ),
            const Divider(height: 1),
            _buildActionTile(
              icon: Icons.speed_rounded,
              title: S.t('memoryWorkingSetLimitMiB'),
              value: prefs['memory_working_set_limit']?.toString() ??
                  '0 (Unlimited)',
              onTap: () => _showNumberEditDialog(
                title: S.t('memoryWorkingSetLimitMiB0ForUnlimited'),
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
        known ? address : S.t('notKnownYet'),
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
    String message = S.t('titleCopied1', [title]);
    try {
      await Clipboard.setData(ClipboardData(text: address));
    } on PlatformException {
      message = S.t('couldNotCopyToTheClipboard');
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
    if (limit == null) return S.t('unlimited');
    final int bytes = int.tryParse(limit.toString()) ?? 0;
    if (bytes <= 0) return S.t('unlimited');
    return '${fmtBytes(bytes)}/s';
  }
}
