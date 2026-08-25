import 'package:flutter/material.dart';

import '../l10n/youversion_ui_strings.dart';
import '../theme/bible_text_theme.dart';
import 'bible_card.dart';

/// Verse-of-the-day card: a [BibleCard] with a "Verse of the Day" label.
///
/// `VerseOfTheDay` (`youversion_platform_core`) only carries `day` and
/// `passageId` - the actual passage HTML/reference must be fetched
/// separately via `YouVersionContentClient.getPassage` and passed in here,
/// same widget-receives-fetched-data split as [BibleCard]. Mirrors
/// `platform-ui`'s `views/VotdView.kt` (Kotlin), `Views/VotdView.swift`
/// (Swift), React's `components/verse-of-the-day.tsx`.
class VerseOfTheDayCard extends StatelessWidget {
  const VerseOfTheDayCard({
    super.key,
    required this.reference,
    required this.content,
    this.onTap,
  });

  final String reference;
  final String content;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = BibleTextTheme.of(context);
    final strings = youVersionUiStringsOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(strings.verseOfTheDayLabel.toUpperCase(), style: textTheme.label),
        const SizedBox(height: 8),
        BibleCard(reference: reference, content: content, onTap: onTap),
      ],
    );
  }
}
