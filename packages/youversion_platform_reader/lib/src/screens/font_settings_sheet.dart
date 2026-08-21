import 'package:flutter/material.dart';

import '../settings/reader_font_settings.dart';

/// Sheet for adjusting [ReaderFontSettings]: size, line-height, dark mode.
/// Font family itself isn't user-facing here (it's app-injected, see
/// package README) - this only exposes the presets the official readers
/// expose. Mirrors Kotlin's `BibleReaderFontSettingsView`/
/// `sheets/FontSettings` equivalent.
class FontSettingsSheet extends StatelessWidget {
  const FontSettingsSheet({super.key, required this.settings, required this.onChanged});

  final ReaderFontSettings settings;
  final ValueChanged<ReaderFontSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Font size', style: Theme.of(context).textTheme.labelLarge),
            Wrap(
              spacing: 8,
              children: [
                for (final size in ReaderFontSettings.availableFontSizes)
                  ChoiceChip(
                    label: Text(size.toStringAsFixed(0)),
                    selected: settings.fontSize == size,
                    onSelected: (_) => onChanged(settings.copyWith(fontSize: size)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Line spacing', style: Theme.of(context).textTheme.labelLarge),
            Wrap(
              spacing: 8,
              children: [
                for (final height in ReaderFontSettings.availableLineHeights)
                  ChoiceChip(
                    label: Text(height.toStringAsFixed(1)),
                    selected: settings.lineHeight == height,
                    onSelected: (_) => onChanged(settings.copyWith(lineHeight: height)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Dark mode'),
              value: settings.darkMode,
              onChanged: (value) => onChanged(settings.copyWith(darkMode: value)),
            ),
          ],
        ),
      ),
    );
  }
}
