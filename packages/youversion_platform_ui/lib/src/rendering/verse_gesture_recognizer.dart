import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

/// A [TapGestureRecognizer] configured to also distinguish a long-press
/// from a plain tap, for use as [TextSpan.recognizer].
///
/// Not a custom [GestureRecognizer] subclass: confirmed live,
/// `RenderParagraph.assembleSemanticsNode` asserts a `TextSpan`'s
/// recognizer is one of a fixed, hardcoded set of Flutter's own types
/// (`TapGestureRecognizer`/`DoubleTapGestureRecognizer`/
/// `LongPressGestureRecognizer`) when building the semantics tree - a
/// custom subclass throws there (`"X is not supported"`), it's not
/// something `TextSpan.recognizer`'s `GestureRecognizer?` type actually
/// allows freely despite the type signature. So this hand-rolls
/// tap-vs-long-press timing (`kLongPressTimeout`) on top of a real,
/// framework-recognized [TapGestureRecognizer] instead: start a timer on
/// `onTapDown`, and in `onTapUp` fire [onLongPress] if the timer already
/// elapsed, [onTap] otherwise.
TapGestureRecognizer verseTapLongPressRecognizer({VoidCallback? onTap, VoidCallback? onLongPress}) {
  final recognizer = TapGestureRecognizer();
  Timer? longPressTimer;
  var longPressFired = false;

  recognizer.onTapDown = (_) {
    longPressFired = false;
    longPressTimer?.cancel();
    longPressTimer = Timer(kLongPressTimeout, () {
      longPressFired = true;
      onLongPress?.call();
    });
  };
  recognizer.onTapUp = (_) {
    longPressTimer?.cancel();
    if (!longPressFired) onTap?.call();
  };
  recognizer.onTapCancel = () => longPressTimer?.cancel();

  return recognizer;
}
