import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youversion_platform_core/youversion_platform_core.dart';
import 'package:youversion_platform_ui/youversion_platform_ui.dart';

import 'auth_session.dart';
import 'l10n/example_localizations.dart';

/// Demonstrates `YouVersionSignIn`'s full Authorization Code + PKCE flow,
/// plus the sign-in-related `_ui` widgets (`SignInPromptSheet`,
/// `SignInErrorDialog`, `SignOutConfirmationDialog`, `YouVersionSignInButton`).
///
/// **Demo-only redirect handling**: this app has no deep link/App Link of
/// its own, so it can't automatically capture the OAuth redirect. It uses
/// the App Key's real registered `redirectUri`
/// (`https://api.symmetris.com.br/api/oauth/youversion/callback` - another
/// app's production backend, unrelated to this SDK) purely so
/// `/auth/authorize` accepts the request; after the browser redirects
/// there, the user copies the resulting URL straight out of the address
/// bar (the `code`/`state` are plain query params, visible whether or not
/// that page actually loads) and pastes it back into this app. This
/// example never calls that backend - it only ever reads the URL string
/// the browser itself shows. A real app would register its own
/// deep link/App Link and skip this paste step entirely.
///
/// **The pasted URL may not have a `code` yet** - confirmed live, some App
/// Key configurations land here with only `state`/`granted_permissions`
/// first. `_submitCallbackUrl` calls `YouVersionSignIn.resolveCallback` in
/// that case before parsing `code` - see its doc comment.
class SignInPage extends StatefulWidget {
  const SignInPage({super.key, required this.signIn, required this.session});

  final YouVersionSignIn signIn;
  final AuthSession session;

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  PkceAuthorizationRequest? _pendingRequest;
  bool _isExchanging = false;

  Future<void> _startSignIn() async {
    final strings = ExampleLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      builder: (_) => SignInPromptSheet(
        appName: 'YouVersion SDK Example',
        message: strings.signInPromptMessage,
        onConfirm: () {
          Navigator.pop(context);
          _launchAuthorization();
        },
      ),
    );
  }

  Future<void> _launchAuthorization() async {
    final request = widget.signIn.buildAuthorizationUrl(
      permissions: const {YouVersionPermission.profile, YouVersionPermission.email, YouVersionPermission.highlights},
    );
    setState(() => _pendingRequest = request);
    await launchUrl(request.authorizationUrl, mode: LaunchMode.externalApplication);
  }

  Future<void> _submitCallbackUrl(String pastedUrl) async {
    final request = _pendingRequest;
    if (request == null) return;
    var uri = Uri.tryParse(pastedUrl.trim());
    if (uri == null) {
      await _showError(ExampleLocalizations.of(context).invalidUrlError);
      return;
    }

    setState(() => _isExchanging = true);
    try {
      // Some App Key configurations redirect here with only `state`/
      // `granted_permissions` first, no `code` yet - resolve the extra
      // `/auth/callback` hop to get the real one. See
      // `YouVersionSignIn.resolveCallback`'s doc comment.
      if (!uri.queryParameters.containsKey('code')) {
        uri = await widget.signIn.resolveCallback(uri);
      }
      final code = uri.queryParameters['code'];
      if (code == null) {
        if (mounted) await _showError(ExampleLocalizations.of(context).noCodeError);
        return;
      }

      final token = await widget.signIn.exchangeCode(
        code: code,
        codeVerifier: request.codeVerifier,
        receivedState: uri.queryParameters['state'],
        expectedState: request.state,
        expectedNonce: request.nonce,
        grantedPermissions: YouVersionSignIn.parseGrantedPermissions(uri),
      );
      await widget.session.signIn(token);
      if (mounted) setState(() => _pendingRequest = null);
    } on YouVersionException catch (e) {
      await _showError(e.message);
    } catch (error) {
      await _showError('$error');
    } finally {
      if (mounted) setState(() => _isExchanging = false);
    }
  }

  Future<void> _showError(String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => SignInErrorDialog(message: message, onRetry: _launchAuthorization),
    );
  }

  Future<void> _confirmSignOut() async {
    await showDialog<void>(
      context: context,
      builder: (_) => SignOutConfirmationDialog(
        onConfirm: () {
          Navigator.pop(context);
          widget.session.signOut();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) {
        final identity = widget.session.identity;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: identity != null
              ? _ProfileCard(identity: identity, onSignOut: _confirmSignOut)
              : _pendingRequest != null
                  ? _PasteCallbackForm(isSubmitting: _isExchanging, onSubmit: _submitCallbackUrl)
                  : Center(
                      child: YouVersionSignInButton(onPressed: _startSignIn),
                    ),
        );
      },
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.identity, required this.onSignOut});

  final YouVersionIdentity identity;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Confirmed live: the server can send "" (empty string), not just a
        // missing field, for users without a profile picture - NetworkImage("")
        // throws "No host specified in URI" repeatedly on every frame.
        if (identity.profilePicture != null && identity.profilePicture!.isNotEmpty)
          CircleAvatar(backgroundImage: NetworkImage(identity.profilePicture!)),
        const SizedBox(height: 12),
        Text(identity.name ?? identity.sub, style: Theme.of(context).textTheme.titleLarge),
        if (identity.email != null) Text(identity.email!),
        const SizedBox(height: 16),
        FilledButton(onPressed: onSignOut, child: Text(ExampleLocalizations.of(context).signOutButton)),
      ],
    );
  }
}

class _PasteCallbackForm extends StatefulWidget {
  const _PasteCallbackForm({required this.isSubmitting, required this.onSubmit});

  final bool isSubmitting;
  final ValueChanged<String> onSubmit;

  @override
  State<_PasteCallbackForm> createState() => _PasteCallbackFormState();
}

class _PasteCallbackFormState extends State<_PasteCallbackForm> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ExampleLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(strings.pasteCallbackInstructions),
        const SizedBox(height: 12),
        TextField(
          controller: _controller,
          decoration: InputDecoration(labelText: strings.redirectedUrlLabel, border: const OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: widget.isSubmitting ? null : () => widget.onSubmit(_controller.text),
          child: widget.isSubmitting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(strings.completeSignInButton),
        ),
      ],
    );
  }
}
