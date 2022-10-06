import 'dart:isolate';

import 'package:rx_command/rx_command.dart';
import 'package:yaga/managers/file_manager/isolateable/file_action_manager.dart';
import 'package:yaga/managers/isolateable/sort_manager.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/sort_config.dart';
import 'package:yaga/model/sorted_file_list.dart';
import 'package:yaga/utils/forground_worker/isolateable.dart';
import 'package:yaga/utils/forground_worker/messages/file_list_message.dart';
import 'package:yaga/utils/forground_worker/messages/file_list_response.dart';
import 'package:yaga/utils/forground_worker/messages/file_update_msg.dart';
import 'package:yaga/utils/forground_worker/messages/image_update_msg.dart';
import 'package:yaga/utils/forground_worker/messages/init_msg.dart';
import 'package:yaga/utils/logger.dart';
import 'package:rxdart/rxdart.dart';

class IsolatedFileManager extends FileActionManager
    with Isolateable<IsolatedFileManager> {
  final _logger = YagaLogger.getLogger(IsolatedFileManager);

  final SortManager _sortManager;
  RxCommand<FileListMessage, FileListMessage> updateFilesCommand = RxCommand.createSync((param) => param);

  IsolatedFileManager(this._sortManager);

  @override
  Future<IsolatedFileManager> initIsolated(
    InitMsg init,
    SendPort isolateToMain,
  ) async {
    //todo: we probably can improve the capsuling of front end and foreground_worker communication further
    //--> check if it is possible to completely hide communications in bridges
    updateFileList.listen(
      (value) => isolateToMain.send(FileUpdateMsg("", value)),
    );

    updateImageCommand.listen(
      (file) => isolateToMain.send(ImageUpdateMsg("", file)),
    );

    updateFilesCommand.listen((event) => isolateToMain.send(event));

    return this;
  }

  Future<void> listFileLists(
    String requestKey,
    Uri uri,
    SortConfig sortConfig, {
    bool recursive = false,
  }) async {
    return fileServiceManagers[uri.scheme]
        ?.listFileList(uri, recursive: recursive)
        .map((event) => _sortManager.sortList(event, sortConfig))
        .fold(
      null,
      (SortedFileList<SortedFileList<dynamic>>? previous, element) {
        if (previous == null) {
          updateFilesCommand(
            FileListResponse(requestKey, uri, element, recursive: recursive),
          );
          return element;
        }

        if (_sortManager.mergeSort(previous, element)) {
          updateFilesCommand(
            FileListResponse(requestKey, uri, previous, recursive: recursive),
          );
        }

        return previous;
      },
    ).then((value) => value);
  }

  @override
  Stream<NcFile> listFiles(Uri uri, {bool recursive = false}) {
    //todo: throw when scheme is not registered
    return fileServiceManagers[uri.scheme]?.listFiles(uri).flatMap((file) =>
      file.isDirectory && recursive
        ? listFiles(file.uri, recursive: recursive)
        : Stream.value(file)) ??
        const Stream.empty();
  }
}
