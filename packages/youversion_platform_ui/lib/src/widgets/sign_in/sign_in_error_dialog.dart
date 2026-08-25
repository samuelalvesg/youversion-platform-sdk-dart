import 'package:flutter/material.dart';

import '../../l10n/youversion_ui_strings.dart';

/// Alert shown when the OAuth sign-in flow fails. Mirrors `platform-ui`'s
/// `signin/SignInErrorAlert.kt` (Kotlin).
///
/// Show with `showDialog(context: context, builder: (_) => SignInErrorDialog(...))`.
class SignInErrorDialog extends StatelessWidget {
  const SignInErrorDialog({super.key, this.message, this.onRetry});

  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final strings = youVersionUiStringsOf(context);
    return AlertDialog(
      title: Text(strings.signInFailedTitle),
      content: Text(message ?? strings.signInFailedMessage),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(strings.closeButton)),
        if (onRetry != null)
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry!();
            },
            child: Text(strings.tryAgainButton),
          ),
      ],
    );
  }
}
