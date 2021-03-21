import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/foundation.dart';
import 'package:rx_command/rx_command.dart';
import 'package:yaga/managers/file_sub_manager.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/utils/forground_worker/messages/file_list_response.dart';
import 'package:yaga/utils/logger.dart';

abstract class FileManagerBase {
  Logger _logger = YagaLogger.getLogger(FileManagerBase);

  RxCommand<NcFile, NcFile> updateFileList;
  RxCommand<NcFile, NcFile> updateImageCommand =
      RxCommand.createSync((param) => param);
  RxCommand<FileListResponse, FileListResponse> updateFilesCommand =
      RxCommand.createSync((param) => param);

  @protected
  Map<String, FileSubManager> fileSubManagers = Map();

  FileManagerBase() {
    updateFileList = RxCommand.createSync((param) => param);
  }

  void registerFileManager(FileSubManager fileSubManager) {
    this
        .fileSubManagers
        .putIfAbsent(fileSubManager.scheme, () => fileSubManager);
  }

  Stream<NcFile> listFiles(Uri uri, {bool recursive = false}) {
    return this.fileSubManagers[uri.scheme].listFiles(uri).flatMap((file) =>
        file.isDirectory && recursive
            ? this.listFiles(file.uri, recursive: recursive)
            : Stream.value(file));
  }
}
