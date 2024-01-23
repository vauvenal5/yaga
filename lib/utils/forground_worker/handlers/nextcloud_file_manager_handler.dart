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
import 'package:yaga/utils/forground_worker/messages/files_action/favorite_files_request.dart';
import 'package:yaga/utils/forground_worker/messages/files_action/files_action_done.dart';
import 'package:yaga/utils/forground_worker/messages/init_msg.dart';
import 'package:yaga/utils/service_locator.dart';

class NextcloudFileManagerHandler implements IsolateMsgHandler<NextcloudFileManagerHandler> {
  @override
  Future<NextcloudFileManagerHandler> initIsolated(
    InitMsg init,
    SendPort isolateToMain,
    IsolateHandlerRegistry registry,
  ) async {
    registry.registerHandler<DeleteFilesRequest>(
      (msg) => getIt.get<IsolatedFileManager>().deleteFiles(msg),
    );
    registry.registerHandler<FavoriteFilesRequest>(
      (msg) => getIt.get<IsolatedFileManager>().toggleFavorites(msg),
    );
    registry.registerHandler<DestinationActionFilesRequest>(
      (msg) => getIt.get<IsolatedFileManager>().copyMoveRequest(msg),
    );
    registry.registerHandler<FilesActionDone>(
      (msg) => getIt.get<IsolatedFileManager>().cancelActionCommand(true),
    );
    registry.registerHandler<DownloadPreviewRequest>(
      (msg) => getIt.get<NextcloudFileManager>().downloadPreviewCommand(msg.file),
    );
    registry.registerHandler<DownloadFileRequest>(
      (msg) => handleDownload(msg, isolateToMain),
    );

    getIt.get<IsolatedFileManager>().filesActionDoneCommand.listen((value) => isolateToMain.send(value));
    getIt.get<IsolatedFileManager>().fileUpdateMessage.listen((value) => isolateToMain.send(value));
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

  Future<void> handleDownload(
    DownloadFileRequest request,
    SendPort isolateToMain,
  ) async {
    getIt.get<IsolatedFileManager>().downloadFile(request.file, persist: request.persist).then((value) async {
      isolateToMain.send(FetchedFile(request.file, value));
    });
  }
}
