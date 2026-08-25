import 'package:flutter/foundation.dart';

/// `true` on a real desktop build (Linux/macOS/Windows) - `kIsWeb` first,
/// not just `defaultTargetPlatform`, since Flutter Web running in a
/// desktop browser also reports a desktop `TargetPlatform`.
bool get isDesktopPlatform =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows);
