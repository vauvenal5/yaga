import 'package:rxdart/rxdart.dart';
import 'package:yaga/managers/settings_manager.dart';
import 'package:yaga/utils/forground_worker/foreground_worker.dart';
import 'package:yaga/utils/forground_worker/messages/preference_msg.dart';
import 'package:yaga/utils/logger.dart';

class SettingsManagerBridge {
  final _logger = YagaLogger.getLogger(SettingsManagerBridge);
  final SettingsManager _settingsManager;
  final ForegroundWorker _worker;

  SettingsManagerBridge(this._settingsManager, this._worker);

  Future<SettingsManagerBridge> init() async {
    _settingsManager.updateSettingCommand.doOnData((event) {
      _logger.warning(event);
    }).listen((event) => _worker.sendRequest(PreferenceMsg("", event)));

    return this;
  }
}
