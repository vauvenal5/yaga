import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/sync_file.dart';

class SyncManager {
  Map<Uri, Map<Uri, SyncFile>> _syncMatrix = {}; 

  Map<Uri, SyncFile> _addKey(Uri key) {
    return _syncMatrix.putIfAbsent(key, () => {});
  }

  SyncFile _addFile(Uri key, NcFile file) {
    return _addKey(key).putIfAbsent(file.uri, () => SyncFile(file));
  }

  Future<void> addLocalFile(Uri key, NcFile file) {
    _addFile(key, file);
  }

  Future<void> addTmpFile(Uri key, NcFile file) {
    _addFile(key, file);
  }

  Future<void> addRemoteFile(Uri key, NcFile file) {
    _addFile(key, file).remote = true;
  }

  Future<List<NcFile>> syncUri(Uri key) async {
    if(!_syncMatrix.containsKey(key)) {
      return [];
    }

    return _syncMatrix.remove(key).values 
      .where((file) => !file.remote)
      .map((e) => e.file)
      .toList();
  }

  Future<void> removeUri(Uri key) async {
    _syncMatrix.remove(key);
  }
}

