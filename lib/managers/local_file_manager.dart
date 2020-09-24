import 'dart:io';

import 'package:yaga/managers/file_manager.dart';
import 'package:yaga/managers/file_sub_manager.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/services/local_file_service.dart';
import 'package:yaga/services/system_location_service.dart';

class LocalFileManager implements FileSubManager {
  final FileManager _fileManager;
  final LocalFileService _localFileService;
  final SystemLocationService _systemPathService;
  
  @override
  String get scheme => _systemPathService.getOrigin().scheme;

  LocalFileManager(this._fileManager, this._localFileService, this._systemPathService);

  Future<LocalFileManager> init() async {
    this._fileManager.registerFileManager(this);
    return this;
  }

  @override
  //todo: should add a wrapper around uri to distinguish between internal and absolute uri
  // --> for example this serivce requires a internal uri but the call from within the nextcloudFileManager passes an absolute uri!
  Stream<NcFile> listFiles(Uri uri) {
    //todo: add uri check? or simply handle exception?
    return _localFileService.list(Directory.fromUri(this._systemPathService.absoluteUriFromInternal(uri)))
      .map((event) {
        NcFile file = NcFile();
        file.uri = this._systemPathService.internalUriFromAbsolute(event.uri);

        if(event is Directory) {
          file.isDirectory = true;
          file.name = file.uri.pathSegments[file.uri.pathSegments.length-2];
        } else {
          file.isDirectory = false;
          file.name = file.uri.pathSegments.last;
          //todo: also set for directories? or at least don't set anything (see file_manager: list)
          file.localFile = event;
          file.lastModified =  (event as File).lastModifiedSync();
        }

        return file;
      });
  }

  @override
  Stream<List<NcFile>> listFileList(Uri uri, {bool recursive = false}) {
    //todo: implement recursive
    return this.listFiles(uri).toList().asStream();
  }
}