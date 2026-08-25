import 'package:flutter/material.dart';

import 'iso_countries.dart';
import 'l10n/example_localizations.dart';

/// Searchable country field (flag + name), backed by [isoCountries]. Shared
/// by every page that filters `YouVersionLanguagesClient.listLanguages` by
/// `country`.
///
/// Built on [Autocomplete], not [DropdownMenu] - confirmed live,
/// `DropdownMenu` (in a constrained space like an `AlertDialog`) rendered
/// its options overlapping the field itself instead of below it, and
/// typing didn't replace the current selection's text, it inserted into
/// it. `Autocomplete` is the widget Flutter actually built for "type to
/// filter, options anchor below the field, picking one replaces the field
/// text" - exactly what was wanted here.
class CountryDropdown extends StatelessWidget {
  const CountryDropdown({
    super.key,
    required this.onSelected,
    this.initialSelection,
    this.label,
    this.autofocus = false,
  });

  final ValueChanged<String?> onSelected;
  final String? initialSelection;

  /// Defaults to [ExampleLocalizations.filterByCountryLabel] - a plain
  /// default value can't itself be localized (no `BuildContext` at
  /// constructor-default time).
  final String? label;
  final bool autofocus;

  // Not the flag emoji: confirmed live, Flutter's desktop text renderer
  // (Linux, and Windows historically) doesn't compose the two "regional
  // indicator" code points into a flag glyph the way mobile/web do - shows
  // as two boxed letters instead, even with a font that has the real flag
  // glyph installed (Noto Color Emoji). Not fixable by bundling a font;
  // it's a text-shaping gap in Flutter's desktop embeddings. Plain text
  // works everywhere.
  static String _display((String, String) option) => '${option.$2} (${option.$1})';

  @override
  Widget build(BuildContext context) {
    final strings = ExampleLocalizations.of(context);
    final initial = initialSelection == null ? null : isoCountries.where((c) => c.$1 == initialSelection).firstOrNull;

    return Autocomplete<(String, String)>(
      initialValue: TextEditingValue(text: initial == null ? '' : _display(initial)),
      displayStringForOption: _display,
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text.trim().toLowerCase();
        if (query.isEmpty) return isoCountries;
        return isoCountries.where(
          (c) => c.$2.toLowerCase().startsWith(query) || c.$1.toLowerCase().startsWith(query),
        );
      },
      onSelected: (option) => onSelected(option.$1),
      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
        return AnimatedBuilder(
          animation: textController,
          builder: (context, _) {
            return TextField(
              controller: textController,
              focusNode: focusNode,
              autofocus: autofocus,
              decoration: InputDecoration(
                labelText: label ?? strings.filterByCountryLabel,
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: textController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: strings.clearTooltip,
                        onPressed: () {
                          textController.clear();
                          onSelected(null);
                        },
                      ),
              ),
            );
          },
        );
      },
    );
  }
}
