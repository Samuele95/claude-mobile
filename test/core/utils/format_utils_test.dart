import 'package:flutter_test/flutter_test.dart';
import 'package:claude_mobile/core/utils/format_utils.dart';

void main() {
  group('formatFileSize', () {
    test('formats bytes correctly', () {
      expect(formatFileSize(0), '0 B');
      expect(formatFileSize(512), '512 B');
      expect(formatFileSize(1023), '1023 B');
    });

    test('formats kilobytes correctly', () {
      expect(formatFileSize(1024), '1.0 KB');
      expect(formatFileSize(1536), '1.5 KB');
      expect(formatFileSize(1024 * 1023), '1023.0 KB');
    });

    test('formats megabytes correctly', () {
      expect(formatFileSize(1024 * 1024), '1.0 MB');
      expect(formatFileSize(1024 * 1024 * 5), '5.0 MB');
    });

    test('formats gigabytes correctly', () {
      expect(formatFileSize(1024 * 1024 * 1024), '1.0 GB');
      expect(formatFileSize(1024 * 1024 * 1024 * 3), '3.0 GB');
    });

    test('handles boundary values at unit transitions', () {
      // Just below KB boundary
      expect(formatFileSize(1023), '1023 B');
      // Exactly at KB boundary
      expect(formatFileSize(1024), '1.0 KB');
      // Just below MB boundary
      expect(formatFileSize(1024 * 1024 - 1), '1024.0 KB');
      // Exactly at MB boundary
      expect(formatFileSize(1024 * 1024), '1.0 MB');
    });
  });
}
