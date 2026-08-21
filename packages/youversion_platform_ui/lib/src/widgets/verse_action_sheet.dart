import 'package:flutter/material.dart';
import 'package:youversion_platform_core/youversion_platform_core.dart';

/// Bottom sheet shown when a verse/passage is selected: copy, share, and
/// highlight-color swatches (from `HighlightColors`, `youversion_platform_core`
/// - the fixed 5-color palette, not fetched from an API).
///
/// Mirrors React's `components/verse-action-popover.tsx`, Kotlin's
/// `platform-reader/.../sheets/HighlightColor.kt` swatch row.
///
/// All actions are callbacks - this widget never touches
/// `YouVersionHighlightsClient` directly.
class VerseActionSheet extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final hex in HighlightColors.all)
                  _ColorSwatch(
                    hex: hex,
                    selected: hex == selectedColor,
                    onTap: () => onColorSelected?.call(hex),
                  ),
                if (selectedColor != null)
                  IconButton(
                    icon: const Icon(Icons.format_color_reset_outlined),
                    tooltip: 'Remove highlight',
                    onPressed: onRemoveHighlight,
                  ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                if (onCopy != null)
                  Expanded(
                    child: TextButton.icon(
                      onPressed: onCopy,
                      icon: const Icon(Icons.copy_outlined),
                      label: const Text('Copy'),
                    ),
                  ),
                if (onShare != null)
                  Expanded(
                    child: TextButton.icon(
                      onPressed: onShare,
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('Share'),
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
  const _ColorSwatch({required this.hex, required this.selected, required this.onTap});

  final String hex;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse('FF$hex', radix: 16));
    return InkWell(
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
    );
  }
}
