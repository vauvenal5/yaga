import 'dart:async';
import 'dart:isolate';

import 'package:yaga/managers/isolateable/isolated_file_manager.dart';
import 'package:yaga/managers/isolateable/sort_manager.dart';
import 'package:yaga/model/sorted_file_list.dart';
import 'package:yaga/utils/forground_worker/isolate_handler_regestry.dart';
import 'package:yaga/utils/forground_worker/isolate_msg_handler.dart';
import 'package:yaga/utils/forground_worker/messages/file_list_done.dart';
import 'package:yaga/utils/forground_worker/messages/file_list_request.dart';
import 'package:yaga/utils/forground_worker/messages/init_msg.dart';
import 'package:yaga/utils/forground_worker/messages/merge_sort_done.dart';
import 'package:yaga/utils/forground_worker/messages/merge_sort_request.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/utils/uri_utils.dart';

class FileListRequestHandler
    implements IsolateMsgHandler<FileListRequestHandler> {
  @override
  Future<FileListRequestHandler> initIsolated(
    InitMsg init,
    SendPort isolateToMain,
    IsolateHandlerRegistry registry,
  ) async {
    registry.registerHandler<FileListRequest>(
      (msg) => this.handle(msg, isolateToMain),
    );
    registry.registerHandler<MergeSortRequest>(
      (msg) => this.handleMergeSort(msg, isolateToMain),
    );
    return this;
  }

  void handle(FileListRequest message, SendPort isolateToMain) {
    getIt
        .get<IsolatedFileManager>()
        .listFileLists(
          message.key,
          message.uri,
          message.config,
          recursive: message.recursive,
        )
        .then(
          (_) => isolateToMain.send(
            FileListDone(
              message.key,
              message.uri,
              message.recursive,
            ),
          ),
        );
  }

  void handleMergeSort(
    MergeSortRequest message,
    SendPort isolateToMain,
  ) {
    SortedFileList addition = message.addition;

    if (message.uri != null && !message.recursive) {
      addition = addition.applyFilter(
        (file) =>
            file.uri.path ==
            UriUtils.chainPathSegments(message.uri.path, file.name),
      );
    }

    if (getIt.get<SortManager>().mergeSort(message.main, addition)) {
      isolateToMain.send(MergeSortDone(
        message.key,
        message.main,
        updateLoading: message.updateLoading,
      ));
    }
  }
}
