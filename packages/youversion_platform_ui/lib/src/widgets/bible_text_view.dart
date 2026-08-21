import 'package:flutter/material.dart';

import '../theme/bible_text_theme.dart';

/// Renders a [BiblePassage.content] HTML string as scripture text.
///
/// This is a minimal renderer for the subset of markup YouVersion passage
/// HTML actually uses (paragraphs, verse numbers, red-letter/"words of
/// Christ" spans) - not a general HTML engine. Apps needing full HTML
/// fidelity can swap in `flutter_html` and skip this widget; it's kept
/// dependency-free on purpose (see package README).
///
/// No picker, no navigation, no data fetching - purely renders the string
/// it's given. Mirrors `platform-ui`'s `views/BibleTextView.kt` (Kotlin) /
/// `Views/BibleTextView.swift` (Swift).
class BibleTextView extends StatelessWidget {
  const BibleTextView({
    super.key,
    required this.content,
    this.footer,
    this.onVerseTap,
  });

  /// Raw passage HTML, as returned by `YouVersionContentClient.getPassage`.
  final String content;

  /// Optional reader-footer text (`Bible.readerFooter`).
  final String? footer;

  final ValueChanged<String>? onVerseTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = BibleTextTheme.of(context);
    final plainText = _stripTags(content);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SelectableText(plainText, style: textTheme.scriptureM),
        if (footer != null && footer!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(footer!, style: textTheme.caption),
        ],
      ],
    );
  }

  static String _stripTags(String html) {
    return html
        .replaceAll(RegExp(r'<br\s*/?>'), '\n')
        .replaceAll(RegExp(r'</p>'), '\n\n')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&nbsp;', ' ')
        .trim();
  }
}
