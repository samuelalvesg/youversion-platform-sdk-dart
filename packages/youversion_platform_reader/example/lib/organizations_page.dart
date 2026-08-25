import 'package:flutter/material.dart';
import 'package:youversion_platform_core/youversion_platform_core.dart';

import 'error_retry.dart';
import 'l10n/example_localizations.dart';

/// `YouVersionOrganizationsClient.listOrganizations` → tap → `getOrganization`.
class OrganizationsPage extends StatefulWidget {
  const OrganizationsPage({super.key, required this.organizations});

  final YouVersionOrganizationsClient organizations;

  @override
  State<OrganizationsPage> createState() => _OrganizationsPageState();
}

class _OrganizationsPageState extends State<OrganizationsPage> {
  late Future<List<Organization>> _future = widget.organizations.listOrganizations();
  Organization? _selected;

  Future<void> _open(Organization summary) async {
    try {
      final organization = await widget.organizations.getOrganization(summary.id);
      if (mounted) setState(() => _selected = organization);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Organization>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorRetry(
            error: snapshot.error!,
            // Block body, not `setState(() => _future = ...())` - `x = y`
            // evaluates to `y`, so an arrow-body closure returns the
            // Future itself, and setState() asserts its callback must be
            // synchronous (confirmed live: "setState() callback argument
            // returned a Future").
            onRetry: () => setState(() {
              _future = widget.organizations.listOrganizations();
            }),
          );
        }
        final strings = ExampleLocalizations.of(context);
        final organizations = snapshot.data;
        if (organizations == null) return const Center(child: CircularProgressIndicator());
        if (organizations.isEmpty) {
          return Center(child: Text(strings.noOrganizationsMessage));
        }
        return Row(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: organizations.length,
                itemBuilder: (context, index) {
                  final organization = organizations[index];
                  return ListTile(
                    title: Text(organization.name ?? organization.id),
                    selected: _selected?.id == organization.id,
                    onTap: () => _open(organization),
                  );
                },
              ),
            ),
            if (_selected != null)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_selected!.name ?? _selected!.id, style: Theme.of(context).textTheme.titleLarge),
                      Text(strings.idLabel(_selected!.id)),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
