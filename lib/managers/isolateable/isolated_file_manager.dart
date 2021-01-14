import 'dart:isolate';

import 'package:yaga/managers/file_manager_base.dart';
import 'package:yaga/utils/forground_worker/isolateable.dart';
import 'package:yaga/utils/forground_worker/messages/file_update_msg.dart';
import 'package:yaga/utils/forground_worker/messages/init_msg.dart';

class IsolatedFileManager extends FileManagerBase
    with Isolateable<IsolatedFileManager> {
  Future<IsolatedFileManager> initIsolated(
    InitMsg init,
    SendPort isolateToMain,
  ) async {
    //todo: we probably can improve the capsuling of front end and foreground_worker communication further
    //--> check if it is possible to completely hide communications in bridges
    this.updateFileList.listen((value) {
      isolateToMain.send(FileUpdateMsg("", value));
    });
    return this;
  }
}
