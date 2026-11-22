---
name: a11y-audit
description: Accessibility audit (WCAG 2.1/2.2 AA) for Flutter/Web screens. Use before delivering new screens or during UI reviews.
---
# Criteria (verify against official WCAG text when reporting)
- Contrast: text >= 4.5:1 (large >= 3:1); component/graphics >= 3:1 (1.4.3, 1.4.11).
- Keyboard: fully operable, logical focus order, visible focus indicator, no focus traps (2.1.1, 2.4.3, 2.4.7).
- Touch target: 2.5.8 (AA, WCAG 2.2) requires >= 24x24 px; platform guidelines recommend 48 dp (Android) / 44 pt (iOS). 2.5.5 (44 px) is AAA level, not AA.
- Names/roles: every control must have an accessible label (4.1.2); error described in text, not color alone (3.3.1, 1.4.1).
- Zoom/font 200%: layout does not break; no truncated text.
- Motion: respect "reduce motion" preferences.

# Flutter
- Use `Semantics(label:, button:, ...)` where the widget is not natively semantic; use `ExcludeSemantics` only for decorative elements.
- Tests: `await expectLater(tester, meetsGuideline(androidTapTargetGuideline))`, `iOSTapTargetGuideline`, `labeledTapTargetGuideline`, `textContrastGuideline`.
- Test with screen readers (TalkBack / VoiceOver) whenever possible; automated checks catch only a subset of issues.

# Output (<= 20 lines)
`# | issue | criterion | severity (critical/major/minor) | remediation`. For untested items in screen readers: note "not verified".
