import 'dart:async';
import 'dart:isolate';

import 'package:yaga/managers/isolateable/isolated_file_manager.dart';
import 'package:yaga/utils/forground_worker/messages/file_list_done.dart';
import 'package:yaga/utils/forground_worker/messages/file_list_request.dart';
import 'package:yaga/utils/forground_worker/messages/file_update_msg.dart';
import 'package:yaga/utils/service_locator.dart';

class FileListRequestHandler {
  static void handle(FileListRequest message, SendPort isolateToMain) {
    StreamSubscription updateSub =
        getIt.get<IsolatedFileManager>().updateFileList.listen((value) {
      isolateToMain.send(FileUpdateMsg(message.key, value));
    });

    getIt
        .get<IsolatedFileManager>()
        .listFileLists(message.key, message.uri, recursive: message.recursive)
        .listen((event) => isolateToMain.send(event))
        .onDone(() {
      isolateToMain
          .send(FileListDone(message.key, message.uri, message.recursive));
      updateSub.cancel();
    });
  }
}
