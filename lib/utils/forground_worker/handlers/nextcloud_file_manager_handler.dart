import 'dart:isolate';

import 'package:yaga/managers/isolateable/isolated_file_manager.dart';
import 'package:yaga/managers/isolateable/nextcloud_file_manger.dart';
import 'package:yaga/utils/forground_worker/isolate_handler_regestry.dart';
import 'package:yaga/utils/forground_worker/isolate_msg_handler.dart';
import 'package:yaga/utils/forground_worker/messages/files_action/copy_files_request.dart';
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
        (msg) => this.handleDelete(msg, isolateToMain));
    registry.registerHandler<CopyFilesRequest>(
        (msg) => this.handleCopy(msg, isolateToMain));
    registry.registerHandler<FilesActionDone>((msg) => this.handleCancel(msg));
    registry.registerHandler<DownloadPreviewRequest>(
        (msg) => this.handleDownloadPreview(msg, isolateToMain));
    return this;
  }

  void handleDelete(DeleteFilesRequest message, SendPort isolateToMain) {
    getIt
        .get<IsolatedFileManager>()
        .deleteFiles(message.files, message.local)
        .then((_) => isolateToMain.send(FilesActionDone(message.key)));
  }

  void handleCopy(CopyFilesRequest message, SendPort isolateToMain) {
    final fileManager = getIt.get<IsolatedFileManager>();

    fileManager
        .copyFiles(message.files, message.destination)
        .then((_) => isolateToMain.send(FilesActionDone(message.key)))
        .whenComplete(
          () => fileManager.listFileLists(message.key, message.destination),
        );
  }

  void handleCancel(FilesActionDone message) {
    getIt.get<IsolatedFileManager>().cancelActionCommand(true);
  }

  void handleDownloadPreview(
    DownloadPreviewRequest msg,
    SendPort isolateToMain,
  ) {
    getIt.get<NextcloudFileManager>().updatePreviewCommand.listen((file) {
      isolateToMain.send(DownloadPreviewComplete("", file));
    });

    getIt.get<NextcloudFileManager>().downloadPreviewFaildCommand.listen(
          (file) => isolateToMain.send(
            DownloadPreviewComplete("", file, success: false),
          ),
        );

    getIt.get<NextcloudFileManager>().downloadPreviewCommand(msg.file);
  }
}
