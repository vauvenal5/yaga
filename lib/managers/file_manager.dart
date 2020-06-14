import 'dart:io';
import 'dart:typed_data';

import 'package:rxdart/rxdart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rx_command/rx_command.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/services/file_provider_service.dart';
import 'package:yaga/services/local_image_provider_service.dart';
import 'package:yaga/services/nextcloud_service.dart';
import 'package:yaga/utils/service_locator.dart';

class FileManager {
  RxCommand<NcFile, NcFile> _getPreviewCommand;
  RxCommand<NcFile, NcFile> _getImageCommand;

  RxCommand<NcFile, NcFile> downloadPreviewCommand;
  RxCommand<NcFile, NcFile> updatePreviewCommand;

  RxCommand<NcFile, NcFile> downloadImageCommand;
  RxCommand<NcFile, NcFile> updateImageCommand;

  RxCommand<Uri, Uri> listFilesCommand;
  RxCommand<NcFile, NcFile> updateFilesListCommand;

  NextCloudService _nextCloudService;
  LocalImageProviderService _localFileService;
  Map<String, FileProviderService> _fileProviders = Map();

  FileManager() {
    _nextCloudService = getIt.get<NextCloudService>();
    _localFileService = getIt.get<LocalImageProviderService>();
    _fileProviders.putIfAbsent(_localFileService.scheme, () => _localFileService);
    _fileProviders.putIfAbsent(_nextCloudService.scheme, () => _nextCloudService);

    _getPreviewCommand = RxCommand.createSync((param) => param);
    //todo: this has to be improved; currently asyncMap blocks for download + writing file to local storage; we need it to block only for download
    _getPreviewCommand.asyncMap((ncFile) => getIt.get<NextCloudService>().getPreview(ncFile.uri.path)
      .then((value) async {
        ncFile.previewFile.createSync(recursive: true);
        ncFile.previewFile = await ncFile.previewFile.writeAsBytes(value); 
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
    _getImageCommand.asyncMap((ncFile) => getIt.get<NextCloudService>().downloadImage(ncFile.uri.path)
      .then((value) async {
        ncFile.localFile.createSync(recursive: true);
        ncFile.localFile = await ncFile.localFile.writeAsBytes(value); 
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

    updateFilesListCommand = RxCommand.createSync((param) => param);
    listFilesCommand = RxCommand.createSync((param) => param);
    listFilesCommand.flatMap((uri) => _fileProviders[uri.scheme].list(uri))
    .listen((file) {
      if(file.localFile == null) {
        //todo: this is actually already a "mapping" activity and has to be handled by the FileMapperManager in future
        file.localFile = _localFileService.getLocalFile(file.uri.path);
        file.previewFile = _localFileService.getTmpFile(file.uri.path);
      }
      updateFilesListCommand(file);
    });
  }
}