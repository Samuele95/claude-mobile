import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:dartssh2/dartssh2.dart';
import '../models/transfer_item.dart';

class SftpService {
  SftpClient? _sftp;
  final _transferController = StreamController<TransferItem>.broadcast();

  Stream<TransferItem> get transferStream => _transferController.stream;

  Future<void> initialize(SSHClient client) async {
    _sftp = await client.sftp();
  }

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

  Future<SftpFileAttrs> stat(String path) async {
    _ensureConnected();
    return _sftp!.stat(path);
  }

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
        final stream = localFile.openRead();

        await for (final chunk in stream) {
          await remoteFile.write(Stream.value(Uint8List.fromList(chunk)));
          transferred += chunk.length;
          _transferController.add(item.copyWith(
            transferredBytes: transferred,
            status: TransferStatus.inProgress,
          ));
        }
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

  Future<void> mkdir(String path) async {
    _ensureConnected();
    await _sftp!.mkdir(path);
  }

  Future<void> rename(String oldPath, String newPath) async {
    _ensureConnected();
    await _sftp!.rename(oldPath, newPath);
  }

  Future<void> remove(String path) async {
    _ensureConnected();
    await _sftp!.remove(path);
  }

  Future<void> rmdir(String path) async {
    _ensureConnected();
    await _sftp!.rmdir(path);
  }

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

  void dispose() {
    _sftp = null;
    _transferController.close();
  }
}
