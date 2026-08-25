// Full demo app for the YouVersion Platform Dart SDK - exercises every
// `youversion_platform_core` client (Content, Sign-In, Data Exchange,
// Highlights, Languages, Organizations, VOTD) and the sign-in/reading
// widgets from `youversion_platform_ui`/`youversion_platform_reader`.
// `youversion_platform_ui`'s own example stays a static, network-free
// widget gallery - this app is the real, end-to-end one.
//
// Get a free App Key at https://developers.youversion.com and run with
// `flutter run --dart-define=APP_KEY=your-key-here`.
import 'package:flutter/material.dart';
import 'package:youversion_platform_core/youversion_platform_core.dart';
import 'package:youversion_platform_reader/youversion_platform_reader.dart';
import 'package:youversion_platform_ui/youversion_platform_ui.dart';

import 'auth_session.dart';
import 'bible_explorer_page.dart';
import 'data_exchange_page.dart';
import 'l10n/example_localizations.dart';
import 'languages_page.dart';
import 'organizations_page.dart';
import 'reader_page.dart';
import 'shared_preferences_reader_storage.dart';
import 'sign_in_page.dart';
import 'votd_page.dart';

// Passed at build/run time (`--dart-define=APP_KEY=...`), so nothing
// secret ever needs to live in this tracked file. Falls back to a
// placeholder for anyone who just opens this file to read it.
const _appKey = String.fromEnvironment('APP_KEY', defaultValue: 'YOUR_APP_KEY');

// The App Key's real registered redirect URI - another app's (Symmetris)
// production backend, unrelated to this SDK. See `SignInPage`'s doc
// comment for why this example uses it anyway without ever calling it.
final _redirectUri = Uri.parse('https://api.symmetris.com.br/api/oauth/youversion/callback');

void main() => runApp(const ExampleApp());

// `_ui`/`_reader` ship 14 locales, but this app's own text (this file, and
// every page under lib/) only has real translations for these 2
// (lib/l10n/example_*.arb) - offering the other 12 here would leave this
// app's own screens back in English while `_ui`/`_reader` widgets switched,
// the exact "mixed languages" bug this whole settings feature exists to
// fix. A real app would only ever offer the locales it has actually
// localized its own UI into, same reasoning.
const _supportedLocales = [Locale('en'), Locale('pt')];
const _localeNames = {'en': 'English', 'pt': 'Português'};

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  // Pinned to English by default, not left to follow the OS locale -
  // confirmed live, this app's own page text used to be hardcoded English
  // while `_ui`/`_reader` widgets followed the OS locale, so e.g. an
  // OS locale of pt-BR showed them in Portuguese right next to this app's
  // still-English text (a real "mixed languages" bug). This app's own
  // text is now localized too (lib/l10n/example_*.arb), in lockstep with
  // `_ui`/`_reader` - the Settings button switches all of it together,
  // restricted to the 2 locales (en/pt) this app's own text actually has,
  // see `_supportedLocales`'s doc comment.
  Locale _locale = const Locale('en');

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YouVersion Platform SDK example',
      theme: YouVersionPlatformTheme.light(),
      darkTheme: YouVersionPlatformTheme.dark(),
      localizationsDelegates: const [
        // Already includes Global{Material,Widgets,Cupertino}Localizations.
        ...YouVersionUiLocalizations.localizationsDelegates,
        YouVersionReaderLocalizations.delegate,
        ExampleLocalizations.delegate,
      ],
      // Only en/pt - see `_supportedLocales`'s doc comment.
      supportedLocales: _supportedLocales,
      locale: _locale,
      home: HomeMenu(locale: _locale, onLocaleChanged: (locale) => setState(() => _locale = locale)),
    );
  }
}

class HomeMenu extends StatefulWidget {
  const HomeMenu({super.key, required this.locale, required this.onLocaleChanged});

  final Locale locale;
  final ValueChanged<Locale> onLocaleChanged;

  @override
  State<HomeMenu> createState() => _HomeMenuState();
}

class _HomeMenuState extends State<HomeMenu> {
  late final _content = YouVersionContentClient(appKey: _appKey);
  late final _highlights = YouVersionHighlightsClient(appKey: _appKey);
  late final _languages = YouVersionLanguagesClient(appKey: _appKey);
  late final _organizations = YouVersionOrganizationsClient(appKey: _appKey);
  late final _votd = YouVersionVotdClient(appKey: _appKey);
  late final _dataExchange = YouVersionDataExchangeClient(appKey: _appKey);
  late final _signIn = YouVersionSignIn(appKey: _appKey, redirectUri: _redirectUri);
  late final _session = AuthSession(_signIn);

  @override
  void initState() {
    super.initState();
    _session.restore();
  }

  @override
  void dispose() {
    _content.close();
    _highlights.close();
    _languages.close();
    _organizations.close();
    _votd.close();
    super.dispose();
  }

  Future<void> _openSettings() async {
    final strings = ExampleLocalizations.of(context);
    final locale = await showDialog<Locale>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(strings.appLanguageLabel),
        children: [
          for (final supported in _supportedLocales)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, supported),
              child: Row(
                children: [
                  if (supported.languageCode == widget.locale.languageCode)
                    const Padding(padding: EdgeInsets.only(right: 8), child: Icon(Icons.check, size: 18))
                  else
                    const SizedBox(width: 26),
                  Text(_localeNames[supported.languageCode] ?? supported.languageCode),
                ],
              ),
            ),
        ],
      ),
    );
    if (locale != null) widget.onLocaleChanged(locale);
  }

  void _open(String title, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(appBar: AppBar(title: Text(title)), body: page),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = ExampleLocalizations.of(context);
    return AnimatedBuilder(
      animation: _session,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('YouVersion Platform SDK'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: strings.appLanguageLabel,
                onPressed: _openSettings,
              ),
              if (!_session.isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: YouVersionSignInButton(
                    mode: YouVersionSignInButtonMode.iconOnly,
                    dark: true,
                    onPressed: _session.isSignedIn
                        ? null
                        : () => _open(strings.signInTile, SignInPage(signIn: _signIn, session: _session)),
                  ),
                ),
            ],
          ),
          body: ListView(
            children: [
              // This screen's own text (below) is always English by
              // design - only `_ui`/`_reader` widgets follow the
              // language picked in Settings. Nothing else on this
              // specific screen renders SDK text, so without this
              // preview, switching languages looked like it did nothing
              // until you opened a page with a real `_ui`/`_reader`
              // widget on it.
              Card(
                margin: const EdgeInsets.all(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.translate, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          strings.previewLabel(youVersionUiStringsOf(context).searchLanguagesHint),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(strings.signInTile),
                subtitle: Text(_session.isSignedIn
                    ? strings.signedInAs(_session.identity?.name ?? _session.identity?.sub ?? '')
                    : strings.notSignedIn),
                onTap: () => _open(strings.signInTile, SignInPage(signIn: _signIn, session: _session)),
              ),
              // BibleReader supplies its own full Scaffold/AppBar once it
              // mounts - pushed directly, not wrapped in another one.
              // `ReaderPage` itself supplies a Scaffold for its own
              // loading/error states, before that (confirmed live: without
              // one, a load failure here had no AppBar/back button at all).
              ListTile(
                leading: const Icon(Icons.menu_book_outlined),
                title: Text(strings.readerTile),
                subtitle: Text(strings.readerSubtitle),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ReaderPage(content: _content, highlights: _highlights, session: _session),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.travel_explore_outlined),
                title: Text(strings.bibleExplorerTile),
                subtitle: const Text('listBibles/getBible/getIndex/listBooks/getBook/listChapters/getChapter/'
                    'listVerses/getVerse/getPassage'),
                onTap: () => _open(
                  strings.bibleExplorerTile,
                  BibleExplorerPage(
                    content: _content,
                    languages: _languages,
                    highlights: _highlights,
                    storage: SharedPreferencesReaderStorage(),
                    userAccessToken: _session.token?.accessToken,
                    onSignInRequested: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(strings.signInToSyncMessage)),
                      );
                    },
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.language_outlined),
                title: Text(strings.languagesTile),
                subtitle: const Text('listLanguages / getLanguage'),
                onTap: () => _open(strings.languagesTile, LanguagesPage(languages: _languages)),
              ),
              ListTile(
                leading: const Icon(Icons.corporate_fare_outlined),
                title: Text(strings.organizationsTile),
                subtitle: const Text('listOrganizations / getOrganization'),
                onTap: () => _open(strings.organizationsTile, OrganizationsPage(organizations: _organizations)),
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today_outlined),
                title: Text(strings.votdTile),
                subtitle: const Text('listAll / getDay'),
                onTap: () => _open(
                  strings.votdTile,
                  VotdPage(votd: _votd, content: _content, bibleId: 206),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.sync_outlined),
                title: Text(strings.dataExchangeTile),
                subtitle: Text(
                  _session.isSignedIn ? 'createToken / buildApprovalUrl / parseCallback' : strings.signInFirst,
                ),
                enabled: _session.isSignedIn,
                onTap: () => _open(
                  strings.dataExchangeTile,
                  DataExchangePage(dataExchange: _dataExchange, userAccessToken: _session.token!.accessToken),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
