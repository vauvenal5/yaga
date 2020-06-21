import 'dart:io';

import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rxdart/rxdart.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/services/file_provider_service.dart';

class LocalImageProviderService implements FileProviderService<LocalImageProviderService> {
  final String scheme = "file";
  final String _android = "Android";
  Directory _tmpDir;
  Directory _externalAppDir;

  @override
  Future<LocalImageProviderService> init() async {
    _tmpDir = await getTemporaryDirectory();
    _externalAppDir = await getExternalStorageDirectory();
    return this;
  }

  Uri _getOriginInternalStorage() {
    var splited = _externalAppDir.path.split('/$_android');
    var internal = splited[0].replaceFirst("/", "").split("/");
    var host = splited[0].replaceFirst("/${internal[0]}/", "").replaceAll("/", ".");
    return Uri(scheme: this.scheme, host: host, userInfo: internal[0], path: "");
  }

  Uri _systemEntityToInternalUri(FileSystemEntity entity) {
    var origin = _getOriginInternalStorage();
    print(origin.toString());
    var path = entity.path.replaceFirst(_internalUriToSystemPath(origin), "");
    return Uri(scheme: origin.scheme, host: origin.host, userInfo: origin.userInfo, path: path);
  }

  String _internalUriToSystemPath(Uri uri) {
    return "/${uri.userInfo}/${uri.host.replaceAll(".", "/")}${uri.path}";
  }

  bool _checkMimeType(String path) {
    String type = lookupMimeType(path);
    return type != null && type.startsWith("image");
  }

  @override
  Stream<NcFile> list(Uri directory) {
    //todo: bug: for local files we are missing file type filtering
    return Permission.storage.request().asStream()
      .where((event) => event.isGranted)
      .map((event) => new Directory(_internalUriToSystemPath(directory)))
      .flatMap((dir) => dir.list(recursive: false, followLinks: false)
      .where((event) => event is Directory || _checkMimeType(event.path))
      .map((event) {
        NcFile file = NcFile();
        file.uri = _systemEntityToInternalUri(event);
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
        //.where((entity) => entity is File)
        //.map((entity) => entity as File)
        //.where((file) => file.path.endsWith(".bmp") || file.path.endsWith(".jpg"))
      );
  }

  String _normalizePath(String path) => path.startsWith("/")?path.replaceFirst("/", ""):path;

  Uri get externalAppDirUri => _systemEntityToInternalUri(_externalAppDir);

  File getTmpFile(String path) {
    // String tmpPath = "${(await _checkSetTmpDir()).path}/${_normalizePath(path)}";
    String tmpPath = "${_tmpDir.path}/${_normalizePath(path)}";
    return File(tmpPath);
  }

  File getLocalFile(String path) {
    // String localPath = "${(await _checkSetExcternalAppDir()).path}/${_normalizePath(path)}";
    String localPath = "${_externalAppDir.path}/${_normalizePath(path)}";
    return File(localPath);
  }

  Uri getOrigin() {
    return _getOriginInternalStorage();
  }
}