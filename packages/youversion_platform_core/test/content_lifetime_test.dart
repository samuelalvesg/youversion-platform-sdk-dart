import 'package:test/test.dart';
import 'package:youversion_platform_core/youversion_platform_core.dart';

void main() {
  test('max-age is the lifetime', () {
    expect(contentLifetime(cacheControl: 'max-age=3600'), const Duration(hours: 1));
  });

  test('Age is subtracted and the result is clamped at zero', () {
    expect(contentLifetime(cacheControl: 'max-age=100', age: '40'),
        const Duration(seconds: 60));
    expect(contentLifetime(cacheControl: 'max-age=100', age: '500'), Duration.zero);
  });

  test('no-store and no-cache are never stored', () {
    expect(contentLifetime(cacheControl: 'no-store'), isNull);
    expect(contentLifetime(cacheControl: 'max-age=60, no-cache'), isNull);
  });

  test('missing or unusable max-age falls back to seven days', () {
    expect(contentLifetime(), defaultContentLifetime);
    expect(contentLifetime(cacheControl: 'public'), defaultContentLifetime);
    expect(contentLifetime(cacheControl: 'max-age=abc'), defaultContentLifetime);
  });

  test('accepts the quoted-string argument form', () {
    expect(contentLifetime(cacheControl: 'max-age="120"'), const Duration(seconds: 120));
  });
}
