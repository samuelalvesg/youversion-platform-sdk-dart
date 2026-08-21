import 'package:flutter/material.dart';

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
    final message = switch (warning) {
      SignOutWarning.none => 'You can sign back in at any time.',
      SignOutWarning.unsyncedHighlights =>
        'Some of your highlights have not finished syncing yet. '
            'They will not be saved to your account if you sign out now.',
    };

    return AlertDialog(
      title: const Text('Sign out?'),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm();
          },
          child: const Text('Sign out'),
        ),
      ],
    );
  }
}
