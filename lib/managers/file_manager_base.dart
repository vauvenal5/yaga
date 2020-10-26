import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/foundation.dart';
import 'package:rx_command/rx_command.dart';
import 'package:yaga/managers/file_sub_manager.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/utils/logger.dart';

abstract class FileManagerBase {
  Logger _logger = getLogger(FileManagerBase);

  RxCommand<NcFile, NcFile> updateFileList;

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

  Stream<List<NcFile>> listFileLists(Uri uri, {bool recursive = false}) {
    return this.fileSubManagers[uri.scheme].listFileList(uri).flatMap((list) {
      if (!recursive) {
        return Stream.value(list);
      }

      return Rx.merge([
        Stream.value(list),
        Stream.fromIterable(list)
            .where((file) => file.isDirectory)
            .doOnData((file) =>
                _logger.d("Emiting from recursive. (${file.uri.path})"))
            .flatMap(
                (file) => this.listFileLists(file.uri, recursive: recursive))
      ]);
    });
  }
}
