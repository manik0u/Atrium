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
      builder: (BuildContext _) => const _TextDialog(
        title: "Définir l'emplacement du torrent",
        label: 'Emplacement',
        verb: 'Apply',
        helper: 'Un chemin tel que le serveur le voit. Les données y sont déplacées.',
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
        title: 'Renommer',
        label: 'Saisir un nouveau nom',
        verb: 'Rename',
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
          child: const Text('Annuler'),
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
      title: const Text('Modifier les labels'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Labels',
              helperText: 'Séparez les labels par des virgules',
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
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_parse(_controller.text)),
          child: const Text('Enregistrer'),
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
              ? 'Remove torrent'
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
              title: const Text('Mettre aussi les données téléchargées à la corbeille'),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(withData),
            child: const Text('Retirer'),
          ),
        ],
      ),
    ),
  );
}

/// The web UI's peer flag legend, letter for letter.
const List<(String, String)> transmissionPeerFlags = <(String, String)>[
  ('O', 'Optimistic unchoke'),
  ('D', 'Téléchargement depuis ce pair'),
  ('d', "Nous téléchargerions depuis ce pair s'il nous le permettait"),
  ('U', 'Uploading to peer'),
  ('u', "Nous enverrions à ce pair s'il le demandait"),
  ('K', 'Le pair nous a désétouffé, mais nous ne sommes pas intéressés'),
  ('?', "Nous avons désétouffé ce pair, mais il n'est pas intéressé"),
  ('E', 'Encrypted connection'),
  ('H', 'Pair découvert via DHT'),
  ('X', "Pair découvert via l'échange de pairs (PEX)"),
  ('I', 'Peer is an incoming connection'),
  ('T', 'Peer is connected via uTP'),
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
            Text('Drapeaux de pairs', style: Theme.of(context).textTheme.titleMedium),
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
