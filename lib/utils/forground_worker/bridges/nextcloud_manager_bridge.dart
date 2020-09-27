import 'package:yaga/managers/nextcloud_manager.dart';
import 'package:yaga/utils/forground_worker/foreground_worker.dart';
import 'package:yaga/utils/forground_worker/messages/login_state_msg.dart';

class NextcloudManagerBridge {
  final NextCloudManager _nextCloudManager;
  final ForegroundWorker _worker;

  NextcloudManagerBridge(this._nextCloudManager, this._worker) {
    this._nextCloudManager.updateLoginStateCommand
      .listen((value) {
        this._worker.sendRequest(LoginStateMsg("", value));
      });

    this._worker.sendRequest(LoginStateMsg("",this._nextCloudManager.updateLoginStateCommand.lastResult));
  }
}