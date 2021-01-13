import 'dart:io';

import 'package:mime/mime.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yaga/services/service.dart';
import 'package:yaga/utils/forground_worker/isolateable.dart';
import 'package:yaga/utils/forground_worker/messages/init_msg.dart';

class LocalFileService extends Service<LocalFileService>
    implements Isolateable<LocalFileService> {
  PermissionStatus _permissionState;

  @override
  Future<LocalFileService> init() async {
    _permissionState = await Permission.storage.request();
    return this;
  }

  @override
  Future<LocalFileService> initIsolated(InitMsg init) async {
    _permissionState = PermissionStatus.granted;
    return this;
  }

  Future<File> createFile(
      {@required File file,
      @required List<int> bytes,
      DateTime lastModified}) async {
    logger.d("Creating file ${file.path}");
    await file.create(recursive: true);
    File res = await file.writeAsBytes(bytes, flush: true);
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
    if (file != null && file.existsSync()) {
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
    String type = lookupMimeType(path);
    return type != null && type.startsWith("image");
  }
}
