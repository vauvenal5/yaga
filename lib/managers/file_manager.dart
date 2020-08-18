import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';
import 'package:rx_command/rx_command.dart';
import 'package:yaga/managers/file_sub_manager.dart';
import 'package:yaga/managers/mapping_manager.dart';
import 'package:yaga/managers/sync_manager.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/services/file_provider_service.dart';
import 'package:yaga/services/local_file_service.dart';
import 'package:yaga/services/local_image_provider_service.dart';
import 'package:yaga/services/nextcloud_service.dart';
import 'package:yaga/services/system_location_service.dart';

class FileManager {
  Logger _logger = Logger();
  RxCommand<NcFile, NcFile> _getPreviewCommand;
  RxCommand<NcFile, NcFile> _getImageCommand;

  RxCommand<NcFile, NcFile> downloadPreviewCommand;
  RxCommand<NcFile, NcFile> updatePreviewCommand;

  RxCommand<NcFile, NcFile> downloadImageCommand;
  RxCommand<NcFile, NcFile> updateImageCommand;

  RxCommand<NcFile, NcFile> removeLocal;
  RxCommand<NcFile, NcFile> removeTmp;

  RxCommand<NcFile, NcFile> updateFileList;

  NextCloudService _nextCloudService;
  LocalFileService _localFileService;
  Map<String, FileSubManager> _fileSubManagers = Map();

  FileManager(this._nextCloudService, this._localFileService) {
    _getPreviewCommand = RxCommand.createSync((param) => param);
    //todo: this has to be improved; currently asyncMap blocks for download + writing file to local storage; we need it to block only for download
    //todo: bug: this also tries to fetch previews for local files; no check if the file is local or remote
    _getPreviewCommand.asyncMap((ncFile) => this._nextCloudService.getPreview(ncFile.uri)
      .then((value) async {
        ncFile.previewFile = await _localFileService.createFile(
          file: ncFile.previewFile, 
          bytes: value, 
          lastModified: ncFile.lastModified
        );
        return ncFile;
      }, 
      onError: (err) {
        return null;
      })
    )
    .where((event) => event != null)
    .listen((value) => updatePreviewCommand(value));

    _getImageCommand = RxCommand.createSync((param) => param);
    //todo: this has to be improved; currently asyncMap blocks for download + writing file to local storage; we need it to block only for download
    _getImageCommand.asyncMap((ncFile) => this._nextCloudService.downloadImage(ncFile.uri)
      .then((value) async {
        ncFile.localFile = await _localFileService.createFile(
          file: ncFile.localFile, 
          bytes: value, 
          lastModified: ncFile.lastModified
        );
        return ncFile;
      }, 
      onError: (err) {
        return null;
      })
    )
    .where((event) => event != null)
    .listen((value) => updateImageCommand(value));

    downloadPreviewCommand = RxCommand.createSync((param) => param);
    downloadPreviewCommand.listen((ncFile) {
      if(ncFile.previewFile != null && ncFile.previewFile.existsSync()) {
        updatePreviewCommand(ncFile);
        return;
      }
      this._getPreviewCommand(ncFile);
    });

    downloadImageCommand = RxCommand.createSync((param) => param);
    downloadImageCommand.listen((ncFile) {
      if(ncFile.localFile != null && ncFile.localFile.existsSync()) {
        updateImageCommand(ncFile);
        return;
      }
      this._getImageCommand(ncFile);
    });

    updatePreviewCommand = RxCommand.createSync((param) => param);
    updateImageCommand = RxCommand.createSync((param) => param);

    removeLocal = RxCommand.createSync((param) => param);
    removeLocal.listen((value) {
      _logger.d("Removing local file ${value.localFile.path}");
      _localFileService.deleteFile(value.localFile);
    });

    removeTmp = RxCommand.createSync((param) => param);
    removeTmp.listen((value) {
      _logger.d("Removing preview file ${value.previewFile.path}");
      _localFileService.deleteFile(value.previewFile);
    });

    updateFileList = RxCommand.createSync((param) => param);
  }

  void registerFileManager(FileSubManager fileSubManager) {
    this._fileSubManagers.putIfAbsent(fileSubManager.scheme, () => fileSubManager);
  }

  Stream<NcFile> listFiles(Uri uri) {
    return this._fileSubManagers[uri.scheme].listFiles(uri);
  }
}