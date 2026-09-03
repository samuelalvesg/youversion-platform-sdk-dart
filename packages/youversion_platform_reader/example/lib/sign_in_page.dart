import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youversion_platform_core/youversion_platform_core.dart';
import 'package:youversion_platform_ui/youversion_platform_ui.dart';

import 'auth_session.dart';
import 'l10n/example_localizations.dart';
import 'platform_check.dart';

/// Demonstrates `YouVersionSignIn`'s full Authorization Code + PKCE flow,
/// plus the sign-in-related `_ui` widgets (`SignInPromptSheet`,
/// `SignInErrorDialog`, `SignOutConfirmationDialog`, `YouVersionSignInButton`).
///
/// Two sign-in flows against the same `widget.signIn` (one `redirectUri`,
/// this App Key only has the one registered - confirmed live, pointing it
/// at a second, unregistered URI silently fell back to whatever *is*
/// registered instead of erroring, so there's no "register a second one
/// just for desktop" option here):
///
/// **Desktop (Linux/macOS/Windows): automatic, via `OAuthLoopbackServer`**
/// (`_core`) - a real, no-copy-paste flow, *if* `widget.signIn.redirectUri`
/// is itself a loopback address (`http://127.0.0.1:<port>/<path>`, RFC
/// 8252 §7.3 - the desktop equivalent of a custom-scheme deep link, which
/// the OS never registers for a desktop build the way it does on
/// Android/iOS). `_startDesktopSignIn` starts an `OAuthLoopbackServer` on
/// exactly that port/path.
///
/// **Everywhere else (or if `redirectUri` isn't a loopback address):
/// paste-the-callback-URL** - this app has no deep link/App Link of its
/// own on mobile/web, so it can't automatically capture the OAuth
/// redirect there. The user copies the resulting URL straight out of the
/// browser's address bar (the `code`/`state` are plain query params,
/// visible whether or not that page actually loads - if `redirectUri`
/// isn't a real running server, it won't load, that's expected) and
/// pastes it back into this app. A real mobile/web app would register
/// its own deep link/App Link and skip this paste step entirely.
///
/// **The redirect may not have a `code` yet** (either flow) - confirmed
/// live, some App Key configurations land here with only `state`/
/// `granted_permissions` first. Both `_submitCallbackUrl` and
/// `_startDesktopSignIn` call `YouVersionSignIn.resolveCallback` in that
/// case before parsing `code` - see its doc comment.
class SignInPage extends StatefulWidget {
  const SignInPage({super.key, required this.signIn, required this.session});

  final YouVersionSignIn signIn;
  final AuthSession session;

  @override
  State<SignInPage> createState() => _SignInPageState();
}

/// Whether [redirectUri] is actually a loopback address - guards the
/// desktop auto-sign-in button from showing (and `OAuthLoopbackServer`
/// from trying to bind an unrelated port, e.g. `443` for an `https://`
/// URL) if this App Key's registered `redirectUri` ever changes back to
/// something else.
bool _isLoopbackUri(Uri redirectUri) =>
    redirectUri.scheme == 'http' && (redirectUri.host == '127.0.0.1' || redirectUri.host == 'localhost');

class _SignInPageState extends State<SignInPage> {
  PkceAuthorizationRequest? _pendingRequest;
  bool _isExchanging = false;
  bool _isAutoSigningIn = false;

  // Automatic sign-in via a temporary local HTTP server catching the
  // OAuth redirect (RFC 8252 §7.3 loopback interface redirection) -
  // desktop-only (`OAuthLoopbackServer`, `_core`, needs `dart:io`). Uses
  // `widget.signIn` directly - this App Key only has one registered
  // redirect_uri (confirmed live: pointing at a second, unregistered one
  // silently fell back to whichever *is* registered instead of erroring),
  // so it has to be the loopback address itself for this to work, and the
  // port/path below come from parsing it rather than a separate constant
  // - one source of truth for what's actually registered.
  Future<void> _startDesktopSignIn() async {
    final redirectUri = widget.signIn.redirectUri;
    final request = widget.signIn.buildAuthorizationUrl(
      permissions: const {YouVersionPermission.profile, YouVersionPermission.email, YouVersionPermission.highlights},
    );

    final OAuthLoopbackServer server;
    try {
      server = await OAuthLoopbackServer.start(port: redirectUri.port, path: redirectUri.path);
    } catch (error) {
      await _showError('$error', onRetry: _startDesktopSignIn);
      return;
    }

    setState(() => _isAutoSigningIn = true);
    try {
      await launchUrl(request.authorizationUrl, mode: LaunchMode.externalApplication);
      var uri = await server.waitForCallback();
      if (!uri.queryParameters.containsKey('code')) {
        uri = await widget.signIn.resolveCallback(uri);
      }
      final code = uri.queryParameters['code'];
      if (code == null) {
        if (mounted) await _showError(ExampleLocalizations.of(context).noCodeError, onRetry: _startDesktopSignIn);
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
    } on YouVersionException catch (e) {
      await _showError(e.message, onRetry: _startDesktopSignIn);
    } catch (error) {
      await _showError('$error', onRetry: _startDesktopSignIn);
    } finally {
      if (mounted) setState(() => _isAutoSigningIn = false);
    }
  }

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

  Future<void> _showError(String message, {VoidCallback? onRetry}) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => SignInErrorDialog(message: message, onRetry: onRetry ?? _launchAuthorization),
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
        final strings = ExampleLocalizations.of(context);
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Surfaces `AuthSession.sessionExpired` (see its own doc
              // comment) - the one case where a sign-out isn't the user's
              // own action, so it gets an explanation instead of just
              // landing on the same silent login screen.
              if (widget.session.sessionExpired)
                MaterialBanner(
                  content: Text(strings.sessionExpiredMessage),
                  leading: Icon(Icons.info_outline, color: Theme.of(context).colorScheme.error),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: strings.clearTooltip,
                      onPressed: widget.session.clearSignOutReason,
                    ),
                  ],
                ),
              identity != null
                  ? _ProfileCard(identity: identity, onSignOut: _confirmSignOut)
                  : _isAutoSigningIn
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 12),
                              Text(ExampleLocalizations.of(context).waitingForBrowserMessage),
                            ],
                          ),
                        )
                      : _pendingRequest != null
                          ? _PasteCallbackForm(isSubmitting: _isExchanging, onSubmit: _submitCallbackUrl)
                          // Only one button, not both stacked side by side -
                          // confirmed live, having the automatic and
                          // paste-flow buttons together just meant the wrong
                          // one got tapped by mistake. The automatic flow is
                          // strictly better whenever it's available (no copy-
                          // paste at all); paste-flow is only ever the
                          // fallback for when it isn't (mobile/web, or a
                          // `redirectUri` that isn't a loopback address).
                          : Center(
                              child: (isDesktopPlatform && _isLoopbackUri(widget.signIn.redirectUri))
                                  ? FilledButton(
                                      onPressed: _startDesktopSignIn,
                                      child: Text(ExampleLocalizations.of(context).autoSignInButton),
                                    )
                                  : YouVersionSignInButton(onPressed: _startSignIn),
                            ),
            ],
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
