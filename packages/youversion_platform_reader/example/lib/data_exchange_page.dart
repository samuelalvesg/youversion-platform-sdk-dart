import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youversion_platform_core/youversion_platform_core.dart';

import 'l10n/example_localizations.dart';

/// Demonstrates `YouVersionDataExchangeClient`'s 3-step consent flow:
/// `createToken` → `buildApprovalUrl` → (browser) → `parseCallback`.
///
/// Same demo-only caveat as `SignInPage`: the approval callback URL is
/// fixed/registered beforehand (not passed as a parameter, unlike
/// Sign-In's `redirectUri`), and this app has no deep link of its own to
/// catch it - the user pastes the resulting URL back in manually.
class DataExchangePage extends StatefulWidget {
  const DataExchangePage({super.key, required this.dataExchange, required this.userAccessToken});

  final YouVersionDataExchangeClient dataExchange;
  final String userAccessToken;

  @override
  State<DataExchangePage> createState() => _DataExchangePageState();
}

class _DataExchangePageState extends State<DataExchangePage> {
  bool _isWorking = false;
  DataExchangeResult? _result;

  Future<void> _start() async {
    setState(() => _isWorking = true);
    final token = await widget.dataExchange.createToken(
      userAccessToken: widget.userAccessToken,
      requestedPermissions: const {'highlights'},
    );
    setState(() => _isWorking = false);
    if (!mounted) return;
    await launchUrl(widget.dataExchange.buildApprovalUrl(token), mode: LaunchMode.externalApplication);
  }

  void _submitCallbackUrl(String pastedUrl) {
    final uri = Uri.tryParse(pastedUrl.trim());
    if (uri == null) return;
    setState(() => _result = widget.dataExchange.parseCallback(uri));
  }

  @override
  Widget build(BuildContext context) {
    final strings = ExampleLocalizations.of(context);
    final result = _result;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(strings.dataExchangeIntro),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _isWorking ? null : _start,
            child: Text(strings.startDataExchangeButton),
          ),
          const SizedBox(height: 16),
          Text(strings.pasteApprovalInstructions),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(labelText: strings.redirectedUrlLabel, border: const OutlineInputBorder()),
            onSubmitted: _submitCallbackUrl,
          ),
          if (result != null) ...[
            const SizedBox(height: 16),
            Text(strings.statusLabel(result.status.toString())),
            Text(strings.grantedPermissionsLabel(result.grantedPermissions.map((p) => p.rawValue).join(', '))),
          ],
        ],
      ),
    );
  }
}
