import 'dart:async';
import 'dart:isolate';

import 'package:yaga/managers/isolateable/isolated_file_manager.dart';
import 'package:yaga/managers/isolateable/nextcloud_file_manger.dart';
import 'package:yaga/utils/forground_worker/messages/delete_files_done.dart';
import 'package:yaga/utils/forground_worker/messages/delete_files_request.dart';
import 'package:yaga/utils/forground_worker/messages/file_update_msg.dart';
import 'package:yaga/utils/service_locator.dart';

//todo: clean up handlers
//--> create a handler regestry
class DeleteFilesHandler {
  static void handle(DeleteFilesRequest message, SendPort isolateToMain) {
    getIt
        .get<NextcloudFileManager>()
        .deleteFiles(message.files)
        .then((_) => isolateToMain.send(DeleteFilesDone(message.key)));
  }

  static void handleCancel(DeleteFilesDone message, SendPort isolateToMain) {
    getIt.get<NextcloudFileManager>().cancelDeleteCommand(true);
  }
}
