import 'package:flutter/material.dart';

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
    return AlertDialog(
      title: const Text('Sign-in failed'),
      content: Text(message ?? 'Something went wrong while signing in with YouVersion.'),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        if (onRetry != null)
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry!();
            },
            child: const Text('Try again'),
          ),
      ],
    );
  }
}
