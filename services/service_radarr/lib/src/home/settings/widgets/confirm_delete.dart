import 'package:core_models/core_models.dart';
import 'package:flutter/material.dart';

Future<bool> confirmDelete(BuildContext context, String what) async {
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(S.t('confirmDelete')),
        content: Text(S.t('deleteWhatThisCannotBeUndone1', [what])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(S.t('cancel')),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(S.t('delete')),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}
