enum TransferDirection { upload, download }

enum TransferStatus { queued, inProgress, completed, failed }

class TransferItem {
  final String id;
  final String localPath;
  final String remotePath;
  final TransferDirection direction;
  final int totalBytes;
  final int transferredBytes;
  final TransferStatus status;
  final String? error;

  const TransferItem({
    required this.id,
    required this.localPath,
    required this.remotePath,
    required this.direction,
    required this.totalBytes,
    this.transferredBytes = 0,
    this.status = TransferStatus.queued,
    this.error,
  });

  double get progress =>
      totalBytes > 0 ? transferredBytes / totalBytes : 0.0;

  TransferItem copyWith({
    int? transferredBytes,
    TransferStatus? status,
    String? error,
  }) {
    return TransferItem(
      id: id,
      localPath: localPath,
      remotePath: remotePath,
      direction: direction,
      totalBytes: totalBytes,
      transferredBytes: transferredBytes ?? this.transferredBytes,
      status: status ?? this.status,
      error: error ?? this.error,
    );
  }
}
