import 'package:flutter/material.dart';
import 'package:youversion_platform_core/youversion_platform_core.dart';
import 'package:youversion_platform_ui/youversion_platform_ui.dart';

import 'error_retry.dart';
import 'l10n/example_localizations.dart';

/// `YouVersionVotdClient.listAll` (the whole year) as a horizontal strip of
/// day numbers, tap one → `getDay` → `YouVersionContentClient.getPassage`
/// for that day's `passageId` → rendered in a `VerseOfTheDayCard`. VOTD
/// itself only carries `day`+`passageId`, never the passage text - same
/// widget-receives-fetched-data split used everywhere else in this SDK.
class VotdPage extends StatefulWidget {
  const VotdPage({super.key, required this.votd, required this.content, required this.bibleId});

  final YouVersionVotdClient votd;
  final YouVersionContentClient content;
  final int bibleId;

  @override
  State<VotdPage> createState() => _VotdPageState();
}

class _VotdPageState extends State<VotdPage> {
  late Future<List<VerseOfTheDay>> _future = widget.votd.listAll();
  BiblePassage? _passage;
  String? _reference;
  int? _selectedDay;
  Object? _openError;

  Future<void> _open(int dayOfYear) async {
    try {
      final entry = await widget.votd.getDay(dayOfYear);
      final passage = await widget.content.getPassage(bibleId: widget.bibleId, passageId: entry.passageId);
      if (!mounted) return;
      setState(() {
        _selectedDay = dayOfYear;
        _passage = passage;
        _reference = passage.reference;
        _openError = null;
      });
    } catch (error) {
      if (mounted) setState(() => _openError = error);
    }
  }

  @override
  void initState() {
    super.initState();
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year)).inDays + 1;
    _open(dayOfYear);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The day-strip's ErrorRetry/loading states must NOT be forced into
        // the same 56px-tall SizedBox as the ListView - confirmed live,
        // that overflowed by 100px ("RenderFlex overflowed") because
        // ErrorRetry's icon+text+button column needs ~110px. Only the
        // successful (ListView) state gets height-constrained.
        FutureBuilder<List<VerseOfTheDay>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return ErrorRetry(
                error: snapshot.error!,
                // Block body, not `setState(() => _future = ...())` - `x =
                // y` evaluates to `y`, so an arrow-body closure returns the
                // Future itself, and setState() asserts its callback must
                // be synchronous (confirmed live: "setState() callback
                // argument returned a Future").
                onRetry: () => setState(() {
                  _future = widget.votd.listAll();
                }),
              );
            }
            final entries = snapshot.data;
            if (entries == null) {
              return const SizedBox(height: 56, child: Center(child: CircularProgressIndicator()));
            }
            return SizedBox(
              height: 56,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(ExampleLocalizations.of(context).dayLabel(entry.day)),
                      selected: _selectedDay == entry.day,
                      onSelected: (_) => _open(entry.day),
                    ),
                  );
                },
              ),
            );
          },
        ),
        if (_openError != null)
          ErrorRetry(error: _openError!, onRetry: () => _open(_selectedDay ?? DateTime.now().day))
        else if (_passage != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: VerseOfTheDayCard(reference: _reference!, content: _passage!.content),
          ),
      ],
    );
  }
}
