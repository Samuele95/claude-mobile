import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:dartssh2/dartssh2.dart';
import '../models/transfer_item.dart';

import 'sftp_service_interface.dart';

class SftpService implements SftpServiceInterface {
  SftpClient? _sftp;
  final _transferController = StreamController<TransferItem>.broadcast();

  @override
  Stream<TransferItem> get transferStream => _transferController.stream;

  Future<void> initialize(SSHClient client) async {
    _sftp = await client.sftp();
  }

  /// Initialize with an already-opened SftpClient.
  @override
  void initializeWithClient(SftpClient client) {
    _sftp = client;
  }

  @override
  Future<List<SftpName>> listDirectory(String path) async {
    _ensureConnected();
    final items = await _sftp!.listdir(path);
    return items.where((i) => i.filename != '.' && i.filename != '..').toList()
      ..sort((a, b) {
        final aIsDir = a.attr.isDirectory;
        final bIsDir = b.attr.isDirectory;
        if (aIsDir && !bIsDir) return -1;
        if (!aIsDir && bIsDir) return 1;
        return a.filename.compareTo(b.filename);
      });
  }

  @override
  Future<SftpFileAttrs> stat(String path) async {
    _ensureConnected();
    return _sftp!.stat(path);
  }

  @override
  Future<void> upload({
    required String localPath,
    required String remotePath,
    required TransferItem item,
  }) async {
    _ensureConnected();
    _transferController.add(item.copyWith(status: TransferStatus.inProgress));

    try {
      final localFile = File(localPath);
      final remoteFile = await _sftp!.open(
        remotePath,
        mode: SftpFileOpenMode.create |
            SftpFileOpenMode.write |
            SftpFileOpenMode.truncate,
      );

      try {
        int transferred = 0;
        // Stream the file directly — avoids per-chunk Stream.value() overhead
        final dataStream = localFile.openRead().map((chunk) {
          final bytes = Uint8List.fromList(chunk);
          transferred += bytes.length;
          _transferController.add(item.copyWith(
            transferredBytes: transferred,
            status: TransferStatus.inProgress,
          ));
          return bytes;
        });
        await remoteFile.write(dataStream);
      } finally {
        await remoteFile.close();
      }

      _transferController.add(item.copyWith(
        transferredBytes: item.totalBytes,
        status: TransferStatus.completed,
      ));
    } catch (e) {
      _transferController.add(item.copyWith(
        status: TransferStatus.failed,
        error: e.toString(),
      ));
      rethrow;
    }
  }

  @override
  Future<void> download({
    required String remotePath,
    required String localPath,
    required TransferItem item,
  }) async {
    _ensureConnected();
    _transferController.add(item.copyWith(status: TransferStatus.inProgress));

    try {
      final remoteFile = await _sftp!.open(remotePath);

      final localFile = File(localPath);
      await localFile.parent.create(recursive: true);
      final sink = localFile.openWrite();

      int transferred = 0;
      try {
        await for (final chunk in remoteFile.read()) {
          sink.add(chunk);
          transferred += chunk.length;
          _transferController.add(item.copyWith(
            transferredBytes: transferred,
            status: TransferStatus.inProgress,
          ));
        }
        await sink.flush();
      } finally {
        await sink.close();
        await remoteFile.close();
      }

      _transferController.add(item.copyWith(
        transferredBytes: item.totalBytes,
        status: TransferStatus.completed,
      ));
    } catch (e) {
      _transferController.add(item.copyWith(
        status: TransferStatus.failed,
        error: e.toString(),
      ));
      rethrow;
    }
  }

  @override
  Future<void> mkdir(String path) async {
    _ensureConnected();
    await _sftp!.mkdir(path);
  }

  @override
  Future<void> rename(String oldPath, String newPath) async {
    _ensureConnected();
    await _sftp!.rename(oldPath, newPath);
  }

  @override
  Future<void> remove(String path) async {
    _ensureConnected();
    await _sftp!.remove(path);
  }

  @override
  Future<void> rmdir(String path) async {
    _ensureConnected();
    await _sftp!.rmdir(path);
  }

  /// Resolve a path to its absolute form on the remote server.
  /// Useful for resolving '.' to the user's home directory.
  @override
  Future<String> realpath(String path) async {
    _ensureConnected();
    return _sftp!.absolute(path);
  }

  @override
  Future<Uint8List> readFileBytes(String path) async {
    _ensureConnected();
    final file = await _sftp!.open(path);
    final bytes = await file.readBytes();
    await file.close();
    return bytes;
  }

  void _ensureConnected() {
    if (_sftp == null) throw StateError('SFTP not initialized');
  }

  @override
  void dispose() {
    _sftp = null;
    _transferController.close();
  }
}
