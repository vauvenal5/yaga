import 'dart:async';
import 'dart:isolate';

import 'package:yaga/managers/isolateable/isolated_file_manager.dart';
import 'package:yaga/utils/forground_worker/isolate_handler_regestry.dart';
import 'package:yaga/utils/forground_worker/isolate_msg_handler.dart';
import 'package:yaga/utils/forground_worker/messages/file_list_done.dart';
import 'package:yaga/utils/forground_worker/messages/file_list_request.dart';
import 'package:yaga/utils/forground_worker/messages/init_msg.dart';
import 'package:yaga/utils/service_locator.dart';

class FileListRequestHandler
    implements IsolateMsgHandler<FileListRequestHandler> {
  @override
  Future<FileListRequestHandler> initIsolated(
    InitMsg init,
    SendPort isolateToMain,
    IsolateHandlerRegistry registry,
  ) async {
    registry.registerHandler<FileListRequest>(
        (msg) => this.handle(msg, isolateToMain));
    return this;
  }

  void handle(FileListRequest message, SendPort isolateToMain) {
    getIt
        .get<IsolatedFileManager>()
        .listFileLists(message.key, message.uri, recursive: message.recursive)
        .listen((event) => isolateToMain.send(event))
        .onDone(
          () => isolateToMain.send(
            FileListDone(
              message.key,
              message.uri,
              message.recursive,
            ),
          ),
        );
  }
}
