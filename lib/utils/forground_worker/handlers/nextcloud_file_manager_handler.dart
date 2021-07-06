import 'dart:io';
import 'dart:isolate';
import 'package:yaga/managers/isolateable/isolated_file_manager.dart';
import 'package:yaga/managers/isolateable/isolated_global_settings_manager.dart';
import 'package:yaga/managers/isolateable/nextcloud_file_manger.dart';
import 'package:yaga/model/fetched_file.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/services/isolateable/local_file_service.dart';
import 'package:yaga/services/isolateable/nextcloud_service.dart';
import 'package:yaga/utils/forground_worker/isolate_handler_regestry.dart';
import 'package:yaga/utils/forground_worker/isolate_msg_handler.dart';
import 'package:yaga/utils/forground_worker/messages/download_file_request.dart';
import 'package:yaga/utils/forground_worker/messages/files_action/destination_action_files_request.dart';
import 'package:yaga/utils/forground_worker/messages/files_action/files_action_done.dart';
import 'package:yaga/utils/forground_worker/messages/files_action/delete_files_request.dart';
import 'package:yaga/utils/forground_worker/messages/download_preview_complete.dart';
import 'package:yaga/utils/forground_worker/messages/download_preview_request.dart';
import 'package:yaga/utils/forground_worker/messages/init_msg.dart';
import 'package:yaga/utils/service_locator.dart';

class NextcloudFileManagerHandler
    implements IsolateMsgHandler<NextcloudFileManagerHandler> {
  @override
  Future<NextcloudFileManagerHandler> initIsolated(
    InitMsg init,
    SendPort isolateToMain,
    IsolateHandlerRegistry registry,
  ) async {
    registry.registerHandler<DeleteFilesRequest>(
        (msg) => handleDelete(msg, isolateToMain));
    registry.registerHandler<DestinationActionFilesRequest>(
        (msg) => handleDestinationAction(msg, isolateToMain));
    registry.registerHandler<FilesActionDone>((msg) => handleCancel(msg));
    registry.registerHandler<DownloadPreviewRequest>(
        (msg) => handleDownloadPreview(msg, isolateToMain));
    registry.registerHandler<DownloadFileRequest>(
        (msg) => handleDownload(msg, isolateToMain));
    return this;
  }

  NextcloudFileManagerHandler(
    NextcloudFileManager nextcloudFileManager,
    SendPort isolateToMain,
  ) {
    nextcloudFileManager.updatePreviewCommand.listen((file) {
      isolateToMain.send(DownloadPreviewComplete("", file));
    });

    nextcloudFileManager.downloadPreviewFaildCommand.listen(
      (file) => isolateToMain.send(
        DownloadPreviewComplete("", file, success: false),
      ),
    );
  }

  void handleDelete(DeleteFilesRequest message, SendPort isolateToMain) {
    getIt
        .get<IsolatedFileManager>()
        .deleteFiles(message.files, local: message.local)
        .whenComplete(() => isolateToMain.send(FilesActionDone(message.key)));
  }

  void handleDestinationAction(
    DestinationActionFilesRequest message,
    SendPort isolateToMain,
  ) {
    final fileManager = getIt.get<IsolatedFileManager>();

    final action = message.action == DestinationAction.copy
        ? fileManager.copyFiles(
            message.files,
            message.destination,
            overwrite: message.overwrite,
          )
        : fileManager.moveFiles(
            message.files,
            message.destination,
            overwrite: message.overwrite,
          );

    action
        .whenComplete(
          () => isolateToMain.send(FilesActionDone(message.key)),
        )
        .whenComplete(
          () => fileManager.listFileLists(
            message.key,
            message.destination,
            message.config,
          ),
        );
  }

  void handleCancel(FilesActionDone message) {
    getIt.get<IsolatedFileManager>().cancelActionCommand(true);
  }

  void handleDownloadPreview(
    DownloadPreviewRequest msg,
    SendPort isolateToMain,
  ) {
    getIt.get<NextcloudFileManager>().downloadPreviewCommand(msg.file);
  }

  Future<void> handleDownload(
    DownloadFileRequest request,
    SendPort isolateToMain,
  ) async {
    final NcFile ncFile = request.file;
    if (ncFile.localFile != null && await ncFile.localFile.file.exists()) {
      ncFile.localFile.exists = true;
      isolateToMain.send(FetchedFile(
        ncFile,
        await (ncFile.localFile.file as File).readAsBytes(),
      ));
      return;
    }

    getIt.get<NextCloudService>().downloadImage(ncFile.uri).then((value) async {
      if (request.overrideGlobalPersistFlag ||
          getIt.get<IsolatedGlobalSettingsManager>().autoPersist.value) {
        ncFile.localFile.file = await getIt.get<LocalFileService>().createFile(
            file: ncFile.localFile.file as File,
            bytes: value,
            lastModified: ncFile.lastModified);
        ncFile.localFile.exists = true;
      }

      isolateToMain.send(FetchedFile(ncFile, value));
    });
  }
}
