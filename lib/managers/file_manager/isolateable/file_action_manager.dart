import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:nextcloud/nextcloud.dart';
import 'package:rx_command/rx_command.dart';
import 'package:rxdart/rxdart.dart';
import 'package:yaga/managers/file_manager/file_manager_base.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/services/isolateable/local_file_service.dart';
import 'package:yaga/services/isolateable/nextcloud_service.dart';
import 'package:yaga/utils/background_worker/background_channel.dart';
import 'package:yaga/utils/forground_worker/messages/file_update_msg.dart';
import 'package:yaga/utils/forground_worker/messages/files_action/delete_files_request.dart';
import 'package:yaga/utils/forground_worker/messages/files_action/destination_action_files_request.dart';
import 'package:yaga/utils/forground_worker/messages/files_action/favorite_files_request.dart';
import 'package:yaga/utils/forground_worker/messages/files_action/files_action_done.dart';
import 'package:yaga/utils/forground_worker/messages/files_action/files_action_request.dart';
import 'package:yaga/utils/forground_worker/messages/image_update_msg.dart';
import 'package:yaga/utils/logger.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/utils/uri_utils.dart';

class FileActionManager extends FileManagerBase {
  final _logger = YagaLogger.getLogger(FileActionManager);
  RxCommand<void, bool> cancelActionCommand = RxCommand.createSyncNoParam(() => true);

  Future<FileActionManager> initBackground(
    BackgroundChannel backgroundToMain,
  ) async {
    updateImageCommand.listen(
      (file) => backgroundToMain.send(ImageUpdateMsg("", file)),
    );

    return this;
  }

  Future<Uint8List> downloadFile(NcFile file, {bool persist = false}) async {
    return getIt.get<NextCloudService>().downloadImage(file.uri).then((value) async {
      if (persist) {
        await getIt.get<LocalFileService>().createFile(
              file: file.localFile!.file as File,
              bytes: value,
              lastModified: file.lastModified,
            );
        file.localFile!.exists = true;
      }
      return value;
    });
  }

  Future<void> deleteFiles(DeleteFilesRequest message) async => _cancelableAction(
        message,
        (file) async => fileServiceManagers[file.uri.scheme]?.deleteFile(file, local: message.local),
      );

  Future<void> copyMoveRequest(DestinationActionFilesRequest message) =>
      message.action == DestinationAction.copy ? _copyFiles(message) : _moveFiles(message);

  Future<void> _copyFiles(DestinationActionFilesRequest message) async => _cancelableAction(
        message,
        (file) async => fileServiceManagers[file.uri.scheme]?.copyFile(
          file,
          message.destination,
          overwrite: message.overwrite,
        ),
        filter: (file) => _destinationFilter(file, message.destination),
      );

  Future<void> _moveFiles(DestinationActionFilesRequest message) async => _cancelableAction(
        message,
        (file) async => fileServiceManagers[file.uri.scheme]
            ?.moveFile(
              file,
              message.destination,
              overwrite: message.overwrite,
            )
            .then(
              (value) => fileUpdateMessage(FileUpdateMsg("", file)),
            ),
        filter: (file) => _destinationFilter(file, message.destination),
      );

  Future<void> toggleFavorites(FavoriteFilesRequest message) => Stream.fromIterable(message.files)
      .asyncMap(
        (file) => fileServiceManagers[file.uri.scheme]?.toggleFavorite(file).then((file) => updateImageCommand(file)),
      )
      .toList();

  bool _destinationFilter(NcFile file, Uri destination) => !compareFilePathToTargetFilePath(file, destination);

  Future<void> _cancelableAction(
    FilesActionRequest request,
    Future<dynamic> Function(NcFile) action, {
    bool Function(NcFile file)? filter,
  }) =>
      Stream.fromIterable(request.files)
          .where((event) => filter == null || filter(event))
          .asyncMap(
            (file) => action(file).catchError(
              (err) => null,
              test: (err) => err is DynamiteApiException || err is FileSystemException,
            ),
          )
          .where((event) => event != null)
          .takeUntil(
            cancelActionCommand.doOnData((event) => _logger.finest("Canceling action!")),
          )
          .toList()
          .whenComplete(
            () => filesActionDoneCommand(FilesActionDone(request.key, request.sourceDir)),
          );

  @override
  Stream<NcFile> listFiles(Uri uri, {bool recursive = false}) {
    // not supported in true background because not needed when app not in foreground
    throw UnimplementedError();
  }
}
