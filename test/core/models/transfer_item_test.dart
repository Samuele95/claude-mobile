import 'package:flutter_test/flutter_test.dart';
import 'package:claude_mobile/core/models/transfer_item.dart';

void main() {
  group('TransferItem', () {
    final item = TransferItem(
      id: 'tx-1',
      localPath: '/local/file.txt',
      remotePath: '/remote/file.txt',
      direction: TransferDirection.upload,
      totalBytes: 1000,
    );

    group('progress', () {
      test('returns 0.0 when no bytes transferred', () {
        expect(item.progress, 0.0);
      });

      test('returns correct fractional progress', () {
        final partial = item.copyWith(transferredBytes: 500);
        expect(partial.progress, 0.5);
      });

      test('returns 1.0 when fully transferred', () {
        final complete = item.copyWith(transferredBytes: 1000);
        expect(complete.progress, 1.0);
      });

      test('returns 0.0 when totalBytes is zero (avoids division by zero)', () {
        final zeroSize = TransferItem(
          id: 'tx-zero',
          localPath: '/empty',
          remotePath: '/empty',
          direction: TransferDirection.download,
          totalBytes: 0,
        );

        expect(zeroSize.progress, 0.0);
      });
    });

    group('copyWith', () {
      test('updates status while preserving identity', () {
        final updated = item.copyWith(status: TransferStatus.inProgress);

        expect(updated.status, TransferStatus.inProgress);
        expect(updated.id, item.id);
        expect(updated.localPath, item.localPath);
        expect(updated.remotePath, item.remotePath);
      });

      test('records error message on failure', () {
        final failed = item.copyWith(
          status: TransferStatus.failed,
          error: 'Connection lost',
        );

        expect(failed.status, TransferStatus.failed);
        expect(failed.error, 'Connection lost');
      });
    });

    test('defaults to queued status', () {
      expect(item.status, TransferStatus.queued);
    });
  });
}
