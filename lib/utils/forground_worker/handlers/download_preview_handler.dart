import 'dart:isolate';

import 'package:yaga/managers/isolateable/nextcloud_file_manger.dart';
import 'package:yaga/utils/forground_worker/messages/download_preview_complete.dart';
import 'package:yaga/utils/forground_worker/messages/download_preview_request.dart';
import 'package:yaga/utils/service_locator.dart';

class DownloadPreviewHandler {
  static void handle(DownloadPreviewRequest msg, SendPort isolateToMain) {
    getIt.get<NextcloudFileManager>().updatePreviewCommand.listen((file) {
      isolateToMain.send(DownloadPreviewComplete("", file));
    });

    getIt.get<NextcloudFileManager>().downloadPreviewCommand(msg.file);
  }
}
