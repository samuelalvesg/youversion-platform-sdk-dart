import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:youversion_platform_core/youversion_platform_core.dart';
import 'package:youversion_platform_ui/youversion_platform_ui.dart';

import 'error_retry.dart';
import 'l10n/example_localizations.dart';
import 'platform_check.dart';

/// `YouVersionVotdClient.getDay` (a specific day of the year) →
/// `YouVersionContentClient.getPassage` for that day's `passageId` →
/// rendered in a `VerseOfTheDayCard`. VOTD itself only carries
/// `day`+`passageId`, never the passage text - same widget-receives-
/// fetched-data split used everywhere else in this SDK.
///
/// **A date picker, not a list of 366 day chips** - confirmed live, even
/// wrapped into multiple rows (`Wrap`, not a horizontal scroll - see
/// `docs/DECISIONS.md`), 366 chips at once just took over the whole
/// screen. `YouVersionVotdClient` addresses days by ordinal (1-366,
/// `day-of-year`), but nobody actually thinks in day-of-year - a real
/// calendar date picker is both the more recognizable UI for "verse of
/// the day" and means never rendering more than one control at a time.
/// `listAll` (the endpoint this page used to call to build the chip list)
/// is no longer used here at all - `getDay` alone is enough once the
/// picked date is converted to a day-of-year locally.
class VotdPage extends StatefulWidget {
  const VotdPage({super.key, required this.votd, required this.content, required this.bibleId});

  final YouVersionVotdClient votd;
  final YouVersionContentClient content;
  final int bibleId;

  @override
  State<VotdPage> createState() => _VotdPageState();
}

class _VotdPageState extends State<VotdPage> {
  BiblePassage? _passage;
  String? _reference;
  DateTime? _selectedDate;
  Object? _openError;
  bool _isLoading = false;

  static int _dayOfYear(DateTime date) => date.difference(DateTime(date.year)).inDays + 1;

  Future<void> _open(DateTime date) async {
    setState(() {
      _selectedDate = date;
      _isLoading = true;
    });
    try {
      final entry = await widget.votd.getDay(_dayOfYear(date));
      final passage = await widget.content.getPassage(bibleId: widget.bibleId, passageId: entry.passageId);
      if (!mounted) return;
      setState(() {
        _passage = passage;
        _reference = passage.reference;
        _openError = null;
      });
    } catch (error) {
      if (mounted) setState(() => _openError = error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // `CupertinoDatePicker` (a scrolling wheel) only on mobile - confirmed
  // live, on Linux desktop its `ListWheelScrollView` jumps several items
  // per mouse-wheel notch (the wheel scroll delta a physical mouse sends
  // is much larger than a touchscreen's per-pixel-ish scroll, and Flutter
  // doesn't scale it down for this widget) and doesn't support
  // click-and-drag to scroll at all (Flutter's default `ScrollBehavior`
  // only enables drag-to-scroll for touch/stylus pointers, not mouse,
  // unless a scroll behavior explicitly opts mouse in) - both real,
  // Flutter-level desktop papercuts with wheel-style scrollables, not
  // something to patch around here. `showDatePicker`'s calendar grid
  // needs neither gesture (plain taps/clicks), so desktop gets that
  // instead; touch-scrolling a wheel works fine on mobile.
  Future<void> _pickDate() async {
    // `getDay` addresses a day-of-year (1-366) within a single year's
    // VOTD calendar - not confirmed to resolve across year boundaries, so
    // both pickers only offer dates within the currently selected year.
    final year = (_selectedDate ?? DateTime.now()).year;
    final firstDate = DateTime(year);
    final lastDate = DateTime(year, 12, 31);
    final initial = _selectedDate ?? DateTime.now();

    final DateTime? picked;
    if (isDesktopPlatform) {
      picked = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: firstDate,
        lastDate: lastDate,
      );
    } else {
      var pending = initial;
      picked = await showModalBottomSheet<DateTime>(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 216,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: pending,
                  minimumDate: firstDate,
                  maximumDate: lastDate,
                  onDateTimeChanged: (date) => pending = date,
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, pending),
                      child: Text(MaterialLocalizations.of(context).okButtonLabel),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (picked != null) await _open(picked);
  }

  @override
  void initState() {
    super.initState();
    _open(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = _selectedDate;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today_outlined, size: 18),
            label: Text(
              selectedDate == null
                  ? ExampleLocalizations.of(context).pickDateButton
                  : MaterialLocalizations.of(context).formatMediumDate(selectedDate),
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_openError != null)
            ErrorRetry(error: _openError!, onRetry: () => _open(selectedDate ?? DateTime.now()))
          else if (_passage != null)
            VerseOfTheDayCard(reference: _reference!, content: _passage!.content),
        ],
      ),
    );
  }
}
