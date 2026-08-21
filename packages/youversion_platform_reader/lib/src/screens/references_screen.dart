import 'package:flutter/material.dart';
import 'package:youversion_platform_core/youversion_platform_core.dart';

/// Book/chapter picker with search - navigate to any chapter of the
/// current [BibleVersionIndex]. Mirrors `platform-reader`'s
/// `screens/references/ReferencesScreen.kt` (Kotlin).
///
/// Pushed by [BibleReader] itself; can also be used standalone (e.g. from a
/// "go to verse" search entry point elsewhere in the app) - it only needs
/// the index and a selection callback.
class ReferencesScreen extends StatefulWidget {
  const ReferencesScreen({super.key, required this.index, required this.onChapterSelected});

  final BibleVersionIndex index;
  final ValueChanged<String> onChapterSelected;

  @override
  State<ReferencesScreen> createState() => _ReferencesScreenState();
}

class _ReferencesScreenState extends State<ReferencesScreen> {
  BibleBook? _expandedBook;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final books = widget.index.books ?? const [];
    final query = _query.trim().toLowerCase();
    final filtered = query.isEmpty
        ? books
        : books.where((book) => (book.title ?? book.id).toLowerCase().contains(query)).toList();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          decoration: const InputDecoration(hintText: 'Search books', border: InputBorder.none),
          onChanged: (value) => setState(() => _query = value),
        ),
      ),
      body: ListView.builder(
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final book = filtered[index];
          final expanded = _expandedBook == book;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: Text(book.title ?? book.id),
                trailing: Icon(expanded ? Icons.expand_less : Icons.expand_more),
                onTap: () => setState(() => _expandedBook = expanded ? null : book),
              ),
              if (expanded)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (book.intro != null)
                        ActionChip(
                          label: const Text('Intro'),
                          onPressed: () => widget.onChapterSelected('${book.id}.intro'),
                        ),
                      for (final chapter in book.chapters ?? const [])
                        ActionChip(
                          label: Text(chapter.title ?? chapter.id.split('.').last),
                          onPressed: () => widget.onChapterSelected(chapter.id),
                        ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
