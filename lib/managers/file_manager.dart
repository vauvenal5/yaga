import 'dart:io';

import 'package:rx_command/rx_command.dart';
import 'package:yaga/managers/file_manager_base.dart';
import 'package:yaga/model/fetched_file.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/services/isolateable/local_file_service.dart';
import 'package:yaga/services/isolateable/nextcloud_service.dart';

class FileManager extends FileManagerBase {
  RxCommand<NcFile, NcFile> _getImageCommand;

  RxCommand<NcFile, NcFile> downloadImageCommand;

  NextCloudService _nextCloudService;
  LocalFileService _localFileService;

  FileManager(this._nextCloudService, this._localFileService) {
    _getImageCommand = RxCommand.createSync((param) => param);
    //todo: this has to be improved; currently asyncMap blocks for download + writing file to local storage; we need it to block only for download
    _getImageCommand
        .asyncMap((ncFile) => this
                ._nextCloudService
                .downloadImage(ncFile.uri)
                .then((value) async {
              ncFile.localFile.file = await _localFileService.createFile(
                  file: ncFile.localFile.file,
                  bytes: value,
                  lastModified: ncFile.lastModified);
              return FetchedFile(ncFile, value);
            }, onError: (err) {
              return null;
            }))
        .where((event) => event != null)
        .listen((value) => fetchedFileCommand(value));

    downloadImageCommand = RxCommand.createSync((param) => param);
    downloadImageCommand.listen((ncFile) async {
      if (ncFile.localFile != null && ncFile.localFile.file.existsSync()) {
        fetchedFileCommand(FetchedFile(
          ncFile,
          await (ncFile.localFile.file as File).readAsBytes(),
        ));
        return;
      }
      this._getImageCommand(ncFile);
    });
  }
}
