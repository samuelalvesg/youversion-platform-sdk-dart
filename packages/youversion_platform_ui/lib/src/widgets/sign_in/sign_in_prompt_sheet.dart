import 'package:flutter/material.dart';

import 'youversion_sign_in_button.dart';

/// Bottom sheet explaining why sign-in is being requested, before opening
/// the OAuth flow. Mirrors `platform-ui`'s
/// `views/SignInWithYouVersionPromptSheet.kt` (Kotlin).
///
/// Content is fully caller-supplied (no global config lookup) - show it
/// with [showModalBottomSheet].
class SignInPromptSheet extends StatelessWidget {
  const SignInPromptSheet({
    super.key,
    required this.appName,
    required this.message,
    required this.onConfirm,
    this.onDismiss,
  });

  final String appName;
  final String message;
  final VoidCallback onConfirm;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(appName, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(message, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 20),
            YouVersionSignInButton(onPressed: onConfirm),
            if (onDismiss != null) ...[
              const SizedBox(height: 8),
              TextButton(onPressed: onDismiss, child: const Text('Not now')),
            ],
          ],
        ),
      ),
    );
  }
}
