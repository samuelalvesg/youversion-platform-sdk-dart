import 'package:flutter/material.dart';
import 'package:youversion_platform_core/youversion_platform_core.dart';

import '../l10n/youversion_ui_localizations.dart';
import '../l10n/youversion_ui_strings.dart';

/// Screen-reader label for a highlight-color swatch. `HighlightColors` is a
/// fixed 5-color palette (not remote, see [HighlightColors] doc comment),
/// so this mapping is safe to hardcode rather than threading a name through
/// core's hex-only constants.
String _highlightColorLabel(YouVersionUiLocalizations strings, String hex) {
  return switch (hex) {
    HighlightColors.yellow => strings.highlightColorYellow,
    HighlightColors.green => strings.highlightColorGreen,
    HighlightColors.cyan => strings.highlightColorCyan,
    HighlightColors.orange => strings.highlightColorOrange,
    HighlightColors.pink => strings.highlightColorPink,
    _ => hex,
  };
}

/// Bottom sheet shown when a verse/passage is selected: copy, share, and
/// highlight-color swatches (from `HighlightColors`, `youversion_platform_core`
/// - the fixed 5-color palette, not fetched from an API).
///
/// Mirrors React's `components/verse-action-popover.tsx`, Kotlin's
/// `platform-reader/.../sheets/HighlightColor.kt` swatch row.
///
/// All actions are callbacks - this widget never touches
/// `YouVersionHighlightsClient` directly.
///
/// Keeps its own local copy of [selectedColor] - same reasoning as
/// `FontSettingsSheet`: `showModalBottomSheet`'s `builder` isn't
/// re-invoked just because the caller's state changes elsewhere, so
/// without local state the swatch selection ring wouldn't update on tap
/// even though [onColorSelected] does fire.
class VerseActionSheet extends StatefulWidget {
  const VerseActionSheet({
    super.key,
    this.onCopy,
    this.onShare,
    this.onColorSelected,
    this.onRemoveHighlight,
    this.selectedColor,
  });

  final VoidCallback? onCopy;
  final VoidCallback? onShare;
  final ValueChanged<String>? onColorSelected;
  final VoidCallback? onRemoveHighlight;

  /// Hex color (from [HighlightColors]) currently applied, if any - drawn
  /// with a selection ring.
  final String? selectedColor;

  @override
  State<VerseActionSheet> createState() => _VerseActionSheetState();
}

class _VerseActionSheetState extends State<VerseActionSheet> {
  late String? _selectedColor = widget.selectedColor;

  void _selectColor(String hex) {
    setState(() => _selectedColor = hex);
    widget.onColorSelected?.call(hex);
  }

  void _removeHighlight() {
    setState(() => _selectedColor = null);
    widget.onRemoveHighlight?.call();
  }

  @override
  Widget build(BuildContext context) {
    final strings = youVersionUiStringsOf(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              container: true,
              label: strings.highlightColorsLabel,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final hex in HighlightColors.all)
                    _ColorSwatch(
                      hex: hex,
                      label: _highlightColorLabel(strings, hex),
                      selected: hex == _selectedColor,
                      onTap: () => _selectColor(hex),
                    ),
                  if (_selectedColor != null)
                    IconButton(
                      icon: const Icon(Icons.format_color_reset_outlined),
                      tooltip: strings.clearHighlightTooltip,
                      onPressed: widget.onRemoveHighlight == null ? null : _removeHighlight,
                    ),
                ],
              ),
            ),
            const Divider(height: 24),
            Row(
              children: [
                if (widget.onCopy != null)
                  Expanded(
                    child: TextButton.icon(
                      onPressed: widget.onCopy,
                      icon: const Icon(Icons.copy_outlined),
                      label: Text(strings.copyButton),
                    ),
                  ),
                if (widget.onShare != null)
                  Expanded(
                    child: TextButton.icon(
                      onPressed: widget.onShare,
                      icon: const Icon(Icons.share_outlined),
                      label: Text(strings.shareButton),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({required this.hex, required this.label, required this.selected, required this.onTap});

  final String hex;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse('FF$hex', radix: 16));
    return Semantics(
      label: label,
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: selected ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2) : null,
          ),
        ),
      ),
    );
  }
}
