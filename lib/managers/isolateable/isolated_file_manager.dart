import 'dart:isolate';

import 'package:rx_command/rx_command.dart';
import 'package:yaga/managers/file_manager_base.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/utils/forground_worker/isolateable.dart';
import 'package:yaga/utils/forground_worker/messages/file_update_msg.dart';
import 'package:yaga/utils/forground_worker/messages/image_update_msg.dart';
import 'package:yaga/utils/forground_worker/messages/init_msg.dart';
import 'package:rxdart/rxdart.dart';
import 'package:yaga/utils/logger.dart';
import 'package:yaga/utils/uri_utils.dart';

class IsolatedFileManager extends FileManagerBase
    with Isolateable<IsolatedFileManager> {
  final _logger = getLogger(IsolatedFileManager);

  RxCommand<void, bool> cancelActionCommand =
      RxCommand.createSyncNoParam(() => true);

  Future<IsolatedFileManager> initIsolated(
    InitMsg init,
    SendPort isolateToMain,
  ) async {
    //todo: we probably can improve the capsuling of front end and foreground_worker communication further
    //--> check if it is possible to completely hide communications in bridges
    this.updateFileList.listen(
          (value) => isolateToMain.send(FileUpdateMsg("", value)),
        );

    this.updateImageCommand.listen(
          (file) => isolateToMain.send(ImageUpdateMsg("", file)),
        );

    this.updateFilesCommand.listen((event) => isolateToMain.send(event));

    return this;
  }

  Future<void> deleteFiles(List<NcFile> files, bool local) async =>
      this._cancelableAction(
        files,
        (file) => this.fileSubManagers[file.uri.scheme].deleteFile(
              file,
              local,
            ),
      );

  Future<void> copyFiles(List<NcFile> files, Uri destination) async =>
      this._cancelableAction(
        files,
        (file) => this.fileSubManagers[file.uri.scheme].copyFile(
              file,
              destination,
            ),
        filter: (file) => _destinationFilter(file, destination),
      );

  Future<void> moveFiles(List<NcFile> files, Uri destination) async =>
      this._cancelableAction(
        files,
        (file) => fileSubManagers[file.uri.scheme]
            .moveFile(file, destination)
            .then((value) => this.updateFileList(file)),
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
          (file) => action(file),
        )
        .takeUntil(
          this
              .cancelActionCommand
              .doOnData((event) => _logger.v("Canceling action!")),
        )
        .last;
  }
}
