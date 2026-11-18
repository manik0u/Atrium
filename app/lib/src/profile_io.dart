import 'dart:convert';
import 'dart:io';

import 'package:core_models/core_models.dart';
import 'package:core_profile/core_profile.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// User-facing export and import flows for [Profile]s.
///
/// These sit between the Settings UI and `ProfileRepository`. Splitting them
/// out keeps `SettingsScreen` focused on layout - the dialogs and
/// file-picker plumbing live here.
class ProfileIo {
  ProfileIo._();

  /// Export the currently-active profile to a file the user picks.
  ///
  /// Shows a dialog with the "Include API keys & passwords" toggle (off by
  /// default - exports are safer to share when secrets are stripped) before
  /// opening the system save sheet.
  static Future<void> exportActiveProfile(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final Profile? profile = ref.read(activeProfileProvider);
    if (profile == null) {
      _snack(context, 'Aucun profil à exporter pour le moment.');
      return;
    }

    final bool? includeSecrets = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => _ExportOptionsDialog(profile: profile),
    );
    if (includeSecrets == null) {
      return;
    }

    final ProfileRepository repo = ref.read(profileRepositoryProvider);
    final String json =
        repo.exportProfile(profile, includeSecrets: includeSecrets);
    final List<int> bytes = utf8.encode(json);

    String? outputPath;
    try {
      outputPath = await FilePicker.saveFile(
        dialogTitle: 'Save Atrium profile',
        fileName: _sanitizeFileName('atrium-${profile.name}.json'),
        type: FileType.custom,
        allowedExtensions: <String>['json'],
        bytes: Uint8List.fromList(bytes),
      );
    } on PlatformException catch (e) {
      if (context.mounted) {
        _snack(context, "Impossible d'ouvrir la feuille d'enregistrement : ${e.message}");
      }
      return;
    }

    if (outputPath == null) {
      return;
    }
    if (!context.mounted) {
      return;
    }
    _snack(
      context,
      includeSecrets
          ? 'Exporté (contient des secrets - gardez ce fichier privé)'
          : 'Exported (secrets stripped)',
    );
  }

  /// Pick a previously-exported profile JSON and add it as a new profile.
  ///
  /// Validates the file parses to a [Profile] and shows a preview before
  /// committing. The repository mints fresh ids on import so existing
  /// profiles and instances are never overwritten.
  static Future<void> importProfile(
    BuildContext context,
    WidgetRef ref,
  ) async {
    FilePickerResult? picked;
    try {
      picked = await FilePicker.pickFiles(
        dialogTitle: 'Open Atrium profile',
        type: FileType.custom,
        allowedExtensions: <String>['json'],
      );
    } on PlatformException catch (e) {
      if (context.mounted) {
        _snack(context, "Impossible d'ouvrir le sélecteur de fichiers : ${e.message}");
      }
      return;
    }
    if (picked == null || picked.files.isEmpty) {
      return;
    }

    final PlatformFile file = picked.files.single;
    final String? json = await _readPlatformFile(file);
    if (json == null) {
      if (context.mounted) {
        _snack(context, 'Impossible de lire le fichier.');
      }
      return;
    }

    Profile preview;
    try {
      preview = Profile.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      if (context.mounted) {
        _snack(context, 'Fichier de profil Atrium invalide.');
      }
      return;
    }

    if (!context.mounted) {
      return;
    }
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => _ImportConfirmDialog(profile: preview),
    );
    if (confirmed != true) {
      return;
    }

    final ProfileListController controller =
        ref.read(profileListProvider.notifier);
    final Profile created = await controller.importProfile(json);
    if (!context.mounted) {
      return;
    }
    _snack(
      context,
      'Imported "${created.name}" - ${created.instances.length} '
      '${created.instances.length == 1 ? 'instance' : 'instances'}',
    );
  }

  static Future<String?> _readPlatformFile(PlatformFile file) async {
    try {
      final Uint8List bytes = await file.readAsBytes();
      return utf8.decode(bytes);
    } catch (_) {
      if (file.path != null) {
        try {
          return await File(file.path!).readAsString();
        } on FileSystemException {
          return null;
        }
      }
    }
    return null;
  }

  static String _sanitizeFileName(String s) =>
      s.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');

  static void _snack(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

class _ExportOptionsDialog extends StatefulWidget {
  const _ExportOptionsDialog({required this.profile});

  final Profile profile;

  @override
  State<_ExportOptionsDialog> createState() => _ExportOptionsDialogState();
}

class _ExportOptionsDialogState extends State<_ExportOptionsDialog> {
  bool _includeSecrets = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int n = widget.profile.instances.length;
    return AlertDialog(
      title: const Text('Exporter le profil'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
              '"${widget.profile.name}" - $n ${n == 1 ? 'instance' : 'instances'}'),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Inclure les clés API et mots de passe'),
            subtitle: Text(
              _includeSecrets
                  ? 'Toute personne ayant ce fichier peut se connecter à vos serveurs.'
                  : 'Recommandé - les identifiants sont masqués.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: _includeSecrets ? theme.colorScheme.error : null,
              ),
            ),
            value: _includeSecrets,
            onChanged: (bool v) => setState(() => _includeSecrets = v),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_includeSecrets),
          child: const Text('Exporter'),
        ),
      ],
    );
  }
}

class _ImportConfirmDialog extends StatelessWidget {
  const _ImportConfirmDialog({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final int n = profile.instances.length;
    return AlertDialog(
      title: const Text('Importer un profil'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Profil : ${profile.name}'),
          Text('Instances : $n'),
          const SizedBox(height: 12),
          Text(
            'Un nouveau profil sera ajouté - vos profils existants ne sont pas '
            'touched. Instances arrive with their credentials only if the '
            'export included them.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Importer'),
        ),
      ],
    );
  }
}
