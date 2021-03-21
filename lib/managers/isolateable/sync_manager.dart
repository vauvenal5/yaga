import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/sync_file.dart';
import 'package:yaga/utils/forground_worker/isolateable.dart';
import 'package:yaga/utils/logger.dart';

class SyncManager with Isolateable<SyncManager> {
  final _logger = YagaLogger.getLogger(SyncManager);
  Map<Uri, Map<Uri, SyncFile>> _syncMatrix = {};

  Future<void> addUri(Uri key) async {
    return _syncMatrix.putIfAbsent(key, () => {});
  }

  SyncFile _addFile(Uri key, NcFile file) {
    if (!_syncMatrix.containsKey(key)) {
      return null;
    }
    return _syncMatrix[key].putIfAbsent(file.uri, () => SyncFile(file));
  }

  Future<void> addFile(Uri key, NcFile file) async {
    _logger.fine("Adding file ${file.uri.path}");
    _addFile(key, file);
  }

  Future<void> addRemoteFile(Uri key, NcFile file) async {
    _logger.fine("Adding remote file ${file.uri.path}");
    _addFile(key, file)?.remote = true;
  }

  Future<List<NcFile>> syncUri(Uri key) async {
    if (!_syncMatrix.containsKey(key)) {
      return [];
    }

    return _syncMatrix
        .remove(key)
        .values
        .where((file) => !file.remote)
        .map((e) => e.file)
        .toList();
  }

  Future<void> removeUri(Uri key) async {
    _syncMatrix.remove(key);
  }
}
