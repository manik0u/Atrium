import 'package:flutter/material.dart';

/// Asks the user to confirm a destructive delete before it runs.
///
/// Returns true only when the user explicitly taps Delete.
Future<bool> confirmDelete(BuildContext context, String what) async {
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Supprimer $what ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Supprimer'),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}
