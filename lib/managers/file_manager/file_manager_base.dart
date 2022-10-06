import 'package:flutter/foundation.dart';
import 'package:rx_command/rx_command.dart';
import 'package:rxdart/rxdart.dart';
import 'package:yaga/managers/file_sub_manager.dart';
import 'package:yaga/model/fetched_file.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/utils/forground_worker/messages/file_list_message.dart';

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
  Map<String, FileSubManager> fileSubManagers = {};

  FileManagerBase() {
    fetchedFileCommand = RxCommand.createSync((param) {
      updateImageCommand(param.file);
      return param;
    });
  }

  void registerFileManager(FileSubManager fileSubManager) {
    fileSubManagers.putIfAbsent(fileSubManager.scheme, () => fileSubManager);
  }

  //todo: fileManager refactoring: this method should not be callable from the UI
  Stream<NcFile> listFiles(Uri uri, {bool recursive = false}) {
    //todo: throw when scheme is not registered
    return fileSubManagers[uri.scheme]?.listFiles(uri).flatMap((file) =>
            file.isDirectory && recursive
                ? listFiles(file.uri, recursive: recursive)
                : Stream.value(file)) ??
        const Stream.empty();
  }
}
