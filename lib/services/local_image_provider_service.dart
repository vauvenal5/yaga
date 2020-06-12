import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rxdart/rxdart.dart';
import 'package:yaga/model/nc_file.dart';

class LocalImageProviderService {
  final String scheme = "file";
  final String _android = "Android";
  Directory _tmpDir;
  Directory _externalAppDir;

  Future<void> init() async {
    _tmpDir = await getTemporaryDirectory();
    _externalAppDir = await getExternalStorageDirectory();
  }

  // Future<Directory> _checkSetTmpDir() {
  //   if(_tmpDir == null) {
  //     _tmpDir = getTemporaryDirectory();
  //   }
  //   return _tmpDir;
  // }

  // Future<Directory> _checkSetExcternalAppDir() {
  //   if(_externalAppDir == null) {
  //     _externalAppDir = getExternalStorageDirectory();
  //   }
  //   return _externalAppDir;
  // }

  // Future<Uri> _getOriginInternalStorage() async {
  //   // var splited = (await _checkSetExcternalAppDir()).path.split('/$_android');
  //   var splited = _externalAppDir.path.split('/$_android');
  //   var internal = splited[0].replaceFirst("/", "").split("/");
  //   var host = splited[0].replaceFirst("/${internal[0]}/", "").replaceAll("/", ".");
  //   return Uri(scheme: this.scheme, host: host, userInfo: internal[0], path: "");
  // }

  Uri _getOriginInternalStorage() {
    // var splited = (await _checkSetExcternalAppDir()).path.split('/$_android');
    var splited = _externalAppDir.path.split('/$_android');
    var internal = splited[0].replaceFirst("/", "").split("/");
    var host = splited[0].replaceFirst("/${internal[0]}/", "").replaceAll("/", ".");
    return Uri(scheme: this.scheme, host: host, userInfo: internal[0], path: "");
  }

  Future<Uri> _systemEntityToInternalUri(FileSystemEntity entity) async {
    var origin = _getOriginInternalStorage();
    print(origin.toString());
    var path = entity.path.replaceFirst(_internalUriToSystemPath(origin), "");
    return Uri(scheme: origin.scheme, host: origin.host, userInfo: origin.userInfo, path: path);
  }

  String _internalUriToSystemPath(Uri uri) {
    return "/${uri.userInfo}/${uri.host.replaceAll(".", "/")}${uri.path}";
  }

  Stream<NcFile> searchDir(Uri directory) {
    return Permission.storage.request().asStream()
      .where((event) => event.isGranted)
      .map((event) => new Directory(_internalUriToSystemPath(directory)))
      .flatMap((dir) => dir.list(recursive: false, followLinks: false)
      .map((event) async {
        NcFile file = NcFile();
        file.uri = await _systemEntityToInternalUri(event);
        file.name = file.uri.pathSegments.last;
        file.isDirectory = false;

        if(event is Directory) {
          file.isDirectory = true;
        } else {
          file.localFile = event;
          file.lastModified =  (event as File).lastModifiedSync();
        }

        return file;
      })
      .flatMap((value) => value.asStream())
        //.where((entity) => entity is File)
        //.map((entity) => entity as File)
        //.where((file) => file.path.endsWith(".bmp") || file.path.endsWith(".jpg"))
      );
  }

  String _normalizePath(String path) => path.startsWith("/")?path.replaceFirst("/", ""):path;

  Future<Uri> getExternalAppDirUri() async {
    // Directory dir = await _checkSetExcternalAppDir();
    return _systemEntityToInternalUri(_externalAppDir);
  }

  Future<File> getTmpFile(String path) async {
    // String tmpPath = "${(await _checkSetTmpDir()).path}/${_normalizePath(path)}";
    String tmpPath = "${_tmpDir.path}/${_normalizePath(path)}";
    return File(tmpPath);
  }

  Future<File> getLocalFile(String path) async {
    // String localPath = "${(await _checkSetExcternalAppDir()).path}/${_normalizePath(path)}";
    String localPath = "${_externalAppDir.path}/${_normalizePath(path)}";
    return File(localPath);
  }

  Uri getOrigin() {
    return _getOriginInternalStorage();
  }
}