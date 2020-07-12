import 'dart:io';
import 'dart:typed_data';

import 'package:rxdart/rxdart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rx_command/rx_command.dart';
import 'package:yaga/managers/mapping_manager.dart';
import 'package:yaga/managers/sync_manager.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/services/file_provider_service.dart';
import 'package:yaga/services/local_image_provider_service.dart';
import 'package:yaga/services/nextcloud_service.dart';

class FileManager {
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
  LocalImageProviderService _localFileService;
  Map<String, FileProviderService> _fileProviders = Map();

  //todo: private
  MappingManager mappingManager;
  SyncManager syncManager;

  FileManager(this._nextCloudService, this._localFileService, this.mappingManager, this.syncManager) {
    _fileProviders.putIfAbsent(_localFileService.scheme, () => _localFileService);
    _fileProviders.putIfAbsent(_nextCloudService.scheme, () => _nextCloudService);

    _getPreviewCommand = RxCommand.createSync((param) => param);
    //todo: this has to be improved; currently asyncMap blocks for download + writing file to local storage; we need it to block only for download
    //todo: bug: this also tries to fetch previews for local files; no check if the file is local or remote
    _getPreviewCommand.asyncMap((ncFile) => this._nextCloudService.getPreview(ncFile.uri)
      .then((value) async {
        ncFile.previewFile.createSync(recursive: true);
        ncFile.previewFile = await ncFile.previewFile.writeAsBytes(value, flush: true);
        await ncFile.previewFile.setLastModified(ncFile.lastModified);
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
        ncFile.localFile.createSync(recursive: true);
        ncFile.localFile = await ncFile.localFile.writeAsBytes(value, flush: true); 
        await ncFile.localFile.setLastModified(ncFile.lastModified);
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
      _localFileService.deleteFile(value.localFile);
    });

    removeTmp = RxCommand.createSync((param) => param);
    removeTmp.listen((value) {
      _localFileService.deleteFile(value.previewFile);
    });

    updateFileList = RxCommand.createSync((param) => param);
  }

  Stream<NcFile> listFiles(Uri uri) {
    Stream<NcFile> defaultStream = _fileProviders[uri.scheme].list(uri).asyncMap((file) async {
      if(file.localFile == null) {
        //todo: add reverse mapping to recognize local files which are coming from the cloud
        //todo: should this be a FileSystemEntity?
        file.localFile = await mappingManager.mapToLocalFile(file.uri);
        file.previewFile = _localFileService.getTmpFile(file.uri.path);
      }
      return file;
    })
    .doOnData((file) => syncManager.addRemoteFile(uri, file));
    //todo: we have to fix the issue with recognizing remotely deleted files
    if(this._nextCloudService.isUriOfService(uri)) {
      File previewFile = _localFileService.getTmpFile(uri.path);
      return Rx.merge([
        this._localFileService.list(previewFile.uri)
        .asyncMap((file) async {
          file.uri = await mappingManager.mapToRemoteUri(file.uri, uri, _localFileService.tmpAppDirUri);
          //todo: should this be a FileSystemEntity?
          file.localFile = await mappingManager.mapToLocalFile(file.uri);
          // file.previewFile = _localFileService.getTmpFile(file.uri.path);
          return file;
        })
        .doOnData((file) => syncManager.addTmpFile(uri, file)),
        this.mappingManager.mapToLocalFile(uri).asStream()
        .flatMap((value) => this._localFileService.list(value.uri))
        .asyncMap((file) async {
          file.uri = await mappingManager.mapToRemoteUri(file.uri, uri, _localFileService.externalAppDirUri);
          //todo: should this be a FileSystemEntity?
          // file.localFile = await mappingManager.mapToLocalFile(file.uri);
          file.previewFile = _localFileService.getTmpFile(file.uri.path);
          return file;
        })
        .doOnData((file) => syncManager.addLocalFile(uri, file)),
        defaultStream.doOnError((err, stack) {
          syncManager.removeUri(uri);
          throw err;
        })
      ]).doOnDone(() => syncManager.syncUri(uri).then((value) => value.forEach((element) {
        this.updateFileList(element);
        this.removeLocal(element);
        this.removeTmp(element);
      })));
    }

    return defaultStream;
  }
}