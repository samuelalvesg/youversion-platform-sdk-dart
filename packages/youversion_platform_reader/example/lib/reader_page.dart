import 'package:flutter/material.dart';
import 'package:youversion_platform_core/youversion_platform_core.dart';
import 'package:youversion_platform_reader/youversion_platform_reader.dart';
import 'package:youversion_platform_ui/youversion_platform_ui.dart';

import 'auth_session.dart';
import 'error_retry.dart';
import 'l10n/example_localizations.dart';
import 'shared_preferences_reader_storage.dart';

const _initialChapterId = 'JHN.3';

// A handful of real, public-domain (no permissions required) English
// Bible ids to demonstrate BibleVersionPicker/switching versions -
// avoids needing a full listBibles() call (and a language picker to go
// with it) just for this page. WEBUS is the default - zero-setup, same
// one this SDK's own test fixtures use.
const versionIds = [206, 100, 111];

class ReaderPage extends StatefulWidget {
  const ReaderPage({super.key, required this.content, required this.highlights, required this.session});

  final YouVersionContentClient content;
  final YouVersionHighlightsClient highlights;
  final AuthSession session;

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  int _bibleId = versionIds.first;
  late Future<(Bible, BibleVersionIndex)> _loaded = _load(_bibleId);

  Future<(Bible, BibleVersionIndex)> _load(int bibleId) async {
    final bible = await widget.content.getBible(bibleId);
    final index = await widget.content.getIndex(bibleId);
    return (bible, index);
  }

  Future<void> _pickVersion() async {
    final List<Bible> bibles;
    try {
      bibles = await Future.wait(versionIds.map(widget.content.getBible));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
      return;
    }
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (_) => BibleVersionPicker(
        bibles: bibles,
        selectedBibleId: _bibleId,
        onSelected: (bible) {
          Navigator.pop(context);
          setState(() {
            _bibleId = bible.id;
            _loaded = _load(bible.id);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) {
        final strings = ExampleLocalizations.of(context);
        return FutureBuilder<(Bible, BibleVersionIndex)>(
          future: _loaded,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              // `BibleReader` (the success case below) supplies its own
              // full Scaffold/AppBar - but that widget doesn't exist yet
              // here, before `_load` has succeeded even once. Confirmed
              // live: without this page's own Scaffold, this state
              // rendered with no AppBar/back button at all (nothing to
              // pop with) and no Material ancestor styling the text.
              return Scaffold(
                appBar: AppBar(title: Text(strings.readerTile)),
                body: ErrorRetry(
                  error: snapshot.error!,
                  // Block body, not `setState(() => _loaded = _load(...))`
                  // - `x = y` evaluates to `y`, so an arrow-body closure
                  // returns the Future itself, and setState() asserts its
                  // callback must be synchronous (confirmed live:
                  // "setState() callback argument returned a Future").
                  onRetry: () => setState(() {
                    _loaded = _load(_bibleId);
                  }),
                ),
              );
            }
            if (!snapshot.hasData) {
              return Scaffold(
                appBar: AppBar(title: Text(strings.readerTile)),
                body: const Center(child: CircularProgressIndicator()),
              );
            }
            final (bible, index) = snapshot.data!;
            return BibleReader(
              // Re-keying on the version forces a fresh `BibleReader` (and
              // its internal controller) whenever the selected version
              // changes - `BibleReader` itself has no "switch version"
              // entry point beyond the `onVersionTap` callback slot (which
              // versions to offer is app policy, not SDK policy).
              key: ValueKey(_bibleId),
              content: widget.content,
              bible: bible,
              index: index,
              initialChapterId: _initialChapterId,
              storage: SharedPreferencesReaderStorage(),
              highlightsClient: widget.highlights,
              userAccessToken: widget.session.token?.accessToken,
              onVersionTap: _pickVersion,
              onSignInRequested: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(strings.signInToSyncMessage)),
                );
              },
            );
          },
        );
      },
    );
  }
}
