import 'package:rx_command/rx_command.dart';
import 'package:yaga/managers/isolateable/nextcloud_file_manger.dart';
import 'package:yaga/managers/nextcloud_manager.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/utils/forground_worker/foreground_worker.dart';
import 'package:yaga/utils/forground_worker/messages/download_preview_complete.dart';
import 'package:yaga/utils/forground_worker/messages/download_preview_request.dart';
import 'package:yaga/utils/forground_worker/messages/login_state_msg.dart';
import 'package:yaga/utils/service_locator.dart';

class NextcloudManagerBridge {
  final NextCloudManager _nextCloudManager;
  final ForegroundWorker _worker;

  RxCommand<NcFile, NcFile> downloadPreviewCommand =
      RxCommand.createSync((param) => param);

  NextcloudManagerBridge(this._nextCloudManager, this._worker) {
    //todo: update loginStateCommand has no logout values... see todo in ncManager
    this._nextCloudManager.updateLoginStateCommand.listen((value) {
      this._worker.sendRequest(LoginStateMsg("", value));
    });

    this
        ._worker
        .isolateResponseCommand
        .where((event) => event is DownloadPreviewComplete)
        .map((event) => event as DownloadPreviewComplete)
        .listen((value) =>
            getIt.get<NextcloudFileManager>().updatePreviewCommand(value.file));

    this.downloadPreviewCommand.listen((ncFile) {
      this._worker.sendRequest(DownloadPreviewRequest("", ncFile));
    });
  }
}
