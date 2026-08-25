import 'package:flutter/material.dart';

import '../../l10n/youversion_ui_strings.dart';

/// Visual density of [YouVersionSignInButton].
enum YouVersionSignInButtonMode { full, compact, iconOnly }

/// Corner style of [YouVersionSignInButton].
enum YouVersionSignInButtonShape { capsule, rectangle }

/// "Sign in with YouVersion" button.
///
/// Purely presentational - it does not call [YouVersionSignIn] itself, the
/// same core-vs-UI split already used by `youversion_platform_core` (that
/// package builds the URL, this widget just triggers [onPressed]; opening
/// the browser is the app's job via `url_launcher`).
///
/// Mirrors `platform-ui`'s `views/SignInWithYouVersionButton.kt` (Kotlin)
/// and `Views/SignInWithYouVersionButton.swift` (Swift): mode
/// full/compact/iconOnly, capsule/rectangle shape, dark/light variant.
class YouVersionSignInButton extends StatelessWidget {
  const YouVersionSignInButton({
    super.key,
    required this.onPressed,
    this.mode = YouVersionSignInButtonMode.full,
    this.shape = YouVersionSignInButtonShape.capsule,
    this.isLoading = false,
    this.dark = false,
  });

  final VoidCallback? onPressed;
  final YouVersionSignInButtonMode mode;
  final YouVersionSignInButtonShape shape;
  final bool isLoading;

  /// Uses light text/icon on a dark fill when `true` (for placement on a
  /// light background), or the inverse when `false`.
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final foreground = dark ? Colors.white : Colors.black;
    final background = dark ? Colors.black : Colors.white;
    final borderRadius = shape == YouVersionSignInButtonShape.capsule
        ? const BorderRadius.all(Radius.circular(999))
        : const BorderRadius.all(Radius.circular(8));

    final style = OutlinedButton.styleFrom(
      foregroundColor: foreground,
      backgroundColor: background,
      side: BorderSide(color: foreground.withValues(alpha: 0.15)),
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      padding: mode == YouVersionSignInButtonMode.iconOnly
          ? const EdgeInsets.all(12)
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );

    final icon = isLoading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
          )
        : Icon(Icons.menu_book_outlined, size: 18, color: foreground);

    if (mode == YouVersionSignInButtonMode.iconOnly) {
      return OutlinedButton(onPressed: isLoading ? null : onPressed, style: style, child: icon);
    }

    const brandName = 'YouVersion';
    final label = mode == YouVersionSignInButtonMode.compact
        ? brandName
        : youVersionUiStringsOf(context).signInWithYouVersionLabel(brandName);

    return OutlinedButton.icon(
      onPressed: isLoading ? null : onPressed,
      style: style,
      icon: icon,
      label: Text(label),
    );
  }
}
