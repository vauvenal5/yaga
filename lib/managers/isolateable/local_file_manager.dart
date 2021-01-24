import 'dart:io';

import 'package:mime/mime.dart';
import 'package:yaga/managers/file_manager_base.dart';
import 'package:yaga/managers/file_sub_manager.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/services/isolateable/local_file_service.dart';
import 'package:yaga/services/isolateable/system_location_service.dart';
import 'package:yaga/utils/forground_worker/isolateable.dart';
import 'package:yaga/utils/ncfile_stream_extensions.dart';

class LocalFileManager
    with Isolateable<LocalFileManager>
    implements FileSubManager {
  final FileManagerBase _fileManager;
  final LocalFileService _localFileService;
  final SystemLocationService _systemPathService;

  @override
  String get scheme => _systemPathService.getOrigin().scheme;

  LocalFileManager(
      this._fileManager, this._localFileService, this._systemPathService) {
    this._fileManager.registerFileManager(this);
  }

  @override
  //todo: should add a wrapper around uri to distinguish between internal and absolute uri
  // --> for example this serivce requires a internal uri but the call from within the nextcloudFileManager passes an absolute uri!
  Stream<NcFile> listFiles(
    Uri uri, {
    bool recursive = false,
  }) {
    //todo: add uri check? or simply handle exception?
    return this
        ._listLocalFiles(uri)
        .recursively(recursive, this._listLocalFiles);
  }

  @override
  Stream<List<NcFile>> listFileList(
    Uri uri, {
    bool recursive = false,
  }) {
    return this.listFiles(uri, recursive: recursive).collectToList();
  }

  Stream<NcFile> _listLocalFiles(Uri uri) {
    //todo: add uri check? or simply handle exception?
    return _localFileService
        .list(Directory.fromUri(
            this._systemPathService.absoluteUriFromInternal(uri)))
        .map((event) {
      Uri uri = this._systemPathService.internalUriFromAbsolute(event.uri);

      NcFile file = _createFile(uri, event);
      file.localFile = event;
      return file;
    });
  }

  NcFile _createFile(Uri uri, FileSystemEntity event) {
    if (event is Directory) {
      NcFile file = NcFile.directory(
        uri,
        uri.pathSegments[uri.pathSegments.length - 2],
      );
      //todo: think about this!
      file.lastModified = DateTime.now();
      return file;
    }

    NcFile file = NcFile.file(
      uri,
      uri.pathSegments.last,
      lookupMimeType(event.path),
    );
    file.lastModified = (event as File).lastModifiedSync();
    return file;
  }

  @override
  Future<NcFile> deleteFile(NcFile file, bool local) async {
    this._localFileService.deleteFile(file.localFile);
    this._fileManager.updateFileList(file);
    return file;
  }

  @override
  Future<NcFile> copyFile(NcFile file, Uri destination) async {
    this._localFileService.copyFile(
          file,
          this._systemPathService.absoluteUriFromInternal(destination),
        );
    return file;
  }
}
