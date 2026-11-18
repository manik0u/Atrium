import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../aria2_api.dart';
import '../aria2_format.dart';
import '../aria2_providers.dart';

/// Tab 2: Global aria2 configuration editor (bandwidth, concurrency, storage, and BitTorrent).
class Aria2SettingsTab extends ConsumerStatefulWidget {
  const Aria2SettingsTab({
    required this.instance,
    this.onOpenDrawer,
    super.key,
  });

  final Instance instance;
  final VoidCallback? onOpenDrawer;

  @override
  ConsumerState<Aria2SettingsTab> createState() => _Aria2SettingsTabState();
}

class _Aria2SettingsTabState extends ConsumerState<Aria2SettingsTab> {
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

  Future<void> _write(String key, String value) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      final Aria2Api api = await ref.read(
        aria2ApiProvider(widget.instance).future,
      );
      await api.changeGlobalOption(<String, String>{key: value});
      messenger.showSnackBar(
        SnackBar(
          content: Text(S.t('settingSaved')),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(S.t('couldNotSaveE1', [e]))));
    } finally {
      ref.invalidate(aria2GlobalOptionsProvider(widget.instance));
    }
  }

  Future<void> _editText({
    required String title,
    required String key,
    required String initial,
    String? helper,
  }) async {
    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext _) =>
          _EditDialog(title: title, initial: initial, helper: helper),
    );
    if (result != null && result != initial) {
      await _write(key, result);
    }
  }

  Future<void> _editNumber({
    required String title,
    required String key,
    required String initial,
    bool decimal = false,
    String? helper,
  }) async {
    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext _) => _EditDialog(
        title: title,
        initial: initial,
        helper: helper,
        number: true,
        decimal: decimal,
      ),
    );
    if (result != null && result != initial) {
      await _write(key, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Map<String, String>> options = ref.watch(
      aria2GlobalOptionsProvider(widget.instance),
    );

    ref.listen<int>(aria2ScrollToTopProvider((widget.instance, 1)), (
      previous,
      next,
    ) {
      if (next > 0 && _scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: widget.onOpenDrawer ??
              () => Scaffold.of(context).openDrawer(),
        ),
        title: Text(S.t('aria2Settings')),
      ),
      body: AsyncValueView<Map<String, String>>(
        value: options,
        onRetry: () =>
            ref.invalidate(aria2GlobalOptionsProvider(widget.instance)),
        data: (Map<String, String> opt) {
          final String dlLimit = opt['max-overall-download-limit'] ?? '0';
          final String ulLimit = opt['max-overall-upload-limit'] ?? '0';
          final String taskDlLimit = opt['max-download-limit'] ?? '0';
          final String taskUlLimit = opt['max-upload-limit'] ?? '0';

          final String maxConcurrent = opt['max-concurrent-downloads'] ?? '5';
          final String maxConnPerServer =
              opt['max-connection-per-server'] ?? '1';
          final String split = opt['split'] ?? '5';
          final String minSplitSize = opt['min-split-size'] ?? '20M';
          final String connectTimeout = opt['connect-timeout'] ?? '60';

          final String downloadDir = opt['dir'] ?? '';
          final String diskCache = opt['disk-cache'] ?? '16M';
          final String fileAlloc = opt['file-allocation'] ?? 'prealloc';
          final bool autoRenaming =
              (opt['auto-file-renaming'] ?? 'true') == 'true';
          final bool conditionalGet =
              (opt['conditional-get'] ?? 'false') == 'true';

          final String seedRatio = opt['seed-ratio'] ?? '1.0';
          final String seedTime = opt['seed-time'] ?? '';
          final bool enableDht = (opt['enable-dht'] ?? 'true') == 'true';
          final String btMaxPeers = opt['bt-max-peers'] ?? '55';
          final String listenPort = opt['listen-port'] ?? '6881-6999';

          String formatRate(String bytesStr) {
            final int? b = int.tryParse(bytesStr);
            if (b == null || b <= 0) return S.t('unlimited0');
            return aria2FmtRate(b);
          }

          return EasyRefresh(
            onRefresh: () async {
              ref.invalidate(aria2GlobalOptionsProvider(widget.instance));
              await ref.read(
                aria2GlobalOptionsProvider(widget.instance).future,
              );
            },
            child: ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                Insets.md,
                Insets.xs,
                Insets.md,
                Insets.xl,
              ),
              children: <Widget>[
                // Group 1: Bandwidth & Limits
                _SettingsGroup(
                  title: S.t('bandwidthLimits'),
                  icon: Icons.speed_outlined,
                  children: <Widget>[
                    ListTile(
                      title: Text(S.t('overallDownloadSpeedLimit')),
                      subtitle: Text(formatRate(dlLimit)),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () => _editNumber(
                        title: S.t('globalDownloadLimitBytesS'),
                        key: 'max-overall-download-limit',
                        initial: dlLimit,
                        helper: '0 for unlimited, e.g. 1048576 for 1 MB/s',
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: Text(S.t('overallUploadSpeedLimit')),
                      subtitle: Text(formatRate(ulLimit)),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () => _editNumber(
                        title: S.t('globalUploadLimitBytesS'),
                        key: 'max-overall-upload-limit',
                        initial: ulLimit,
                        helper: '0 for unlimited, e.g. 524288 for 512 KB/s',
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: Text(S.t('defaultTaskDownloadLimit')),
                      subtitle: Text(formatRate(taskDlLimit)),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () => _editNumber(
                        title: S.t('taskDownloadLimitBytesSec'),
                        key: 'max-download-limit',
                        initial: taskDlLimit,
                        helper: S.t('speedLimitPerDownload0Unlimited'),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: Text(S.t('defaultTaskUploadLimit')),
                      subtitle: Text(formatRate(taskUlLimit)),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () => _editNumber(
                        title: S.t('taskUploadLimitBytesSec'),
                        key: 'max-upload-limit',
                        initial: taskUlLimit,
                        helper: S.t('uploadLimitPerDownload0Unlimited'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Insets.md),

                // Group 2: Tasks & Concurrency
                _SettingsGroup(
                  title: S.t('tasksConcurrency'),
                  icon: Icons.alt_route_outlined,
                  children: <Widget>[
                    ListTile(
                      title: Text(S.t('maxConcurrentDownloads')),
                      subtitle: Text(S.t('maxconcurrentActiveDownloadsAtOnce1', [maxConcurrent])),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () => _editNumber(
                        title: S.t('maxConcurrentDownloads'),
                        key: 'max-concurrent-downloads',
                        initial: maxConcurrent,
                        helper: S.t('numberOfParallelDownloadsDefault5'),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: Text(S.t('connPerServer')),
                      subtitle: Text(S.t('maxconnperserverPerHost1', [maxConnPerServer])),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () => _editNumber(
                        title: S.t('maxConnectionsPerServer'),
                        key: 'max-connection-per-server',
                        initial: maxConnPerServer,
                        helper: S.t('k1To16Default1'),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: Text(S.t('splitCount')),
                      subtitle: Text(S.t('downloadFileInSplitPieces1', [split])),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () => _editNumber(
                        title: S.t('splitCount'),
                        key: 'split',
                        initial: split,
                        helper: S.t('numberOfPiecesToSplitAFileInto1To16'),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: Text(S.t('minSplitSize')),
                      subtitle: Text(minSplitSize),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () => _editText(
                        title: S.t('minSplitSize_2'),
                        key: 'min-split-size',
                        initial: minSplitSize,
                        helper: S.t('eG10M20M50M'),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: Text(S.t('connectionTimeout')),
                      subtitle: Text(S.t('connecttimeoutSeconds1', [connectTimeout])),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () => _editNumber(
                        title: S.t('connectTimeoutSeconds'),
                        key: 'connect-timeout',
                        initial: connectTimeout,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Insets.md),

                // Group 3: Storage & Directories
                _SettingsGroup(
                  title: S.t('storageDirectories'),
                  icon: Icons.folder_outlined,
                  children: <Widget>[
                    ListTile(
                      title: Text(S.t('downloadDirectory')),
                      subtitle: Text(
                        downloadDir.isEmpty ? S.t('default') : downloadDir,
                      ),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () => _editText(
                        title: S.t('defaultDownloadDirectory'),
                        key: 'dir',
                        initial: downloadDir,
                        helper: S.t('absoluteFilesystemPathOnTheAria2Host'),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: Text(S.t('diskCache')),
                      subtitle: Text(
                        '${diskCache.isEmpty ? 'Disabled' : diskCache} (startup only • set in aria2.conf)',
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: Text(S.t('fileAllocationMethod')),
                      subtitle: Text(fileAlloc),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () async {
                        final String? selected = await showDialog<String>(
                          context: context,
                          builder: (BuildContext ctx) => SimpleDialog(
                            title: Text(S.t('fileAllocationMethod')),
                            children: <Widget>[
                              for (final String m in <String>[
                                'none',
                                'prealloc',
                                'trunc',
                                'falloc',
                              ])
                                SimpleDialogOption(
                                  onPressed: () => Navigator.of(ctx).pop(m),
                                  child: Text(m),
                                ),
                            ],
                          ),
                        );
                        if (selected != null && selected != fileAlloc) {
                          await _write('file-allocation', selected);
                        }
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: Text(S.t('autoFileRenaming')),
                      subtitle: const Text(
                        'Rename file if filename already exists',
                      ),
                      value: autoRenaming,
                      onChanged: (bool val) =>
                          _write('auto-file-renaming', val ? 'true' : 'false'),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: Text(S.t('conditionalGET')),
                      subtitle: Text(
                        S.t('skipDownloadingIfLocalFileHasMatchingTimestamp'),
                      ),
                      value: conditionalGet,
                      onChanged: (bool val) =>
                          _write('conditional-get', val ? 'true' : 'false'),
                    ),
                  ],
                ),
                const SizedBox(height: Insets.md),

                // Group 4: BitTorrent & Seeding
                _SettingsGroup(
                  title: S.t('bittorrentSeeding'),
                  icon: Icons.grain_outlined,
                  children: <Widget>[
                    ListTile(
                      title: Text(S.t('seedRatio')),
                      subtitle: Text(
                        seedRatio == '0' || seedRatio == '0.0'
                            ? S.t('infiniteSeeding')
                            : '${seedRatio}x',
                      ),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () => _editNumber(
                        title: S.t('seedRatio'),
                        key: 'seed-ratio',
                        initial: seedRatio,
                        decimal: true,
                        helper: S.t('k00ForUnlimitedOrEG1020'),
                      ),
                    ),
                    if (seedTime.isNotEmpty) ...<Widget>[
                      const Divider(height: 1),
                      ListTile(
                        title: Text(S.t('seedTime')),
                        subtitle: Text('$seedTime minutes'),
                        trailing: const Icon(Icons.chevron_right, size: 20),
                        onTap: () => _editNumber(
                          title: S.t('seedTimeMinutes'),
                          key: 'seed-time',
                          initial: seedTime,
                        ),
                      ),
                    ],
                    const Divider(height: 1),
                    ListTile(
                      title: Text(S.t('enableDHT')),
                      subtitle: Text(
                        '${enableDht ? S.t('enabled') : S.t('disabled')} (startup only • set in aria2.conf)',
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: Text(S.t('maxPeers')),
                      subtitle: Text(S.t('btmaxpeersPeers1', [btMaxPeers])),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () => _editNumber(
                        title: S.t('maxBitTorrentPeers'),
                        key: 'bt-max-peers',
                        initial: btMaxPeers,
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: Text(S.t('listenPort')),
                      subtitle: Text(
                        '${listenPort.isEmpty ? 'Default' : listenPort} (startup only • set in aria2.conf)',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Insets.md,
              Insets.md,
              Insets.md,
              Insets.xs,
            ),
            child: Row(
              children: <Widget>[
                Icon(icon, size: 18, color: cs.primary),
                const SizedBox(width: Insets.sm),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _EditDialog extends StatefulWidget {
  const _EditDialog({
    required this.title,
    required this.initial,
    this.helper,
    this.number = false,
    this.decimal = false,
  });

  final String title;
  final String initial;
  final String? helper;
  final bool number;
  final bool decimal;

  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: widget.number
            ? TextInputType.numberWithOptions(decimal: widget.decimal)
            : TextInputType.text,
        inputFormatters: <TextInputFormatter>[
          if (widget.number)
            FilteringTextInputFormatter.allow(
              RegExp(widget.decimal ? r'[0-9.]' : r'[0-9]'),
            ),
        ],
        decoration: InputDecoration(
          helperText: widget.helper,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(S.t('cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: Text(S.t('save')),
        ),
      ],
    );
  }
}
