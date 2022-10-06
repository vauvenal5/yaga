import 'dart:io';

import 'package:nextcloud/nextcloud.dart';
import 'package:rx_command/rx_command.dart';
import 'package:rxdart/rxdart.dart';
import 'package:yaga/managers/file_manager/file_manager_base.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/utils/background_worker/background_channel.dart';
import 'package:yaga/utils/forground_worker/messages/file_update_msg.dart';
import 'package:yaga/utils/forground_worker/messages/image_update_msg.dart';
import 'package:yaga/utils/logger.dart';
import 'package:yaga/utils/uri_utils.dart';

class FileActionManager extends FileManagerBase {
  final _logger = YagaLogger.getLogger(FileActionManager);
  RxCommand<void, bool> cancelActionCommand =
      RxCommand.createSyncNoParam(() => true);

  Future<FileActionManager> initBackground(
    BackgroundChannel backgroundToMain,
  ) async {
    updateFileList.listen(
          (value) => backgroundToMain.send(FileUpdateMsg("", value)),
    );

    updateImageCommand.listen(
          (file) => backgroundToMain.send(ImageUpdateMsg("", file)),
    );

    return this;
  }

  Future<void> deleteFiles(List<NcFile> files, {required bool local}) async =>
      _cancelableAction(
        files,
        (file) async => fileServiceManagers[file.uri.scheme]?.deleteFile(
          file,
          local: local,
        ),
      );

  Future<void> copyFiles(List<NcFile> files, Uri destination,
          {required bool overwrite}) async =>
      _cancelableAction(
        files,
        (file) async => fileServiceManagers[file.uri.scheme]
            ?.copyFile(file, destination, overwrite: overwrite),
        filter: (file) => _destinationFilter(file, destination),
      );

  Future<void> moveFiles(List<NcFile> files, Uri destination,
          {required bool overwrite}) async =>
      _cancelableAction(
        files,
        (file) async => fileServiceManagers[file.uri.scheme]
            ?.moveFile(file, destination, overwrite: overwrite)
            .then((value) => updateFileList(file)),
        filter: (file) => _destinationFilter(file, destination),
      );

  bool _destinationFilter(NcFile file, Uri destination) =>
      file.uri.path != chainPathSegments(destination.path, file.name);

  Future<void> _cancelableAction(
    List<NcFile> files,
    Future<dynamic> Function(NcFile) action, {
    bool Function(NcFile file)? filter,
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
