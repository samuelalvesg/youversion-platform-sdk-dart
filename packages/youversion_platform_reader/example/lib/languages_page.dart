import 'package:flutter/material.dart';
import 'package:youversion_platform_core/youversion_platform_core.dart';

import 'country_dropdown.dart';
import 'error_retry.dart';
import 'l10n/example_localizations.dart';

/// `YouVersionLanguagesClient.listLanguages` → tap → `getLanguage`.
///
/// **Real incremental pagination, not "load every page up front"**:
/// confirmed live, `total_size` for this endpoint is 8583 - even at the
/// API's max `page_size` (99), that's ~87 sequential requests. An earlier
/// version of this page tried to `await` every page in a loop before
/// showing anything, which either looked like infinite loading (each
/// request takes time, and 87 of them add up) or tripped the API's burst
/// rate limit outright. This loads one page at a time, appending on
/// "Load more" - `next_page_token` is exactly what it's for.
///
/// **`country` is the only server-side filter this endpoint has** -
/// confirmed against both `platform-sdk-kotlin`'s `LanguagesEndpoints.kt`
/// and `platform-sdk-react`'s `languages.ts` (neither exposes anything
/// else, e.g. no free-text search param). Filtering by country cuts the
/// list dramatically - confirmed live, `country=BR` drops `total_size`
/// from 8583 to 55.
class LanguagesPage extends StatefulWidget {
  const LanguagesPage({super.key, required this.languages});

  final YouVersionLanguagesClient languages;

  @override
  State<LanguagesPage> createState() => _LanguagesPageState();
}

class _LanguagesPageState extends State<LanguagesPage> {
  final List<Language> _loaded = [];
  String? _appliedCountry;
  String? _nextPageToken;
  bool _isLoadingFirstPage = true;
  bool _isLoadingMore = false;
  Object? _error;
  Language? _selected;

  @override
  void initState() {
    super.initState();
    _loadNextPage();
  }

  void _applyCountryFilter(String? country) {
    setState(() {
      _appliedCountry = country;
      _loaded.clear();
      _nextPageToken = null;
      _selected = null;
    });
    _loadNextPage();
  }

  Future<void> _loadNextPage() async {
    setState(() {
      if (_loaded.isEmpty) {
        _isLoadingFirstPage = true;
      } else {
        _isLoadingMore = true;
      }
      _error = null;
    });
    try {
      final page = await widget.languages.listLanguages(
        country: _appliedCountry,
        pageSize: 99,
        pageToken: _nextPageToken,
      );
      if (!mounted) return;
      setState(() {
        _loaded.addAll(page.data);
        _nextPageToken = page.nextPageToken;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingFirstPage = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _open(Language summary) async {
    try {
      final language = await widget.languages.getLanguage(summary.id);
      if (mounted) setState(() => _selected = language);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: CountryDropdown(
            initialSelection: _appliedCountry,
            onSelected: _applyCountryFilter,
          ),
        ),
        Expanded(child: _buildList(context)),
      ],
    );
  }

  Widget _buildList(BuildContext context) {
    final strings = ExampleLocalizations.of(context);
    if (_isLoadingFirstPage) return const Center(child: CircularProgressIndicator());
    if (_error != null && _loaded.isEmpty) {
      return ErrorRetry(error: _error!, onRetry: _loadNextPage);
    }

    return Row(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _loaded.length + 1,
            itemBuilder: (context, index) {
              if (index == _loaded.length) {
                if (_error != null) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: ErrorRetry(error: _error!, onRetry: _loadNextPage),
                  );
                }
                if (_nextPageToken == null) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(child: Text(strings.endOfListLabel)),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: _isLoadingMore
                        ? const CircularProgressIndicator()
                        : OutlinedButton(onPressed: _loadNextPage, child: Text(strings.loadMoreButton)),
                  ),
                );
              }
              final language = _loaded[index];
              return ListTile(
                title: Text(language.language ?? language.id),
                selected: _selected?.id == language.id,
                onTap: () => _open(language),
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
                  Text(_selected!.language ?? _selected!.id, style: Theme.of(context).textTheme.titleLarge),
                  Text(strings.idLabel(_selected!.id)),
                  Text(strings.scriptLabel(_selected!.script ?? '-')),
                  Text(strings.textDirectionLabel(_selected!.textDirection.toString())),
                  Text(strings.defaultBibleVersionIdLabel(_selected!.defaultBibleVersionId?.toString() ?? '-')),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
