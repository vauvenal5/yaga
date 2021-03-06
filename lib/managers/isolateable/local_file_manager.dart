import 'dart:io';

import 'package:mime/mime.dart';
import 'package:yaga/managers/file_manager_base.dart';
import 'package:yaga/managers/file_sub_manager.dart';
import 'package:yaga/model/local_file.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/services/isolateable/local_file_service.dart';
import 'package:yaga/services/isolateable/system_location_service.dart';
import 'package:yaga/utils/forground_worker/isolateable.dart';
import 'package:yaga/utils/ncfile_stream_extensions.dart';
import 'package:yaga/utils/uri_utils.dart';
import 'package:rxdart/rxdart.dart';

class LocalFileManager
    with Isolateable<LocalFileManager>
    implements FileSubManager {
  final FileManagerBase _fileManager;
  final LocalFileService _localFileService;
  final SystemLocationService _systemPathService;

  @override
  String get scheme => _systemPathService.internalStorage.origin.scheme;

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
    return Stream.value(uri)
        .map(this._systemPathService.absoluteUriFromInternal)
        .map((uri) => Directory.fromUri(uri))
        .flatMap((dir) => _localFileService.list(dir))
        .map((event) {
      Uri uri = this._systemPathService.internalUriFromAbsolute(event.uri);

      NcFile file = _createFile(uri, event);
      file.localFile = LocalFile(event);
      file.localFile.exists = event.existsSync();
      return file;
    });
  }

  NcFile _createFile(Uri uri, FileSystemEntity event) {
    if (event is Directory) {
      NcFile file = NcFile.directory(
        uri,
        UriUtils.getNameFromUri(uri),
      );
      //todo: think about this!
      file.lastModified = DateTime.now();
      return file;
    }

    NcFile file = NcFile.file(
      uri,
      UriUtils.getNameFromUri(uri),
      lookupMimeType(event.path),
    );
    //todo: this value is not necessarily correct(!)
    file.lastModified = (event as File).lastModifiedSync().toUtc();
    return file;
  }

  @override
  Future<NcFile> deleteFile(NcFile file, bool local) async {
    this._localFileService.deleteFile(file.localFile.file);
    this._fileManager.updateFileList(file);
    return file;
  }

  @override
  Future<NcFile> copyFile(NcFile file, Uri destination, bool overwrite) async {
    this._localFileService.copyFile(
          file,
          this._systemPathService.absoluteUriFromInternal(destination),
          overwrite,
        );
    return file;
  }

  @override
  Future<NcFile> moveFile(NcFile file, Uri destination, bool overwrite) async {
    this._localFileService.moveFile(
          file,
          this._systemPathService.absoluteUriFromInternal(destination),
          overwrite,
        );
    return file;
  }
}
