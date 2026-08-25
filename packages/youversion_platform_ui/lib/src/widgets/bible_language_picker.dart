import 'package:flutter/material.dart';
import 'package:youversion_platform_core/youversion_platform_core.dart';

import '../l10n/youversion_ui_strings.dart';

/// Searchable list of [Language]s, matching the display-name locale of the
/// caller's choice (`Language.displayNames` is keyed by locale tag).
///
/// Receives an already-fetched `List<Language>` (from
/// `YouVersionLanguagesClient.listLanguages`); never calls the client
/// itself, same split as [BibleVersionPicker].
class BibleLanguagePicker extends StatefulWidget {
  const BibleLanguagePicker({
    super.key,
    required this.languages,
    required this.onSelected,
    this.selectedLanguageId,
    this.displayLocale = 'en',
  });

  final List<Language> languages;
  final ValueChanged<Language> onSelected;
  final String? selectedLanguageId;

  /// Locale key looked up in `Language.displayNames` for the label shown
  /// per row; falls back to `Language.language`/`Language.id`.
  final String displayLocale;

  @override
  State<BibleLanguagePicker> createState() => _BibleLanguagePickerState();
}

class _BibleLanguagePickerState extends State<BibleLanguagePicker> {
  String _query = '';

  String _labelFor(Language language) {
    return language.displayNames?[widget.displayLocale] ?? language.language ?? language.id;
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final filtered = query.isEmpty
        ? widget.languages
        : widget.languages.where((language) => _labelFor(language).toLowerCase().contains(query)).toList();
    final strings = youVersionUiStringsOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: strings.searchLanguagesHint,
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
        ),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final language = filtered[index];
              return ListTile(
                title: Text(_labelFor(language)),
                selected: language.id == widget.selectedLanguageId,
                trailing: language.id == widget.selectedLanguageId ? const Icon(Icons.check) : null,
                onTap: () => widget.onSelected(language),
              );
            },
          ),
        ),
      ],
    );
  }
}
