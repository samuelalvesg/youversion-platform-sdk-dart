import 'package:flutter/material.dart';

import '../l10n/youversion_reader_localizations.dart';
import '../l10n/youversion_reader_strings.dart';
import '../settings/reader_font_settings.dart';
import '../settings/reader_theme.dart';

/// Sheet for adjusting [ReaderFontSettings]: size, line-height, reading
/// theme. Font family itself isn't user-facing here (it's app-injected, see
/// package README) - this only exposes the presets the official readers
/// expose. Mirrors Kotlin's `BibleReaderFontSettingsSheet`/`ReaderThemes.kt`.
///
/// Keeps its own local copy of [settings] - `showModalBottomSheet`'s
/// `builder` isn't re-invoked just because the caller's state changes
/// elsewhere (the sheet lives in a separate route), so without local state
/// the chip/swatch selection rings would never visually update on tap even
/// though [onChanged] does fire and the underlying settings do change.
///
/// Resyncs that local copy from [settings] on every widget update
/// (`didUpdateWidget`), not just at construction - a host embedding this
/// sheet alongside its own sibling controls (e.g. a font-family picker
/// above it, `ReaderSettingsSheet` in bible_with_me) can pass a newly
/// updated [settings] value back down after one of *those* controls
/// changes something. Without resyncing, this widget's stale local copy
/// becomes the base for its own next `copyWith` call, silently reverting
/// whatever the sibling control had just changed (confirmed live: toggling
/// Bionic Reading reverted a just-picked font family back to whatever it
/// was when this sheet first mounted).
class FontSettingsSheet extends StatefulWidget {
  const FontSettingsSheet({super.key, required this.settings, required this.onChanged});

  final ReaderFontSettings settings;
  final ValueChanged<ReaderFontSettings> onChanged;

  @override
  State<FontSettingsSheet> createState() => _FontSettingsSheetState();
}

class _FontSettingsSheetState extends State<FontSettingsSheet> {
  late ReaderFontSettings _settings = widget.settings;

  @override
  void didUpdateWidget(covariant FontSettingsSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    _settings = widget.settings;
  }

  void _update(ReaderFontSettings next) {
    setState(() => _settings = next);
    widget.onChanged(next);
  }

  String _themeLabel(YouVersionReaderLocalizations strings, ReaderTheme theme) {
    return switch (theme) {
      ReaderTheme.pureWhite => strings.themePureWhite,
      ReaderTheme.sepia => strings.themeSepia,
      ReaderTheme.paperGray => strings.themePaperGray,
      ReaderTheme.cream => strings.themeCream,
      ReaderTheme.mint => strings.themeMint,
      ReaderTheme.skyBlue => strings.themeSkyBlue,
      ReaderTheme.charcoal => strings.themeCharcoal,
      ReaderTheme.midnightBlue => strings.themeMidnightBlue,
      ReaderTheme.trueBlack => strings.themeTrueBlack,
      ReaderTheme.graphite => strings.themeGraphite,
      ReaderTheme.forestNight => strings.themeForestNight,
    };
  }

  @override
  Widget build(BuildContext context) {
    final strings = youVersionReaderStringsOf(context);
    final settings = _settings;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.themeLabel, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final theme in ReaderTheme.values)
                  _ThemeSwatch(
                    theme: theme,
                    label: _themeLabel(strings, theme),
                    selected: settings.theme == theme,
                    onTap: () => _update(settings.copyWith(theme: theme)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(strings.fontSizeLabel, style: Theme.of(context).textTheme.labelLarge),
            Row(
              children: [
                IconButton(
                  icon: const Text('A', style: TextStyle(fontSize: 14)),
                  tooltip: strings.decreaseFontSizeTooltip,
                  onPressed: settings.fontSize == settings.nextSmallerFontSize
                      ? null
                      : () => _update(settings.copyWith(fontSize: settings.nextSmallerFontSize)),
                ),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    children: [
                      for (final size in ReaderFontSettings.availableFontSizes)
                        ChoiceChip(
                          label: Text(size.toStringAsFixed(0)),
                          selected: settings.fontSize == size,
                          onSelected: (_) => _update(settings.copyWith(fontSize: size)),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Text('A', style: TextStyle(fontSize: 28)),
                  tooltip: strings.increaseFontSizeTooltip,
                  onPressed: settings.fontSize == settings.nextLargerFontSize
                      ? null
                      : () => _update(settings.copyWith(fontSize: settings.nextLargerFontSize)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(strings.lineSpacingLabel, style: Theme.of(context).textTheme.labelLarge),
            Wrap(
              spacing: 8,
              children: [
                for (final height in ReaderFontSettings.availableLineHeights)
                  ChoiceChip(
                    label: Text(height.toStringAsFixed(2)),
                    selected: settings.lineHeight == height,
                    onSelected: (_) => _update(settings.copyWith(lineHeight: height)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(strings.bionicReadingLabel),
              value: settings.bionicReading,
              onChanged: (value) => _update(settings.copyWith(bionicReading: value)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({required this.theme, required this.label, required this.selected, required this.onTap});

  final ReaderTheme theme;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: theme.background,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? Theme.of(context).colorScheme.primary : theme.foreground.withValues(alpha: 0.2),
              width: selected ? 2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text('A', style: TextStyle(color: theme.foreground, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
