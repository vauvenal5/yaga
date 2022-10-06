import 'package:flutter/foundation.dart';
import 'package:rx_command/rx_command.dart';
import 'package:yaga/managers/file_service_manager/file_service_manager.dart';
import 'package:yaga/model/fetched_file.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/utils/forground_worker/messages/file_list_message.dart';

/// File Managers provide files functions, i.e. copy/delete/move/download
/// with context of required actions over multiple services
abstract class FileManagerBase {
  RxCommand<NcFile, NcFile> updateFileList =
      RxCommand.createSync((param) => param);
  RxCommand<NcFile, NcFile> updateImageCommand =
      RxCommand.createSync((param) => param);
  late RxCommand<FetchedFile, FetchedFile> fetchedFileCommand;
  //todo: Background: this should be moved out of here because it does not concern FileActionsManager
  RxCommand<FileListMessage, FileListMessage> updateFilesCommand =
      RxCommand.createSync((param) => param);

  @protected
  Map<String, FileServiceManager> fileServiceManagers = {};

  FileManagerBase() {
    fetchedFileCommand = RxCommand.createSync((param) {
      updateImageCommand(param.file);
      return param;
    });
  }

  void registerFileManager(FileServiceManager fileServiceManager) {
    fileServiceManagers.putIfAbsent(fileServiceManager.scheme, () => fileServiceManager);
  }

  //todo: fileManager refactoring: this method should not be callable from the UI
  Stream<NcFile> listFiles(Uri uri, {bool recursive = false});
}
