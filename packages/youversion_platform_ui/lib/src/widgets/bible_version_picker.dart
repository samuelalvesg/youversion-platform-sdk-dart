import 'package:flutter/material.dart';
import 'package:youversion_platform_core/youversion_platform_core.dart';

/// Searchable list of [Bible]s, e.g. for a "change translation" sheet.
///
/// Receives an already-fetched `List<Bible>` (from
/// `YouVersionContentClient.listBibles`) - it never calls the client
/// itself. Mirrors `platform-ui`'s `VersionPicking` module (Kotlin/Swift),
/// React's `components/bible-version-picker.tsx`.
class BibleVersionPicker extends StatefulWidget {
  const BibleVersionPicker({
    super.key,
    required this.bibles,
    required this.onSelected,
    this.selectedBibleId,
  });

  final List<Bible> bibles;
  final ValueChanged<Bible> onSelected;
  final int? selectedBibleId;

  @override
  State<BibleVersionPicker> createState() => _BibleVersionPickerState();
}

class _BibleVersionPickerState extends State<BibleVersionPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final filtered = query.isEmpty
        ? widget.bibles
        : widget.bibles.where((bible) {
            final title = bible.title?.toLowerCase() ?? '';
            final abbreviation = bible.abbreviation?.toLowerCase() ?? '';
            return title.contains(query) || abbreviation.contains(query);
          }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search translations',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
        ),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final bible = filtered[index];
              return ListTile(
                title: Text(bible.title ?? bible.abbreviation ?? 'Bible ${bible.id}'),
                subtitle: bible.abbreviation != null ? Text(bible.abbreviation!) : null,
                selected: bible.id == widget.selectedBibleId,
                trailing: bible.id == widget.selectedBibleId ? const Icon(Icons.check) : null,
                onTap: () => widget.onSelected(bible),
              );
            },
          ),
        ),
      ],
    );
  }
}
