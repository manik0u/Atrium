import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/transmission_session.dart';
import 'transmission_api.dart';
import 'transmission_format.dart';
import 'transmission_providers.dart';
import 'transmission_visuals.dart';

/// The web UI's Statistics dialog and its four preference pages, as one
/// scrolling tab. Every change is written on its own, then the session is
/// read again so the screen shows what the daemon accepted.
class TransmissionSettingsTab extends ConsumerStatefulWidget {
  const TransmissionSettingsTab({
    required this.instance,
    this.onOpenDrawer,
    super.key,
  });

  final Instance instance;

  /// How to open the app's services drawer. Handed in because this tab's own
  /// app bar cannot reach the home's Scaffold through a second Scaffold.
  final VoidCallback? onOpenDrawer;

  @override
  ConsumerState<TransmissionSettingsTab> createState() =>
      _TransmissionSettingsTabState();
}

class _TransmissionSettingsTabState
    extends ConsumerState<TransmissionSettingsTab> {
  bool _updatingBlocklist = false;
  bool _testingPort = false;
  final ScrollController _scroll = ScrollController();

  /// Per protocol, or a single `''` key on a daemon that tests only one.
  Map<String, bool> _portResults = <String, bool>{};

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _write(String key, Object? value) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      final TransmissionApi api =
          await ref.read(transmissionApiProvider(widget.instance).future);
      await api.setSession(<String, Object?>{key: value});
      messenger.showSnackBar(
        SnackBar(
          content: Text(S.t('settingSaved')),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(S.t('couldNotSaveE1', [e]))));
    } finally {
      // Whether it took or not, show what the daemon has now.
      ref.invalidate(transmissionSessionProvider(widget.instance));
    }
  }

  Future<void> _editText({
    required String title,
    required String key,
    required String initial,
    bool multiline = false,
    String? helper,
  }) async {
    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext _) => _EditDialog(
        title: title,
        initial: initial,
        helper: helper,
        multiline: multiline,
      ),
    );
    if (result != null && result != initial) await _write(key, result);
  }

  Future<void> _editNumber({
    required String title,
    required String key,
    required num initial,
    bool decimal = false,
    String? helper,
  }) async {
    final String? text = await showDialog<String>(
      context: context,
      builder: (BuildContext _) => _EditDialog(
        title: title,
        initial: '$initial',
        helper: helper,
        number: true,
        decimal: decimal,
      ),
    );
    if (text == null) return;
    final num? value = decimal ? double.tryParse(text) : int.tryParse(text);
    if (value != null && value != initial) await _write(key, value);
  }

  Future<void> _pickTime({required String key, required int minutes}) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
    );
    if (picked != null) await _write(key, picked.hour * 60 + picked.minute);
  }

  Future<void> _updateBlocklist() async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    setState(() => _updatingBlocklist = true);
    try {
      final TransmissionApi api =
          await ref.read(transmissionApiProvider(widget.instance).future);
      final int rules = await api.updateBlocklist();
      messenger.showSnackBar(
        SnackBar(content: Text(S.t('blocklistUpdatedRulesRules1', [rules]))),
      );
      ref.invalidate(transmissionSessionProvider(widget.instance));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(S.t('blocklistUpdateFailedE1', [e]))),
      );
    } finally {
      if (mounted) setState(() => _updatingBlocklist = false);
    }
  }

  Future<void> _testPort(TransmissionSession session) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    setState(() {
      _testingPort = true;
      _portResults = <String, bool>{};
    });
    try {
      final TransmissionApi api =
          await ref.read(transmissionApiProvider(widget.instance).future);
      final Map<String, bool> results = <String, bool>{};
      if (session.supportsPortTestPerProtocol) {
        for (final String protocol in <String>['ipv4', 'ipv6']) {
          results[protocol] = await api.portTest(ipProtocol: protocol);
        }
      } else {
        results[''] = await api.portTest();
      }
      if (mounted) setState(() => _portResults = results);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(S.t('portTestFailedE1', [e]))));
    } finally {
      if (mounted) setState(() => _testingPort = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AsyncValue<TransmissionSession> session =
        ref.watch(transmissionSessionProvider(widget.instance));

    ref.listen<int>(
      transmissionScrollToTopProvider((widget.instance, 1)),
      (int? previous, int next) {
        if (next > 0 && _scroll.hasClients) {
          _scroll.animateTo(
            0,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
          );
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed:
              widget.onOpenDrawer ?? () => Scaffold.of(context).openDrawer(),
        ),
        title: Text(S.t('widgetInstanceNameSettings1', [widget.instance.name])),
        actions: <Widget>[
          IconButton(
            tooltip: S.t('refresh'),
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref
                ..invalidate(transmissionSessionProvider(widget.instance))
                ..invalidate(
                  transmissionSessionStatsProvider(widget.instance),
                );
            },
          ),
        ],
      ),
      body: AsyncValueView<TransmissionSession>(
        value: session,
        onRetry: () =>
            ref.invalidate(transmissionSessionProvider(widget.instance)),
        data: (TransmissionSession s) => ListView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            Insets.md,
            Insets.xs,
            Insets.md,
            Insets.xl,
          ),
          children: <Widget>[
            _StatisticsCard(instance: widget.instance),
            const SizedBox(height: Insets.sm),
            _Group(
              title: S.t('torrents'),
              children: <Widget>[
                _pathTile(S.t('downloadTo'), s.downloadDir, 'download-dir'),
                _switchTile(
                  S.t('startWhenAdded'),
                  s.startAddedTorrents,
                  'start-added-torrents',
                ),
                _switchTile(
                  'Stop seeding at ratio',
                  s.seedRatioLimited,
                  'seedRatioLimited',
                ),
                _numberTile(
                  'Seed ratio limit',
                  s.seedRatioLimit,
                  'seedRatioLimit',
                  decimal: true,
                ),
                _switchTile(
                  'Stop seeding if idle',
                  s.idleSeedingLimitEnabled,
                  'idle-seeding-limit-enabled',
                ),
                _numberTile(
                  'Idle limit (minutes)',
                  s.idleSeedingLimit,
                  'idle-seeding-limit',
                ),
                _switchTile(
                  'Keep incomplete torrents in a separate folder',
                  s.incompleteDirEnabled,
                  'incomplete-dir-enabled',
                ),
                _pathTile(
                  'Incomplete folder',
                  s.incompleteDir,
                  'incomplete-dir',
                ),
                _switchTile(
                  S.t('appendPartToIncompleteFiles'),
                  s.renamePartialFiles,
                  'rename-partial-files',
                ),
                _switchTile(
                  S.t('limitTheDownloadQueue'),
                  s.downloadQueueEnabled,
                  'download-queue-enabled',
                ),
                _numberTile(
                  S.t('downloadQueueSize'),
                  s.downloadQueueSize,
                  'download-queue-size',
                ),
                if (s.supportsDefaultTrackers)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(S.t('defaultPublicTrackers')),
                    subtitle: Text(_trackerCount(s.defaultTrackers)),
                    onTap: () => _editText(
                      title: S.t('defaultPublicTrackers'),
                      key: 'default-trackers',
                      initial: s.defaultTrackers,
                      multiline: true,
                      helper: S.t('oneURLPerLineABlankLineBetweenTiers'),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: Insets.sm),
            _Group(
              title: S.t('speed'),
              children: <Widget>[
                _switchTile(
                  S.t('limitUpload'),
                  s.speedLimitUpEnabled,
                  'speed-limit-up-enabled',
                ),
                _numberTile(
                  'Upload limit (kB/s)',
                  s.speedLimitUp,
                  'speed-limit-up',
                ),
                _switchTile(
                  S.t('limitDownload'),
                  s.speedLimitDownEnabled,
                  'speed-limit-down-enabled',
                ),
                _numberTile(
                  'Download limit (kB/s)',
                  s.speedLimitDown,
                  'speed-limit-down',
                ),
                _numberTile(
                  'Alternative upload limit (kB/s)',
                  s.altSpeedUp,
                  'alt-speed-up',
                ),
                _numberTile(
                  'Alternative download limit (kB/s)',
                  s.altSpeedDown,
                  'alt-speed-down',
                ),
                _switchTile(
                  S.t('scheduledAlternativeLimits'),
                  s.altSpeedTimeEnabled,
                  'alt-speed-time-enabled',
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(S.t('from')),
                  subtitle: Text(_clock(s.altSpeedTimeBegin)),
                  onTap: () => _pickTime(
                    key: 'alt-speed-time-begin',
                    minutes: s.altSpeedTimeBegin,
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(S.t('to')),
                  subtitle: Text(_clock(s.altSpeedTimeEnd)),
                  onTap: () => _pickTime(
                    key: 'alt-speed-time-end',
                    minutes: s.altSpeedTimeEnd,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: Insets.xs),
                  child: Text(S.t('onDaysTrDaySummarySAltSpeedTimeDay1', [trDaySummary(s.altSpeedTimeDay)])),
                ),
                Wrap(
                  spacing: Insets.xs,
                  runSpacing: Insets.xs,
                  children: <Widget>[
                    for (final (int mask, String name) in <(int, String)>[
                      (trEveryDay, S.t('everyDay')),
                      (trWeekdays, S.t('weekdays')),
                      (trWeekends, S.t('weekends')),
                    ])
                      ChoiceChip(
                        label: Text(name),
                        selected: s.altSpeedTimeDay == mask,
                        onSelected: (_) => _write('alt-speed-time-day', mask),
                      ),
                    for (final (int bit, String name) in trDays)
                      FilterChip(
                        label: Text(name),
                        selected: s.altSpeedTimeDay & bit != 0,
                        onSelected: (_) => _write(
                          'alt-speed-time-day',
                          trToggleDay(s.altSpeedTimeDay, bit),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: Insets.sm),
            _Group(
              title: S.t('peers'),
              children: <Widget>[
                _numberTile(
                  S.t('maxPeersPerTorrent'),
                  s.peerLimitPerTorrent,
                  'peer-limit-per-torrent',
                ),
                _numberTile(
                  S.t('maxPeersOverall'),
                  s.peerLimitGlobal,
                  'peer-limit-global',
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(S.t('encryption')),
                  subtitle: Text(_encryptionLabel(s.encryption)),
                  onTap: () async {
                    final String? mode = await showDialog<String>(
                      context: context,
                      builder: (BuildContext context) => SimpleDialog(
                        title: Text(S.t('encryption')),
                        children: <Widget>[
                          RadioGroup<String>(
                            groupValue: _encryptionValue(s.encryption),
                            onChanged: (String? v) =>
                                Navigator.of(context).pop(v),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                for (final (String value, String label)
                                    in _encryptionModes)
                                  RadioListTile<String>(
                                    value: value,
                                    title: Text(label),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                    if (mode != null) await _write('encryption', mode);
                  },
                ),
                _switchTile(
                  S.t('usePEXToFindMorePeers'),
                  s.pexEnabled,
                  'pex-enabled',
                ),
                _switchTile(
                  'Use DHT to find more peers',
                  s.dhtEnabled,
                  'dht-enabled',
                ),
                _switchTile(
                  'Use LPD to find local peers',
                  s.lpdEnabled,
                  'lpd-enabled',
                ),
                _switchTile(
                  S.t('enableBlocklist'),
                  s.blocklistEnabled,
                  'blocklist-enabled',
                ),
                _pathTile(S.t('blocklistURL'), s.blocklistUrl, 'blocklist-url'),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: Insets.xs),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: TransmissionPill(
                          icon: Icons.block,
                          label: S.t('blocklistHasSBlocklistSizeRules1', [s.blocklistSize]),
                          foreground: cs.onSurfaceVariant,
                          background: cs.surfaceContainerHighest,
                        ),
                      ),
                      const SizedBox(width: Insets.sm),
                      FilledButton.tonal(
                        onPressed: _updatingBlocklist ? null : _updateBlocklist,
                        child: Text(S.t('updateBlocklist')),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Insets.sm),
            _Group(
              title: S.t('network'),
              children: <Widget>[
                _numberTile(S.t('peerListeningPort'), s.peerPort, 'peer-port'),
                _switchTile(
                  S.t('randomizePortOnLaunch'),
                  s.peerPortRandomOnStart,
                  'peer-port-random-on-start',
                ),
                _switchTile(
                  S.t('usePortForwardingUPnPOrNATPMP'),
                  s.portForwardingEnabled,
                  'port-forwarding-enabled',
                ),
                _switchTile(S.t('enableUTP'), s.utpEnabled, 'utp-enabled'),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: Insets.xs),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Wrap(
                          spacing: Insets.xs,
                          runSpacing: Insets.xs,
                          children: <Widget>[
                            for (final MapEntry<String, bool> r
                                in _portResults.entries)
                              TransmissionPill(
                                icon: r.value
                                    ? Icons.check_circle_outline
                                    : Icons.error_outline,
                                label: S.t('protocollabelRKeyIs1', [_protocolLabel(r.key)]) +
                                    '${r.value ? S.t('open') : S.t('closed')}',
                                foreground: r.value
                                    ? cs.onTertiaryContainer
                                    : cs.onErrorContainer,
                                background: r.value
                                    ? cs.tertiaryContainer
                                    : cs.errorContainer,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: Insets.sm),
                      FilledButton.tonal(
                        onPressed: _testingPort ? null : () => _testPort(s),
                        child: Text(S.t('testPort')),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Insets.lg),
            Center(
              child: Text(
                'Transmission ${s.version}, RPC ${s.rpcVersion}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _switchTile(String title, bool value, String key) => SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title),
        value: value,
        onChanged: (bool v) => _write(key, v),
      );

  Widget _numberTile(
    String title,
    num value,
    String key, {
    bool decimal = false,
  }) =>
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title),
        subtitle: Text('$value'),
        onTap: () => _editNumber(
          title: title,
          key: key,
          initial: value,
          decimal: decimal,
        ),
      );

  Widget _pathTile(String title, String value, String key) => ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title),
        subtitle: Text(value.isEmpty ? S.t('notSet') : value),
        onTap: () => _editText(
          title: title,
          key: key,
          initial: value,
          helper: S.t('aPathAsTheServerSeesItNotYourPhone'),
        ),
      );

  static String _clock(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
      '${(minutes % 60).toString().padLeft(2, '0')}';

  static String _trackerCount(String trackers) {
    final int n = trackers
        .split('\n')
        .where((String l) => l.trim().isNotEmpty)
        .length;
    return n == 0 ? 'None' : trCount(n, 'tracker', 'trackers');
  }

  static String _protocolLabel(String protocol) => switch (protocol) {
        'ipv4' => S.t('ipv4Port'),
        'ipv6' => S.t('ipv6Port'),
        _ => S.t('port'),
      };

  /// The daemon writes `allowed` but reads it back as `tolerated`.
  static final List<(String, String)> _encryptionModes = <(String, String)>[
    ('allowed', S.t('allowEncryption')),
    ('preferred', S.t('preferEncryption')),
    ('required', S.t('requireEncryption')),
  ];

  static String _encryptionValue(String raw) =>
      raw == 'tolerated' ? 'allowed' : raw;

  static String _encryptionLabel(String raw) {
    final String value = _encryptionValue(raw);
    for (final (String v, String label) in _encryptionModes) {
      if (v == value) return label;
    }
    return raw;
  }
}

/// One of the web UI's preference pages, as a titled panel of rows.
class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return TransmissionPanel(
      padding: const EdgeInsets.fromLTRB(
        Insets.md,
        Insets.md,
        Insets.md,
        Insets.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TransmissionPanelTitle(title),
          ...children,
        ],
      ),
    );
  }
}

/// One field and Save, owning its controller so it outlives the dialog's
/// exit animation.
class _EditDialog extends StatefulWidget {
  const _EditDialog({
    required this.title,
    required this.initial,
    this.helper,
    this.multiline = false,
    this.number = false,
    this.decimal = false,
  });

  final String title;
  final String initial;
  final String? helper;
  final bool multiline;
  final bool number;
  final bool decimal;

  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

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
        maxLines: widget.multiline ? 6 : 1,
        keyboardType: widget.number
            ? TextInputType.numberWithOptions(decimal: widget.decimal)
            : null,
        inputFormatters: <TextInputFormatter>[
          if (widget.number)
            FilteringTextInputFormatter.allow(
              RegExp(widget.decimal ? r'[0-9.]' : r'[0-9]'),
            ),
        ],
        decoration: transmissionFieldDecoration(context, helper: widget.helper),
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

/// The web UI's Statistics dialog: this session above all time, each as one
/// tinted block of figures, two to a line so the pair does not fill the first
/// screen before any actual setting appears.
class _StatisticsCard extends ConsumerWidget {
  const _StatisticsCard({required this.instance});

  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final TextTheme text = theme.textTheme;
    final TransmissionSessionStats stats =
        ref.watch(transmissionSessionStatsProvider(instance)).value ??
            const TransmissionSessionStats();

    Widget figure(String label, String value) => Padding(
          padding: const EdgeInsets.only(bottom: Insets.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: text.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        );

    Widget block(
      String title,
      IconData icon,
      TransmissionStatsBlock b, {
      bool started = false,
    }) {
      final double ratio =
          b.downloadedBytes == 0 ? -1 : b.uploadedBytes / b.downloadedBytes;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Insets.md),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, size: 16, color: cs.primary),
                const SizedBox(width: Insets.xs),
                Expanded(
                  child: Text(
                    title,
                    style: text.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Insets.sm),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double column = (constraints.maxWidth - Insets.sm) / 2;
                return Wrap(
                  spacing: Insets.sm,
                  children: <Widget>[
                    for (final (String label, String value)
                        in <(String, String)>[
                      (S.t('uploaded'), trFmtBytes(b.uploadedBytes)),
                      (S.t('downloaded'), trFmtBytes(b.downloadedBytes)),
                      ('Ratio', trRatioString(ratio)),
                      (S.t('runningTime'), trTimeInterval(b.secondsActive)),
                    ])
                      SizedBox(
                        width: column,
                        child: figure(label, value),
                      ),
                  ],
                );
              },
            ),
            if (started)
              Text(
                'Started ${b.sessionCount} times',
                style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
          ],
        ),
      );
    }

    return TransmissionPanel(
      key: const ValueKey<String>('statistics-panel'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TransmissionPanelTitle(S.t('statistics')),
          block(
            'This session',
            Icons.timelapse_rounded,
            stats.currentStats,
          ),
          const SizedBox(height: Insets.sm),
          block(
            'All time',
            Icons.history_rounded,
            stats.cumulativeStats,
            started: true,
          ),
        ],
      ),
    );
  }
}
