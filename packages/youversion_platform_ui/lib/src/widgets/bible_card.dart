import 'package:flutter/material.dart';

import '../theme/bible_text_theme.dart';
import 'bible_text_view.dart';

/// Card presenting a Bible passage with a reference header and an optional
/// version-selector affordance.
///
/// Receives already-fetched data (`title`, `content`) - it never calls
/// `YouVersionContentClient` itself, same data-in/callback-out split as
/// every other widget in this package. Mirrors `platform-ui`'s
/// `views/BibleCardView.kt` (Kotlin), React's
/// `components/bible-card.tsx`.
class BibleCard extends StatelessWidget {
  const BibleCard({
    super.key,
    required this.reference,
    required this.content,
    this.versionAbbreviation,
    this.onVersionTap,
    this.onTap,
  });

  /// e.g. `"John 3:16"`.
  final String reference;

  /// Passage HTML, as returned by `YouVersionContentClient.getPassage`.
  final String content;

  /// e.g. `"NIV"` - shown as a tappable chip when [onVersionTap] is set.
  final String? versionAbbreviation;
  final VoidCallback? onVersionTap;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = BibleTextTheme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: Text(reference, style: textTheme.header)),
                  if (versionAbbreviation != null)
                    ActionChip(
                      label: Text(versionAbbreviation!),
                      onPressed: onVersionTap,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              BibleTextView(content: content),
            ],
          ),
        ),
      ),
    );
  }
}
