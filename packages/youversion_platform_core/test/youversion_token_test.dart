import 'package:test/test.dart';
import 'package:youversion_platform_core/youversion_platform_core.dart';

void main() {
  group('YouVersionToken.fromJson', () {
    test('parses expires_in as an int (documented shape)', () {
      final token = YouVersionToken.fromJson({
        'access_token': 'a',
        'refresh_token': 'r',
        'expires_in': 3600,
      });
      expect(token.expiresIn, 3600);
    });

    test('parses expires_in as a string - confirmed live, the server sends this shape', () {
      final token = YouVersionToken.fromJson({
        'access_token': 'a',
        'refresh_token': 'r',
        'expires_in': '3600',
      });
      expect(token.expiresIn, 3600);
    });
  });
}
