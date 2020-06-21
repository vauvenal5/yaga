import 'dart:io';
import 'dart:typed_data';

import 'package:rxdart/rxdart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rx_command/rx_command.dart';
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

  NextCloudService _nextCloudService;
  LocalImageProviderService _localFileService;
  Map<String, FileProviderService> _fileProviders = Map();

  FileManager(this._nextCloudService, this._localFileService) {
    _fileProviders.putIfAbsent(_localFileService.scheme, () => _localFileService);
    _fileProviders.putIfAbsent(_nextCloudService.scheme, () => _nextCloudService);

    _getPreviewCommand = RxCommand.createSync((param) => param);
    //todo: this has to be improved; currently asyncMap blocks for download + writing file to local storage; we need it to block only for download
    //todo: bug: this also tries to fetch previews for local files; no check if the file is local or remote
    _getPreviewCommand.asyncMap((ncFile) => this._nextCloudService.getPreview(ncFile.uri.path)
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
    _getImageCommand.asyncMap((ncFile) => this._nextCloudService.downloadImage(ncFile.uri.path)
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
  }

  Stream<NcFile> listFiles(Uri uri) {
    return _fileProviders[uri.scheme].list(uri).doOnData((file) {
      if(file.localFile == null) {
        //todo: this is actually already a "mapping" activity and has to be handled by the FileMapperManager in future
        file.localFile = _localFileService.getLocalFile(Uri.decodeComponent(file.uri.path));
        file.previewFile = _localFileService.getTmpFile(Uri.decodeComponent(file.uri.path));
      }
    });
  }
}