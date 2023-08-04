import 'package:flutter/foundation.dart';
import 'package:yaga/managers/file_manager/file_manager_base.dart';
import 'package:yaga/managers/file_service_manager/file_service_manager.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/services/isolateable/local_file_service.dart';
import 'package:yaga/services/isolateable/nextcloud_service.dart';
import 'package:yaga/utils/logger.dart';

class NextcloudBackgroundFileManager implements FileServiceManager {
  final _logger = YagaLogger.getLogger(NextcloudBackgroundFileManager);
  @protected
  final NextCloudService nextCloudService;
  @protected
  final LocalFileService localFileService;
  @protected
  final FileManagerBase fileManager;

  NextcloudBackgroundFileManager(this.nextCloudService, this.localFileService, this.fileManager);

  Future<NextcloudBackgroundFileManager> initBackground() async {
    fileManager.registerFileManager(this);
    return this;
  }

  //todo: background: clean up file manager mess

  @override
  Future<NcFile> deleteFile(NcFile file, {required bool local}) async {
    if (local) {
      localFileService.deleteFile(file.localFile!.file);
      file.localFile!.exists = false;
      fileManager.updateImageCommand(file);
      return file;
    }

    return nextCloudService
        .deleteFile(file)
        .then((value) => deleteLocalFile(file));
  }

  @protected
  Future<NcFile> deleteLocalFile(NcFile file) async {
    _logger.warning("Removing local file! (${file.uri.path})");
    localFileService.deleteFile(file.localFile!.file);
    localFileService.deleteFile(file.previewFile!.file);
    fileManager.updateFileList(file);
    return file;
  }

  @override
  Stream<List<NcFile>> listFileList(Uri uri, {bool recursive = false}) {
    // not supported in true background since listing files makes only sense when app in foreground
    throw UnimplementedError();
  }

  @override
  Stream<NcFile> listFiles(Uri uri, {bool recursive = false}) {
    // not supported in true background since listing files makes only sense when app in foreground
    throw UnimplementedError();
  }

  @override
  Future<NcFile> copyFile(NcFile file, Uri destination,
      {bool overwrite = false}) =>
      nextCloudService.copyFile(file, destination, overwrite: overwrite);

  @override
  Future<NcFile> moveFile(NcFile file, Uri destination,
      {bool overwrite = false}) =>
      nextCloudService.moveFile(file, destination, overwrite: overwrite);

  @override
  String get scheme => nextCloudService.scheme;


}