import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rxdart/rxdart.dart';

class LocalImageProviderService {

  Future<Directory> _tmpDir;
  Future<Directory> _externalAppDir;

  Future<Directory> _checkSetTmpDir() {
    if(_tmpDir == null) {
      _tmpDir = getTemporaryDirectory();
    }
    return _tmpDir;
  }

  Future<Directory> _checkSetExcternalAppDir() {
    if(_externalAppDir == null) {
      _externalAppDir = getExternalStorageDirectory();
    }
    return _externalAppDir;
  }

  Stream<FileSystemEntity> searchDir(String directory) {
    return Permission.storage.request().asStream()
      .where((event) => event.isGranted)
      .map((event) => new Directory(directory))
      .flatMap((dir) => dir.list(recursive: false, followLinks: false)
        //.where((entity) => entity is File)
        //.map((entity) => entity as File)
        //.where((file) => file.path.endsWith(".bmp") || file.path.endsWith(".jpg"))
      );
  }

  String _normalizePath(String path) => path.startsWith("/")?path.replaceFirst("/", ""):path;

  Future<File> getTmpFile(String path) async {
    String tmpPath = "${(await _checkSetTmpDir()).path}/${_normalizePath(path)}";
    return File(tmpPath);
  }

  Future<File> getLocalFile(String path) async {
    String localPath = "${(await _checkSetExcternalAppDir()).path}/${_normalizePath(path)}";
    return File(localPath);
  }
}