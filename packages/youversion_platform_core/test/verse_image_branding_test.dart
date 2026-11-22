import 'package:test/test.dart';
import 'package:youversion_platform_core/youversion_platform_core.dart';

void main() {
  test('brand overlay matches the images guide', () {
    expect(
      VerseImageBranding.overlayUrl,
      'https://cdn.youversion.com/branding/bible-app-overlay-white.png',
    );
    expect(VerseImageBranding.overlayWidth, 660);
  });
}
