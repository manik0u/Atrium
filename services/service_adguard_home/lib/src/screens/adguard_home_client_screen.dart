import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progress_indicator_m3e/progress_indicator_m3e.dart';

import '../adguard_home_client_edit.dart';
import '../adguard_home_errors.dart';
import '../adguard_home_filter_rules.dart';
import '../adguard_home_format.dart';
import '../adguard_home_providers.dart';
import '../models/adguard_home_clients.dart';
import '../models/adguard_home_filters.dart';
import '../models/adguard_home_services.dart';
import '../widgets/adguard_home_failure_dialog.dart';
import '../widgets/adguard_home_fields.dart';
import '../widgets/adguard_home_schedule_editor.dart';
import 'adguard_home_services_screen.dart';

/// What became of the client a form was opened for.
enum AdguardHomeClientOutcome { saved, deleted }

/// Opens the form for [client], or for a new client when there is none. A
/// new one can start with a [name] and one identifier, [id], filled in.
///
/// The answer is what was done: null when the form was left with nothing
/// written. [supportedTags] are the tags the server offers.
Future<AdguardHomeClientOutcome?> adguardHomeEditClient(
  BuildContext context, {
  required Instance instance,
  required List<String> supportedTags,
  AdguardHomeClient? client,
  String name = '',
  String id = '',
}) =>
    pushScreen<AdguardHomeClientOutcome>(
      context,
      AdguardHomeClientScreen(
        instance: instance,
        supportedTags: supportedTags,
        client: client,
        name: name,
        id: id,
      ),
    );

/// The form for one persistent client: everything the web UI's form has but
/// the pause schedule, on one page.
class AdguardHomeClientScreen extends ConsumerWidget {
  const AdguardHomeClientScreen({
    required this.instance,
    required this.supportedTags,
    this.client,
    this.name = '',
    this.id = '',
    super.key,
  });

  final Instance instance;
  final List<String> supportedTags;

  /// The client to change. Null for a new one.
  final AdguardHomeClient? client;

  /// What a new client starts with.
  final String name;
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AdguardHomeClient? client = this.client;
    if (client != null) {
      return _ClientForm(
        instance: instance,
        supportedTags: supportedTags,
        client: client,
        before: AdguardHomeClientDraft.of(client),
      );
    }

    // A new client starts from the server's own safe search, as in the web
    // UI. Without it the per-engine switches would have nothing to show.
    final AsyncValue<AdguardHomeSafeSearch> safeSearch =
        ref.watch(adguardHomeSafeSearchProvider(instance));
    return safeSearch.when(
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
      loading: () => Scaffold(
        appBar: AppBar(title: Text(S.t('newClient'))),
        body: const Center(child: ExpressiveProgressIndicator()),
      ),
      error: (Object error, StackTrace _) => Scaffold(
        appBar: AppBar(title: Text(S.t('newClient'))),
        body: SingleChildScrollView(
          child: ErrorView(
            message: describeAdguardHomeError(error),
            // After a refused sign-in this sends nothing.
            onRetry: () =>
                ref.invalidate(adguardHomeSafeSearchProvider(instance)),
          ),
        ),
      ),
      data: (AdguardHomeSafeSearch safeSearch) => _ClientForm(
        instance: instance,
        supportedTags: supportedTags,
        before: AdguardHomeClientDraft.blank(
          safeSearch: safeSearch,
          name: name,
          ids: <String>[id],
        ),
      ),
    );
  }
}

class _ClientForm extends ConsumerStatefulWidget {
  const _ClientForm({
    required this.instance,
    required this.supportedTags,
    required this.before,
    this.client,
  });

  final Instance instance;
  final List<String> supportedTags;

  /// What the form starts with.
  final AdguardHomeClientDraft before;
  final AdguardHomeClient? client;

  @override
  ConsumerState<_ClientForm> createState() => _ClientFormState();
}

class _ClientFormState extends ConsumerState<_ClientForm> {
  /// What the form started with. A write changes only what differs from it.
  late final AdguardHomeClientDraft _before = widget.before;

  /// The settings that are not text. The text is in the controllers.
  late AdguardHomeClientDraft _settings = widget.before;

  late final TextEditingController _name =
      TextEditingController(text: _before.name);
  late final List<TextEditingController> _ids = <TextEditingController>[
    for (final String id in _before.ids) TextEditingController(text: id),
  ];
  late final TextEditingController _upstreams =
      TextEditingController(text: _before.upstreams);
  late final TextEditingController _cacheSize =
      TextEditingController(text: _before.upstreamsCacheSize);

  final GlobalKey _nameKey = GlobalKey();
  final GlobalKey _idsKey = GlobalKey();
  final GlobalKey _cacheKey = GlobalKey();

  /// Whether something is being written. Nothing else can be started then.
  bool _busy = false;

  /// Whether Delete is asking first.
  bool _confirming = false;

  /// Whether Save has been asked for once. Until then an empty field is not
  /// complained about: the form opens with several.
  bool _checked = false;

  Instance get _instance => widget.instance;

  /// The name the client has on the server. Null for a new one.
  String? get _originalName => widget.client?.name;

  @override
  void dispose() {
    _name.dispose();
    for (final TextEditingController id in _ids) {
      id.dispose();
    }
    _upstreams.dispose();
    _cacheSize.dispose();
    super.dispose();
  }

  /// Everything the form holds now.
  AdguardHomeClientDraft get _draft => _settings.copyWith(
        name: _name.text,
        ids: <String>[for (final TextEditingController id in _ids) id.text],
        upstreams: _upstreams.text,
        upstreamsCacheSize: _cacheSize.text,
      );

  bool get _changed =>
      !adguardHomeJsonEquals(_before.toJson(), _draft.toJson());

  void _set(AdguardHomeClientDraft settings) =>
      setState(() => _settings = settings);

  /// The complaints and the question on leaving follow the text.
  void _typed(String _) => setState(() {});

  void _addId() => setState(() => _ids.add(TextEditingController()));

  void _removeId(int row) {
    final TextEditingController removed = _ids.removeAt(row);
    setState(() {});
    // After the frame that no longer shows its field.
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      removed.dispose();
    });
  }

  void _toggleTag(String tag, {required bool on}) => _set(
        _settings.copyWith(
          tags: <String>[
            for (final String own in _settings.tags)
              if (own != tag) own,
            if (on) tag,
          ],
        ),
      );

  Future<void> _pickServices() async {
    final String name = _name.text.trim();
    final Set<String>? picked = await pushScreen<Set<String>>(
      context,
      AdguardHomeServicesScreen(
        instance: _instance,
        title: name.isEmpty ? S.t('blockedServices') : S.t('blockedForName1', [name]),
        selected: _settings.blockedServices.toSet(),
      ),
    );
    if (picked == null || !mounted) return;
    // The picker has read the catalogue by now, and it is kept.
    final AdguardHomeServiceCatalogue? catalogue =
        ref.read(adguardHomeServicesProvider(_instance)).value;
    final List<String> kept = <String>[
      for (final String id in _settings.blockedServices)
        if (picked.contains(id)) id,
    ];
    final List<String> added = <String>[
      // In the catalogue's order, where it is known.
      if (catalogue != null)
        for (final AdguardHomeBlockedService service in catalogue.services)
          if (picked.contains(service.id) && !kept.contains(service.id))
            service.id,
    ];
    _set(
      _settings.copyWith(
        blockedServices: <String>[
          ...kept,
          ...added,
          for (final String id in picked)
            if (!kept.contains(id) && !added.contains(id)) id,
        ],
      ),
    );
  }

  /// After a refused sign-in, lets one more request out.
  void _retrySignIn() =>
      ref.read(adguardHomeActionsProvider(_instance)).retrySignIn();

  /// Brings the first field that will not do into view.
  void _showProblem(AdguardHomeClientProblems problems) {
    final GlobalKey key = problems.name != null
        ? _nameKey
        : problems.ids != null
            ? _idsKey
            : _cacheKey;
    final BuildContext? field = key.currentContext;
    if (field == null) return;
    Scrollable.ensureVisible(
      field,
      alignment: 0.1,
      duration: const Duration(milliseconds: 200),
    );
  }

  /// Saves the form. [updateRules] is the answer, once given, to whether
  /// the custom rules that name a renamed client follow the rename.
  Future<void> _save({bool? updateRules}) async {
    if (_busy) return;
    final AdguardHomeClientDraft draft = _draft;
    final AdguardHomeClientProblems problems = draft.problems;
    if (problems.any) {
      setState(() => _checked = true);
      _showProblem(problems);
      return;
    }
    final String? originalName = _originalName;
    // Nothing to write. A new client always has something.
    if (originalName != null && !_changed) {
      Navigator.of(context).pop();
      return;
    }

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final ModalRoute<Object?>? form = ModalRoute.of(context);
    final String name = draft.name.trim();
    setState(() => _busy = true);
    bool rename = updateRules ?? false;
    if (updateRules == null && originalName != null && name != originalName) {
      final bool? answer = await _askAboutRules(originalName, name);
      if (!mounted) return;
      if (answer == null) {
        setState(() => _busy = false);
        return;
      }
      rename = answer;
    }
    try {
      await ref.read(adguardHomeActionsProvider(_instance)).saveClient(
            originalName: originalName,
            before: _before,
            after: draft,
          );
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      final bool again = await showAdguardHomeFailure(
        context,
        title: S.t('notSaved'),
        error: error,
      );
      if (again && mounted) {
        _retrySignIn();
        await _save(updateRules: rename);
      }
      return;
    }
    String message =
        'Client "$name" ${originalName == null ? 'added' : 'saved'}';
    if (rename && originalName != null) {
      try {
        final int rules = await ref
            .read(adguardHomeActionsProvider(_instance))
            .renameClientInRules(originalName, name);
        if (rules == 1) message = S.t('message1CustomRuleNowNamesIt1', [message]);
        if (rules > 1) message = S.t('messageRulesCustomRulesNowNameIt2', [message, rules]);
      } on Object catch (error) {
        message = S.t('messageButTheCustomRulesThatNameItCouldNotBe1', [message]) +
            'updated: ${describeAdguardHomeError(error)}';
      }
    }
    if (!mounted) return;
    _close(form, AdguardHomeClientOutcome.saved);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Asks whether the custom rules that name the client as [from] should
  /// name it as [to] once it is renamed: left alone, they apply to no one.
  /// True to change them, false to leave them, null to not save at all.
  /// With no such rules, or none readable, nothing is asked and they are
  /// left alone.
  Future<bool?> _askAboutRules(String from, String to) async {
    int rules;
    try {
      rules = adguardHomeRulesNamingClient(
        (await ref.read(adguardHomeFilteringProvider(_instance).future))
            .userRules,
        from,
      );
    } on Object {
      return false;
    }
    if (rules == 0 || !mounted) return false;
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(S.t('updateTheCustomRules')),
        content: Text(
          '${rules == 1 ? '1 custom rule names' : '$rules custom rules name'} '
          'this client "$from". Renamed, it is no longer covered by '
          '${rules == 1 ? 'that rule' : 'them'} unless '
          '${rules == 1 ? 'it names' : 'they name'} "$to" instead.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(S.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(S.t('leaveThem')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(S.t('updateThem')),
          ),
        ],
      ),
    );
  }

  Future<void> _delete() async {
    final String? name = _originalName;
    if (_busy || _confirming || name == null) return;
    // The rules are read before the question is asked: a second tap
    // meanwhile would ask it twice.
    _confirming = true;
    // Rules written for this client alone name it, and would apply to no
    // one once it is gone. When the rules cannot be read, the question is
    // asked without that part rather than not at all.
    int rules = 0;
    try {
      rules = adguardHomeRulesNamingClient(
        (await ref.read(adguardHomeFilteringProvider(_instance).future))
            .userRules,
        name,
      );
    } on Object {
      rules = 0;
    }
    if (!mounted) return;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(S.t('deleteName1', [name])),
        content: Text(
          'Its settings are removed. The device itself is not shut out: ' +
          S.t('adguardHomeGoesOnAnsweringItWithTheGlobalSettings')
          '${switch (rules) {
            0 => '',
            1 => S.t('k1CustomRuleNamesItAndWillNoLongerApply'),
            _ => S.t('rulesCustomRulesNameItAndWillNoLongerApply1', [rules]),
          }}',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(S.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(S.t('delete')),
          ),
        ],
      ),
    );
    _confirming = false;
    if (confirmed != true || !mounted || _busy) return;

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final ModalRoute<Object?>? form = ModalRoute.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(adguardHomeActionsProvider(_instance)).deleteClient(name);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      final bool again = await showAdguardHomeFailure(
        context,
        title: S.t('notDeleted'),
        error: error,
      );
      if (again && mounted) {
        _retrySignIn();
        await _delete();
      }
      return;
    }
    if (!mounted) return;
    _close(form, AdguardHomeClientOutcome.deleted);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(S.t('clientNameDeleted1', [name]))));
  }

  /// Closes the form once its client was written, handing back [outcome].
  ///
  /// [form] is the form's own route, taken before the write was awaited.
  /// "The route on top" will not do: by the time the server has answered,
  /// something else may stand over the form, and popping that with a
  /// client's outcome leaves both it and the form stuck. Whatever is over
  /// the form goes first, then the form.
  void _close(ModalRoute<Object?>? form, AdguardHomeClientOutcome outcome) {
    if (form == null || !form.isActive) return;
    Navigator.of(context)
      ..popUntil((Route<Object?> route) => route == form)
      ..pop(outcome);
  }

  /// Asked when the form is left with something changed.
  Future<void> _leave() async {
    final bool? discard = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(S.t('discardChanges')),
        content: Text(S.t('whatWasChangedHereHasNotBeenSaved')),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(S.t('keepEditing')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(S.t('discard')),
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final AdguardHomeClient? client = widget.client;
    final AdguardHomeClientDraft settings = _settings;
    final AdguardHomeClientProblems problems = _checked
        ? _draft.problems
        : const AdguardHomeClientProblems();
    // Only wanted for the names of what is blocked. A client that blocks
    // nothing of its own does not cost the few hundred kilobytes of it.
    final AdguardHomeServiceCatalogue? catalogue =
        settings.blockedServices.isEmpty
            ? null
            : ref.watch(adguardHomeServicesProvider(_instance)).value;
    final bool ownSettings = !settings.useGlobalSettings;
    final bool ownServices = !settings.useGlobalBlockedServices;
    final TextStyle? note =
        theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant);
    final List<String> tags = <String>[
      ...widget.supportedTags,
      // One it has that the server no longer offers, so it can be taken off.
      for (final String tag in _before.tags)
        if (!widget.supportedTags.contains(tag)) tag,
    ];

    return PopScope<Object?>(
      canPop: !_busy && !_changed,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        // While something is being written the form stays.
        if (didPop || _busy) return;
        _leave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(client == null ? S.t('newClient') : S.t('editClient')),
          actions: <Widget>[
            if (client != null)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: S.t('deleteClient'),
                onPressed: _busy ? null : _delete,
              ),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: Text(S.t('save')),
            ),
            const SizedBox(width: Insets.md),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: _busy
                ? const LinearProgressIndicatorM3E(
                    size: LinearProgressM3ESize.s,
                    shape: ProgressM3EShape.flat,
                  )
                : const SizedBox(height: 4),
          ),
        ),
        // Nothing in the form can be touched while it is being written:
        // what was changed now would not be in what was sent, and a screen
        // opened now would stand over a form that is about to close.
        body: AbsorbPointer(
          absorbing: _busy,
          // The whole form is built, not only what is on screen. Save can
          // complain about a field at the other end of it, and has to be
          // able to bring that field into view.
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: Insets.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _Inset(
                  key: _nameKey,
                  top: Insets.lg,
                  child: TextField(
                    key: const Key('adguard-client-name'),
                    controller: _name,
                    onChanged: _typed,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: S.t('name'),
                      border: const OutlineInputBorder(),
                      errorText: problems.name,
                      errorMaxLines: 3,
                    ),
                  ),
                ),
                _Inset(
                  key: _idsKey,
                  child: AdguardHomeHeading(S.t('identifiers')),
                ),
                _Inset(
                  top: Insets.xs,
                  child: Text(
                    'An IP address, a range such as 192.168.1.0/24, a MAC '
                    'address, or a ClientID.',
                    style: note,
                  ),
                ),
                for (int row = 0; row < _ids.length; row++)
                  _Inset(
                    top: Insets.sm,
                    child: TextField(
                      key: Key('adguard-client-id-$row'),
                      controller: _ids[row],
                      onChanged: _typed,
                      autocorrect: false,
                      enableSuggestions: false,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        hintText: S.t('identifier'),
                        border: const OutlineInputBorder(),
                        isDense: true,
                        errorText: row == 0 ? problems.ids : null,
                        errorMaxLines: 3,
                        suffixIcon: _ids.length < 2
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                tooltip: S.t('removeIdentifier'),
                                onPressed: () => _removeId(row),
                              ),
                      ),
                    ),
                  ),
                _Inset(
                  top: Insets.xs,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _addId,
                      icon: const Icon(Icons.add),
                      label: Text(S.t('addIdentifier')),
                    ),
                  ),
                ),
                _Inset(child: AdguardHomeHeading(S.t('protection'))),
                SwitchListTile(
                  title: Text(S.t('useGlobalSettings')),
                  subtitle: Text(S.t('theSettingsOfTheServerApply')),
                  value: settings.useGlobalSettings,
                  onChanged: (bool on) =>
                      _set(settings.copyWith(useGlobalSettings: on)),
                ),
                SwitchListTile(
                  title: Text(
                    S.t('blockDomainsUsingFiltersAndHostsFiles'),
                  ),
                  value: settings.filteringEnabled,
                  onChanged: ownSettings
                      ? (bool on) =>
                          _set(settings.copyWith(filteringEnabled: on))
                      : null,
                ),
                SwitchListTile(
                  title: Text(S.t('browsingSecurity')),
                  subtitle: Text(S.t('blocksMalwareAndPhishingDomains')),
                  value: settings.safeBrowsingEnabled,
                  onChanged: ownSettings
                      ? (bool on) =>
                          _set(settings.copyWith(safeBrowsingEnabled: on))
                      : null,
                ),
                SwitchListTile(
                  title: Text(S.t('parentalControl')),
                  subtitle: Text(S.t('blocksAdultWebsites')),
                  value: settings.parentalEnabled,
                  onChanged: ownSettings
                      ? (bool on) =>
                          _set(settings.copyWith(parentalEnabled: on))
                      : null,
                ),
                SwitchListTile(
                  title: Text(S.t('safeSearch')),
                  subtitle: Text(S.t('hidesExplicitResultsOnTheSearch') +
                      'engines below'),
                  value: settings.safeSearch.enabled,
                  onChanged: ownSettings
                      ? (bool on) => _set(
                            settings.copyWith(
                              safeSearch:
                                  settings.safeSearch.copyWith(enabled: on),
                            ),
                          )
                      : null,
                ),
                for (final MapEntry<String, bool> engine
                    in settings.safeSearch.engines.entries)
                  SwitchListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.only(
                      left: Insets.xl,
                      right: Insets.lg,
                    ),
                    title: Text(adguardHomeSearchEngineLabel(engine.key)),
                    value: engine.value,
                    onChanged: ownSettings && settings.safeSearch.enabled
                        ? (bool on) => _set(
                              settings.copyWith(
                                safeSearch: settings.safeSearch
                                    .withEngine(engine.key, on: on),
                              ),
                            )
                        : null,
                  ),
                _Inset(child: AdguardHomeHeading(S.t('blockedServices'))),
                SwitchListTile(
                  title: Text(S.t('useGlobalBlockedServices')),
                  subtitle: Text(S.t('theListOfTheServerApplies')),
                  value: settings.useGlobalBlockedServices,
                  onChanged: (bool on) =>
                      _set(settings.copyWith(useGlobalBlockedServices: on)),
                ),
                ListTile(
                  enabled: ownServices,
                  title: Text(S.t('blockedForThisClient')),
                  subtitle: Text(
                    settings.blockedServices.isEmpty
                        ? 'None'
                        : <String>[
                            for (final String id in settings.blockedServices)
                              catalogue?.nameOf(id) ?? id,
                          ].join(', '),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _pickServices,
                ),
                // Its own schedule applies only to its own services. On the
                // global list, the server's schedule applies instead.
                if (ownServices) ...<Widget>[
                  _Inset(
                    top: Insets.sm,
                    child: Text(
                      S.t('pauseScheduleWhilePausedTheServicesBlockedFor') +
                      'this client are let through.',
                      style: note,
                    ),
                  ),
                  AdguardHomeScheduleEditor(
                    schedule: settings.schedule,
                    enabled: !_busy,
                    onChanged: (AdguardHomeSchedule next) =>
                        _set(settings.copyWith(schedule: next)),
                  ),
                ],
                _Inset(child: AdguardHomeHeading(S.t('upstreamDNSServers'))),
                _Inset(
                  top: Insets.sm,
                  child: TextField(
                    key: const Key('adguard-client-upstreams'),
                    controller: _upstreams,
                    onChanged: _typed,
                    autocorrect: false,
                    enableSuggestions: false,
                    keyboardType: TextInputType.multiline,
                    minLines: 3,
                    maxLines: 8,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontFamily: 'monospace'),
                    decoration: InputDecoration(
                      hintText: S.t('oneServerPerLine'),
                      helperText: S.t('leaveEmptyToUseTheServersOfTheDNSSettings'),
                      helperMaxLines: 3,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SwitchListTile(
                  title: Text(S.t('cacheTheAnswersOfTheseServers')),
                  value: settings.upstreamsCacheEnabled,
                  onChanged: (bool on) =>
                      _set(settings.copyWith(upstreamsCacheEnabled: on)),
                ),
                _Inset(
                  key: _cacheKey,
                  top: Insets.xs,
                  child: TextField(
                    key: const Key('adguard-client-cache-size'),
                    controller: _cacheSize,
                    onChanged: _typed,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      labelText: S.t('cacheSizeInBytes'),
                      border: const OutlineInputBorder(),
                      errorText: problems.cacheSize,
                      // The longest complaint, with the bound in it, is wider
                      // than the field at a large text size.
                      errorMaxLines: 3,
                    ),
                  ),
                ),
                _Inset(
                  child: AdguardHomeHeading(S.t('queryLogAndStatistics')),
                ),
                SwitchListTile(
                  title: Text(S.t('ignoreInTheQueryLog')),
                  subtitle: Text(
                    S.t('itsQueriesAreNotWrittenToTheLog'),
                  ),
                  value: settings.ignoreQueryLog,
                  onChanged: (bool on) =>
                      _set(settings.copyWith(ignoreQueryLog: on)),
                ),
                SwitchListTile(
                  title: Text(S.t('ignoreInStatistics')),
                  subtitle: Text(S.t('itsQueriesAreNotCounted')),
                  value: settings.ignoreStatistics,
                  onChanged: (bool on) =>
                      _set(settings.copyWith(ignoreStatistics: on)),
                ),
                // Last: there are some twenty of them, they are the least used
                // part of a client, and anywhere higher they would stand
                // between the identifiers and the settings on every visit.
                _Inset(child: AdguardHomeHeading(S.t('tags'))),
                _Inset(
                  top: Insets.xs,
                  child: Text(
                    S.t('aFilteringRuleCanBeWrittenForATagInsteadOfA') +
                    'client.',
                    style: note,
                  ),
                ),
                _Inset(
                  top: Insets.sm,
                  child: Wrap(
                    spacing: Insets.sm,
                    runSpacing: Insets.xs,
                    children: <Widget>[
                      for (final String tag in tags)
                        FilterChip(
                          label: Text(tag),
                          selected: settings.tags.contains(tag),
                          onSelected: (bool on) => _toggleTag(tag, on: on),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A child of the form that is not a list tile, set in from the sides as
/// the tiles are.
class _Inset extends StatelessWidget {
  const _Inset({required this.child, this.top = 0, super.key});

  final Widget child;
  final double top;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(Insets.lg, top, Insets.lg, 0),
        child: child,
      );
}
