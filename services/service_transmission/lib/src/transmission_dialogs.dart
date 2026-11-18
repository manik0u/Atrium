import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

// The small dialogs the web UI has: one field and a verb each. Each owns its
// text controller as a StatefulWidget: disposing it when `showDialog`
// completes is too early, since the dialog is still animating out then.

Future<String?> showTransmissionLocationDialog(
  BuildContext context, {
  required String initial,
}) =>
    showDialog<String>(
      context: context,
      builder: (BuildContext _) => _TextDialog(
        title: S.t('setTorrentLocation'),
        label: S.t('location'),
        verb: S.t('apply'),
        helper: S.t('aPathAsTheServerSeesItTheDataIsMovedThere'),
        initial: '',
      ).withInitial(initial),
    );

Future<String?> showTransmissionRenameDialog(
  BuildContext context, {
  required String initial,
}) =>
    showDialog<String>(
      context: context,
      builder: (BuildContext _) => _TextDialog(
        title: S.t('rename'),
        label: S.t('enterNewName'),
        verb: S.t('rename'),
        initial: initial,
      ),
    );

class _TextDialog extends StatefulWidget {
  const _TextDialog({
    required this.title,
    required this.label,
    required this.verb,
    required this.initial,
    this.helper,
  });

  final String title;
  final String label;
  final String verb;
  final String initial;
  final String? helper;

  _TextDialog withInitial(String value) => _TextDialog(
        title: title,
        label: label,
        verb: verb,
        initial: value,
        helper: helper,
      );

  @override
  State<_TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends State<_TextDialog> {
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
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: widget.label,
          helperText: widget.helper,
        ),
        onSubmitted: (String v) => Navigator.of(context).pop(v.trim()),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(S.t('cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: Text(widget.verb),
        ),
      ],
    );
  }
}

/// Comma-separated, as the web UI takes them, with the instance's other
/// labels offered as chips that add themselves to the field.
Future<List<String>?> showTransmissionLabelsDialog(
  BuildContext context, {
  required List<String> initial,
  required List<String> suggestions,
}) =>
    showDialog<List<String>>(
      context: context,
      builder: (BuildContext _) =>
          _LabelsDialog(initial: initial, suggestions: suggestions),
    );

class _LabelsDialog extends StatefulWidget {
  const _LabelsDialog({required this.initial, required this.suggestions});

  final List<String> initial;
  final List<String> suggestions;

  @override
  State<_LabelsDialog> createState() => _LabelsDialogState();
}

class _LabelsDialogState extends State<_LabelsDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial.join(', '));

  static List<String> _parse(String text) => <String>[
        for (final String part in text.split(','))
          if (part.trim().isNotEmpty) part.trim(),
      ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(S.t('editLabels')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Labels',
              helperText: S.t('separateLabelsWithCommas'),
            ),
          ),
          if (widget.suggestions.isNotEmpty) ...<Widget>[
            const SizedBox(height: Insets.sm),
            Wrap(
              spacing: Insets.xs,
              children: <Widget>[
                for (final String s in widget.suggestions)
                  ActionChip(
                    label: Text(s),
                    onPressed: () {
                      final List<String> current = _parse(_controller.text);
                      if (!current.contains(s)) {
                        _controller.text = <String>[...current, s].join(', ');
                      }
                    },
                  ),
              ],
            ),
          ],
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(S.t('cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_parse(_controller.text)),
          child: Text(S.t('save')),
        ),
      ],
    );
  }
}

/// Returns whether to trash the data as well, or null when cancelled.
Future<bool?> showTransmissionRemoveDialog(
  BuildContext context, {
  required List<String> names,
  required bool trash,
}) {
  bool withData = trash;
  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) => StatefulBuilder(
      builder: (BuildContext context, StateSetter setLocal) => AlertDialog(
        title: Text(
          names.length == 1
              ? S.t('removeTorrent')
              : 'Remove ${names.length} torrents',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              names.length == 1 ? names.single : names.join('\n'),
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: Insets.md),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: withData,
              onChanged: (bool? v) => setLocal(() => withData = v ?? false),
              title: Text(S.t('alsoTrashTheDownloadedData')),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(S.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(withData),
            child: Text(S.t('remove')),
          ),
        ],
      ),
    ),
  );
}

/// The web UI's peer flag legend, letter for letter.
final List<(String, String)> transmissionPeerFlags = <(String, String)>[
  ('O', 'Optimistic unchoke'),
  ('D', S.t('downloadingFromThisPeer')),
  ('d', S.t('weWouldDownloadFromThisPeerIfTheyDLetUs')),
  ('U', 'Uploading to peer'),
  ('u', S.t('weWouldUploadToThisPeerIfTheyDAsk')),
  ('K', S.t('peerHasUnchokedUsButWeReNotInterested')),
  ('?', S.t('weUnchokedThisPeerButTheyReNotInterested')),
  ('E', 'Encrypted connection'),
  ('H', S.t('peerWasDiscoveredThroughDHT')),
  ('X', S.t('peerWasDiscoveredThroughPeerExchangePEX')),
  ('I', 'Peer is an incoming connection'),
  ('T', S.t('peerIsConnectedViaUTP')),
];

Future<void> showTransmissionPeerFlagsSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (BuildContext context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding:
              const EdgeInsets.fromLTRB(Insets.lg, 0, Insets.lg, Insets.lg),
          children: <Widget>[
            Text(S.t('peerFlags'), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: Insets.sm),
            for (final (String flag, String meaning) in transmissionPeerFlags)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Text(
                  flag,
                  style:
                      const TextStyle(fontFamily: 'monospace', fontSize: 16),
                ),
                title: Text(meaning),
              ),
          ],
        ),
      ),
    );
