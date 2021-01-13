import 'dart:async';
import 'dart:isolate';

import 'package:yaga/managers/isolateable/isolated_file_manager.dart';
import 'package:yaga/managers/isolateable/nextcloud_file_manger.dart';
import 'package:yaga/utils/forground_worker/messages/delete_files_done.dart';
import 'package:yaga/utils/forground_worker/messages/delete_files_request.dart';
import 'package:yaga/utils/forground_worker/messages/file_update_msg.dart';
import 'package:yaga/utils/service_locator.dart';

//todo: clean up handlers
//--> updateFileList is used in two places
//--> create a handler regestry
class DeleteFilesHandler {
  static void handle(DeleteFilesRequest message, SendPort isolateToMain) {
    StreamSubscription updateSub =
        getIt.get<IsolatedFileManager>().updateFileList.listen((value) {
      isolateToMain.send(FileUpdateMsg(message.key, value));
    });

    getIt
        .get<NextcloudFileManager>()
        .deleteFiles(message.files)
        .then((_) => isolateToMain.send(DeleteFilesDone(message.key)))
        .whenComplete(() => updateSub.cancel());
  }
}
