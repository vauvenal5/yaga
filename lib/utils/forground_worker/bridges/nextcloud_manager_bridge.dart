import 'package:rx_command/rx_command.dart';
import 'package:yaga/managers/isolateable/nextcloud_file_manger.dart';
import 'package:yaga/managers/nextcloud_manager.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/utils/forground_worker/foreground_worker.dart';
import 'package:yaga/utils/forground_worker/messages/download_preview_complete.dart';
import 'package:yaga/utils/forground_worker/messages/download_preview_request.dart';
import 'package:yaga/utils/forground_worker/messages/login_state_msg.dart';

class NextcloudManagerBridge {
  final NextCloudManager _nextCloudManager;
  final ForegroundWorker _worker;
  final NextcloudFileManager _nextcloudFileManager;

  RxCommand<NcFile, NcFile> downloadPreviewCommand =
      RxCommand.createSync((param) => param);

  NextcloudManagerBridge(
    this._nextCloudManager,
    this._worker,
    this._nextcloudFileManager,
  ) {
    //todo: update loginStateCommand has no logout values... see todo in ncManager
    _nextCloudManager.updateLoginStateCommand.listen((value) {
      _worker.sendRequest(LoginStateMsg("", value));
    });

    _worker.isolateResponseCommand
        .where((event) => event is DownloadPreviewComplete)
        .map((event) => event as DownloadPreviewComplete)
        .listen(
          (value) => value.success
              ? _nextcloudFileManager.updatePreviewCommand(value.file)
              : _nextcloudFileManager.downloadPreviewFaildCommand(value.file),
        );

    downloadPreviewCommand.listen((ncFile) {
      _worker.sendRequest(DownloadPreviewRequest("", ncFile));
    });
  }
}
