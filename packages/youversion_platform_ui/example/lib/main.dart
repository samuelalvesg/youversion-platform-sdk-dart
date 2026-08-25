// Example app for `youversion_platform_ui`. Runs with no App Key - every
// widget here receives hand-written sample data instead of a real network
// response, matching the "widgets take data/callbacks, never call the
// network themselves" design of this package. A real app would fetch this
// data via `youversion_platform_core`'s `YouVersionContentClient`/
// `YouVersionLanguagesClient` first.
import 'package:flutter/material.dart';
import 'package:youversion_platform_core/youversion_platform_core.dart';
import 'package:youversion_platform_ui/youversion_platform_ui.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'youversion_platform_ui example',
      theme: YouVersionPlatformTheme.light(),
      darkTheme: YouVersionPlatformTheme.dark(),
      localizationsDelegates: YouVersionUiLocalizations.localizationsDelegates,
      supportedLocales: YouVersionUiLocalizations.supportedLocales,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _signingIn = false;
  String? _highlightColor;

  final _sampleBibles = [
    Bible(id: 111, title: 'New International Version', abbreviation: 'NIV'),
    Bible(id: 206, title: 'World English Bible, American English Edition', abbreviation: 'WEBUS'),
  ];

  final _sampleLanguages = [
    Language(id: 'eng', language: 'English', displayNames: const {'en': 'English'}),
    Language(id: 'por', language: 'Portuguese', displayNames: const {'en': 'Portuguese'}),
  ];

  Future<void> _fakeSignIn() async {
    setState(() => _signingIn = true);
    // A real app would use `youversion_platform_core`'s `YouVersionSignIn`
    // to build the authorization URL, launch it (`url_launcher`), and
    // handle the redirect - this button is purely presentational.
    await Future<void>.delayed(const Duration(seconds: 1));
    if (mounted) setState(() => _signingIn = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('youversion_platform_ui')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionTitle('Sign-in'),
          YouVersionSignInButton(onPressed: _fakeSignIn, isLoading: _signingIn),
          const SizedBox(height: 8),
          const YouVersionSignInButton(onPressed: null, mode: YouVersionSignInButtonMode.compact),
          const SizedBox(height: 8),
          const YouVersionSignInButton(onPressed: null, mode: YouVersionSignInButtonMode.iconOnly, dark: true),
          const _SectionTitle('Bible / verse-of-the-day cards'),
          BibleCard(
            reference: 'John 3:16',
            content: 'For God so loved the world, that he gave his only Son, '
                'that whoever believes in him should not perish, but have eternal life.',
            versionAbbreviation: 'WEBUS',
            onVersionTap: () {},
          ),
          const SizedBox(height: 12),
          const VerseOfTheDayCard(
            reference: 'Romans 8:28',
            content: 'We know that all things work together for good for those '
                'who love God, for those who are called according to his purpose.',
          ),
          const _SectionTitle('Pickers'),
          FilledButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              builder: (_) => BibleVersionPicker(bibles: _sampleBibles, onSelected: (bible) => Navigator.pop(context)),
            ),
            child: const Text('Open BibleVersionPicker'),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              builder: (_) =>
                  BibleLanguagePicker(languages: _sampleLanguages, onSelected: (language) => Navigator.pop(context)),
            ),
            child: const Text('Open BibleLanguagePicker'),
          ),
          const _SectionTitle('Verse actions'),
          FilledButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              builder: (_) => VerseActionSheet(
                selectedColor: _highlightColor,
                onColorSelected: (hex) => setState(() => _highlightColor = hex),
                onRemoveHighlight: _highlightColor == null ? null : () => setState(() => _highlightColor = null),
              ),
            ),
            child: const Text('Open VerseActionSheet'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
