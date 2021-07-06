import 'dart:io';
import 'dart:isolate';

import 'package:nextcloud/nextcloud.dart';
import 'package:rx_command/rx_command.dart';
import 'package:yaga/managers/file_manager_base.dart';
import 'package:yaga/managers/isolateable/sort_manager.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/sort_config.dart';
import 'package:yaga/model/sorted_file_list.dart';
import 'package:yaga/utils/forground_worker/isolateable.dart';
import 'package:yaga/utils/forground_worker/messages/file_list_response.dart';
import 'package:yaga/utils/forground_worker/messages/file_update_msg.dart';
import 'package:yaga/utils/forground_worker/messages/image_update_msg.dart';
import 'package:yaga/utils/forground_worker/messages/init_msg.dart';
import 'package:rxdart/rxdart.dart';
import 'package:yaga/utils/logger.dart';
import 'package:yaga/utils/uri_utils.dart';

class IsolatedFileManager extends FileManagerBase
    with Isolateable<IsolatedFileManager> {
  final _logger = YagaLogger.getLogger(IsolatedFileManager);

  final SortManager _sortManager;

  RxCommand<void, bool> cancelActionCommand =
      RxCommand.createSyncNoParam(() => true);

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
  }) {
    return fileSubManagers[uri.scheme]
        .listFileList(uri, recursive: recursive)
        .map((event) => _sortManager.sortList(event, sortConfig))
        .fold(
      null,
      (SortedFileList<SortedFileList<dynamic>> previous, element) {
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

  Future<void> deleteFiles(List<NcFile> files, {bool local}) async =>
      _cancelableAction(
        files,
        (file) => fileSubManagers[file.uri.scheme].deleteFile(
          file,
          local: local,
        ),
      );

  Future<void> copyFiles(List<NcFile> files, Uri destination,
          {bool overwrite}) async =>
      _cancelableAction(
        files,
        (file) => fileSubManagers[file.uri.scheme]
            .copyFile(file, destination, overwrite: overwrite),
        filter: (file) => _destinationFilter(file, destination),
      );

  Future<void> moveFiles(List<NcFile> files, Uri destination,
          {bool overwrite}) async =>
      _cancelableAction(
        files,
        (file) => fileSubManagers[file.uri.scheme]
            .moveFile(file, destination, overwrite: overwrite)
            .then((value) => updateFileList(file)),
        filter: (file) => _destinationFilter(file, destination),
      );

  bool _destinationFilter(NcFile file, Uri destination) =>
      file.uri.path != UriUtils.chainPathSegments(destination.path, file.name);

  Future<void> _cancelableAction(
    List<NcFile> files,
    Future<dynamic> Function(NcFile) action, {
    bool Function(NcFile file) filter,
  }) {
    return Stream.fromIterable(files)
        .where((event) => filter == null || filter(event))
        .asyncMap(
          (file) => action(file).catchError(
            (err) => null,
            test: (err) =>
                err is RequestException || err is FileSystemException,
          ),
        )
        .where((event) => event != null)
        .takeUntil(
          cancelActionCommand
              .doOnData((event) => _logger.finest("Canceling action!")),
        )
        .last;
  }
}
