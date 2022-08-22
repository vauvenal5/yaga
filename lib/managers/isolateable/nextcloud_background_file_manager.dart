import 'package:yaga/managers/file_manager_base.dart';
import 'package:yaga/managers/file_sub_manager.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/services/isolateable/local_file_service.dart';
import 'package:yaga/services/isolateable/nextcloud_service.dart';
import 'package:yaga/utils/logger.dart';

class NextcloudBackgroundFileManager implements FileSubManager {
  final _logger = YagaLogger.getLogger(NextcloudBackgroundFileManager);
  final NextCloudService _nextCloudService;
  final LocalFileService _localFileService;
  final FileManagerBase _fileManager;

  NextcloudBackgroundFileManager(this._nextCloudService, this._localFileService, this._fileManager);

  Future<NextcloudBackgroundFileManager> initBackground() async {
    _fileManager.registerFileManager(this);
    return this;
  }

  //todo: background: clean up file manager mess

  @override
  Future<NcFile> deleteFile(NcFile file, {required bool local}) async {
    if (local) {
      _localFileService.deleteFile(file.localFile!.file);
      file.localFile!.exists = false;
      _fileManager.updateImageCommand(file);
      return file;
    }

    return _nextCloudService
        .deleteFile(file)
        .then((value) => _deleteLocalFile(file));
  }

  Future<NcFile> _deleteLocalFile(NcFile file) async {
    _logger.warning("Removing local file! (${file.uri.path})");
    _localFileService.deleteFile(file.localFile!.file);
    _localFileService.deleteFile(file.previewFile!.file);
    _fileManager.updateFileList(file);
    return file;
  }

  @override
  Stream<List<NcFile>> listFileList(Uri uri, {bool recursive = false}) {
    // TODO: implement listFileList
    throw UnimplementedError();
  }

  @override
  Stream<NcFile> listFiles(Uri uri, {bool recursive = false}) {
    // TODO: implement listFiles
    throw UnimplementedError();
  }

  @override
  Future<NcFile> copyFile(NcFile file, Uri destination,
      {bool overwrite = false}) =>
      _nextCloudService.copyFile(file, destination, overwrite: overwrite);

  @override
  Future<NcFile> moveFile(NcFile file, Uri destination,
      {bool overwrite = false}) =>
      _nextCloudService.moveFile(file, destination, overwrite: overwrite);

  @override
  String get scheme => _nextCloudService.scheme;


}