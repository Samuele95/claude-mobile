import 'package:flutter_test/flutter_test.dart';
import 'package:claude_mobile/core/utils/platform_utils.dart';

void main() {
  group('platform_utils', () {
    test('isMobile and isDesktop are mutually exclusive', () {
      // On any platform, one must be true and the other false
      expect(isMobile != isDesktop, isTrue,
          reason: 'isMobile and isDesktop should be mutually exclusive');
    });

    test('defaultLocalPath returns a non-empty string', () {
      expect(defaultLocalPath, isNotEmpty);
    });

    test('defaultLocalPath starts with /', () {
      // Both Android and desktop paths should be absolute
      expect(defaultLocalPath, startsWith('/'));
    });
  });
}
