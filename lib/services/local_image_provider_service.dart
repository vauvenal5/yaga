import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rxdart/rxdart.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/services/file_provider_service.dart';
import 'package:yaga/services/isolateable/system_location_service.dart';

class LocalImageProviderService
    extends FileProviderService<LocalImageProviderService> {
  final String schemeLocal = "local";
  final String schemeTmp = "tmp";
  final String _android = "Android";
  Directory _tmpDir;
  Directory _externalAppDir;
  SystemLocationService systemPathService;

  LocalImageProviderService(this.systemPathService);

  @override
  Future<LocalImageProviderService> init() async {
    _tmpDir = await getTemporaryDirectory();
    _externalAppDir = await getExternalStorageDirectory();
    return this;
  }

  // Uri _getOriginInternalStorage() {
  //   _logger.w(SystemLocations.local.getName());
  //   var splited = _externalAppDir.path.split('/$_android');
  //   var internal = splited[0].replaceFirst("/", "").split("/");
  //   var host = splited[0].replaceFirst("/${internal[0]}/", "").replaceAll("/", ".");
  //   return Uri(scheme: this.schemeLocal, host: host, userInfo: internal[0], path: "");
  // }

  // Uri _systemEntityToInternalUri(FileSystemEntity entity) {
  //   var origin = _getOriginInternalStorage();
  //   // String originAsPath = origin.toSystemPath();
  //   String originAsPath = _internalUriToSystemPath(origin);
  //   if(!entity.path.startsWith(originAsPath)) {
  //     return UriUtils.fromUri(uri: entity.uri, path: entity.path);
  //   }
  //   var path = entity.path.replaceFirst(originAsPath, "");
  //   return UriUtils.fromUri(uri: origin, path: path);
  // }

  // String _internalUriToSystemPath(Uri uri) {
  //   //uri is absolut: this is the case for tmp files
  //   if(uri.userInfo == "") {
  //     return uri.path;
  //   }
  //   return "/${uri.userInfo}/${uri.host.replaceAll(".", "/")}${Uri.decodeComponent(uri.path)}";
  // }

  bool _checkMimeType(String path) {
    String type = lookupMimeType(path);
    return type != null && type.startsWith("image");
  }

  @override
  Stream<NcFile> list(Uri directory) {
    //todo: bug: for local files we are missing file type filtering
    return Permission.storage
        .request()
        .asStream()
        .where((event) => event.isGranted)
        .map((event) => new Directory(
            this.systemPathService.absoluteUriFromInternal(directory).path))
        // .map((event) => new Directory(_internalUriToSystemPath(directory)))
        //.map((event) => new Directory(directory.toSystemPath()))
        .flatMap((dir) => dir
                    .list(recursive: false, followLinks: false)
                    .where((event) =>
                        event is Directory || _checkMimeType(event.path))
                    .map((event) {
                  NcFile file = NcFile(this
                      .systemPathService
                      .internalUriFromAbsolute(event.uri));
                  // file.uri = _systemEntityToInternalUri(event);
                  file.name = file.uri.pathSegments.last;
                  file.isDirectory = false;

                  if (event is Directory) {
                    file.isDirectory = true;
                  } else {
                    //todo: also set for directories? or at least don't set anything (see file_manager: list)
                    if (file.uri.userInfo == "") {
                      file.previewFile = event;
                    } else {
                      file.localFile = event;
                    }
                    file.lastModified = (event as File).lastModifiedSync();
                  }

                  return file;
                })
            //.where((entity) => entity is File)
            //.map((entity) => entity as File)
            //.where((file) => file.path.endsWith(".bmp") || file.path.endsWith(".jpg"))
            );
  }

  String _normalizePath(String path) {
    path = Uri.decodeComponent(path);
    return path.startsWith("/") ? path.replaceFirst("/", "") : path;
  }

  // Uri get externalAppDirUri => _systemEntityToInternalUri(_externalAppDir);
  Uri get externalAppDirUri => this.systemPathService.externalAppDirUri;

  // Uri get tmpAppDirUri => _systemEntityToInternalUri(_tmpDir);
  Uri get tmpAppDirUri => this.systemPathService.tmpAppDirUri;

  File getTmpFile(String path) {
    // String tmpPath = "${(await _checkSetTmpDir()).path}/${_normalizePath(path)}";
    String tmpPath = "${_tmpDir.path}/${_normalizePath(path)}";
    return File(tmpPath);
  }

  File getLocalFile(String path, {Uri internalPathPrefix}) {
    // String localPath = "${(await _checkSetExcternalAppDir()).path}/${_normalizePath(path)}";
    String prefix = _externalAppDir.path;
    if (internalPathPrefix != null) {
      // prefix = _internalUriToSystemPath(internalPathPrefix);
      prefix = this
          .systemPathService
          .absoluteUriFromInternal(internalPathPrefix)
          .path;
    }
    String localPath = "$prefix/${_normalizePath(path)}";
    return File(localPath);
  }

  File getFile(Uri uri) {
    return File.fromUri(this.systemPathService.absoluteUriFromInternal(uri));
  }

  Uri getOrigin() {
    // return _getOriginInternalStorage();
    return this.systemPathService.getOrigin();
  }

  //todo: refactor when adding remote delete function
  void deleteFile(File file) {
    //todo: null exception comes from webview cache files
    //todo: subtask1: local files in cache and default app dir should be in a user@cloud.bla folder
    //todo: subtask2: check if file is null before delete --> done
    //todo: subtask3: webview should not cache data
    if (file != null && file.existsSync()) {
      file.deleteSync();
    }
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
}
