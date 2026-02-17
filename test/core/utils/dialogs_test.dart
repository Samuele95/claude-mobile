import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:claude_mobile/core/utils/dialogs.dart';

void main() {
  group('friendlyError', () {
    test('translates host key change to MITM warning', () {
      final msg = friendlyError(Exception('Host key has changed'));
      expect(msg, contains('Remote host key has changed'));
      expect(msg, contains('man-in-the-middle'));
    });

    test('translates SocketException to network error', () {
      final msg = friendlyError(
        const SocketException('Connection failed'),
      );
      expect(msg, contains('Could not reach server'));
    });

    test('translates authentication errors', () {
      final msg = friendlyError(Exception('Authentication failed'));
      expect(msg, contains('Authentication failed'));
      expect(msg, contains('password or SSH key'));
    });

    test('translates connection refused errors', () {
      final msg = friendlyError(Exception('Connection refused'));
      expect(msg, contains('Connection refused'));
      expect(msg, contains('SSH is running'));
    });

    test('translates timeout errors', () {
      final msg = friendlyError(Exception('Connection timed out'));
      expect(msg, contains('timed out'));
      expect(msg, contains('unreachable'));
    });

    test('passes through unrecognized errors as-is', () {
      final msg = friendlyError(Exception('Something unusual'));
      expect(msg, contains('Something unusual'));
    });
  });
}
