import 'package:flutter/material.dart';

import '../../l10n/youversion_ui_strings.dart';

/// Whether unsynced local highlights exist at sign-out time - changes the
/// dialog's copy to warn about losing them.
enum SignOutWarning { none, unsyncedHighlights }

/// Confirmation dialog shown before signing out. Mirrors `platform-ui`'s
/// `signin/SignOutConfirmationAlert.kt` (Kotlin), which has a distinct
/// message when there are unsynced highlights pending upload.
class SignOutConfirmationDialog extends StatelessWidget {
  const SignOutConfirmationDialog({
    super.key,
    required this.onConfirm,
    this.warning = SignOutWarning.none,
  });

  final VoidCallback onConfirm;
  final SignOutWarning warning;

  @override
  Widget build(BuildContext context) {
    final strings = youVersionUiStringsOf(context);
    final message = switch (warning) {
      SignOutWarning.none => strings.signOutNoneMessage,
      SignOutWarning.unsyncedHighlights => strings.signOutUnsyncedMessage,
    };

    return AlertDialog(
      title: Text(strings.signOutTitle),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(strings.cancelButton)),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm();
          },
          child: Text(strings.signOutButton),
        ),
      ],
    );
  }
}
