import 'dart:isolate';

import 'package:yaga/managers/file_manager/isolateable/isolated_file_manager.dart';
import 'package:yaga/managers/file_service_manager/isolateable/nextcloud_file_manger.dart';
import 'package:yaga/model/fetched_file.dart';
import 'package:yaga/utils/forground_worker/isolate_handler_regestry.dart';
import 'package:yaga/utils/forground_worker/isolate_msg_handler.dart';
import 'package:yaga/utils/forground_worker/messages/download_file_request.dart';
import 'package:yaga/utils/forground_worker/messages/download_preview_complete.dart';
import 'package:yaga/utils/forground_worker/messages/download_preview_request.dart';
import 'package:yaga/utils/forground_worker/messages/files_action/delete_files_request.dart';
import 'package:yaga/utils/forground_worker/messages/files_action/destination_action_files_request.dart';
import 'package:yaga/utils/forground_worker/messages/files_action/files_action_done.dart';
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
        .whenComplete(() => isolateToMain.send(FilesActionDone(message.key, message.sourceDir)));
  }

  void handleDestinationAction(
    DestinationActionFilesRequest message,
    SendPort isolateToMain,
  ) {
    final action = getIt.get<IsolatedFileManager>().copyMoveRequest(message);

    action
        .whenComplete(
          () => isolateToMain.send(FilesActionDone(message.key, message.destination)),
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
    getIt.get<IsolatedFileManager>()
        .downloadFile(request.file, persist: request.persist)
        .then((value) async {
      isolateToMain.send(FetchedFile(request.file, value));
    });
  }
}
