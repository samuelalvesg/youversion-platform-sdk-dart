---
name: flutter-design-system
description: Enforces Flutter Design System and OpenDesign standards, ThemeData/ColorScheme token inheritance, responsive widget architecture, micro-interactions, and accessibility. Use when building or styling Flutter widgets, screens, and design tokens.
---
# Flutter Design System & OpenDesign Principles
1. **Design Token Inheritance (Theme-First)**:
   - NEVER hardcode arbitrary colors, text styles, or spacing dimensions in widgets.
   - Always resolve through `Theme.of(context)`:
     - Colors: `Theme.of(context).colorScheme.<token>` (e.g., `primary`, `surfaceContainer`, `onSurface`).
     - Typography: `Theme.of(context).textTheme.<style>` (e.g., `titleMedium`, `bodySmall`).
     - Custom Tokens: Use `ThemeExtension<T>` for domain-specific brand tokens.
2. **Spacing & Layout Hierarchy**:
   - Consistent spatial scales using 4/8-point grid constants (e.g. `AppSpacing.xs = 4`, `sm = 8`, `md = 16`, `lg = 24`, `xl = 32`).
   - Use `Gap` or `SizedBox` with spacing constants over arbitrary paddings.
3. **Responsive & Adaptive Architecture**:
   - Use `LayoutBuilder`, `MediaQuery.sizeOf(context)`, or custom breakpoint utilities (`isMobile`, `isTablet`, `isDesktop`).
   - Ensure layouts scale smoothly without overflow bugs (`SingleChildScrollView`, `Expanded`, `Flexible`).
4. **Micro-Interactions & Transitions (OpenDesign Standard)**:
   - Prefer standard Flutter motion primitives: `AnimatedContainer`, `AnimatedSwitcher`, `FadeTransition`.
   - Respect user accessibility preferences: wrap animations with `MediaQuery.of(context).disableAnimations` or check `prefersReducedMotion`.
5. **Accessibility & Semantics**:
   - Maintain minimum tap targets (>= 48 dp Android, >= 44 pt iOS).
   - Label custom icon buttons and interactive widgets with `Semantics(label:, button: true)`.

# Output
Clean, testable Dart/Flutter widget code that strictly imports design tokens and avoids hardcoded visual styles.
