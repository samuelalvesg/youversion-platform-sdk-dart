---
name: ui-ux-pillars
description: UI/UX review checklist for Flutter shared components and screens, grounded in Material 3 adaptive guidance, WCAG 2.2 and NN/g heuristics. Use when reviewing or building navigation shells, themes, tokens, error and empty states, or when asked to review a UI against references.
---
# UI/UX pillars (check each, cite file:line, never claim a contrast or layout result you did not measure)

## 1. Adaptive layout
- Decide by **width of the space the widget gets** (`LayoutBuilder`), not by orientation or device type. Material window classes: compact < 600 dp, medium 600–839, expanded ≥ 840.
- Navigation: compact = bottom bar (or modal drawer); medium = rail; expanded = extended rail or permanent drawer. Rail only with 3+ destinations.
- Do not stretch content across wide windows (max content width, panes).

## 2. Tokens and theme
- Light and dark come from one path (`ColorScheme.fromSeed(brightness:)`); no hard-coded `Colors.*` in text styles or widgets.
- Use Material color pairs (`errorContainer` with `onErrorContainer`, `primary` with `onPrimary`); status colors beyond the scheme (success, warning) go in a `ThemeExtension` with `on*` pairs.
- Type scale derived from `textTheme` (all roles, one title family, one body family); fonts that download at runtime are a decision to record (offline, privacy).
- Spacing from a 4/8 scale constant, not literals.

## 3. Accessibility (see `a11y-audit` for the full list)
- Custom tap targets (`GestureDetector`, `InkWell` with fixed size) ≥ 48 dp, keyboard focus, hover/focus state, `Semantics` (label, `button`, `selected`, `expanded`).
- Text scale 200% and `MediaQuery.disableAnimationsOf`: nothing truncates, motion collapses to `Duration.zero`.

## 4. States and feedback
- Every component lists default, hover, focus, pressed, disabled, loading, empty, error.
- Errors (NN/g heuristic 9): next to the source, never color alone, say what happened and how to recover, no blame, announced (`liveRegion`), with an action when one exists.

## 5. Public API of shared packages
- Labels, tooltips and messages come from parameters (no fixed language); changed defaults are breaking: CHANGELOG and version.
- Each finding ships with a widget test (semantics, text scale, dark theme, narrow and wide width).

# Output
Findings by priority (high, medium, low) with file:line, the reference that backs each, and `NÃO VERIFICADO` for anything judged by reading code only.
