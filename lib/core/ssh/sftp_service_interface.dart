import 'dart:typed_data';
import 'package:dartssh2/dartssh2.dart';
import '../models/transfer_item.dart';

/// Abstract interface for SFTP operations.
///
/// Enables dependency inversion (p008) and testability via mock injection.
/// Concrete implementation: [SftpService].
abstract class SftpServiceInterface {
  Stream<TransferItem> get transferStream;

  Future<List<SftpName>> listDirectory(String path);
  Future<SftpFileAttrs> stat(String path);
  Future<void> upload({
    required String localPath,
    required String remotePath,
    required TransferItem item,
  });
  Future<void> download({
    required String remotePath,
    required String localPath,
    required TransferItem item,
  });
  Future<void> mkdir(String path);
  Future<void> rename(String oldPath, String newPath);
  Future<void> remove(String path);
  Future<void> rmdir(String path);
  Future<String> realpath(String path);
  Future<Uint8List> readFileBytes(String path);
  void initializeWithClient(SftpClient client);
  void dispose();
}
