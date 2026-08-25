import 'package:flutter/material.dart';
import 'package:youversion_platform_core/youversion_platform_core.dart';

import 'l10n/example_localizations.dart';

/// Shared error-state UI for the demo pages' `FutureBuilder`s.
///
/// Every list/detail page in this example previously left
/// `snapshot.hasError` unchecked - any request failure (confirmed live:
/// a `429` from hammering the API while testing pagination) left the
/// `CircularProgressIndicator` spinning forever instead of surfacing the
/// error, which read as "infinite loading" / a stuck screen.
///
/// Two more real bugs fixed here after the first live retest: 1) raw
/// `YouVersionException(YouVersionErrorReason.rateLimited, 429): Request
/// failed` toString() shown straight to the user - now a friendly message
/// per [YouVersionErrorReason], with the real wait time for a `429`
/// (`retryAfter`, confirmed live at 600s/10min - the button disables and
/// counts down instead of hammering the API again immediately). 2) fixed
/// content (icon+text+button, ~110px tall) forced into whatever tight
/// height the caller's layout happened to give it (a 56px `SizedBox` in
/// one case) - "RenderFlex overflowed" every time. Now scrolls internally
/// instead of overflowing, regardless of the space it's given.
class ErrorRetry extends StatefulWidget {
  const ErrorRetry({super.key, required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  State<ErrorRetry> createState() => _ErrorRetryState();
}

class _ErrorRetryState extends State<ErrorRetry> {
  Duration? _remaining;

  @override
  void initState() {
    super.initState();
    _armCountdown();
  }

  @override
  void didUpdateWidget(ErrorRetry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.error != widget.error) _armCountdown();
  }

  void _armCountdown() {
    final error = widget.error;
    _remaining = error is YouVersionException ? error.retryAfter : null;
    _tick();
  }

  void _tick() {
    final remaining = _remaining;
    if (remaining == null || remaining <= Duration.zero) return;
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _remaining = remaining - const Duration(seconds: 1));
      _tick();
    });
  }

  String _message(BuildContext context, Object error) {
    if (error is! YouVersionException) return '$error';
    final strings = ExampleLocalizations.of(context);
    return switch (error.reason) {
      YouVersionErrorReason.rateLimited => strings.rateLimitedMessage,
      YouVersionErrorReason.missingAuthentication => strings.signInRequiredMessage,
      YouVersionErrorReason.notPermitted => strings.notPermittedMessage,
      YouVersionErrorReason.invalidResponse => strings.invalidResponseMessage,
      YouVersionErrorReason.cannotDownload ||
      YouVersionErrorReason.unknown =>
        strings.requestFailedMessage('${error.statusCode ?? '-'}'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final strings = ExampleLocalizations.of(context);
    final remaining = _remaining;
    final waiting = remaining != null && remaining > Duration.zero;
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight.isFinite ? constraints.maxHeight : 0),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 32),
                    const SizedBox(height: 12),
                    Text(_message(context, widget.error), textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: waiting ? null : widget.onRetry,
                      child: Text(
                        waiting ? strings.tryAgainInSecondsButton(remaining.inSeconds) : strings.tryAgainButton,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
