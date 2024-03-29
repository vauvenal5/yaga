import 'dart:io';
import 'dart:isolate';

import 'package:mime/mime.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rxdart/rxdart.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/services/service.dart';
import 'package:yaga/utils/forground_worker/isolateable.dart';
import 'package:yaga/utils/forground_worker/messages/init_msg.dart';
import 'package:yaga/utils/uri_utils.dart';

class LocalFileService extends Service<LocalFileService>
    implements Isolateable<LocalFileService> {
  late PermissionStatus _permissionState;

  @override
  Future<LocalFileService> init() async {
    if (Platform.isAndroid) {
      _permissionState = await Permission.storage.request();
      await Permission.manageExternalStorage.request();
    } else {
      _permissionState = PermissionStatus.granted;
    }
    return this;
  }

  @override
  Future<LocalFileService> initIsolated(
    InitMsg init,
    SendPort isolateToMain,
  ) async {
    _permissionState = PermissionStatus.granted;
    return this;
  }

  Future<LocalFileService> initBackgroundable() async {
    _permissionState = PermissionStatus.granted;
    return this;
  }

  Future<File> createFile({
    required File file,
    required List<int> bytes,
    DateTime? lastModified,
  }) async {
    logger.fine("Creating file ${file.path}");
    await file.create(recursive: true);
    final File res = await file.writeAsBytes(bytes, flush: true);
    if (lastModified != null) {
      await res.setLastModified(lastModified);
    }
    return res;
  }

  //todo: refactor when adding remote delete function
  void deleteFile(FileSystemEntity file) {
    //todo: null exception comes from webview cache files
    //todo: subtask1: local files in cache and default app dir should be in a user@cloud.bla folder
    //todo: subtask3: webview should not cache data
    if (file.existsSync()) {
      file.deleteSync(recursive: true);
    }
  }

  Stream<FileSystemEntity> list(Directory directory) {
    return Stream.value(_permissionState)
        .where((permissionState) => permissionState.isGranted)
        .flatMap((_) => directory.exists().asStream())
        .where((exists) => exists)
        .flatMap((_) => directory.list(recursive: false, followLinks: false))
        .where((event) => event is Directory || _checkMimeType(event.path));
  }

  //todo: is this filtering here at the right place?
  bool _checkMimeType(String path) {
    final String type = lookupMimeType(path) ?? '';
    return type.startsWith("image");
  }

  void copyFile(NcFile file, Uri destination, {bool overwrite = false}) {
    (file.localFile! as File).copySync(
      _checkExists(destination, file.name, overwrite),
    );
  }

  void moveFile(NcFile file, Uri destination, {bool overwrite = false}) {
    (file.localFile! as File).renameSync(
      _checkExists(destination, file.name, overwrite),
    );
  }

  String _checkExists(Uri destination, String name, bool overwrite) {
    final String path = chainPathSegments(destination.path, name);
    if (!overwrite && File(path).existsSync()) {
      throw FileSystemException("File exists!", path);
    }
    return path;
  }
}
